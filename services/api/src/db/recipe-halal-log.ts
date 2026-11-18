import {
  RECIPE_HALAL_LOG_FORMAT,
  RECIPE_HALAL_STATUSES,
  REASON_CODES,
  REASON_KINDS,
  SAFETY_SUBJECT_KINDS,
  type CheckedLine,
  type RecipeHalalFinding,
  type RecipeHalalLogRecord,
  type RecipeHalalStatus,
} from "@keluargamakan/cek-aman";

import { InvalidDataError, NotFoundError, withDbErrors } from "./errors.js";
import type { SqlExecutor } from "./executor.js";
import { isReferenceId, isReferenceVersion, isUuid } from "./ids.js";

/**
 * Recipe halal log (`keluargamakan.recipe-halal-log/1`; SAF-14, LIB-05,
 * QUESTIONS #88, migration 0012). One row per served recipe halal status,
 * keyed by the API's `checkId`, which is also the ID of the check's safety log
 * row (T-025 N2). Written only inside the safety log transaction
 * (`insertSafetyLogs`), never on its own (T-025 N4).
 *
 * Stored: IDs, reason codes, versions and the brand IDs each line was checked
 * with. Never stored: ingredient names, member data or free text. Every value
 * is checked against its ID or code pattern first, so a name can never be
 * logged as an ID.
 */

const VERSION = /^[A-Za-z0-9][A-Za-z0-9._+/-]{0,99}$/;
const DETAIL = /^[a-z0-9][a-z0-9_.-]{0,99}$/;

function requireValid(condition: boolean, message: string): asserts condition {
  if (!condition) throw new InvalidDataError(message);
}

const isIndex = (value: unknown): value is number =>
  typeof value === "number" && Number.isInteger(value) && value >= 0 && value < 1000;

const isRefOrNull = (value: unknown): value is string | null =>
  value === null || isReferenceId(value);

/** A copy of a checked line with only its logged fields, or a refusal. */
function copyLine(line: CheckedLine): CheckedLine {
  requireValid(isIndex(line.index), "line index is invalid");
  requireValid(isReferenceId(line.lineId), "lineId must be an opaque ID");
  requireValid(isRefOrNull(line.ingredientId), "ingredientId must be a reference ID");
  requireValid(
    Array.isArray(line.brandIds) && line.brandIds.every(isReferenceId),
    "brand IDs must be reference IDs",
  );
  return {
    index: line.index,
    lineId: line.lineId,
    ingredientId: line.ingredientId,
    brandIds: [...line.brandIds],
  };
}

function copyFinding(finding: RecipeHalalFinding): RecipeHalalFinding {
  requireValid((REASON_KINDS as readonly string[]).includes(finding.kind), "unknown finding kind");
  requireValid((REASON_CODES as readonly string[]).includes(finding.code), "unknown finding code");
  const line = finding.line;
  requireValid(
    line === null ||
      (isIndex(line.index) && isReferenceId(line.lineId) && isRefOrNull(line.ingredientId)),
    "finding line is invalid",
  );
  requireValid(
    Array.isArray(finding.componentPath) && finding.componentPath.every(isReferenceId),
    "componentPath must hold reference IDs",
  );
  requireValid(isRefOrNull(finding.brandId), "brandId must be a reference ID");
  requireValid(finding.detail === null || DETAIL.test(finding.detail), "detail is invalid");
  return {
    kind: finding.kind,
    code: finding.code,
    line:
      line === null
        ? null
        : { index: line.index, lineId: line.lineId, ingredientId: line.ingredientId },
    componentPath: [...finding.componentPath],
    brandId: finding.brandId,
    detail: finding.detail,
  };
}

/**
 * Checks a record and returns the copy that will be stored. Throws
 * `InvalidDataError` (with a fixed message that names no value) for anything
 * that is not an ID, code or version.
 */
export function checkedHalalLogRecord(record: RecipeHalalLogRecord): RecipeHalalLogRecord {
  requireValid(record.logFormat === RECIPE_HALAL_LOG_FORMAT, "unknown recipe halal log format");
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
  requireValid(isReferenceVersion(record.referenceVersion), "referenceVersion is invalid");
  requireValid(
    !Number.isNaN(Date.parse(record.evaluatedAt)) && /^\d{4}-\d{2}-\d{2}T/.test(record.evaluatedAt),
    "evaluatedAt must be ISO 8601",
  );
  requireValid(
    (RECIPE_HALAL_STATUSES as readonly string[]).includes(record.status),
    "unknown halal status",
  );
  const lines = record.lines.map(copyLine);
  const findings = record.findings.map(copyFinding);
  requireValid(
    (record.status === "halal") === (findings.length === 0),
    "halal status and findings disagree",
  );
  return {
    logFormat: record.logFormat,
    householdId: record.householdId,
    subject: { kind: record.subject.kind, id: record.subject.id, version: record.subject.version },
    evaluatedAt: record.evaluatedAt,
    ruleSetVersion: record.ruleSetVersion,
    referenceVersion: record.referenceVersion,
    status: record.status,
    lines,
    findings,
  };
}

/**
 * Writes one record inside the safety log transaction. The database refuses
 * it unless the safety log row `checkId` exists and names the same
 * household, subject, time and versions (migration 0012).
 */
export async function insertRecipeHalalLog(
  tx: SqlExecutor,
  checkId: string,
  record: RecipeHalalLogRecord,
): Promise<void> {
  requireValid(isUuid(checkId), "checkId must be an opaque UUID");
  const stored = checkedHalalLogRecord(record);
  await tx.query(
    `INSERT INTO recipe_halal_log
       (check_id, household_id, log_format, subject_kind, subject_id, subject_version,
        evaluated_at, rule_set_version, reference_version, status, lines, findings)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11::jsonb, $12::jsonb)`,
    [
      checkId,
      stored.householdId,
      stored.logFormat,
      stored.subject.kind,
      stored.subject.id,
      stored.subject.version,
      stored.evaluatedAt,
      stored.ruleSetVersion,
      stored.referenceVersion,
      stored.status,
      JSON.stringify(stored.lines),
      JSON.stringify(stored.findings),
    ],
  );
}

export interface StoredRecipeHalalLog {
  readonly checkId: string;
  readonly householdId: string | null;
  readonly subject: { readonly kind: string; readonly id: string; readonly version: string | null };
  readonly evaluatedAt: Date;
  readonly ruleSetVersion: string;
  readonly referenceVersion: string;
  readonly status: RecipeHalalStatus;
  readonly lines: readonly CheckedLine[];
  readonly findings: readonly RecipeHalalFinding[];
}

interface Row {
  check_id: string;
  household_id: string | null;
  subject_kind: string;
  subject_id: string;
  subject_version: string | null;
  evaluated_at: Date;
  rule_set_version: string;
  reference_version: string;
  status: RecipeHalalStatus;
  lines: CheckedLine[] | string;
  findings: RecipeHalalFinding[] | string;
}

const json = <T>(value: T | string): T =>
  typeof value === "string" ? (JSON.parse(value) as T) : value;

/** Incident review (SAF-14): one record of the given household, by `checkId`. */
export async function readRecipeHalalLog(
  db: SqlExecutor,
  householdId: string,
  checkId: string,
): Promise<StoredRecipeHalalLog> {
  if (!isUuid(householdId) || !isUuid(checkId)) throw new NotFoundError("recipe halal log");
  const { rows } = await withDbErrors(() =>
    db.query<Row>(
      `SELECT check_id, household_id, subject_kind, subject_id, subject_version, evaluated_at,
              rule_set_version, reference_version, status, lines, findings
         FROM recipe_halal_log WHERE check_id = $1 AND household_id = $2`,
      [checkId, householdId],
    ),
  );
  const row = rows[0];
  if (row === undefined) throw new NotFoundError("recipe halal log");
  return {
    checkId: row.check_id,
    householdId: row.household_id,
    subject: { kind: row.subject_kind, id: row.subject_id, version: row.subject_version },
    evaluatedAt: row.evaluated_at,
    ruleSetVersion: row.rule_set_version,
    referenceVersion: row.reference_version,
    status: row.status,
    lines: json(row.lines),
    findings: json(row.findings),
  };
}
