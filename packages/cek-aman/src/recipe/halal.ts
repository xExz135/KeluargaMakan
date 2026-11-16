import { CekAmanInputError } from "../errors.js";
import {
  analyzeIngredient,
  evaluateMember,
  indexBrands,
  indexReference,
  type PreparedMember,
} from "../evaluate.js";
import { isObject, own, ownItems } from "../normalize.js";
import { RULE_SET_VERSION } from "../rule-set.js";
import type {
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
 * One recipe ingredient line, as the recipe API (T-041, T-043) passes it.
 * Quantity, unit, name and optional flag play no part: the halal status depends
 * on the reference data of the line's ingredient only (LIB-05, REC-06).
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
   * SAF-07: every brand the household recorded for this line's ingredient, as
   * `evaluate` gets them in `recordedBrands`: pass all of them, never a chosen
   * one. Each brand is checked and the worst result wins. On an ingredient
   * that varies by brand, only a verified variant of this ingredient replaces
   * the generic data; any other brand gives "Check the label", and so does no
   * brand at all. On an ingredient that does not vary by brand, brands are
   * ignored. Brands apply to this line only.
   */
  readonly brandIds?: readonly string[];
  /** Use `brandIds`: a single chosen brand could hide a worse one (SAF-07). */
  readonly brandId?: never;
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
 * free text. To serve it, use `deriveRecipeHalalWithLog`, whose log record
 * also keeps the brands each line was checked with (SAF-14, DAT-06).
 */
export interface RecipeHalalResult {
  readonly status: RecipeHalalStatus;
  /** Empty for `halal`; "Not halal" findings first, otherwise line order. */
  readonly findings: readonly RecipeHalalFinding[];
  readonly ruleSetVersion: string;
  readonly referenceVersion: string;
}

/** A line as checked: what the log record echoes. */
export interface CheckedLine extends RecipeLineRef {
  /** The brands the line was checked with, deduplicated, in input order. */
  readonly brandIds: readonly string[];
}

/** The one halal rule (SAF-08) each recipe is checked against. Internal; never returned. */
const HALAL_CHECK: PreparedMember = {
  memberId: "recipe-halal",
  rules: [{ kind: "halal", ref: { ruleId: "recipe-halal", type: "halal", allergen: null } }],
};

/** Same precedence as a member result (SAF-04, SAF-08). */
const HALAL_STATUS_OF: Readonly<Record<SafetyStatus, RecipeHalalStatus>> = {
  safe: "halal",
  not_safe: "not_halal",
  check_label: "check_label",
};

function nonEmptyString(value: unknown): value is string {
  return typeof value === "string" && value !== "";
}

function fail(message: string): never {
  throw new CekAmanInputError(message);
}

function readLines(raw: unknown): readonly CheckedLine[] {
  const list = ownItems(raw);
  if (list === null) fail("recipe lines must be a list (LIB-05)");
  const seen = new Set<string>();
  return list.map((line, index) => {
    const lineId = isObject(line) ? own(line, "lineId") : undefined;
    // The position only: a caller's ID never goes into an error message (AI-03).
    if (!isObject(line) || !nonEmptyString(lineId)) fail(`recipe line ${index} needs a lineId`);
    if (seen.has(lineId)) fail(`recipe line ${index} repeats an earlier lineId`);
    seen.add(lineId);
    const ingredientId = own(line, "ingredientId");
    // Malformed brand entries are ignored, as `evaluate` ignores them, which fails closed.
    const brandIds = (ownItems(own(line, "brandIds")) ?? []).filter(nonEmptyString);
    return {
      index,
      lineId,
      ingredientId: nonEmptyString(ingredientId) ? ingredientId : null,
      brandIds: [...new Set(brandIds)],
    };
  });
}

/**
 * Shared by `deriveRecipeHalal` and `deriveRecipeHalalWithLog`: the result and
 * the lines exactly as checked.
 */
export function deriveWithLines(input: RecipeHalalInput): {
  readonly result: RecipeHalalResult;
  readonly lines: readonly CheckedLine[];
} {
  const raw: unknown = input;
  if (!isObject(raw)) fail("input is required");
  const lines = readLines(own(raw, "lines"));
  // The reference is read and indexed once for the whole recipe (one snapshot, DAT-06).
  const { version, records } = indexReference(own(raw, "reference"));
  // Each line gets its own brands, so a brand never carries over to another line.
  const analyses = lines.map((line) =>
    analyzeIngredient(
      { ingredientId: line.ingredientId, rawName: "" },
      line.index,
      records,
      indexBrands(line.brandIds.map((brandId) => ({ ingredientId: line.ingredientId, brandId }))),
    ),
  );
  // The engine's own halal check and precedence (SAF-04, SAF-08); no lines gives no_ingredients.
  const verdict = evaluateMember(HALAL_CHECK, analyses);
  const findings = verdict.reasons.map((reason): RecipeHalalFinding => ({
    kind: reason.kind,
    code: reason.code,
    line:
      reason.ingredient === null
        ? null
        : {
            index: reason.ingredient.index,
            // Analyses are built from `lines` with their own index, so this line exists.
            lineId: lines[reason.ingredient.index]!.lineId,
            ingredientId: reason.ingredient.ingredientId,
          },
    componentPath: reason.componentPath,
    brandId: reason.brandId,
    detail: reason.detail,
  }));
  return {
    result: {
      status: HALAL_STATUS_OF[verdict.status],
      findings,
      ruleSetVersion: RULE_SET_VERSION,
      referenceVersion: version,
    },
    lines,
  };
}

/**
 * LIB-05: derives a recipe's halal status from the reference ingredient data
 * only, through the same halal check Cek Aman applies to a member with a halal
 * rule (SAF-08), so the two can never disagree:
 *
 * - any alcohol, pork or non-halal animal ingredient or component, in the
 *   generic data or in any brand the line lists: `not_halal`
 * - otherwise any uncertainty (unresolved, custom or unknown line, missing or
 *   unverified component or halal data, brand not known or not verified, or
 *   no lines at all): `check_label`, never `halal` (fail closed)
 * - otherwise `halal`
 *
 * Pure and deterministic, like `evaluate`. Any status in the input is ignored,
 * and recognition output never reaches it (REC-06, SAF-10). The reference is
 * read once and the versions reported are those of that one read.
 *
 * To serve a result, use `deriveRecipeHalalWithLog` instead.
 *
 * @throws CekAmanInputError when the input is structurally unusable (no line
 *   list, a line without a lineId, a duplicate lineId, unusable reference data).
 */
export function deriveRecipeHalal(input: RecipeHalalInput): RecipeHalalResult {
  return deriveWithLines(input).result;
}
