import { isObject } from "./normalize.js";
import { isStandardAllergen } from "./rule-set.js";
import type { ReasonCode, RuleRef } from "./types.js";
import { MAPPING_CONFIRMERS, type StandardAllergen } from "./vocabulary.js";

/** A hard rule the engine can evaluate against ingredient data. */
export type EvaluableRule =
  | { readonly kind: "allergy"; readonly ref: RuleRef; readonly allergen: StandardAllergen }
  | { readonly kind: "halal" | "vegetarian" | "vegan"; readonly ref: RuleRef }
  | { readonly kind: "exclusion"; readonly ref: RuleRef; readonly ids: ReadonlySet<string> };

/** A hard rule that cannot be evaluated, so it always returns "Check the label". */
export interface UnevaluableRule {
  readonly kind: "unevaluable";
  readonly ref: RuleRef;
  readonly code: Extract<
    ReasonCode,
    | "rule_unmapped"
    | "rule_mapping_unconfirmed"
    | "rule_mapping_unknown_ingredient"
    | "rule_invalid"
  >;
}

export type ClassifiedRule = EvaluableRule | UnevaluableRule;

/** Rule summary kept in the safety log: no free text, which may hold names (AI-03, DAT-08). */
export interface RuleSummary extends RuleRef {
  readonly mappingStatus: string | null;
  readonly mappedIngredientIds: readonly string[];
}

function str(value: unknown): string | null {
  return typeof value === "string" && value !== "" ? value : null;
}

export function ruleRef(raw: unknown): RuleRef {
  const rule = isObject(raw) ? raw : {};
  return {
    ruleId: str(rule["ruleId"]) ?? "",
    type: str(rule["type"]) ?? "",
    allergen: str(rule["allergen"]),
  };
}

export function summarizeRule(raw: unknown): RuleSummary {
  const rule = isObject(raw) ? raw : {};
  const mapping = isObject(rule["mapping"]) ? rule["mapping"] : {};
  const ids = mapping["ingredientIds"];
  return {
    ...ruleRef(raw),
    mappingStatus: str(mapping["status"]),
    mappedIngredientIds: Array.isArray(ids) ? ids.filter((id) => typeof id === "string") : [],
  };
}

const unevaluable = (ref: RuleRef, code: UnevaluableRule["code"]): UnevaluableRule => ({
  kind: "unevaluable",
  ref,
  code,
});

/**
 * PRF-08, SAF-09: a free-text or medical-exclusion rule is evaluated only when
 * it is mapped to known reference ingredients and confirmed by the content team
 * or the manager. Unmapped or merely proposed mappings return "Check the label".
 */
function classifyMapping(
  ref: RuleRef,
  raw: unknown,
  knownIngredient: (id: string) => boolean,
): ClassifiedRule {
  if (!isObject(raw)) return unevaluable(ref, "rule_invalid");
  switch (raw["status"]) {
    case "unmapped":
      return unevaluable(ref, "rule_unmapped");
    case "proposed":
      return unevaluable(ref, "rule_mapping_unconfirmed");
    case "mapped": {
      const ids: unknown = raw["ingredientIds"];
      const confirmed = (MAPPING_CONFIRMERS as readonly unknown[]).includes(raw["confirmedBy"]);
      if (!confirmed || !Array.isArray(ids) || ids.length === 0) {
        return unevaluable(ref, "rule_invalid");
      }
      const list: unknown[] = ids;
      if (!list.every((id): id is string => str(id) !== null)) {
        return unevaluable(ref, "rule_invalid");
      }
      if (!list.every(knownIngredient)) {
        return unevaluable(ref, "rule_mapping_unknown_ingredient");
      }
      return { kind: "exclusion", ref, ids: new Set(list) };
    }
    default:
      return unevaluable(ref, "rule_invalid");
  }
}

/** Classifies one hard rule. Anything not understood fails closed as `rule_invalid`. */
export function classifyRule(
  raw: unknown,
  knownIngredient: (id: string) => boolean,
): ClassifiedRule {
  const ref = ruleRef(raw);
  if (!isObject(raw) || ref.ruleId === "") return unevaluable(ref, "rule_invalid");
  switch (raw["type"]) {
    case "allergy": {
      const allergen = raw["allergen"];
      return isStandardAllergen(allergen)
        ? { kind: "allergy", ref, allergen }
        : unevaluable(ref, "rule_invalid");
    }
    case "halal":
      return { kind: "halal", ref };
    case "vegetarian":
      return { kind: "vegetarian", ref };
    case "vegan":
      return { kind: "vegan", ref };
    case "medical_exclusion":
    case "free_text":
      return classifyMapping(ref, raw["mapping"], knownIngredient);
    default:
      return unevaluable(ref, "rule_invalid");
  }
}
