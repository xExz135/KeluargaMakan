/**
 * Closed value lists used by Cek Aman and mirrored in the JSON Schemas under
 * data/schema/. A test checks that both stay identical. Changing any list is a
 * rule-set change: bump RULE_SET_VERSION and record it in docs/DECISIONS.md.
 *
 * This file must stay free of runtime imports so tooling can load it directly.
 */

/** PRF-04 standard allergen list. Free-text allergies use a `free_text` rule. */
export const STANDARD_ALLERGENS = [
  "peanut",
  "tree_nut",
  "shellfish",
  "shrimp",
  "fish",
  "egg",
  "milk",
  "soy",
  "wheat",
  "gluten",
  "sesame",
] as const;
export type StandardAllergen = (typeof STANDARD_ALLERGENS)[number];

/** Whether the content team has verified a piece of reference data. */
export const VERIFICATION_STATES = ["verified", "unverified"] as const;
export type Verification = (typeof VERIFICATION_STATES)[number];

/** SAF-08 halal status. `uncertain` and `unknown` both return "Check the label". */
export const HALAL_VALUES = ["halal", "not_halal", "uncertain", "unknown"] as const;
export type HalalValue = (typeof HALAL_VALUES)[number];

/** SAF-08 reasons an ingredient fails a halal rule. */
export const NON_HALAL_SOURCES = ["alcohol", "pork", "non_halal_animal"] as const;
export type NonHalalSource = (typeof NON_HALAL_SOURCES)[number];

/** PRF-03 vegetarian and vegan suitability of one ingredient. */
export const DIET_SUITABILITY = ["suitable", "not_suitable", "uncertain", "unknown"] as const;
export type DietSuitability = (typeof DIET_SUITABILITY)[number];

/** PRF-03 hard rule types. */
export const HARD_RULE_TYPES = [
  "allergy",
  "halal",
  "vegetarian",
  "vegan",
  "medical_exclusion",
  "free_text",
] as const;
export type HardRuleType = (typeof HARD_RULE_TYPES)[number];

/**
 * PRF-08 mapping state of a free-text or medical-exclusion rule.
 * `proposed` (for example suggested by the system or an AI) is not a mapping:
 * only `mapped` with a human confirmer is evaluated as a mapping.
 */
export const MAPPING_STATUSES = ["mapped", "proposed", "unmapped"] as const;
export type MappingStatus = (typeof MAPPING_STATUSES)[number];

/** PRF-08: who may confirm a free-text mapping. */
export const MAPPING_CONFIRMERS = ["content_team", "manager"] as const;
export type MappingConfirmer = (typeof MAPPING_CONFIRMERS)[number];

// ---------------------------------------------------------------------------
// Result values (SAF-04). Contract 0.3 mirrors them as `SafetyStatus`,
// `SafetyReasonKind` and `SafetyReasonCode`, and the packages/contracts tests
// compare those enums with these lists. Changing a list is a rule-set change.
// ---------------------------------------------------------------------------

/** SAF-04 result per member: Safe, Not safe or Check the label. */
export const SAFETY_STATUSES = ["safe", "not_safe", "check_label"] as const;

/** `contains` and `component` mean "Not safe"; the other kinds mean "Check the label". */
export const REASON_KINDS = [
  "contains",
  "component",
  "unknown",
  "brand_uncertain",
  "unmapped_rule",
] as const;

export const REASON_CODES = [
  // Not safe
  "allergen_contains",
  "halal_not_halal",
  "diet_not_suitable",
  "excluded_ingredient",
  // Check the label: missing or uncertain data
  "no_ingredients",
  "ingredient_unresolved",
  "ingredient_not_in_reference",
  "components_unverified",
  "component_not_in_reference",
  "component_cycle",
  "allergens_unverified",
  "allergen_may_contain",
  "allergen_related",
  "allergen_unrecognized",
  "halal_uncertain",
  "diet_uncertain",
  // Check the label: brand uncertainty (SAF-07)
  "brand_not_recorded",
  "brand_unverified",
  "component_brand_varies",
  // Check the label: rule cannot be evaluated (PRF-08, SAF-09)
  "rule_unmapped",
  "rule_mapping_unconfirmed",
  "rule_mapping_unknown_ingredient",
  "rule_invalid",
] as const;

/** Identifier pattern shared by ingredient, brand and rule IDs. */
export const ID_PATTERN = "^[a-z0-9][a-z0-9_.-]{0,99}$";

/** `schema` value that identifies a reference ingredient dataset file. */
export const INGREDIENT_DATASET_SCHEMA = "keluargamakan.reference.ingredients/1";
