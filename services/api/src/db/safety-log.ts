import {
  SAFETY_LOG_FORMAT,
  SAFETY_SUBJECT_KINDS,
  type RuleSummary,
  type SafetyLogRecord,
  type SafetyReason,
  type SafetyStatus,
} from "@keluargamakan/cek-aman";

import { decryptField, encryptField } from "./crypto/data-key-cipher.js";
import { InvalidDataError, NotFoundError } from "./errors.js";
import type { SqlExecutor } from "./executor.js";
import type { HealthDataKeys } from "./health-data-keys.js";
import { isReferenceId, isUuid } from "./ids.js";

/**
 * SRS 18.1 Safety result log (SAF-14, DAT-05, DAT-06), stored minimal
 * (DECISIONS 2026-11-11, QUESTIONS #40; security review PR #5 M2):
 *
 * - Plain: subject, versions, reference ingredient IDs, recorded brand IDs,
 *   and per member a pseudonymous ID, the status and the reason codes.
 * - Never stored: raw ingredient names (custom ingredients and family recipes
 *   can hold names or phone numbers), member names, free-text rule wording.
 * - Encrypted with the member's health data key: the rule summaries and the
 *   full reasons (allergen, excluded ingredient, component path).
 * - IDs must be opaque: household and member IDs are UUIDs, subject IDs
 *   reference IDs. Anything else is refused, so a name can never be logged as
 *   an ID (PR #5 M2c).
 *
 * The pseudonymous member ID is the member's `health_data_key.id`. When that
 * key is deleted the details are redacted and the ID links to nobody.
 */

const REASON_CODE = /^[a-z_]{1,64}$/;
const STATUSES: readonly SafetyStatus[] = ["safe", "not_safe", "check_label"];
const DETAILS_VERSION = 1;

/** A reason as logged: the ingredient's raw name is removed. */
export type LoggedReason = Omit<SafetyReason, "ingredient"> & {
  readonly ingredient: { readonly index: number; readonly ingredientId: string | null } | null;
};

export interface SafetyLogMemberDetails {
  readonly rules: readonly RuleSummary[];
  readonly reasons: readonly LoggedReason[];
}

export interface StoredSafetyLogMember {
  /** Pseudonymous member ID (not the profile ID). */
  readonly memberKeyId: string;
  readonly status: SafetyStatus;
  readonly reasonCodes: readonly string[];
  /** Null once redacted (consent withdrawn, member or household deleted). */
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
  readonly ingredientIds: readonly (string | null)[];
  readonly recordedBrands: readonly { readonly ingredientId: string; readonly brandId: string }[];
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
    record.subject.version === null ||
      (record.subject.version.length > 0 && record.subject.version.length <= 100),
    "subject.version is invalid",
  );
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
  return db.transaction(async (tx) => {
    const { rows } = await tx.query<{ id: string }>(
      `INSERT INTO safety_log
         (household_id, log_format, subject_kind, subject_id, subject_version, evaluated_at,
          rule_set_version, reference_version, ingredient_ids, recorded_brands)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9::text[], $10::jsonb)
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
        record.ingredients.map((item) => item.ingredientId),
        JSON.stringify(
          record.recordedBrands.map((brand) => ({
            ingredientId: brand.ingredientId,
            brandId: brand.brandId,
          })),
        ),
      ],
    );
    const logId = rows[0]?.id;
    if (logId === undefined) throw new Error("safety log insert returned no row");

    for (const [index, member] of record.members.entries()) {
      const key = await keys.getOrCreate(tx, record.householdId, member.memberId);
      const details: SafetyLogMemberDetails & { v: number } = {
        v: DETAILS_VERSION,
        rules: member.rules.map(stripRule),
        reasons: member.reasons.map(stripReason),
      };
      const reasonCodes = [...new Set(member.reasons.map((reason) => reason.code))];
      await tx.query(
        `INSERT INTO safety_log_member
           (log_id, member_index, member_key_id, status, reason_codes, details_enc)
         VALUES ($1, $2, $3, $4, $5::text[], $6)`,
        [
          logId,
          index,
          key.keyId,
          member.status,
          reasonCodes,
          encryptField(
            key.dataKey,
            JSON.stringify(details),
            memberContext(logId, index, key.keyId),
          ),
        ],
      );
    }
    return logId;
  });
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
  ingredient_ids: (string | null)[];
  recorded_brands: unknown;
}

interface MemberRow {
  member_index: number;
  member_key_id: string;
  status: SafetyStatus;
  reason_codes: string[];
  details_enc: Uint8Array | null;
}

function parseDetails(json: string): SafetyLogMemberDetails {
  const raw = JSON.parse(json) as { v?: unknown; rules?: unknown; reasons?: unknown };
  if (raw.v !== DETAILS_VERSION || !Array.isArray(raw.rules) || !Array.isArray(raw.reasons)) {
    throw new InvalidDataError("unknown safety log details format");
  }
  return {
    rules: raw.rules as RuleSummary[],
    reasons: raw.reasons as LoggedReason[],
  };
}

/**
 * Incident review (SAF-14): reads one log with its decrypted member details.
 * Redacted members come back with `details: null`. Details whose key is gone
 * but which are not yet redacted cannot happen (trigger); if they did, this
 * throws rather than guess.
 */
export async function readSafetyLog(
  db: SqlExecutor,
  keys: HealthDataKeys,
  logId: string,
): Promise<StoredSafetyLog> {
  if (!isUuid(logId)) throw new NotFoundError("safety log");
  const { rows } = await db.query<LogRow>(
    `SELECT id, household_id, log_format, subject_kind, subject_id, subject_version, evaluated_at,
            rule_set_version, reference_version, ingredient_ids, recorded_brands
       FROM safety_log WHERE id = $1`,
    [logId],
  );
  const log = rows[0];
  if (log === undefined) throw new NotFoundError("safety log");
  const members = (
    await db.query<MemberRow>(
      `SELECT member_index, member_key_id, status, reason_codes, details_enc
         FROM safety_log_member WHERE log_id = $1 ORDER BY member_index`,
      [logId],
    )
  ).rows;
  const keyMap = await keys.loadByKeyIds(
    db,
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
    ingredientIds: log.ingredient_ids,
    recordedBrands: log.recorded_brands as StoredSafetyLog["recordedBrands"],
    members: members.map((member): StoredSafetyLogMember => {
      if (member.details_enc === null) {
        return {
          memberKeyId: member.member_key_id,
          status: member.status,
          reasonCodes: member.reason_codes,
          details: null,
        };
      }
      const key = keyMap.get(member.member_key_id);
      if (key === undefined) throw new InvalidDataError("safety log details have no key");
      return {
        memberKeyId: member.member_key_id,
        status: member.status,
        reasonCodes: member.reason_codes,
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
