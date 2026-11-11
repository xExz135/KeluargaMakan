import { withDbErrors } from "./errors.js";
import type { SqlExecutor } from "./executor.js";
import { isUuid } from "./ids.js";

/**
 * Data-layer pieces of SET-04, SET-07, SET-08, DAT-04 (via QUESTIONS #19) and
 * DAT-05. The full flows (scheduling, object storage, caches, confirmation
 * screens) are later tasks (T-072); these functions are what they call.
 *
 * What the database guarantees on its own (migrations 0001 to 0005):
 * - Deleting a profile removes its preferences, likes and dislikes, hard
 *   rules, data key, meal participation and per-member feedback. Deleting the
 *   data key redacts the member's safety log details and replaces their
 *   pseudonymous ID with a random one. Consent records are kept, unlinked
 *   (QUESTIONS #33 safer default, legal to confirm).
 * - Deleting a household removes every row that belongs to it. Safety log rows
 *   stay for DAT-05, but lose the household link and every member's details
 *   and pseudonym, so they keep only the subject, versions and times. They are
 *   still pseudonymous rather than anonymous data (review T-016 M3, legal).
 * - Declining or withdrawing health consent deletes the member's data key,
 *   which removes the hard rules and redacts the log details at once (SET-04).
 *
 * All of this applies to the live database. Backups and point-in-time-recovery
 * copies are not changed: they are purged on their normal cycle (SET-08), and
 * T-023 must keep backup and PITR retention within the SET-04 window.
 */

/**
 * SET-07: deletes one profile and all of its data. The manager's own profile
 * cannot be deleted this way (`ManagerProfileNotDeletableError`); it goes with
 * the household.
 */
export async function deleteProfile(
  db: SqlExecutor,
  householdId: string,
  profileId: string,
): Promise<boolean> {
  if (!isUuid(householdId) || !isUuid(profileId)) return false;
  return withDbErrors(() =>
    db.transaction(async (tx) => {
      const { rowCount } = await tx.query(
        `DELETE FROM profile WHERE id = $1 AND household_id = $2`,
        [profileId, householdId],
      );
      // Check the deferred manager-profile constraint now, inside this call.
      await tx.query(`SET CONSTRAINTS ALL IMMEDIATE`);
      return rowCount === 1;
    }),
  );
}

/** SET-08, ACC-14: deletes the household, its manager account and all household data. */
export async function deleteHousehold(db: SqlExecutor, householdId: string): Promise<boolean> {
  if (!isUuid(householdId)) return false;
  return withDbErrors(() =>
    db.transaction(async (tx) => {
      const { rowCount } = await tx.query(`DELETE FROM household WHERE id = $1`, [householdId]);
      await tx.query(`SET CONSTRAINTS ALL IMMEDIATE`);
      return rowCount === 1;
    }),
  );
}

/**
 * SET-04 backstop for the deletion job: removes any data key (and so any hard
 * rule and unredacted log detail) still held for a member whose latest
 * health-data consent is declined or withdrawn. The triggers already do this
 * when the decision is recorded, so a non-zero result means something went
 * wrong and must be reported.
 */
export async function enforceHealthConsent(db: SqlExecutor): Promise<number> {
  const { rowCount } = await db.query(
    `DELETE FROM health_data_key k
      USING (
        SELECT DISTINCT ON (profile_id) profile_id, decision, withdrawn_at
          FROM consent_record
         WHERE purpose = 'health_data' AND profile_id IS NOT NULL
         ORDER BY profile_id, seq DESC
      ) latest
      WHERE latest.profile_id = k.profile_id
        AND (latest.decision = 'declined' OR latest.withdrawn_at IS NOT NULL)`,
  );
  return rowCount;
}

function yearsBefore(now: Date, years: number): Date {
  if (!Number.isInteger(years) || years < 1) {
    throw new RangeError("retention must be a whole number of years, at least 1");
  }
  const cutoff = new Date(now.getTime());
  cutoff.setUTCFullYear(cutoff.getUTCFullYear() - years);
  return cutoff;
}

/**
 * DAT-05: deletes safety logs older than the retention period
 * (`targets.dataManagement.safetyLogRetentionYears`).
 */
export async function purgeExpiredSafetyLogs(
  db: SqlExecutor,
  now: Date,
  retentionYears: number,
): Promise<number> {
  const { rowCount } = await db.query(`DELETE FROM safety_log WHERE evaluated_at < $1`, [
    yearsBefore(now, retentionYears),
  ]);
  return rowCount;
}

/**
 * QUESTIONS #19 / DAT-04: deletes cooked-meal records (and their feedback)
 * older than the retention period (`targets.dataManagement.mealHistoryRetentionYears`).
 */
export async function purgeExpiredMeals(
  db: SqlExecutor,
  now: Date,
  retentionYears: number,
): Promise<number> {
  const cutoff = yearsBefore(now, retentionYears).toISOString().slice(0, 10);
  const { rowCount } = await db.query(`DELETE FROM meal WHERE eaten_on < $1::date`, [cutoff]);
  return rowCount;
}
