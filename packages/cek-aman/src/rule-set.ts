import { STANDARD_ALLERGENS, type StandardAllergen } from "./vocabulary.js";

/**
 * Version of the rule logic in this package (SAF-14). Bump it whenever any
 * evaluation behavior changes, and record the change in docs/DECISIONS.md.
 */
export const RULE_SET_VERSION = "cek-aman-rules/1.0.0";

type AllergenTable = Readonly<Record<StandardAllergen, readonly StandardAllergen[]>>;

/**
 * Allergen rules that an ingredient tagged with an allergen breaks ("Not safe").
 * Every tag breaks its own rule. Shrimp is a shellfish and wheat contains
 * gluten, so those tags also break the broader rule.
 */
export const ALLERGEN_BREAKS: AllergenTable = {
  peanut: ["peanut"],
  tree_nut: ["tree_nut"],
  shellfish: ["shellfish"],
  shrimp: ["shrimp", "shellfish"],
  fish: ["fish"],
  egg: ["egg"],
  milk: ["milk"],
  soy: ["soy"],
  wheat: ["wheat", "gluten"],
  gluten: ["gluten"],
  sesame: ["sesame"],
};

/**
 * Allergen rules for which a tag is related but not conclusive ("Check the
 * label"). A generic shellfish tag may be shrimp; a generic gluten tag may come
 * from wheat. Pending safety-owner confirmation (docs/QUESTIONS.md).
 */
export const ALLERGEN_RELATED: AllergenTable = {
  peanut: [],
  tree_nut: [],
  shellfish: ["shrimp"],
  shrimp: [],
  fish: [],
  egg: [],
  milk: [],
  soy: [],
  wheat: [],
  gluten: ["wheat"],
  sesame: [],
};

export function isStandardAllergen(value: unknown): value is StandardAllergen {
  return typeof value === "string" && (STANDARD_ALLERGENS as readonly string[]).includes(value);
}
