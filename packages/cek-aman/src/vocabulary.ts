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

/** Identifier pattern shared by ingredient, brand and rule IDs. */
export const ID_PATTERN = "^[a-z0-9][a-z0-9_.-]{0,99}$";

/** `schema` value that identifies a reference ingredient dataset file. */
export const INGREDIENT_DATASET_SCHEMA = "keluargamakan.reference.ingredients/1";
