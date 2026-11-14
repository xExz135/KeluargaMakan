// TEST FIXTURE: not real safety or nutrition data. Fictional reference catalog
// (fx_kit_ IDs, every safety value unverified) and fictional members.
import { join } from "node:path";

import { evaluate, STANDARD_ALLERGENS, type HardRule } from "@keluargamakan/cek-aman";
import { afterAll, beforeAll, describe, expect, it } from "vitest";

import { kitchenIngredientInput, kitchenRecordedBrand } from "./cek-aman-input.js";
import { buildFixtureReference, REPO_ROOT, type BuiltFixture } from "./testing/catalog-fixture.js";

let fixture: BuiltFixture;
beforeAll(() => {
  fixture = buildFixtureReference(join(REPO_ROOT, "data", "fixtures", "kitchen-catalog"));
});
afterAll(() => fixture.cleanup());

const custom = { ingredientId: null, customName: "Bumbu racikan fiktif", brand: null };

const everyRule: HardRule[] = [
  ...STANDARD_ALLERGENS.map((allergen): HardRule => ({
    ruleId: `r-${allergen}`,
    type: "allergy",
    allergen,
  })),
  { ruleId: "r-halal", type: "halal" },
  { ruleId: "r-vegetarian", type: "vegetarian" },
  { ruleId: "r-vegan", type: "vegan" },
  {
    ruleId: "r-medical",
    type: "medical_exclusion",
    freeText: null,
    mapping: { status: "mapped", ingredientIds: ["fx_kit_garam"], confirmedBy: "manager" },
  },
];

describe("KIT-05 SAF-09 custom kitchen ingredients through Cek Aman", () => {
  it("SAF-09 a custom ingredient enters the engine unresolved (no reference ID)", () => {
    expect(kitchenIngredientInput(custom)).toEqual({
      ingredientId: null,
      rawName: "Bumbu racikan fiktif",
    });
    expect(kitchenRecordedBrand(custom)).toBeNull();
  });

  it.each(everyRule.map((rule) => [rule.ruleId, rule] as const))(
    "SAF-09 with a %s rule, any meal with a custom ingredient is Check the label, never Safe",
    (_id, rule) => {
      const result = evaluate({
        ingredients: [kitchenIngredientInput(custom)],
        recordedBrands: [],
        members: [{ memberId: "m1", hardRules: [rule] }],
        reference: fixture.verified.reference,
      });
      const member = result.perMember[0];
      expect(member?.status).toBe("check_label");
      expect(member?.reasons.map((reason) => reason.code)).toContain("ingredient_unresolved");
      expect(result.referenceVersion).toBe(fixture.verified.referenceVersion);
    },
  );

  it("SAF-09 a custom ingredient next to reference ones still makes the result Check the label", () => {
    const result = evaluate({
      ingredients: [
        kitchenIngredientInput({ ingredientId: "fx_kit_beras", customName: null, brand: null }),
        kitchenIngredientInput(custom),
      ],
      recordedBrands: [],
      members: [
        { memberId: "halal", hardRules: [{ ruleId: "r1", type: "halal" }] },
        { memberId: "no-rules", hardRules: [] },
      ],
      reference: fixture.verified.reference,
    });
    expect(result.perMember.map((m) => [m.memberId, m.status])).toEqual([
      ["halal", "check_label"],
      // SAF-09 applies to members with a related hard rule; a member without
      // rules has nothing to check (the consent state decides the badge, Q36).
      ["no-rules", "safe"],
    ]);
  });

  it("SAF-07 a typed brand is never a recorded brand; only a reference brand on a reference item is", () => {
    expect(
      kitchenRecordedBrand({
        ingredientId: "fx_kit_kecap_manis",
        customName: null,
        brand: { brandId: null },
      }),
    ).toBeNull();
    expect(
      kitchenRecordedBrand({
        ingredientId: "fx_kit_kecap_manis",
        customName: null,
        brand: { brandId: "fx_kit_merek_a" },
      }),
    ).toEqual({ ingredientId: "fx_kit_kecap_manis", brandId: "fx_kit_merek_a" });
  });
});
