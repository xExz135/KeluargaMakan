import { DataLayerError, NotFoundError, withDbErrors } from "./errors.js";
import type { SqlExecutor } from "./executor.js";
import { isUuid } from "./ids.js";
import { lockMembers } from "./locks.js";

/**
 * SRS 18.1 Consent record (ACC-08, SET-03, SET-04, SET-10; QUESTIONS #13, #36, #47).
 *
 * - `health_data` consent covers every hard rule (owner decision 2026-11-10).
 *   The member's state is taken from their latest health-data record:
 *   none, given, declined or withdrawn (contract `RulesConsentStatus`).
 * - A decline is stored as a record with no rule data (QUESTIONS #47 default).
 * - A withdrawal records `withdrawnAt` and `deletionDueBy` (now plus the
 *   configured SET-04 window). The database then deletes the member's data key
 *   at once, which removes every hard rule and redacts their safety log
 *   details in the live database. Backups and point-in-time-recovery copies
 *   are purged on their normal cycle, which must stay within the window (T-023).
 * - Every decision locks the member first (`lockMembers`, security review
 *   T-016 H4), so it waits for an in-flight rule write and then removes it.
 * - `guardian_confirmation` records the manager's confirmation as parent or
 *   guardian of a child profile (SET-10).
 */

export type ConsentPurpose = "health_data" | "guardian_confirmation";
export type ConsentDecision = "given" | "declined";
export type Language = "id" | "en";
export type RulesConsentStatus = "none" | "given" | "declined" | "withdrawn";

export interface ConsentRecordRow {
  readonly id: string;
  readonly householdId: string | null;
  readonly profileId: string | null;
  readonly purpose: ConsentPurpose;
  readonly decision: ConsentDecision;
  readonly textVersion: string;
  readonly language: Language;
  readonly decidedAt: Date;
  readonly recordedByAccountId: string | null;
  readonly withdrawnAt: Date | null;
  readonly deletionDueBy: Date | null;
}

/** Contract `RulesConsentState`. */
export interface RulesConsentState {
  readonly status: RulesConsentStatus;
  readonly consentRecordId: string | null;
  readonly decidedAt: Date | null;
  readonly textVersion: string | null;
  readonly deletionDueBy: Date | null;
}

export class ConsentNotActiveError extends DataLayerError {
  constructor() {
    super("consent_not_active", "No active health-data consent to withdraw");
  }
}

const COLUMNS = `id, household_id, profile_id, purpose, decision, text_version, language,
  decided_at, recorded_by_account_id, withdrawn_at, deletion_due_by`;

interface Row {
  id: string;
  household_id: string | null;
  profile_id: string | null;
  purpose: ConsentPurpose;
  decision: ConsentDecision;
  text_version: string;
  language: Language;
  decided_at: Date;
  recorded_by_account_id: string | null;
  withdrawn_at: Date | null;
  deletion_due_by: Date | null;
}

function fromRow(row: Row): ConsentRecordRow {
  return {
    id: row.id,
    householdId: row.household_id,
    profileId: row.profile_id,
    purpose: row.purpose,
    decision: row.decision,
    textVersion: row.text_version,
    language: row.language,
    decidedAt: row.decided_at,
    recordedByAccountId: row.recorded_by_account_id,
    withdrawnAt: row.withdrawn_at,
    deletionDueBy: row.deletion_due_by,
  };
}

export function consentStateOf(latest: ConsentRecordRow | undefined): RulesConsentState {
  if (latest === undefined) {
    return {
      status: "none",
      consentRecordId: null,
      decidedAt: null,
      textVersion: null,
      deletionDueBy: null,
    };
  }
  const status: RulesConsentStatus =
    latest.decision === "declined"
      ? "declined"
      : latest.withdrawnAt !== null
        ? "withdrawn"
        : "given";
  return {
    status,
    consentRecordId: latest.id,
    decidedAt: latest.withdrawnAt ?? latest.decidedAt,
    textVersion: latest.textVersion,
    deletionDueBy: latest.deletionDueBy,
  };
}

export interface ConsentInput {
  readonly householdId: string;
  readonly profileId: string;
  readonly textVersion: string;
  readonly language: Language;
  /** The signed-in manager account (server-side, never from the request body). */
  readonly recordedByAccountId: string;
  readonly decidedAt?: Date;
}

async function insertRecord(
  db: SqlExecutor,
  input: ConsentInput,
  purpose: ConsentPurpose,
  decision: ConsentDecision,
): Promise<ConsentRecordRow> {
  if (!isUuid(input.householdId) || !isUuid(input.profileId)) throw new NotFoundError("profile");
  const { rows } = await withDbErrors(() =>
    db.transaction(async (tx) => {
      await lockMembers(tx, input.householdId, [input.profileId]);
      return tx.query<Row>(
        `INSERT INTO consent_record
         (household_id, profile_id, purpose, decision, text_version, language,
          decided_at, recorded_by_account_id)
       SELECT p.household_id, p.id, $3, $4, $5, $6, COALESCE($7::timestamptz, now()), $8
         FROM profile p
        WHERE p.id = $2 AND p.household_id = $1
       RETURNING ${COLUMNS}`,
        [
          input.householdId,
          input.profileId,
          purpose,
          decision,
          input.textVersion,
          input.language,
          input.decidedAt ?? null,
          input.recordedByAccountId,
        ],
      );
    }),
  );
  const row = rows[0];
  if (row === undefined) throw new NotFoundError("profile");
  return fromRow(row);
}

/** ACC-08, SET-03: records a health-data consent decision for one member. */
export function recordHealthConsent(
  db: SqlExecutor,
  input: ConsentInput & { readonly decision: ConsentDecision },
): Promise<ConsentRecordRow> {
  return insertRecord(db, input, "health_data", input.decision);
}

/** SET-10: records the manager's confirmation as parent or guardian of a child profile. */
export function recordGuardianConfirmation(
  db: SqlExecutor,
  input: ConsentInput,
): Promise<ConsentRecordRow> {
  return insertRecord(db, input, "guardian_confirmation", "given");
}

/** Latest health-data consent record per member (members without one are absent). */
export async function latestHealthConsents(
  db: SqlExecutor,
  householdId: string,
  profileIds: readonly string[],
): Promise<Map<string, ConsentRecordRow>> {
  const ids = profileIds.filter(isUuid);
  if (!isUuid(householdId) || ids.length === 0) return new Map();
  const { rows } = await db.query<Row>(
    `SELECT DISTINCT ON (profile_id) ${COLUMNS}
       FROM consent_record
      WHERE household_id = $1 AND profile_id = ANY($2::uuid[]) AND purpose = 'health_data'
      ORDER BY profile_id, seq DESC`,
    [householdId, ids],
  );
  return new Map(rows.map((row) => [row.profile_id as string, fromRow(row)]));
}

export async function rulesConsentState(
  db: SqlExecutor,
  householdId: string,
  profileId: string,
): Promise<RulesConsentState> {
  return consentStateOf((await latestHealthConsents(db, householdId, [profileId])).get(profileId));
}

export async function guardianConfirmation(
  db: SqlExecutor,
  householdId: string,
  profileId: string,
): Promise<ConsentRecordRow | null> {
  if (!isUuid(householdId) || !isUuid(profileId)) return null;
  const { rows } = await db.query<Row>(
    `SELECT ${COLUMNS} FROM consent_record
      WHERE household_id = $1 AND profile_id = $2 AND purpose = 'guardian_confirmation'
      ORDER BY seq DESC LIMIT 1`,
    [householdId, profileId],
  );
  return rows[0] === undefined ? null : fromRow(rows[0]);
}

/** Every consent record of a member, newest first (contract `ConsentRecordList`). */
export async function listConsentRecords(
  db: SqlExecutor,
  householdId: string,
  profileId: string,
): Promise<ConsentRecordRow[]> {
  if (!isUuid(householdId) || !isUuid(profileId)) return [];
  const { rows } = await db.query<Row>(
    `SELECT ${COLUMNS} FROM consent_record
      WHERE household_id = $1 AND profile_id = $2
      ORDER BY seq DESC`,
    [householdId, profileId],
  );
  return rows.map(fromRow);
}

const DAY_MS = 86_400_000;

/**
 * SET-03, SET-04: withdraws the member's active health-data consent.
 * `deletionWindowDays` is `targets.dataManagement.healthConsentWithdrawalDeletionDays`.
 * The database deletes the member's hard rules and redacts their safety log
 * details in the same transaction. `deletionDueBy` is the outer bound for
 * caches, and for backups and point-in-time-recovery copies, which are purged
 * on their normal cycle (T-023 keeps that cycle within the window).
 */
export async function withdrawHealthConsent(
  db: SqlExecutor,
  input: {
    readonly householdId: string;
    readonly profileId: string;
    readonly withdrawnAt: Date;
    readonly deletionWindowDays: number;
  },
): Promise<ConsentRecordRow> {
  if (!Number.isInteger(input.deletionWindowDays) || input.deletionWindowDays < 0) {
    throw new RangeError("deletionWindowDays must be a non-negative integer");
  }
  return withDbErrors(() =>
    db.transaction(async (tx) => {
      await lockMembers(tx, input.householdId, [input.profileId]);
      const latest = (await latestHealthConsents(tx, input.householdId, [input.profileId])).get(
        input.profileId,
      );
      if (latest === undefined || consentStateOf(latest).status !== "given") {
        throw new ConsentNotActiveError();
      }
      const deletionDueBy = new Date(
        input.withdrawnAt.getTime() + input.deletionWindowDays * DAY_MS,
      );
      const { rows } = await tx.query<Row>(
        `UPDATE consent_record SET withdrawn_at = $2, deletion_due_by = $3
        WHERE id = $1 AND withdrawn_at IS NULL
        RETURNING ${COLUMNS}`,
        [latest.id, input.withdrawnAt, deletionDueBy],
      );
      if (rows[0] === undefined) throw new ConsentNotActiveError();
      return fromRow(rows[0]);
    }),
  );
}
