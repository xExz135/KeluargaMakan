import { randomUUID } from "node:crypto";

import {
  SAFETY_LOG_FORMAT,
  SAFETY_SUBJECT_KINDS,
  type RuleSummary,
  type SafetyLogRecord,
  type SafetyReason,
  type SafetyStatus,
} from "@keluargamakan/cek-aman";

import { bucketFor, decryptField, encryptField } from "./crypto/data-key-cipher.js";
import { InvalidDataError, NotFoundError, withDbErrors } from "./errors.js";
import type { SqlExecutor } from "./executor.js";
import type { HealthDataKeys } from "./health-data-keys.js";
import { isReferenceId, isUuid } from "./ids.js";
import { lockMembers } from "./locks.js";

/**
 * SRS 18.1 Safety result log (SAF-14, DAT-05, DAT-06), stored minimal
 * (DECISIONS 2026-11-11, QUESTIONS #40; security reviews PR #5 M2 and T-016 H3):
 *
 * - Plain: subject, versions and evaluation time, and per member only a
 *   pseudonymous ID. Nothing in plain columns says what the result was or why,
 *   so nothing links a member to a rule type without the health-data key.
 * - Encrypted with the member's data key: status, reason codes, the reference
 *   ingredient IDs and recorded brands evaluated, rule summaries and full
 *   reasons.
 * - Never stored: raw ingredient names (custom ingredients and family recipes
 *   can hold names or phone numbers), member names, free-text rule wording.
 * - IDs must be opaque (UUIDs and reference IDs) and versions must match a
 *   version pattern, so a name can never be logged as an ID (PR #5 M2c, L7).
 *
 * H4: the log never creates a data key. Details are stored only when, at log
 * time and under the member lock, the member's consent is active, their key
 * exists and every logged rule still exists. Otherwise the member row is
 * stored without details under a fresh random pseudonym. A log written after a
 * withdrawal therefore cannot bring the withdrawn rules back.
 *
 * The pseudonymous member ID is the member's `health_data_key.id`. When that
 * key is deleted the details are cleared and the ID is replaced by a random
 * one, so the row links to nobody (migration 0005).
 */

const REASON_CODE = /^[a-z_]{1,64}$/;
const VERSION = /^[A-Za-z0-9][A-Za-z0-9._+/-]{0,99}$/;
const STATUSES: readonly SafetyStatus[] = ["safe", "not_safe", "check_label"];
const DETAILS_VERSION = 2;

/** A reason as logged: the ingredient's raw name is removed. */
export type LoggedReason = Omit<SafetyReason, "ingredient"> & {
  readonly ingredient: { readonly index: number; readonly ingredientId: string | null } | null;
};

export interface SafetyLogMemberDetails {
  readonly status: SafetyStatus;
  readonly reasonCodes: readonly string[];
  /** Reference ingredient IDs in recipe order; null marks an unresolved ingredient. */
  readonly ingredientIds: readonly (string | null)[];
  readonly recordedBrands: readonly { readonly ingredientId: string; readonly brandId: string }[];
  readonly rules: readonly RuleSummary[];
  readonly reasons: readonly LoggedReason[];
}

export interface StoredSafetyLogMember {
  /** Pseudonymous member ID (not the profile ID). */
  readonly memberKeyId: string;
  /** Null when withheld (no active consent or key at log time) or redacted later. */
  readonly details: SafetyLogMemberDetails | null;
}

export interface StoredSafetyLog {
  readonly id: string;
  /** Null once the household is deleted. */
  readonly householdId: string | null;
  readonly logFormat: string;
  readonly subject: { readonly kind: string; readonly id: string; readonly version: string | null };
  readonly evaluatedAt: Date;
  readonly ruleSetVersion: string;
  readonly referenceVersion: string;
  readonly members: readonly StoredSafetyLogMember[];
}

function memberContext(logId: string, index: number, keyId: string): string {
  return `safety_log_member:${logId}:${index}:${keyId}`;
}

function stripReason(reason: SafetyReason): LoggedReason {
  return {
    kind: reason.kind,
    code: reason.code,
    rule: { ruleId: reason.rule.ruleId, type: reason.rule.type, allergen: reason.rule.allergen },
    ingredient:
      reason.ingredient === null
        ? null
        : { index: reason.ingredient.index, ingredientId: reason.ingredient.ingredientId },
    componentPath: [...reason.componentPath],
    brandId: reason.brandId,
    detail: reason.detail,
  };
}

function stripRule(rule: RuleSummary): RuleSummary {
  return {
    ruleId: rule.ruleId,
    type: rule.type,
    allergen: rule.allergen,
    mappingStatus: rule.mappingStatus,
    mappedIngredientIds: [...rule.mappedIngredientIds],
  };
}

function requireValid(condition: boolean, message: string): asserts condition {
  if (!condition) throw new InvalidDataError(message);
}

function validate(record: SafetyLogRecord): void {
  requireValid(record.logFormat === SAFETY_LOG_FORMAT, "unknown safety log format");
  requireValid(isUuid(record.householdId), "householdId must be an opaque UUID");
  requireValid(
    (SAFETY_SUBJECT_KINDS as readonly string[]).includes(record.subject.kind),
    "unknown subject kind",
  );
  requireValid(isReferenceId(record.subject.id), "subject.id must be an opaque reference ID");
  requireValid(
    record.subject.version === null || VERSION.test(record.subject.version),
    "subject.version is invalid",
  );
  requireValid(VERSION.test(record.ruleSetVersion), "ruleSetVersion is invalid");
  requireValid(VERSION.test(record.referenceVersion), "referenceVersion is invalid");
  requireValid(
    !Number.isNaN(Date.parse(record.evaluatedAt)) && /^\d{4}-\d{2}-\d{2}T/.test(record.evaluatedAt),
    "evaluatedAt must be ISO 8601",
  );
  requireValid(
    record.ingredients.every(
      (item) => item.ingredientId === null || isReferenceId(item.ingredientId),
    ),
    "ingredient IDs must be reference IDs",
  );
  requireValid(
    record.recordedBrands.every(
      (brand) => isReferenceId(brand.ingredientId) && isReferenceId(brand.brandId),
    ),
    "recorded brands must be reference IDs",
  );
  const memberIds = record.members.map((member) => member.memberId);
  requireValid(memberIds.every(isUuid), "memberId must be an opaque UUID");
  requireValid(new Set(memberIds).size === memberIds.length, "duplicate memberId");
  for (const member of record.members) {
    requireValid(STATUSES.includes(member.status), "unknown status");
    requireValid(
      member.reasons.every((reason) => REASON_CODE.test(reason.code)),
      "invalid reason code",
    );
  }
}

interface MemberStateRow {
  profile_id: string;
  consent_active: boolean;
  k_id: string | null;
  rule_ids: string[];
}

/**
 * SAF-14: persists one Cek Aman log record from `evaluateWithLog`. The caller
 * must not show the result if this throws.
 */
export async function insertSafetyLog(
  db: SqlExecutor,
  keys: HealthDataKeys,
  record: SafetyLogRecord,
): Promise<string> {
  validate(record);
  const memberIds = record.members.map((member) => member.memberId);

  // N2: unwrap the members' existing keys before any lock or transaction, so a
  // slow key service never holds a member lock. Under the lock below, a key
  // is used only if it is still the member's current key.
  const preloaded = await keys.loadForProfiles(db, record.householdId, memberIds);

  const ingredientIds = record.ingredients.map((item) => item.ingredientId);
  const recordedBrands = record.recordedBrands.map((brand) => ({
    ingredientId: brand.ingredientId,
    brandId: brand.brandId,
  }));
  const detailsJson = record.members.map((member) =>
    JSON.stringify({
      v: DETAILS_VERSION,
      status: member.status,
      reasonCodes: [...new Set(member.reasons.map((reason) => reason.code))],
      ingredientIds,
      recordedBrands,
      rules: member.rules.map(stripRule),
      reasons: member.reasons.map(stripReason),
    } satisfies SafetyLogMemberDetails & { v: number }),
  );
  // N1: every member of this log is padded to the same power-of-two bucket.
  let bucket: number;
  try {
    bucket = bucketFor(detailsJson);
  } catch {
    throw new InvalidDataError("safety log details are too large");
  }

  return withDbErrors(() =>
    db.transaction(async (tx) => {
      // H4: decide on details under the member lock, from the current state.
      const states = new Map<string, MemberStateRow>();
      if (memberIds.length > 0) {
        await lockMembers(tx, record.householdId, memberIds);
        const { rows } = await tx.query<MemberStateRow>(
          `SELECT p.id AS profile_id,
                  health_consent_active(p.id) AS consent_active,
                  k.id AS k_id,
                  COALESCE(
                    (SELECT array_agg(h.id::text) FROM hard_rule h WHERE h.profile_id = p.id),
                    '{}'::text[]
                  ) AS rule_ids
             FROM profile p
             LEFT JOIN health_data_key k ON k.profile_id = p.id AND k.household_id = p.household_id
            WHERE p.household_id = $1 AND p.id = ANY($2::uuid[])`,
          [record.householdId, memberIds],
        );
        for (const row of rows) states.set(row.profile_id, row);
      }

      const { rows } = await tx.query<{ id: string }>(
        `INSERT INTO safety_log
           (household_id, log_format, subject_kind, subject_id, subject_version, evaluated_at,
            rule_set_version, reference_version)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
         RETURNING id`,
        [
          record.householdId,
          record.logFormat,
          record.subject.kind,
          record.subject.id,
          record.subject.version,
          record.evaluatedAt,
          record.ruleSetVersion,
          record.referenceVersion,
        ],
      );
      const logId = rows[0]?.id;
      if (logId === undefined) throw new Error("safety log insert returned no row");

      for (const [index, member] of record.members.entries()) {
        const state = states.get(member.memberId);
        if (state === undefined) throw new NotFoundError("profile");
        const current = new Set(state.rule_ids);
        const rulesStillStored = member.rules.every((rule) => current.has(rule.ruleId));
        const key = preloaded.get(member.memberId);
        const json = detailsJson[index];
        if (
          !state.consent_active ||
          state.k_id === null ||
          key === undefined ||
          key.keyId !== state.k_id ||
          !rulesStillStored ||
          json === undefined
        ) {
          await tx.query(
            `INSERT INTO safety_log_member (log_id, member_index, member_key_id, details_enc, redacted_at)
             VALUES ($1, $2, $3, NULL, now())`,
            [logId, index, randomUUID()],
          );
          continue;
        }
        await tx.query(
          `INSERT INTO safety_log_member (log_id, member_index, member_key_id, details_enc)
           VALUES ($1, $2, $3, $4)`,
          [
            logId,
            index,
            key.keyId,
            encryptField(key.dataKey, json, memberContext(logId, index, key.keyId), bucket),
          ],
        );
      }
      return logId;
    }),
  );
}

interface LogRow {
  id: string;
  household_id: string | null;
  log_format: string;
  subject_kind: string;
  subject_id: string;
  subject_version: string | null;
  evaluated_at: Date;
  rule_set_version: string;
  reference_version: string;
}

interface MemberRow {
  member_index: number;
  member_key_id: string;
  details_enc: Uint8Array | null;
}

/** L1: never echo decrypted text in an error, whatever went wrong. */
function parseDetails(json: string): SafetyLogMemberDetails {
  let raw: unknown;
  try {
    raw = JSON.parse(json);
  } catch {
    throw new InvalidDataError("safety log details are not valid JSON");
  }
  const details = raw as Partial<SafetyLogMemberDetails> & { v?: unknown };
  if (
    typeof raw !== "object" ||
    raw === null ||
    details.v !== DETAILS_VERSION ||
    !STATUSES.includes(details.status as SafetyStatus) ||
    !Array.isArray(details.reasonCodes) ||
    !Array.isArray(details.ingredientIds) ||
    !Array.isArray(details.recordedBrands) ||
    !Array.isArray(details.rules) ||
    !Array.isArray(details.reasons)
  ) {
    throw new InvalidDataError("unknown safety log details format");
  }
  return {
    status: details.status as SafetyStatus,
    reasonCodes: details.reasonCodes,
    ingredientIds: details.ingredientIds,
    recordedBrands: details.recordedBrands,
    rules: details.rules,
    reasons: details.reasons,
  };
}

/**
 * Incident review (SAF-14): reads one log of the given household with its
 * decrypted member details (security review T-016 M4: household-scoped).
 * Members without details come back with `details: null`. Details whose key
 * is gone cannot happen (trigger); if they did, this throws rather than guess.
 */
export async function readSafetyLog(
  db: SqlExecutor,
  keys: HealthDataKeys,
  householdId: string,
  logId: string,
): Promise<StoredSafetyLog> {
  if (!isUuid(householdId) || !isUuid(logId)) throw new NotFoundError("safety log");
  const { rows } = await withDbErrors(() =>
    db.query<LogRow>(
      `SELECT id, household_id, log_format, subject_kind, subject_id, subject_version, evaluated_at,
              rule_set_version, reference_version
         FROM safety_log WHERE id = $1 AND household_id = $2`,
      [logId, householdId],
    ),
  );
  const log = rows[0];
  if (log === undefined) throw new NotFoundError("safety log");
  const members = (
    await withDbErrors(() =>
      db.query<MemberRow>(
        `SELECT member_index, member_key_id, details_enc
           FROM safety_log_member WHERE log_id = $1 ORDER BY member_index`,
        [logId],
      ),
    )
  ).rows;
  const keyMap = await keys.loadByKeyIds(
    db,
    householdId,
    members.filter((member) => member.details_enc !== null).map((member) => member.member_key_id),
  );
  return {
    id: log.id,
    householdId: log.household_id,
    logFormat: log.log_format,
    subject: { kind: log.subject_kind, id: log.subject_id, version: log.subject_version },
    evaluatedAt: log.evaluated_at,
    ruleSetVersion: log.rule_set_version,
    referenceVersion: log.reference_version,
    members: members.map((member): StoredSafetyLogMember => {
      if (member.details_enc === null) {
        return { memberKeyId: member.member_key_id, details: null };
      }
      const key = keyMap.get(member.member_key_id);
      if (key === undefined) throw new InvalidDataError("safety log details have no key");
      return {
        memberKeyId: member.member_key_id,
        details: parseDetails(
          decryptField(
            key.dataKey,
            member.details_enc,
            memberContext(log.id, member.member_index, member.member_key_id),
          ),
        ),
      };
    }),
  };
}
