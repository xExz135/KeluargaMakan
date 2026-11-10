// TEST FIXTURE: not real safety or nutrition data
//
// Builders for fictional reference ingredients and rules used by the unit
// tests in this package. Excluded from the build; never import from src code.

import type {
  CekAmanInput,
  HardRule,
  MemberRulesInput,
  RecordedBrand,
  ReferenceIngredient,
} from "./types.js";
import type { StandardAllergen } from "./vocabulary.js";

/** A fictional ingredient that is verified, plant-based, halal and has no allergens. */
export function ing(id: string, overrides: Record<string, unknown> = {}): ReferenceIngredient {
  return {
    id,
    displayName: { id: `Fiksi ${id}`, en: `Fiction ${id}` },
    localNames: [],
    category: "fixture",
    components: { verification: "verified", ingredientIds: [] },
    allergens: { verification: "verified", contains: [], mayContain: [] },
    halal: { verification: "verified", value: "halal", nonHalalSources: [] },
    diet: { verification: "verified", vegetarian: "suitable", vegan: "suitable" },
    brandVaries: false,
    brandVariants: [],
    tkpiCode: null,
    ...overrides,
  };
}

export const rules = {
  allergy: (allergen: StandardAllergen, ruleId = `r-${allergen}`): HardRule => ({
    ruleId,
    type: "allergy",
    allergen,
  }),
  halal: (): HardRule => ({ ruleId: "r-halal", type: "halal" }),
  vegetarian: (): HardRule => ({ ruleId: "r-vegetarian", type: "vegetarian" }),
  vegan: (): HardRule => ({ ruleId: "r-vegan", type: "vegan" }),
  exclusion: (...ingredientIds: string[]): HardRule => ({
    ruleId: "r-exclusion",
    type: "medical_exclusion",
    freeText: null,
    mapping: { status: "mapped", ingredientIds, confirmedBy: "content_team" },
  }),
};

export function member(memberId: string, ...hardRules: unknown[]): MemberRulesInput {
  return { memberId, hardRules: hardRules as HardRule[] };
}

/** Builds an input; ingredient IDs default their raw name to the ID. */
export function input(options: {
  reference: readonly ReferenceIngredient[];
  recipe: readonly (string | null)[];
  members: readonly MemberRulesInput[];
  brands?: readonly RecordedBrand[];
}): CekAmanInput {
  return {
    ingredients: options.recipe.map((id) => ({ ingredientId: id, rawName: id ?? "custom" })),
    recordedBrands: options.brands ?? [],
    members: options.members,
    reference: {
      schema: "keluargamakan.reference.ingredients/1",
      version: "unit-fixture-1",
      ingredients: options.reference,
    },
  };
}
