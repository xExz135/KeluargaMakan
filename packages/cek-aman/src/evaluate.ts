import { CekAmanInputError } from "./errors.js";
import {
  isObject,
  own,
  ownItems,
  ownList,
  readSafetyData,
  type NormalizedSafetyData,
} from "./normalize.js";
import { classifyRule, type ClassifiedRule, type EvaluableRule } from "./rules.js";
import {
  ALLERGEN_BREAKS,
  ALLERGEN_RELATED,
  RULE_SET_VERSION,
  isStandardAllergen,
} from "./rule-set.js";
import type {
  CekAmanInput,
  CekAmanResult,
  IngredientRef,
  MemberSafetyResult,
  ReasonCode,
  ReasonKind,
  SafetyReason,
  SafetyStatus,
} from "./types.js";
import type { DietSuitability } from "./vocabulary.js";

type Obj = Readonly<Record<string, unknown>>;

/** A record (ingredient or component) whose data is checked against each rule. */
interface Finding {
  readonly id: string;
  readonly componentPath: readonly string[];
  readonly brandId: string | null;
  readonly data: NormalizedSafetyData;
}

/** An uncertainty that applies to every hard rule (SAF-07, SAF-09, fail closed). */
interface GeneralIssue {
  readonly kind: "unknown" | "brand_uncertain";
  readonly code: ReasonCode;
  readonly componentPath: readonly string[];
  readonly brandId: string | null;
  readonly detail: string | null;
}

interface IngredientAnalysis {
  readonly ref: IngredientRef;
  readonly findings: readonly Finding[];
  readonly issues: readonly GeneralIssue[];
}

interface PreparedMember {
  readonly memberId: string;
  readonly rules: readonly ClassifiedRule[];
}

/** Reason without the rule it was evaluated against. */
type PartialReason = Omit<SafetyReason, "rule" | "ingredient">;

const NOT_SAFE_KINDS: readonly ReasonKind[] = ["contains", "component"];

function nonEmptyString(value: unknown): value is string {
  return typeof value === "string" && value !== "";
}

function fail(message: string): never {
  throw new CekAmanInputError(message);
}

// ---------------------------------------------------------------------------
// Input preparation
// ---------------------------------------------------------------------------

function indexReference(raw: unknown): { version: string; records: ReadonlyMap<string, Obj> } {
  if (!isObject(raw)) fail("reference data is required");
  const version = own(raw, "version");
  if (!nonEmptyString(version)) fail("reference data version is required (DAT-06)");
  const list = ownItems(own(raw, "ingredients"));
  if (list === null) fail("reference ingredients must be a list");
  const records = new Map<string, Obj>();
  for (const record of list) {
    const id = isObject(record) ? own(record, "id") : undefined;
    if (!isObject(record) || !nonEmptyString(id)) fail("every reference ingredient needs an id");
    if (records.has(id)) fail(`duplicate reference ingredient id: ${id}`);
    records.set(id, record);
  }
  return { version, records };
}

function prepareMembers(
  raw: unknown,
  knownIngredient: (id: string) => boolean,
): readonly PreparedMember[] {
  const list = ownItems(raw);
  if (list === null || list.length === 0) {
    fail("at least one selected member is required (PRF-09)");
  }
  const seen = new Set<string>();
  return list.map((member) => {
    const memberId = isObject(member) ? own(member, "memberId") : undefined;
    if (!isObject(member) || !nonEmptyString(memberId)) fail("memberId is required");
    if (seen.has(memberId)) fail(`duplicate memberId: ${memberId}`);
    seen.add(memberId);
    const rules = ownItems(own(member, "hardRules"));
    if (rules === null) fail(`hardRules must be a list for member ${memberId}`);
    return { memberId, rules: rules.map((rule) => classifyRule(rule, knownIngredient)) };
  });
}

/** Recorded brands per ingredient ID. Malformed entries are ignored, which fails closed. */
function indexBrands(raw: unknown): ReadonlyMap<string, readonly string[]> {
  const list = ownItems(raw);
  if (list === null) fail("recordedBrands must be a list (may be empty)");
  const brands = new Map<string, string[]>();
  for (const entry of list) {
    if (!isObject(entry)) continue;
    const ingredientId = own(entry, "ingredientId");
    const brandId = own(entry, "brandId");
    if (!nonEmptyString(ingredientId) || !nonEmptyString(brandId)) continue;
    const list = brands.get(ingredientId) ?? [];
    if (!list.includes(brandId)) list.push(brandId);
    brands.set(ingredientId, list);
  }
  return brands;
}

// ---------------------------------------------------------------------------
// Ingredient analysis (independent of members)
// ---------------------------------------------------------------------------

/** SAF-07: which data describe this ingredient for this household. */
function brandViews(
  record: Obj,
  recorded: readonly string[],
  issues: GeneralIssue[],
): { brandId: string | null; data: NormalizedSafetyData }[] {
  const generic = { brandId: null, data: readSafetyData(record) };
  // Only an explicit `false` means the ingredient does not vary by brand.
  if (own(record, "brandVaries") === false) return [generic];
  const issue = (code: ReasonCode, detail: string | null): GeneralIssue => ({
    kind: "brand_uncertain",
    code,
    componentPath: [],
    brandId: null,
    detail,
  });
  if (recorded.length === 0) {
    issues.push(issue("brand_not_recorded", null));
    return [generic];
  }
  const variants = ownList(record, "brandVariants").filter(isObject);
  const views: { brandId: string | null; data: NormalizedSafetyData }[] = [];
  let needGeneric = false;
  for (const brandId of recorded) {
    const variant = variants.find((candidate) => own(candidate, "brandId") === brandId);
    if (variant !== undefined && own(variant, "verified") === true) {
      views.push({ brandId, data: readSafetyData(variant) });
    } else {
      issues.push(issue("brand_unverified", brandId));
      needGeneric = true;
    }
  }
  if (needGeneric) views.push(generic);
  return views;
}

function analyzeIngredient(
  raw: unknown,
  index: number,
  records: ReadonlyMap<string, Obj>,
  brands: ReadonlyMap<string, readonly string[]>,
): IngredientAnalysis {
  const item = isObject(raw) ? raw : {};
  const rawId = own(item, "ingredientId");
  const rawText = own(item, "rawName");
  const ingredientId = nonEmptyString(rawId) ? rawId : null;
  const rawName = typeof rawText === "string" ? rawText : "";
  const ref: IngredientRef = { index, ingredientId, rawName };
  const issues: GeneralIssue[] = [];
  const findings: Finding[] = [];
  const issue = (
    code: ReasonCode,
    componentPath: readonly string[],
    brandId: string | null = null,
    detail: string | null = null,
    kind: GeneralIssue["kind"] = "unknown",
  ): void => {
    issues.push({ kind, code, componentPath, brandId, detail });
  };

  // SAF-09, KIT-05, REC-06: unresolved or custom ingredient.
  if (ingredientId === null) {
    issue("ingredient_unresolved", []);
    return { ref, findings, issues };
  }
  const record = records.get(ingredientId);
  if (record === undefined) {
    issue("ingredient_not_in_reference", []);
    return { ref, findings, issues };
  }

  for (const view of brandViews(record, brands.get(ingredientId) ?? [], issues)) {
    const done = new Set<string>([ingredientId]);
    // SAF-03: walk the ingredient and its known components, depth first.
    const walk = (
      id: string,
      data: NormalizedSafetyData,
      path: readonly string[],
      stack: ReadonlySet<string>,
    ): void => {
      findings.push({ id, componentPath: path, brandId: view.brandId, data });
      if (!data.components.verified) issue("components_unverified", path, view.brandId);
      for (const childId of data.components.ids) {
        const childPath = [...path, childId];
        if (stack.has(childId)) {
          issue("component_cycle", childPath, view.brandId, childId);
          continue;
        }
        if (done.has(childId)) continue;
        done.add(childId);
        const child = records.get(childId);
        if (child === undefined) {
          issue("component_not_in_reference", childPath, view.brandId, childId);
          continue;
        }
        // A component's brand is unknown even when the household recorded one
        // for the standalone ingredient (docs/QUESTIONS.md).
        if (own(child, "brandVaries") !== false) {
          issue("component_brand_varies", childPath, view.brandId, childId, "brand_uncertain");
        }
        walk(childId, readSafetyData(child), childPath, new Set([...stack, childId]));
      }
    };
    walk(ingredientId, view.data, [], new Set([ingredientId]));
  }
  return { ref, findings, issues };
}

// ---------------------------------------------------------------------------
// Rule evaluation
// ---------------------------------------------------------------------------

function notSafe(finding: Finding, code: ReasonCode, detail: string | null): PartialReason {
  return {
    kind: finding.componentPath.length === 0 ? "contains" : "component",
    code,
    componentPath: finding.componentPath,
    brandId: finding.brandId,
    detail,
  };
}

function checkLabel(finding: Finding, code: ReasonCode, detail: string | null): PartialReason {
  return {
    kind: "unknown",
    code,
    componentPath: finding.componentPath,
    brandId: finding.brandId,
    detail,
  };
}

function evaluateAllergy(allergen: string, finding: Finding): PartialReason[] {
  const { allergens } = finding.data;
  const out: PartialReason[] = [];
  for (const tag of allergens.contains) {
    if (!isStandardAllergen(tag)) out.push(checkLabel(finding, "allergen_unrecognized", tag));
    else if (ALLERGEN_BREAKS[tag].some((a) => a === allergen)) {
      out.push(notSafe(finding, "allergen_contains", tag));
    } else if (ALLERGEN_RELATED[tag].some((a) => a === allergen)) {
      out.push(checkLabel(finding, "allergen_related", tag));
    }
  }
  for (const tag of allergens.mayContain) {
    if (!isStandardAllergen(tag)) out.push(checkLabel(finding, "allergen_unrecognized", tag));
    else if ([...ALLERGEN_BREAKS[tag], ...ALLERGEN_RELATED[tag]].some((a) => a === allergen)) {
      out.push(checkLabel(finding, "allergen_may_contain", tag));
    }
  }
  if (!allergens.verified) out.push(checkLabel(finding, "allergens_unverified", null));
  return out;
}

/** SAF-08: alcohol, pork or non-halal animal fails; anything not verified halal is uncertain. */
function evaluateHalal(finding: Finding): PartialReason[] {
  const { halal } = finding.data;
  if (halal.value === "not_halal") {
    return halal.sources.length === 0
      ? [notSafe(finding, "halal_not_halal", null)]
      : halal.sources.map((source) => notSafe(finding, "halal_not_halal", source));
  }
  if (halal.value !== "halal" || !halal.verified) {
    return [checkLabel(finding, "halal_uncertain", halal.value)];
  }
  return [];
}

function evaluateDiet(diet: "vegetarian" | "vegan", finding: Finding): PartialReason[] {
  const data = finding.data.diet;
  // Anything not vegetarian is not vegan either, whatever the vegan field says.
  const value: DietSuitability =
    diet === "vegan" && data.vegetarian === "not_suitable" ? "not_suitable" : data[diet];
  if (value === "not_suitable") return [notSafe(finding, "diet_not_suitable", diet)];
  if (value !== "suitable" || !data.verified) return [checkLabel(finding, "diet_uncertain", diet)];
  return [];
}

function evaluateFinding(rule: EvaluableRule, finding: Finding): PartialReason[] {
  switch (rule.kind) {
    case "allergy":
      return evaluateAllergy(rule.allergen, finding);
    case "halal":
      return evaluateHalal(finding);
    case "vegetarian":
    case "vegan":
      return evaluateDiet(rule.kind, finding);
    case "exclusion":
      return rule.ids.has(finding.id) ? [notSafe(finding, "excluded_ingredient", finding.id)] : [];
  }
}

function deriveStatus(reasons: readonly SafetyReason[]): SafetyStatus {
  if (reasons.some((reason) => NOT_SAFE_KINDS.includes(reason.kind))) return "not_safe";
  return reasons.length > 0 ? "check_label" : "safe";
}

function evaluateMember(
  member: PreparedMember,
  analyses: readonly IngredientAnalysis[],
): MemberSafetyResult {
  const reasons: SafetyReason[] = [];
  for (const rule of member.rules) {
    // PRF-08, SAF-09: a rule the engine cannot evaluate always needs a label check.
    if (rule.kind === "unevaluable") {
      reasons.push({
        kind: "unmapped_rule",
        code: rule.code,
        rule: rule.ref,
        ingredient: null,
        componentPath: [],
        brandId: null,
        detail: null,
      });
      continue;
    }
    if (analyses.length === 0) {
      reasons.push({
        kind: "unknown",
        code: "no_ingredients",
        rule: rule.ref,
        ingredient: null,
        componentPath: [],
        brandId: null,
        detail: null,
      });
    }
    for (const analysis of analyses) {
      const add = (partial: PartialReason): void => {
        reasons.push({ ...partial, rule: rule.ref, ingredient: analysis.ref });
      };
      analysis.issues.forEach(add);
      for (const finding of analysis.findings) evaluateFinding(rule, finding).forEach(add);
    }
  }
  // Stable sort: "Not safe" reasons first, otherwise input order.
  const severity = (reason: SafetyReason): number => (NOT_SAFE_KINDS.includes(reason.kind) ? 0 : 1);
  reasons.sort((a, b) => severity(a) - severity(b));
  return { memberId: member.memberId, status: deriveStatus(reasons), reasons };
}

/**
 * Cek Aman (SAF-01): evaluates a recipe's ingredients against the hard rules of
 * the selected members only (PRF-11).
 *
 * Pure and deterministic: no network, clock, randomness, AI or other I/O, and
 * the input is never modified. Per member, any "Not safe" reason wins, then any
 * uncertainty gives "Check the label", otherwise "Safe" (SAF-04). There is no
 * way to override a result (SAF-12).
 *
 * @throws CekAmanInputError when the input is structurally unusable.
 */
export function evaluate(input: CekAmanInput): CekAmanResult {
  const raw: unknown = input;
  if (!isObject(raw)) fail("input is required");
  const { version, records } = indexReference(own(raw, "reference"));
  const known = (id: string): boolean => records.has(id);
  const members = prepareMembers(own(raw, "members"), known);
  const brands = indexBrands(own(raw, "recordedBrands"));
  const ingredients = ownItems(own(raw, "ingredients"));
  if (ingredients === null) fail("ingredients must be a list");
  const analyses = ingredients.map((item, index) =>
    analyzeIngredient(item, index, records, brands),
  );
  return {
    perMember: members.map((member) => evaluateMember(member, analyses)),
    ruleSetVersion: RULE_SET_VERSION,
    referenceVersion: version,
  };
}
