import { CekAmanInputError } from "./errors.js";
import { evaluate } from "./evaluate.js";
import { isObject, own, ownList } from "./normalize.js";
import { summarizeRule, type RuleSummary } from "./rules.js";
import type {
  CekAmanInput,
  CekAmanResult,
  RecordedBrand,
  SafetyReason,
  SafetyStatus,
} from "./types.js";

export const SAFETY_LOG_FORMAT = "keluargamakan.safety-log/1";

/** SAF-02: every kind of food item that passes Cek Aman before display. */
export const SAFETY_SUBJECT_KINDS = [
  "library_recipe",
  "suggestion",
  "substitution",
  "taste_tweak_fix",
  "planned_meal",
  "family_recipe",
  "leftover_remake",
] as const;
export type SafetySubjectKind = (typeof SAFETY_SUBJECT_KINDS)[number];

/** Supplied by the caller; the engine reads no clock and no IDs of its own. */
export interface SafetyLogContext {
  readonly householdId: string;
  readonly subject: {
    readonly kind: SafetySubjectKind;
    readonly id: string;
    readonly version: string | null;
  };
  /** ISO 8601 timestamp of the evaluation, from the caller's clock. */
  readonly evaluatedAt: string;
}

/**
 * Safety result log record (SAF-14, DAT-06, SRS 18.1 "Safety result log"),
 * built for the API to persist. Sensitive: store it with the health-data key
 * (DAT-02) and keep it for the DAT-05 retention period. It holds member and
 * rule IDs but never member names or free-text rule wording.
 */
export interface SafetyLogRecord {
  readonly logFormat: typeof SAFETY_LOG_FORMAT;
  readonly householdId: string;
  readonly subject: SafetyLogContext["subject"];
  readonly evaluatedAt: string;
  readonly ruleSetVersion: string;
  readonly referenceVersion: string;
  readonly ingredients: readonly {
    readonly ingredientId: string | null;
    readonly rawName: string;
  }[];
  /** Only the recorded brands for ingredients in this recipe. */
  readonly recordedBrands: readonly RecordedBrand[];
  readonly members: readonly {
    readonly memberId: string;
    readonly status: SafetyStatus;
    readonly rules: readonly RuleSummary[];
    readonly reasons: readonly SafetyReason[];
  }[];
}

function requireText(value: unknown, name: string): string {
  if (typeof value !== "string" || value === "") {
    throw new CekAmanInputError(`${name} is required for the safety log (SAF-14)`);
  }
  return value;
}

function readContext(raw: unknown): SafetyLogContext {
  const context = isObject(raw) ? raw : {};
  const rawSubject = own(context, "subject");
  const subject = isObject(rawSubject) ? rawSubject : {};
  const kind = own(subject, "kind");
  if (!(SAFETY_SUBJECT_KINDS as readonly unknown[]).includes(kind)) {
    throw new CekAmanInputError("subject.kind is not a known food item kind (SAF-02)");
  }
  const version = own(subject, "version");
  return {
    householdId: requireText(own(context, "householdId"), "householdId"),
    subject: {
      kind: kind as SafetySubjectKind,
      id: requireText(own(subject, "id"), "subject.id"),
      version: typeof version === "string" && version !== "" ? version : null,
    },
    evaluatedAt: requireText(own(context, "evaluatedAt"), "evaluatedAt"),
  };
}

function buildLogRecord(
  input: CekAmanInput,
  result: CekAmanResult,
  context: SafetyLogContext,
): SafetyLogRecord {
  // Own properties only, exactly as evaluate() reads them (SAF-01).
  const ingredients = ownList(input, "ingredients").map((item) => {
    const entry = isObject(item) ? item : {};
    const id = own(entry, "ingredientId");
    const name = own(entry, "rawName");
    return {
      ingredientId: typeof id === "string" && id !== "" ? id : null,
      rawName: typeof name === "string" ? name : "",
    };
  });
  const inRecipe = new Set(
    ingredients.flatMap((item) => (item.ingredientId === null ? [] : [item.ingredientId])),
  );
  const recordedBrands = ownList(input, "recordedBrands").flatMap((brand): RecordedBrand[] => {
    if (!isObject(brand)) return [];
    const ingredientId = own(brand, "ingredientId");
    const brandId = own(brand, "brandId");
    if (typeof ingredientId !== "string" || !inRecipe.has(ingredientId)) return [];
    return typeof brandId === "string" && brandId !== "" ? [{ ingredientId, brandId }] : [];
  });
  const members = ownList(input, "members");
  const rulesOf = (index: number): readonly RuleSummary[] =>
    ownList(members[index], "hardRules").map(summarizeRule);
  return {
    logFormat: SAFETY_LOG_FORMAT,
    householdId: context.householdId,
    subject: context.subject,
    evaluatedAt: context.evaluatedAt,
    ruleSetVersion: result.ruleSetVersion,
    referenceVersion: result.referenceVersion,
    ingredients,
    recordedBrands,
    // evaluate() returns one result per input member, in input order.
    members: result.perMember.map((member, index) => ({
      memberId: member.memberId,
      status: member.status,
      rules: rulesOf(index),
      reasons: member.reasons,
    })),
  };
}

/**
 * The API entry point for the safety pipeline (ARCHITECTURE section 4, steps 3
 * and 4): evaluates and returns the log record to persist with the result. The
 * context is checked first, so an untraceable result is never produced.
 */
export function evaluateWithLog(
  input: CekAmanInput,
  context: SafetyLogContext,
): { readonly result: CekAmanResult; readonly logRecord: SafetyLogRecord } {
  const checked = readContext(context);
  const result = evaluate(input);
  return { result, logRecord: buildLogRecord(input, result, checked) };
}
