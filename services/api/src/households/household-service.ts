import { randomUUID } from "node:crypto";

import type { ApiConfig } from "../../config/api.js";
import { ApiError, unauthenticated } from "../api-error.js";
import type { AuthContext, Clock } from "../auth/auth-service.js";
import { systemClock } from "../auth/auth-service.js";
import { keyedHash } from "../auth/crypto.js";
import { withDbErrors } from "../db/errors.js";
import type { SqlExecutor } from "../db/executor.js";

/**
 * ACC-03: the household and its single manager account. The signed-in
 * account becomes the household's only manager when it creates the household;
 * there is no way to add a second account (co-cooks are V2, ACC-11), and
 * family members are profiles, not accounts. The database enforces the same
 * rule (`account_one_manager_per_household`, `household_manager_account_key`).
 */

export type Language = "id" | "en";

export interface AvatarInput {
  readonly style: "initials" | "illustration";
  readonly colorToken: string | null;
  readonly illustrationId: string | null;
}

export interface HouseholdCreateInput {
  readonly name: string | null;
  readonly city: string | null;
  readonly timeZone: string;
  readonly language: Language;
  readonly managerProfile: { readonly name: string; readonly avatar: AvatarInput | null };
}

export interface HouseholdUpdateInput {
  readonly name?: string | null;
  readonly city?: string | null;
  readonly timeZone?: string;
  readonly language?: Language;
}

/** SRS 18.1 Household (contract `Household`). */
export interface HouseholdView {
  readonly id: string;
  readonly name: string | null;
  readonly city: string | null;
  readonly timeZone: string;
  readonly language: Language;
  readonly managerAccountId: string;
  readonly managerProfileId: string;
  readonly createdAt: Date;
  readonly updatedAt: Date;
}

interface HouseholdRow {
  id: string;
  name: string | null;
  city: string | null;
  time_zone: string;
  language: Language;
  manager_account_id: string;
  manager_profile_id: string;
  created_at: Date;
  updated_at: Date;
}

const HOUSEHOLD_COLUMNS = `id, name, city, time_zone, language, manager_account_id, manager_profile_id,
  created_at, updated_at`;

function toView(row: HouseholdRow): HouseholdView {
  return {
    id: row.id,
    name: row.name,
    city: row.city,
    timeZone: row.time_zone,
    language: row.language,
    managerAccountId: row.manager_account_id,
    managerProfileId: row.manager_profile_id,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

const householdRequired = () =>
  new ApiError("household_required", 409, "The account has no household yet");
const householdExists = () =>
  new ApiError("household_exists", 409, "The account already has a household");
const idempotencyKeyReused = () =>
  new ApiError("idempotency_key_reused", 409, "The Idempotency-Key was used with another request");

const CREATE_HOUSEHOLD = "create_household";

export interface HouseholdServiceDeps {
  readonly db: SqlExecutor;
  readonly config: ApiConfig;
  readonly hashKey: Buffer;
  readonly clock?: Clock;
}

export class HouseholdService {
  readonly #db: SqlExecutor;
  readonly #config: ApiConfig;
  readonly #hashKey: Buffer;
  readonly #clock: Clock;

  constructor(deps: HouseholdServiceDeps) {
    this.#db = deps.db;
    this.#config = deps.config;
    this.#hashKey = deps.hashKey;
    this.#clock = deps.clock ?? systemClock;
  }

  #transaction<T>(fn: (tx: SqlExecutor) => Promise<T>): Promise<T> {
    return withDbErrors(() =>
      this.#db.transaction(async (tx) => {
        await tx.query(`SELECT set_config('lock_timeout', $1, true)`, [
          `${this.#config.sessions.lockTimeoutMs}ms`,
        ]);
        return fn(tx);
      }),
    );
  }

  /**
   * ACC-03, ACC-04: creates the household with the caller as its only manager
   * and the manager's own adult profile. With an `Idempotency-Key`, a repeat
   * of the same request returns the household it created (`created: false`);
   * the same key with another body is refused.
   */
  async create(
    context: AuthContext,
    input: HouseholdCreateInput,
    idempotencyKey: string | null,
  ): Promise<{ household: HouseholdView; created: boolean }> {
    const now = this.#clock.now();
    const requestHash = keyedHash(this.#hashKey, "idempotent_request", canonicalCreate(input));
    const keptSince = new Date(
      now.getTime() - this.#config.retention.idempotencyKeyHours * 3600_000,
    );

    return this.#transaction(async (tx) => {
      const account = await tx.query<{ household_id: string | null }>(
        `SELECT household_id FROM account WHERE id = $1 FOR UPDATE`,
        [context.accountId],
      );
      const accountRow = account.rows[0];
      if (accountRow === undefined) throw unauthenticated();

      if (idempotencyKey !== null) {
        const previous = await tx.query<{
          operation: string;
          request_hash: Uint8Array;
          resource_id: string;
        }>(
          `SELECT operation, request_hash, resource_id FROM idempotency_record
            WHERE account_id = $1 AND idempotency_key = $2 AND created_at >= $3`,
          [context.accountId, idempotencyKey, keptSince],
        );
        const record = previous.rows[0];
        if (record !== undefined) {
          if (
            record.operation !== CREATE_HOUSEHOLD ||
            !Buffer.from(record.request_hash).equals(requestHash)
          ) {
            throw idempotencyKeyReused();
          }
          const household = await readHousehold(tx, record.resource_id);
          if (household === null || household.managerAccountId !== context.accountId) {
            throw householdExists();
          }
          return { household, created: false };
        }
      }

      if (accountRow.household_id !== null) throw householdExists();

      const householdId = randomUUID();
      const profileId = randomUUID();
      const avatar = input.managerProfile.avatar;
      await tx.query(
        `INSERT INTO household
           (id, name, city, time_zone, language, manager_account_id, manager_profile_id, created_at, updated_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $8)`,
        [
          householdId,
          input.name,
          input.city,
          input.timeZone,
          input.language,
          context.accountId,
          profileId,
          now,
        ],
      );
      await tx.query(`UPDATE account SET household_id = $1, updated_at = $3 WHERE id = $2`, [
        householdId,
        context.accountId,
        now,
      ]);
      // ACC-04: only a name is asked; the age group starts as adult.
      await tx.query(
        `INSERT INTO profile
           (id, household_id, name, avatar_style, avatar_color_token, avatar_illustration_id,
            age_group, created_at, updated_at)
         VALUES ($1, $2, $3, $4, $5, $6, 'adult', $7, $7)`,
        [
          profileId,
          householdId,
          input.managerProfile.name,
          avatar?.style ?? "initials",
          avatar?.colorToken ?? null,
          avatar?.illustrationId ?? null,
          now,
        ],
      );
      if (idempotencyKey !== null) {
        await tx.query(
          `DELETE FROM idempotency_record WHERE account_id = $1 AND idempotency_key = $2`,
          [context.accountId, idempotencyKey],
        );
        await tx.query(
          `INSERT INTO idempotency_record
             (account_id, idempotency_key, operation, request_hash, resource_id, created_at)
           VALUES ($1, $2, $3, $4, $5, $6)`,
          [context.accountId, idempotencyKey, CREATE_HOUSEHOLD, requestHash, householdId, now],
        );
      }
      // Check the deferred manager foreign keys now, inside this call.
      await tx.query(`SET CONSTRAINTS ALL IMMEDIATE`);
      const household = await readHousehold(tx, householdId);
      if (household === null) throw new ApiError("internal_error", 500, "Household not stored");
      return { household, created: true };
    });
  }

  /** ACC-03, ACC-13: the caller's household, unchanged by signing in on another device. */
  async get(context: AuthContext): Promise<HouseholdView> {
    const householdId = await this.#householdOf(this.#db, context);
    const household = await withDbErrors(() => readHousehold(this.#db, householdId));
    if (household === null) throw householdRequired();
    return household;
  }

  async update(context: AuthContext, input: HouseholdUpdateInput): Promise<HouseholdView> {
    const now = this.#clock.now();
    return this.#transaction(async (tx) => {
      const householdId = await this.#householdOf(tx, context);
      const sets: string[] = [];
      const params: unknown[] = [householdId];
      const set = (column: string, value: unknown) => {
        params.push(value);
        sets.push(`${column} = $${params.length}`);
      };
      if (input.name !== undefined) set("name", input.name);
      if (input.city !== undefined) set("city", input.city);
      if (input.timeZone !== undefined) set("time_zone", input.timeZone);
      if (input.language !== undefined) set("language", input.language);
      set("updated_at", now);
      await tx.query(`UPDATE household SET ${sets.join(", ")} WHERE id = $1`, params);
      const household = await readHousehold(tx, householdId);
      if (household === null) throw householdRequired();
      return household;
    });
  }

  /** The household of the calling account, read fresh (not from the token). */
  async #householdOf(db: SqlExecutor, context: AuthContext): Promise<string> {
    const { rows } = await withDbErrors(() =>
      db.query<{ household_id: string | null }>(`SELECT household_id FROM account WHERE id = $1`, [
        context.accountId,
      ]),
    );
    const row = rows[0];
    if (row === undefined) throw unauthenticated();
    if (row.household_id === null) throw householdRequired();
    return row.household_id;
  }
}

async function readHousehold(db: SqlExecutor, householdId: string): Promise<HouseholdView | null> {
  const { rows } = await db.query<HouseholdRow>(
    `SELECT ${HOUSEHOLD_COLUMNS} FROM household WHERE id = $1`,
    [householdId],
  );
  const row = rows[0];
  return row === undefined ? null : toView(row);
}

/** A fixed-order serialization of the request, so equal requests hash equally. */
function canonicalCreate(input: HouseholdCreateInput): string {
  const avatar = input.managerProfile.avatar;
  return JSON.stringify([
    input.name,
    input.city,
    input.timeZone,
    input.language,
    input.managerProfile.name,
    avatar === null ? null : [avatar.style, avatar.colorToken, avatar.illustrationId],
  ]);
}
