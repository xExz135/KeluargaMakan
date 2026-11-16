// TEST FIXTURE: not real safety or nutrition data
//
// LIB-05 recipe halal regression cases (NFR-07), against the fictional
// fixture reference data. Each case names the requirement IDs it verifies.
// Never edit an expectation to make a failing case pass without a
// safety-owner decision.

import type {
  ReasonCode,
  RecipeHalalStatus,
  RecipeLineInput,
} from "../../packages/cek-aman/src/index.js";

/** `[status, ...reason codes that must be present]` */
export type HalalExpectation = readonly [RecipeHalalStatus, ...ReasonCode[]];

/**
 * A reference ID, `null` for an unresolved or custom line, or
 * `[id, ...brandIds]` with every brand the household recorded for it.
 */
export type CaseLine = string | null | readonly [ingredientId: string, ...brandIds: string[]];

export interface RecipeHalalCase {
  readonly id: string;
  readonly requirements: readonly string[];
  readonly title: string;
  readonly lines: readonly CaseLine[];
  /**
   * Evaluate against the fixture plus contradictory records the schema
   * rejects (`malformedReference` in cases.ts), to prove fail closed.
   */
  readonly malformed?: true;
  readonly expect: HalalExpectation;
}

export function toLines(lines: readonly CaseLine[]): RecipeLineInput[] {
  return lines.map((entry, index) => {
    const lineId = `fx-line-${index + 1}`;
    if (entry === null || typeof entry === "string") return { lineId, ingredientId: entry };
    const [ingredientId, ...brandIds] = entry;
    return { lineId, ingredientId, brandIds };
  });
}

const base = ["fx_nasi", "fx_bawang_putih", "fx_cabai", "fx_garam"] as const;

export const recipeHalalCases: readonly RecipeHalalCase[] = [
  {
    id: "HAL-001",
    requirements: ["LIB-05", "SAF-08"],
    title: "every line verified halal gives halal",
    lines: [...base, "fx_santan", "fx_ayam"],
    expect: ["halal"],
  },
  {
    id: "HAL-002",
    requirements: ["LIB-05", "SAF-08"],
    title: "pork gives not_halal",
    lines: [...base, "fx_babi"],
    expect: ["not_halal", "halal_not_halal"],
  },
  {
    id: "HAL-003",
    requirements: ["LIB-05", "SAF-06", "SAF-08"],
    title: "angciu gives not_halal",
    lines: [...base, "fx_udang", "fx_angciu"],
    expect: ["not_halal", "halal_not_halal"],
  },
  {
    id: "HAL-004",
    requirements: ["LIB-05", "SAF-03", "SAF-06", "SAF-08"],
    title: "mirin (own status uncertain) gives not_halal through its alcohol component",
    lines: [...base, "fx_mirin"],
    expect: ["not_halal", "halal_not_halal"],
  },
  {
    id: "HAL-005",
    requirements: ["LIB-05", "SAF-08"],
    title: "a non-halal animal source gives not_halal",
    lines: [...base, "fx_daging_kodok"],
    expect: ["not_halal", "halal_not_halal"],
  },
  {
    id: "HAL-006",
    requirements: ["LIB-05", "SAF-06", "SAF-07", "SAF-08"],
    title: "gelatin without a brand gives check_label",
    lines: [...base, "fx_gelatin"],
    expect: ["check_label", "halal_uncertain", "brand_not_recorded"],
  },
  {
    id: "HAL-007",
    requirements: ["LIB-05", "SAF-06", "SAF-08"],
    title: "bouillon with unverified data gives check_label",
    lines: [...base, "fx_kaldu_bubuk"],
    expect: ["check_label", "components_unverified", "halal_uncertain"],
  },
  {
    id: "HAL-008",
    requirements: ["LIB-05", "SAF-09", "KIT-05"],
    title: "unresolved line gives check_label",
    lines: [...base, null],
    expect: ["check_label", "ingredient_unresolved"],
  },
  {
    id: "HAL-009",
    requirements: ["LIB-05", "SAF-09"],
    title: "a line not in the reference data gives check_label",
    lines: [...base, "fx_unknown_id"],
    expect: ["check_label", "ingredient_not_in_reference"],
  },
  {
    id: "HAL-010",
    requirements: ["LIB-05", "SAF-09"],
    title: "missing component data gives check_label",
    lines: [...base, "fx_bumbu_instan"],
    expect: ["check_label", "components_unverified"],
  },
  {
    id: "HAL-011",
    requirements: ["LIB-05", "SAF-07"],
    title: "kecap manis without a brand gives check_label",
    lines: [...base, "fx_kecap_manis"],
    expect: ["check_label", "brand_not_recorded"],
  },
  {
    id: "HAL-012",
    requirements: ["LIB-05", "SAF-07"],
    title: "kecap manis with a verified brand gives halal",
    lines: [...base, ["fx_kecap_manis", "fx_brand_kecap_a"]],
    expect: ["halal"],
  },
  {
    id: "HAL-013",
    requirements: ["LIB-05", "SAF-07"],
    title: "kecap manis with an unverified brand gives check_label",
    lines: [...base, ["fx_kecap_manis", "fx_brand_kecap_b"]],
    expect: ["check_label", "brand_unverified"],
  },
  {
    id: "HAL-014",
    requirements: ["LIB-05", "SAF-07"],
    title: "kecap asin (brand varies, no variants) with a brand gives check_label",
    lines: [...base, ["fx_kecap_asin", "fx_brand_kecap_a"]],
    expect: ["check_label", "brand_unverified"],
  },
  {
    id: "HAL-015",
    requirements: ["LIB-05", "SAF-06", "SAF-07", "SAF-08"],
    title: "oyster sauce without a brand gives check_label",
    lines: [...base, "fx_saus_tiram"],
    expect: ["check_label", "brand_not_recorded", "halal_uncertain"],
  },
  {
    id: "HAL-016",
    requirements: ["LIB-05", "SAF-06", "SAF-07", "SAF-08"],
    title: "oyster sauce with its verified halal brand gives halal",
    lines: [...base, ["fx_saus_tiram", "fx_brand_tiram_a"]],
    expect: ["halal"],
  },
  {
    id: "HAL-017",
    requirements: ["LIB-05", "SAF-07"],
    title: "a verified brand on one kecap line does not cover another kecap line with no brand",
    lines: [...base, ["fx_kecap_manis", "fx_brand_kecap_a"], "fx_kecap_manis"],
    expect: ["check_label", "brand_not_recorded"],
  },
  {
    id: "HAL-018",
    requirements: ["LIB-05", "SAF-04", "SAF-08", "SAF-09"],
    title: "not_halal outranks an unresolved line",
    lines: [null, ...base, "fx_angciu"],
    expect: ["not_halal", "halal_not_halal", "ingredient_unresolved"],
  },
  {
    id: "HAL-019",
    requirements: ["LIB-05", "SAF-09"],
    title: "a recipe with no lines gives check_label",
    lines: [],
    expect: ["check_label", "no_ingredients"],
  },
  {
    id: "HAL-020",
    requirements: ["LIB-05", "SAF-03", "SAF-06", "SAF-08"],
    title: "sambal terasi with verified halal components gives halal",
    lines: [...base, "fx_sambal_terasi"],
    expect: ["halal"],
  },
  {
    id: "HAL-021",
    requirements: ["LIB-05", "SAF-07"],
    title: "a brand on an ingredient that does not vary by brand is ignored",
    lines: [...base, ["fx_terasi", "fx_brand_kecap_a"]],
    expect: ["halal"],
  },
  {
    id: "HAL-022",
    requirements: ["LIB-05", "SAF-08"],
    title: "data marked halal that lists alcohol gives not_halal (contradictory record)",
    lines: [...base, "fx_bad_halal_with_alcohol"],
    malformed: true,
    expect: ["not_halal", "halal_not_halal"],
  },
  {
    id: "HAL-023",
    requirements: ["LIB-05", "SAF-08"],
    title: "data marked halal that lists a non-halal animal gives not_halal (contradictory record)",
    lines: [...base, "fx_bad_halal_with_animal"],
    malformed: true,
    expect: ["not_halal", "halal_not_halal"],
  },
  {
    id: "HAL-024",
    requirements: ["LIB-05", "SAF-07"],
    title: "two recorded kecap brands, one verified and one not, give check_label",
    lines: [...base, ["fx_kecap_manis", "fx_brand_kecap_a", "fx_brand_kecap_b"]],
    expect: ["check_label", "brand_unverified"],
  },
  {
    id: "HAL-025",
    requirements: ["LIB-05", "SAF-07", "SAF-08"],
    title: "two recorded kecap brands, one halal and one with alcohol, give not_halal",
    lines: [...base, ["fx_kecap_manis", "fx_brand_kecap_a", "fx_brand_kecap_c"]],
    expect: ["not_halal", "halal_not_halal"],
  },
];
