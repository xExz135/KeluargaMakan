import { randomBytes, randomUUID } from "node:crypto";

import { DATA_KEY_BYTES, type KeyEncryptionKey, type KeyProvider } from "./crypto/key-provider.js";
import { NotFoundError, SQLSTATE, translateDbError } from "./errors.js";
import type { SqlExecutor } from "./executor.js";
import { isUuid } from "./ids.js";

/**
 * Per-member data keys for health data (DAT-02). Each member gets one random
 * AES-256 data key, stored only wrapped by the health-data KEK. The key row's
 * ID is also the member's pseudonymous ID in the safety log (QUESTIONS #40).
 *
 * Deleting the row makes every hard rule and safety log detail of that member
 * unreadable in the live database. Backups and point-in-time-recovery copies
 * taken earlier still hold the wrapped key and the ciphertext, and the
 * health-data key can still read them, until they are purged on their normal
 * cycle (SET-08). Backup and PITR retention must therefore stay within the
 * SET-04 window (T-023). The migrations delete the row when consent is
 * declined or withdrawn and when the profile or household is deleted.
 *
 * A key can be created only under an active health consent (database
 * trigger, migration 0005), and only by a rule write.
 */

export interface MemberDataKey {
  readonly keyId: string;
  readonly profileId: string;
  readonly dataKey: Uint8Array;
}

/** A `health_data_key` row as read from the database. */
export interface StoredKeyRow {
  readonly id: string;
  readonly profile_id: string;
  readonly household_id: string;
  readonly key_ref: string;
  readonly wrapped_key: Uint8Array;
}

function wrapContext(keyId: string, profileId: string, householdId: string): string {
  return `health_data_key:${keyId}:${profileId}:${householdId}`;
}

export class HealthDataKeys {
  readonly #kek: KeyEncryptionKey;

  constructor(provider: KeyProvider) {
    const kek = provider.kek("health");
    if (kek.purpose !== "health") {
      throw new Error("health data must be wrapped by the health-data key (DAT-02)");
    }
    this.#kek = kek;
  }

  /** Unwraps one stored key row. Throws on any unwrap failure. */
  async unwrap(row: StoredKeyRow): Promise<MemberDataKey> {
    const dataKey = await this.#kek.unwrap(
      { keyRef: row.key_ref, wrapped: row.wrapped_key },
      wrapContext(row.id, row.profile_id, row.household_id),
    );
    return { keyId: row.id, profileId: row.profile_id, dataKey };
  }

  /** Unwraps the keys of the given members (only those that have one). Throws on any unwrap failure. */
  async loadForProfiles(
    db: SqlExecutor,
    householdId: string,
    profileIds: readonly string[],
  ): Promise<Map<string, MemberDataKey>> {
    const ids = profileIds.filter(isUuid);
    if (!isUuid(householdId) || ids.length === 0) return new Map();
    const { rows } = await db.query<StoredKeyRow>(
      `SELECT id, profile_id, household_id, key_ref, wrapped_key
         FROM health_data_key
        WHERE household_id = $1 AND profile_id = ANY($2::uuid[])`,
      [householdId, ids],
    );
    const keys = await Promise.all(rows.map((row) => this.unwrap(row)));
    return new Map(keys.map((key) => [key.profileId, key]));
  }

  /** Unwraps keys of one household by key ID (the pseudonymous member ID in the safety log). */
  async loadByKeyIds(
    db: SqlExecutor,
    householdId: string,
    keyIds: readonly string[],
  ): Promise<Map<string, MemberDataKey>> {
    const ids = keyIds.filter(isUuid);
    if (!isUuid(householdId) || ids.length === 0) return new Map();
    const { rows } = await db.query<StoredKeyRow>(
      `SELECT id, profile_id, household_id, key_ref, wrapped_key
         FROM health_data_key
        WHERE household_id = $1 AND id = ANY($2::uuid[])`,
      [householdId, ids],
    );
    const keys = await Promise.all(rows.map((row) => this.unwrap(row)));
    return new Map(keys.map((key) => [key.keyId, key]));
  }

  /**
   * Returns the member's key, creating it on first use. For rule writes only:
   * the caller holds the member lock (`lockMembers`) and has checked consent;
   * the database refuses a new key without an active consent
   * (`ConsentRequiredError`). The safety log never creates keys.
   */
  async getOrCreate(
    db: SqlExecutor,
    householdId: string,
    profileId: string,
  ): Promise<MemberDataKey> {
    if (!isUuid(householdId) || !isUuid(profileId)) throw new NotFoundError("profile");
    const existing = (await this.loadForProfiles(db, householdId, [profileId])).get(profileId);
    if (existing !== undefined) return existing;

    const keyId = randomUUID();
    const dataKey = randomBytes(DATA_KEY_BYTES);
    const wrapped = await this.#kek.wrap(dataKey, wrapContext(keyId, profileId, householdId));
    let inserted;
    try {
      inserted = await db.query(
        `INSERT INTO health_data_key (id, household_id, profile_id, key_ref, wrapped_key)
         VALUES ($1, $2, $3, $4, $5)
         ON CONFLICT (profile_id) DO NOTHING
         RETURNING id`,
        [keyId, householdId, profileId, wrapped.keyRef, Buffer.from(wrapped.wrapped)],
      );
    } catch (error) {
      if (
        typeof error === "object" &&
        error !== null &&
        (error as { code?: unknown }).code === SQLSTATE.foreignKeyViolation
      ) {
        throw new NotFoundError("profile");
      }
      throw translateDbError(error);
    }
    if (inserted.rowCount === 1) return { keyId, profileId, dataKey };
    // Created concurrently by another request: use that one.
    const created = (await this.loadForProfiles(db, householdId, [profileId])).get(profileId);
    if (created === undefined) throw new NotFoundError("profile");
    return created;
  }
}
