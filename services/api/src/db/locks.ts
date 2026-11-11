import { NotFoundError, withDbErrors } from "./errors.js";
import type { SqlExecutor } from "./executor.js";
import { isUuid } from "./ids.js";

/**
 * H4 (security review T-016): every health-data write (rule create or change,
 * consent decision, safety log details) first locks the members' profile rows,
 * in ID order so two writers cannot deadlock. A consent withdrawal therefore
 * waits for an in-flight rule write and then deletes what it wrote, and a rule
 * write that starts after a withdrawal sees it. The triggers in migration 0005
 * take the same lock, so writes that bypass this layer are serialized too.
 *
 * `FOR NO KEY UPDATE` excludes other health-data writers but does not block
 * unrelated inserts that only reference the profile (for example meal rows).
 *
 * N2 (re-check): no key service call is made while these locks are held, and
 * the transaction gets a `lock_timeout`, so a stuck writer makes the next one
 * fail fast with the retryable `ConcurrentUpdateError` instead of queuing.
 * Must be called inside a transaction.
 */

/** Longest wait for a member lock. Not an SRS figure; operational default. */
export const HEALTH_DATA_LOCK_TIMEOUT_MS = 5_000;

async function setLockTimeout(tx: SqlExecutor, timeoutMs: number): Promise<void> {
  if (!Number.isInteger(timeoutMs) || timeoutMs < 1) {
    throw new RangeError("lock timeout must be a positive whole number of milliseconds");
  }
  await tx.query(`SELECT set_config('lock_timeout', $1, true)`, [`${timeoutMs}ms`]);
}

export async function lockMembers(
  tx: SqlExecutor,
  householdId: string,
  profileIds: readonly string[],
  timeoutMs: number = HEALTH_DATA_LOCK_TIMEOUT_MS,
): Promise<void> {
  const ids = [...new Set(profileIds)].sort();
  if (!isUuid(householdId) || ids.length === 0 || !ids.every(isUuid)) {
    throw new NotFoundError("profile");
  }
  await setLockTimeout(tx, timeoutMs);
  const { rows } = await withDbErrors(() =>
    tx.query<{ id: string }>(
      `SELECT id FROM profile
        WHERE household_id = $1 AND id = ANY($2::uuid[])
        ORDER BY id
        FOR NO KEY UPDATE`,
      [householdId, ids],
    ),
  );
  if (rows.length !== ids.length) throw new NotFoundError("profile");
}

/**
 * N4 (re-check): before deleting a household or a profile, lock the rows to be
 * deleted in ID order (`FOR UPDATE`), the order every health-data writer uses.
 * The cascade then cannot deadlock against a safety log that holds locks on
 * several members. Returns the number of profiles locked.
 */
export async function lockProfilesForDeletion(
  tx: SqlExecutor,
  householdId: string,
  profileId: string | null,
  timeoutMs: number = HEALTH_DATA_LOCK_TIMEOUT_MS,
): Promise<number> {
  await setLockTimeout(tx, timeoutMs);
  const { rows } = await withDbErrors(() =>
    tx.query<{ id: string }>(
      `SELECT id FROM profile
        WHERE household_id = $1 AND ($2::uuid IS NULL OR id = $2::uuid)
        ORDER BY id
        FOR UPDATE`,
      [householdId, profileId],
    ),
  );
  return rows.length;
}
