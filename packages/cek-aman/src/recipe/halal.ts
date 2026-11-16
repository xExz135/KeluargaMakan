import { CekAmanInputError } from "../errors.js";
import { NOT_SAFE_KINDS, evaluate } from "../evaluate.js";
import { isObject, own, ownItems } from "../normalize.js";
import type {
  CekAmanInput,
  MemberRulesInput,
  ReasonCode,
  ReasonKind,
  RecognitionFieldsAbsent,
  ReferenceDataset,
  SafetyStatus,
} from "../types.js";

/**
 * LIB-05 recipe halal status, the same values as contract 0.3 `HalalStatus`.
 * `check_label` is "Check the label": an unknown value is never shown as halal.
 */
export const RECIPE_HALAL_STATUSES = ["halal", "not_halal", "check_label"] as const;
export type RecipeHalalStatus = (typeof RECIPE_HALAL_STATUSES)[number];

/**
 * LIB-05: a halal status is derived, never typed in. No input may carry one,
 * so passing a stored or hand-entered status fails to compile, and at run time
 * the derivation reads none of these fields.
 */
interface HalalStatusAbsent {
  readonly status?: never;
  readonly halalStatus?: never;
  readonly halal?: never;
}

/**
 * One recipe ingredient line, as the recipe API (T-041) passes it. Quantity,
 * unit, name and optional flag play no part: the halal status depends on the
 * reference data of the line's ingredient only (LIB-05, REC-06).
 */
export interface RecipeLineInput extends HalalStatusAbsent, RecognitionFieldsAbsent {
  /** The recipe line ID, unique within the recipe; findings point back at it. */
  readonly lineId: string;
  /**
   * Resolved reference ingredient ID, or null for a line that does not resolve:
   * custom (KIT-05), unknown, or named by an AI or a photo and not yet mapped
   * (REC-06, SAF-10). Null always gives "Check the label" (SAF-09).
   */
  readonly ingredientId: string | null;
  /**
   * The reference brand this line uses (SAF-07), or null or absent when none
   * is known. Only a verified brand variant of the line's own ingredient
   * replaces the generic data; any other brand gives "Check the label". It
   * applies to this line only, never to another line of the same ingredient.
   */
  readonly brandId?: string | null;
}

export interface RecipeHalalInput extends HalalStatusAbsent {
  /** Every ingredient line of the recipe (or of one regional variant), optional lines included. */
  readonly lines: readonly RecipeLineInput[];
  readonly reference: ReferenceDataset;
}

/** Points a finding at a recipe line: IDs and position only, never a name. */
export interface RecipeLineRef {
  /** Position in the input line list. */
  readonly index: number;
  readonly lineId: string;
  readonly ingredientId: string | null;
}

/**
 * Why a recipe is not halal or needs a label check. The shape of contract 0.3
 * `SafetyFinding` before the API adds display names: `componentPath` holds
 * reference IDs, `brandId` the verified variant whose data were used, and
 * `detail` the non-halal source, halal value, brand or component ID.
 */
export interface RecipeHalalFinding {
  readonly kind: ReasonKind;
  readonly code: ReasonCode;
  /** Null only for a recipe with no lines. */
  readonly line: RecipeLineRef | null;
  readonly componentPath: readonly string[];
  readonly brandId: string | null;
  readonly detail: string | null;
}

/**
 * LIB-05 result. It holds IDs, codes and versions only, no ingredient names or
 * free text, so it can be logged as it is (SAF-14, DAT-06).
 */
export interface RecipeHalalResult {
  readonly status: RecipeHalalStatus;
  /** Empty for `halal`; "Not halal" findings first, otherwise line order. */
  readonly findings: readonly RecipeHalalFinding[];
  readonly ruleSetVersion: string;
  readonly referenceVersion: string;
}

interface PreparedLine {
  readonly ref: RecipeLineRef;
  readonly brandId: string | null;
}

/** The single halal rule the engine checks each line against. Internal; never returned. */
const HALAL_CHECK: MemberRulesInput = {
  memberId: "recipe-halal",
  hardRules: [{ ruleId: "recipe-halal", type: "halal" }],
};

/** Same precedence as a member result (SAF-04, SAF-08). */
const HALAL_STATUS_OF: Readonly<Record<SafetyStatus, RecipeHalalStatus>> = {
  safe: "halal",
  not_safe: "not_halal",
  check_label: "check_label",
};
const RANK: Readonly<Record<RecipeHalalStatus, number>> = {
  halal: 0,
  check_label: 1,
  not_halal: 2,
};

function nonEmptyString(value: unknown): value is string {
  return typeof value === "string" && value !== "";
}

function fail(message: string): never {
  throw new CekAmanInputError(message);
}

function readLines(raw: unknown): readonly PreparedLine[] {
  const list = ownItems(raw);
  if (list === null) fail("recipe lines must be a list (LIB-05)");
  const seen = new Set<string>();
  return list.map((line, index) => {
    const lineId = isObject(line) ? own(line, "lineId") : undefined;
    if (!isObject(line) || !nonEmptyString(lineId)) fail("every recipe line needs a lineId");
    if (seen.has(lineId)) fail(`duplicate recipe lineId: ${lineId}`);
    seen.add(lineId);
    const ingredientId = own(line, "ingredientId");
    const brandId = own(line, "brandId");
    return {
      ref: { index, lineId, ingredientId: nonEmptyString(ingredientId) ? ingredientId : null },
      brandId: nonEmptyString(brandId) ? brandId : null,
    };
  });
}

/** Runs the engine's own halal check on one line, or on an empty recipe when `line` is null. */
function checkLine(reference: unknown, line: PreparedLine | null): CekAmanInput {
  const ingredientId = line?.ref.ingredientId ?? null;
  const brandId = line?.brandId ?? null;
  return {
    ingredients: line === null ? [] : [{ ingredientId, rawName: "" }],
    recordedBrands: ingredientId === null || brandId === null ? [] : [{ ingredientId, brandId }],
    members: [HALAL_CHECK],
    // Checked by evaluate(), which fails on a missing or malformed dataset.
    reference: reference as ReferenceDataset,
  };
}

/**
 * LIB-05: derives a recipe's halal status from the reference ingredient data
 * only, through the same halal check Cek Aman applies to a member with a halal
 * rule (SAF-08), so the two can never disagree. Each line is checked on its
 * own, with its own brand, then the worst result wins:
 *
 * - any alcohol, pork or non-halal animal ingredient or component: `not_halal`
 * - otherwise any uncertainty (unresolved, custom or unknown line, missing or
 *   unverified component or halal data, brand not known or not verified, or
 *   no lines at all): `check_label`, never `halal` (fail closed)
 * - otherwise `halal`
 *
 * Pure and deterministic, like `evaluate`. Any status in the input is ignored,
 * and recognition output never reaches it (REC-06, SAF-10).
 *
 * @throws CekAmanInputError when the input is structurally unusable (no line
 *   list, a line without a lineId, a duplicate lineId, unusable reference data).
 */
export function deriveRecipeHalal(input: RecipeHalalInput): RecipeHalalResult {
  const raw: unknown = input;
  if (!isObject(raw)) fail("input is required");
  const lines = readLines(own(raw, "lines"));
  const reference = own(raw, "reference");
  let status: RecipeHalalStatus = "halal";
  let ruleSetVersion = "";
  let referenceVersion = "";
  const findings: RecipeHalalFinding[] = [];
  for (const line of lines.length === 0 ? [null] : lines) {
    const result = evaluate(checkLine(reference, line));
    ruleSetVersion = result.ruleSetVersion;
    referenceVersion = result.referenceVersion;
    for (const verdict of result.perMember) {
      const lineStatus = HALAL_STATUS_OF[verdict.status];
      if (RANK[lineStatus] > RANK[status]) status = lineStatus;
      for (const reason of verdict.reasons) {
        findings.push({
          kind: reason.kind,
          code: reason.code,
          line: line === null ? null : line.ref,
          componentPath: reason.componentPath,
          brandId: reason.brandId,
          detail: reason.detail,
        });
      }
    }
  }
  // Stable sort: "Not halal" findings first, otherwise line order.
  const severity = (finding: RecipeHalalFinding): number =>
    NOT_SAFE_KINDS.includes(finding.kind) ? 0 : 1;
  findings.sort((a, b) => severity(a) - severity(b));
  return { status, findings, ruleSetVersion, referenceVersion };
}
