// TEST FIXTURE: not real safety or nutrition data
//
// Deliberately INVALID reference records for Cek Aman tests only. Each
// record below contradicts itself and is rejected by data/schema (a validator
// test proves it). It exists to show that the engine still fails closed when
// such data bypasses validation (for example an admin edit or a sync bug).
// Every value is invented. IDs carry the `fx_bad_` prefix. The regression
// suite combines these records with the valid fixture ingredients.
// Never load this file outside tests (enforced by `pnpm check:fixtures`).

import type { ReferenceIngredient } from "../../../packages/cek-aman/src/types.js";

export const MALFORMED_FIXTURE_REFERENCE_VERSION = "TEST-FIXTURE-2026.11.0-malformed";

function record(
  id: string,
  nameId: string,
  nameEn: string,
  overrides: Partial<ReferenceIngredient>,
): ReferenceIngredient {
  return {
    id,
    displayName: { id: nameId, en: nameEn },
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

/** The contradictory records only, so a test can check each one is rejected. */
export const malformedIngredients: readonly ReferenceIngredient[] = [
  // PRF-03: vegan "suitable" while vegetarian is only uncertain.
  record("fx_bad_vegan_veg_uncertain", "Perisa fiksi", "Fiction flavouring", {
    diet: { verification: "verified", vegetarian: "uncertain", vegan: "suitable" },
  }),
  // PRF-03: vegan "suitable" while vegetarian is unknown.
  record("fx_bad_vegan_veg_unknown", "Pewarna fiksi", "Fiction colouring", {
    diet: { verification: "verified", vegetarian: "unknown", vegan: "suitable" },
  }),
];
