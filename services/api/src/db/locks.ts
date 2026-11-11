import { NotFoundError } from "./errors.js";
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
 * Must be called inside a transaction.
 */
export async function lockMembers(
  tx: SqlExecutor,
  householdId: string,
  profileIds: readonly string[],
): Promise<void> {
  const ids = [...new Set(profileIds)].sort();
  if (!isUuid(householdId) || ids.length === 0 || !ids.every(isUuid)) {
    throw new NotFoundError("profile");
  }
  const { rows } = await tx.query<{ id: string }>(
    `SELECT id FROM profile
      WHERE household_id = $1 AND id = ANY($2::uuid[])
      ORDER BY id
      FOR NO KEY UPDATE`,
    [householdId, ids],
  );
  if (rows.length !== ids.length) throw new NotFoundError("profile");
}
