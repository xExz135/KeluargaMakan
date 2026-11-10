// TEST FIXTURE: not real safety or nutrition data
//
// Cek Aman regression cases (NFR-07). Each case names the requirement IDs it
// verifies. The suite grows with every reported error: add a case, never edit
// an expectation to make a failing case pass without a safety-owner decision.

import {
  fixtureMembers,
  type FixtureMemberKey,
} from "../../data/fixtures/cek-aman/members.fixture.js";
import { fixtureReference } from "../../data/fixtures/cek-aman/reference.fixture.js";
import type {
  CekAmanInput,
  ReasonCode,
  ReasonKind,
  SafetyStatus,
} from "../../packages/cek-aman/src/index.js";

/** `[status, ...reason codes that must be present]` */
export type Expectation = readonly [SafetyStatus, ...ReasonCode[]];

export interface RegressionCase {
  readonly id: string;
  readonly requirements: readonly string[];
  readonly title: string;
  /** Reference IDs, or `{ custom }` for an ingredient with no reference ID. */
  readonly ingredients: readonly (string | { readonly custom: string })[];
  readonly brands?: readonly (readonly [ingredientId: string, brandId: string])[];
  /** The selected members (PRF-11) and what each must get. */
  readonly expect: Partial<Record<FixtureMemberKey, Expectation>>;
}

export function toInput(testCase: RegressionCase): CekAmanInput {
  return {
    ingredients: testCase.ingredients.map((item) =>
      typeof item === "string"
        ? { ingredientId: item, rawName: item.replace(/^fx_/, "").replaceAll("_", " ") }
        : { ingredientId: null, rawName: item.custom },
    ),
    recordedBrands: (testCase.brands ?? []).map(([ingredientId, brandId]) => ({
      ingredientId,
      brandId,
    })),
    members: (Object.keys(testCase.expect) as FixtureMemberKey[]).map((key) => fixtureMembers[key]),
    reference: fixtureReference,
  };
}

export const NOT_SAFE_KINDS: readonly ReasonKind[] = ["contains", "component"];

const base = ["fx_nasi", "fx_bawang_putih", "fx_cabai", "fx_garam"] as const;

export const regressionCases: readonly RegressionCase[] = [
  // --- SAF-06 known unsafe combinations: blocked in 100% of cases ---------
  {
    id: "REG-001",
    requirements: ["SAF-03", "SAF-06", "PRF-04"],
    title: "terasi with a shrimp allergy",
    ingredients: [...base, "fx_terasi"],
    expect: { kakak: ["not_safe", "allergen_contains"], ibu: ["safe"] },
  },
  {
    id: "REG-002",
    requirements: ["SAF-03", "SAF-06", "PRF-04"],
    title: "terasi with a shellfish allergy (shrimp is a shellfish)",
    ingredients: [...base, "fx_terasi"],
    expect: { adik: ["not_safe", "allergen_contains"] },
  },
  {
    id: "REG-003",
    requirements: ["SAF-03", "SAF-06"],
    title: "petis, tagged only through its shrimp component, with a shrimp allergy",
    ingredients: [...base, "fx_petis"],
    expect: { kakak: ["not_safe", "allergen_contains"], adik: ["not_safe", "allergen_contains"] },
  },
  {
    id: "REG-004",
    requirements: ["SAF-03", "SAF-06"],
    title: "sambal terasi: shrimp two levels deep in the components",
    ingredients: ["fx_nasi", "fx_sambal_terasi"],
    expect: { kakak: ["not_safe", "allergen_contains"], ibu: ["safe"] },
  },
  {
    id: "REG-005",
    requirements: ["SAF-06", "SAF-07"],
    title: "oyster sauce with a shellfish allergy, no brand recorded",
    ingredients: [...base, "fx_saus_tiram"],
    expect: { adik: ["not_safe", "allergen_contains", "brand_not_recorded"] },
  },
  {
    id: "REG-006",
    requirements: ["SAF-06", "SAF-07"],
    title: "oyster sauce with a shellfish allergy, verified brand recorded",
    ingredients: [...base, "fx_saus_tiram"],
    brands: [["fx_saus_tiram", "fx_brand_tiram_a"]],
    expect: { adik: ["not_safe", "allergen_contains"] },
  },
  {
    id: "REG-007",
    requirements: ["SAF-06", "PRF-04"],
    title: "oyster sauce (generic shellfish) with a shrimp allergy is never safe",
    ingredients: [...base, "fx_saus_tiram"],
    brands: [["fx_saus_tiram", "fx_brand_tiram_a"]],
    expect: { kakak: ["check_label", "allergen_related"] },
  },
  {
    id: "REG-008",
    requirements: ["SAF-03", "SAF-06"],
    title: "fish sauce with a fish allergy",
    ingredients: [...base, "fx_kecap_ikan"],
    expect: { paman: ["not_safe", "allergen_contains"], ibu: ["safe"] },
  },
  {
    id: "REG-009",
    requirements: ["SAF-06", "SAF-08"],
    title: "angciu with a halal rule",
    ingredients: [...base, "fx_ayam", "fx_angciu"],
    expect: { ayah: ["not_safe", "halal_not_halal"], ibu: ["safe"] },
  },
  {
    id: "REG-010",
    requirements: ["SAF-03", "SAF-06", "SAF-08"],
    title: "mirin fails halal through its alcohol component",
    ingredients: [...base, "fx_mirin"],
    expect: { ayah: ["not_safe", "halal_not_halal", "halal_uncertain"] },
  },
  {
    id: "REG-011",
    requirements: ["SAF-06"],
    title: "kecap manis with a soy allergy, no brand recorded",
    ingredients: [...base, "fx_tahu", "fx_kecap_manis"],
    expect: { kakek: ["not_safe", "allergen_contains", "brand_not_recorded"] },
  },
  {
    id: "REG-012",
    requirements: ["SAF-06", "SAF-07"],
    title: "kecap manis (possibly wheat) with a wheat allergy, no brand recorded",
    ingredients: [...base, "fx_kecap_manis"],
    expect: { bibi: ["check_label", "allergen_may_contain", "brand_not_recorded"] },
  },
  {
    id: "REG-013",
    requirements: ["SAF-06", "PRF-04"],
    title: "soy sauce with a wheat allergy",
    ingredients: [...base, "fx_kecap_asin"],
    expect: { bibi: ["not_safe", "allergen_contains"], kakek: ["not_safe", "allergen_contains"] },
  },
  {
    id: "REG-014",
    requirements: ["SAF-06", "SAF-07"],
    title: "bouillon powder with wheat and milk allergies",
    ingredients: [...base, "fx_kaldu_bubuk"],
    expect: {
      bibi: ["check_label", "allergen_may_contain", "components_unverified"],
      sepupu: ["check_label", "allergen_may_contain", "allergens_unverified"],
    },
  },
  {
    id: "REG-015",
    requirements: ["SAF-06", "SAF-08"],
    title: "gelatin with a halal rule (uncertain animal source)",
    ingredients: ["fx_gelatin", "fx_santan"],
    expect: { ayah: ["check_label", "halal_uncertain", "brand_not_recorded"] },
  },
  {
    id: "REG-016",
    requirements: ["SAF-06", "PRF-03"],
    title: "gelatin with vegetarian and vegan rules",
    ingredients: ["fx_gelatin", "fx_santan"],
    expect: {
      tante: ["not_safe", "diet_not_suitable"],
      keponakan: ["not_safe", "diet_not_suitable"],
    },
  },
  {
    id: "REG-017",
    requirements: ["SAF-08"],
    title: "pork with a halal rule",
    ingredients: [...base, "fx_babi"],
    expect: { ayah: ["not_safe", "halal_not_halal"], ibu: ["safe"] },
  },
  {
    id: "REG-018",
    requirements: ["SAF-03", "PRF-04"],
    title: "prawn crackers with wheat and shrimp allergies",
    ingredients: ["fx_nasi", "fx_kerupuk_udang"],
    expect: { bibi: ["not_safe", "allergen_contains"], kakak: ["not_safe", "allergen_contains"] },
  },

  // --- SAF-07 brand uncertainty --------------------------------------------
  {
    id: "REG-020",
    requirements: ["SAF-07"],
    title: "kecap manis with a verified brand that has no wheat: safe for wheat allergy",
    ingredients: [...base, "fx_kecap_manis"],
    brands: [["fx_kecap_manis", "fx_brand_kecap_a"]],
    expect: { bibi: ["safe"] },
  },
  {
    id: "REG-021",
    requirements: ["SAF-07"],
    title: "kecap manis with an unverified brand: check the label",
    ingredients: [...base, "fx_kecap_manis"],
    brands: [["fx_kecap_manis", "fx_brand_kecap_b"]],
    expect: {
      bibi: ["check_label", "brand_unverified"],
      ayah: ["check_label", "brand_unverified"],
    },
  },
  {
    id: "REG-022",
    requirements: ["SAF-07"],
    title: "kecap manis with a brand unknown to the reference data",
    ingredients: [...base, "fx_kecap_manis"],
    brands: [["fx_kecap_manis", "fx_brand_not_in_reference"]],
    expect: { bibi: ["check_label", "brand_unverified"] },
  },
  {
    id: "REG-023",
    requirements: ["SAF-07"],
    title: "two recorded brands, one verified and one not: worst case applies",
    ingredients: [...base, "fx_kecap_manis"],
    brands: [
      ["fx_kecap_manis", "fx_brand_kecap_a"],
      ["fx_kecap_manis", "fx_brand_kecap_b"],
    ],
    expect: { bibi: ["check_label", "brand_unverified", "allergen_may_contain"] },
  },
  {
    id: "REG-024",
    requirements: ["SAF-07"],
    title: "brand-variant ingredient with no brand: never safe for any hard rule",
    ingredients: [...base, "fx_kecap_asin"],
    expect: { ayah: ["check_label", "brand_not_recorded"], om: ["check_label", "rule_unmapped"] },
  },
  {
    id: "REG-025",
    requirements: ["SAF-07", "PRF-11"],
    title: "brand uncertainty does not affect a member with no hard rules",
    ingredients: [...base, "fx_kecap_asin"],
    expect: { ibu: ["safe"] },
  },

  // --- SAF-08 halal ---------------------------------------------------------
  {
    id: "REG-030",
    requirements: ["SAF-08"],
    title: "verified halal ingredients only: safe for a halal rule",
    ingredients: [...base, "fx_ayam", "fx_santan"],
    expect: { ayah: ["safe"] },
  },
  {
    id: "REG-031",
    requirements: ["SAF-08", "SAF-07"],
    title: "oyster sauce with uncertain generic halal status and no brand: check the label",
    ingredients: [...base, "fx_saus_tiram"],
    expect: { ayah: ["check_label", "halal_uncertain", "brand_not_recorded"] },
  },
  {
    id: "REG-033",
    requirements: ["SAF-08", "SAF-07"],
    title: "oyster sauce with a verified brand recorded as halal: its data replace the generic",
    ingredients: [...base, "fx_saus_tiram"],
    brands: [["fx_saus_tiram", "fx_brand_tiram_a"]],
    expect: { ayah: ["safe"] },
  },
  {
    id: "REG-032",
    requirements: ["SAF-08"],
    title: "bouillon powder with uncertain halal status",
    ingredients: [...base, "fx_kaldu_bubuk"],
    expect: { ayah: ["check_label", "halal_uncertain"] },
  },

  // --- SAF-09 custom ingredients and unmapped rules --------------------------
  {
    id: "REG-040",
    requirements: ["SAF-09", "KIT-05"],
    title: "custom ingredient: check the label for every member with a hard rule",
    ingredients: [...base, { custom: "bumbu rahasia" }],
    expect: {
      kakak: ["check_label", "ingredient_unresolved"],
      ayah: ["check_label", "ingredient_unresolved"],
      tante: ["check_label", "ingredient_unresolved"],
      nenek: ["check_label", "ingredient_unresolved"],
      ibu: ["safe"],
    },
  },
  {
    id: "REG-041",
    requirements: ["SAF-09", "SAF-10", "REC-06", "AI-01"],
    title: "AI-named ingredient not mapped to a reference ID",
    ingredients: [...base, { custom: "saus misterius (dari foto)" }],
    expect: { adik: ["check_label", "ingredient_unresolved"], ayah: ["check_label"] },
  },
  {
    id: "REG-042",
    requirements: ["SAF-09"],
    title: "ingredient ID missing from the reference data",
    ingredients: [...base, "fx_not_in_reference"],
    expect: { kakak: ["check_label", "ingredient_not_in_reference"] },
  },
  {
    id: "REG-043",
    requirements: ["SAF-09", "PRF-08"],
    title: "unmapped free-text rule: check the label even for plain rice",
    ingredients: ["fx_nasi"],
    expect: { om: ["check_label", "rule_unmapped"], ibu: ["safe"] },
  },
  {
    id: "REG-044",
    requirements: ["SAF-09", "PRF-08", "SAF-10"],
    title: "proposed (unconfirmed) mapping is not trusted",
    ingredients: ["fx_nasi"],
    expect: { kakekBuyut: ["check_label", "rule_mapping_unconfirmed"] },
  },
  {
    id: "REG-045",
    requirements: ["PRF-03", "PRF-08"],
    title: "confirmed medical exclusion blocks the mapped ingredient",
    ingredients: ["fx_durian", "fx_santan"],
    expect: { nenek: ["not_safe", "excluded_ingredient"] },
  },
  {
    id: "REG-046",
    requirements: ["PRF-03", "PRF-08"],
    title: "confirmed medical exclusion allows other ingredients",
    ingredients: [...base, "fx_santan"],
    expect: { nenek: ["safe"] },
  },

  // --- Fail closed on missing or unverified data -----------------------------
  {
    id: "REG-050",
    requirements: ["SAF-03", "SAF-09"],
    title: "unverified component data: never safe for any hard rule",
    ingredients: [...base, "fx_bumbu_instan"],
    expect: {
      kakak: ["check_label", "components_unverified"],
      ayah: ["check_label", "components_unverified"],
      tante: ["check_label", "components_unverified"],
      nenek: ["check_label", "components_unverified"],
      ibu: ["safe"],
    },
  },
  {
    id: "REG-051",
    requirements: ["SAF-04"],
    title: "empty ingredient list is never safe for a member with a hard rule",
    ingredients: [],
    expect: { ayah: ["check_label", "no_ingredients"] },
  },

  // --- PRF-03 diets ----------------------------------------------------------
  {
    id: "REG-060",
    requirements: ["PRF-03"],
    title: "egg and milk: vegetarian is safe, vegan is not",
    ingredients: [...base, "fx_telur", "fx_susu"],
    expect: { tante: ["safe"], keponakan: ["not_safe", "diet_not_suitable"] },
  },
  {
    id: "REG-061",
    requirements: ["PRF-03"],
    title: "chicken with a vegetarian rule",
    ingredients: [...base, "fx_ayam"],
    expect: { tante: ["not_safe", "diet_not_suitable"] },
  },
  {
    id: "REG-062",
    requirements: ["PRF-03", "SAF-03"],
    title: "fish sauce in an otherwise vegetable dish with a vegan rule",
    ingredients: [...base, "fx_kecap_ikan"],
    expect: { keponakan: ["not_safe", "diet_not_suitable"] },
  },

  // --- PRF-11 only selected members ------------------------------------------
  {
    id: "REG-070",
    requirements: ["PRF-11", "PRF-09"],
    title: "Only me: other members' rules do not apply",
    ingredients: [...base, "fx_terasi", "fx_babi"],
    expect: { ibu: ["safe"] },
  },
  {
    id: "REG-071",
    requirements: ["PRF-11", "SAF-05"],
    title: "Whole family: badges per person for the same recipe",
    ingredients: [...base, "fx_terasi"],
    expect: {
      ibu: ["safe"],
      ayah: ["safe"],
      tante: ["not_safe", "diet_not_suitable"],
      kakak: ["not_safe", "allergen_contains"],
      adik: ["not_safe", "allergen_contains"],
      paman: ["safe"],
    },
  },
];
