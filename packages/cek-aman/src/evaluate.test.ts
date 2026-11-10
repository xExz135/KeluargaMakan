// TEST FIXTURE: not real safety or nutrition data
import { describe, expect, it } from "vitest";

import { CekAmanInputError, RULE_SET_VERSION, evaluate } from "./index.js";
import { ing, input, member, rules } from "./test-fixtures.js";
import type { CekAmanInput, MemberSafetyResult, ReasonCode } from "./types.js";

const one = (value: CekAmanInput): MemberSafetyResult => evaluate(value).perMember[0]!;
const codes = (result: MemberSafetyResult): ReasonCode[] => result.reasons.map((r) => r.code);
const run = (raw: unknown): unknown => evaluate(raw as CekAmanInput);

const shrimp = ing("shrimp", {
  allergens: { verification: "verified", contains: ["shrimp"], mayContain: [] },
});
const plain = ing("plain");

describe("SAF-04 status and precedence", () => {
  it("SAF-04 returns safe with no reasons when nothing applies", () => {
    const result = evaluate(
      input({ reference: [plain], recipe: ["plain"], members: [member("m", rules.halal())] }),
    );
    expect(result).toEqual({
      perMember: [{ memberId: "m", status: "safe", reasons: [] }],
      ruleSetVersion: RULE_SET_VERSION,
      referenceVersion: "unit-fixture-1",
    });
  });

  it("SAF-04 any Not safe reason wins over uncertainty, and Not safe reasons sort first", () => {
    const result = one(
      input({
        reference: [plain, shrimp],
        recipe: [null, "shrimp"],
        members: [member("m", rules.allergy("shrimp"))],
      }),
    );
    expect(result.status).toBe("not_safe");
    expect(codes(result)).toEqual(["allergen_contains", "ingredient_unresolved"]);
  });

  it("SAF-04 uncertainty without a Not safe reason gives check_label", () => {
    const result = one(
      input({ reference: [plain], recipe: [null], members: [member("m", rules.halal())] }),
    );
    expect(result.status).toBe("check_label");
  });

  it("PRF-11 a member with no hard rules is safe even for unknown ingredients", () => {
    const result = one(input({ reference: [], recipe: [null, "missing"], members: [member("m")] }));
    expect(result).toEqual({ memberId: "m", status: "safe", reasons: [] });
  });

  it("SAF-04 an empty recipe is check_label for a member with a hard rule", () => {
    const result = one(input({ reference: [], recipe: [], members: [member("m", rules.vegan())] }));
    expect(result.status).toBe("check_label");
    expect(result.reasons[0]).toMatchObject({ kind: "unknown", code: "no_ingredients" });
  });
});

describe("SAF-01 structurally unusable input throws (fail closed, no result)", () => {
  const good = input({ reference: [plain], recipe: ["plain"], members: [member("m")] });
  const cases: [string, unknown][] = [
    ["input missing", null],
    ["reference missing", { ...good, reference: null }],
    ["reference version missing (DAT-06)", { ...good, reference: { ingredients: [] } }],
    ["reference version empty", { ...good, reference: { version: "", ingredients: [] } }],
    ["reference ingredients not a list", { ...good, reference: { version: "v", ingredients: {} } }],
    ["reference record not an object", { ...good, reference: { version: "v", ingredients: [1] } }],
    ["reference record without id", { ...good, reference: { version: "v", ingredients: [{}] } }],
    [
      "duplicate reference id",
      { ...good, reference: { version: "v", ingredients: [plain, plain] } },
    ],
    ["members not a list", { ...good, members: {} }],
    ["no members selected", { ...good, members: [] }],
    ["member not an object", { ...good, members: ["m"] }],
    ["memberId empty", { ...good, members: [{ memberId: "", hardRules: [] }] }],
    ["duplicate memberId", { ...good, members: [member("m"), member("m")] }],
    ["hardRules not a list", { ...good, members: [{ memberId: "m" }] }],
    ["recordedBrands not a list", { ...good, recordedBrands: undefined }],
    ["ingredients not a list", { ...good, ingredients: "plain" }],
  ];
  it.each(cases)("SAF-01 throws CekAmanInputError: %s", (_name, raw) => {
    expect(() => run(raw)).toThrow(CekAmanInputError);
  });

  it("SAF-01 the error has its own name", () => {
    expect(new CekAmanInputError("x").name).toBe("CekAmanInputError");
  });
});

describe("SAF-09 KIT-05 REC-06 unresolved ingredients", () => {
  it("SAF-09 null, empty and malformed ingredient entries are unresolved", () => {
    const raw = {
      ...input({ reference: [plain], recipe: [], members: [member("m", rules.halal())] }),
      ingredients: [
        { ingredientId: null, rawName: "bumbu sendiri" },
        { ingredientId: "", rawName: "kosong" },
        "not an object",
        { ingredientId: 42, rawName: 7 },
      ],
    };
    const result = (run(raw) as ReturnType<typeof evaluate>).perMember[0]!;
    expect(result.status).toBe("check_label");
    expect(result.reasons.map((r) => [r.code, r.ingredient])).toEqual([
      ["ingredient_unresolved", { index: 0, ingredientId: null, rawName: "bumbu sendiri" }],
      ["ingredient_unresolved", { index: 1, ingredientId: null, rawName: "kosong" }],
      ["ingredient_unresolved", { index: 2, ingredientId: null, rawName: "" }],
      ["ingredient_unresolved", { index: 3, ingredientId: null, rawName: "" }],
    ]);
  });

  it("SAF-09 an ID missing from the reference data is check_label", () => {
    const result = one(
      input({ reference: [], recipe: ["ghost"], members: [member("m", rules.halal())] }),
    );
    expect(codes(result)).toEqual(["ingredient_not_in_reference"]);
  });
});

describe("SAF-03 components", () => {
  it("SAF-03 a component that breaks a rule is Not safe with kind component and its path", () => {
    const paste = ing("paste", {
      components: { verification: "verified", ingredientIds: ["shrimp"] },
    });
    const result = one(
      input({
        reference: [paste, shrimp],
        recipe: ["paste"],
        members: [member("m", rules.allergy("shrimp"))],
      }),
    );
    expect(result.status).toBe("not_safe");
    expect(result.reasons).toEqual([
      expect.objectContaining({ kind: "component", componentPath: ["shrimp"], detail: "shrimp" }),
    ]);
  });

  it("SAF-03 unverified or malformed component data is check_label for every rule", () => {
    const unverified = ing("a", { components: { verification: "unverified", ingredientIds: [] } });
    const malformed = ing("b", { components: { verification: "verified", ingredientIds: "x" } });
    const missing = ing("c", { components: undefined });
    const result = one(
      input({
        reference: [unverified, malformed, missing],
        recipe: ["a", "b", "c"],
        members: [member("m", rules.vegan())],
      }),
    );
    expect(result.status).toBe("check_label");
    expect(codes(result)).toEqual([
      "components_unverified",
      "components_unverified",
      "components_unverified",
    ]);
  });

  it("SAF-03 a component missing from the reference data is check_label", () => {
    const a = ing("a", { components: { verification: "verified", ingredientIds: ["gone"] } });
    const result = one(
      input({ reference: [a], recipe: ["a"], members: [member("m", rules.halal())] }),
    );
    expect(result.reasons).toEqual([
      expect.objectContaining({ code: "component_not_in_reference", componentPath: ["gone"] }),
    ]);
  });

  it("SAF-03 component cycles are reported, not followed forever", () => {
    const a = ing("a", { components: { verification: "verified", ingredientIds: ["b"] } });
    const b = ing("b", { components: { verification: "verified", ingredientIds: ["a", "b"] } });
    const result = one(
      input({ reference: [a, b], recipe: ["a"], members: [member("m", rules.halal())] }),
    );
    expect(result.status).toBe("check_label");
    expect(result.reasons.map((r) => [r.code, r.componentPath])).toEqual([
      ["component_cycle", ["b", "a"]],
      ["component_cycle", ["b", "b"]],
    ]);
  });

  it("SAF-03 a component shared by two branches is evaluated once", () => {
    const a = ing("a", { components: { verification: "verified", ingredientIds: ["b", "c"] } });
    const b = ing("b", { components: { verification: "verified", ingredientIds: ["shrimp"] } });
    const c = ing("c", { components: { verification: "verified", ingredientIds: ["shrimp"] } });
    const result = one(
      input({
        reference: [a, b, c, shrimp],
        recipe: ["a"],
        members: [member("m", rules.allergy("shrimp"))],
      }),
    );
    expect(result.reasons.map((r) => r.componentPath)).toEqual([["b", "shrimp"]]);
  });

  it("SAF-07 a component whose data vary by brand is check_label", () => {
    const sauce = ing("sauce", { brandVaries: true });
    const dish = ing("dish", {
      components: { verification: "verified", ingredientIds: ["sauce"] },
    });
    const result = one(
      input({
        reference: [sauce, dish],
        recipe: ["dish"],
        members: [member("m", rules.halal())],
        brands: [{ ingredientId: "sauce", brandId: "any" }],
      }),
    );
    expect(result.reasons).toEqual([
      expect.objectContaining({
        kind: "brand_uncertain",
        code: "component_brand_varies",
        detail: "sauce",
      }),
    ]);
  });
});

describe("SAF-07 brand variants", () => {
  const variant = (brandId: string, verified: unknown, contains: string[]): unknown => ({
    brandId,
    brandName: brandId,
    verified,
    components: { verification: "verified", ingredientIds: [] },
    allergens: { verification: "verified", contains, mayContain: [] },
    halal: { verification: "verified", value: "halal", nonHalalSources: [] },
    diet: { verification: "verified", vegetarian: "suitable", vegan: "suitable" },
  });
  const kecap = ing("kecap", {
    allergens: { verification: "verified", contains: ["soy"], mayContain: ["wheat"] },
    brandVaries: true,
    brandVariants: [
      variant("good", true, ["soy"]),
      variant("pending", false, ["soy"]),
      variant("stringly", "true", ["soy"]),
      "not an object",
    ],
  });
  const wheatMember = [member("m", rules.allergy("wheat"))];

  it("SAF-07 no recorded brand is check_label even when generic data look fine", () => {
    const sauce = ing("sauce", { brandVaries: true });
    const result = one(input({ reference: [sauce], recipe: ["sauce"], members: wheatMember }));
    expect(result.status).toBe("check_label");
    expect(result.reasons[0]).toMatchObject({
      kind: "brand_uncertain",
      code: "brand_not_recorded",
    });
  });

  it("SAF-07 a recorded verified brand replaces the generic data", () => {
    const result = one(
      input({
        reference: [kecap],
        recipe: ["kecap"],
        members: wheatMember,
        brands: [{ ingredientId: "kecap", brandId: "good" }],
      }),
    );
    expect(result).toMatchObject({ status: "safe", reasons: [] });
  });

  it("SAF-07 reasons from a verified brand carry its brand ID", () => {
    const result = one(
      input({
        reference: [kecap],
        recipe: ["kecap"],
        members: [member("m", rules.allergy("soy"))],
        brands: [{ ingredientId: "kecap", brandId: "good" }],
      }),
    );
    expect(result.reasons).toEqual([
      expect.objectContaining({ brandId: "good", kind: "contains" }),
    ]);
  });

  it.each(["pending", "stringly", "unknown-brand"])(
    "SAF-07 recorded brand %s without verified data is check_label",
    (brandId) => {
      const result = one(
        input({
          reference: [kecap],
          recipe: ["kecap"],
          members: wheatMember,
          brands: [{ ingredientId: "kecap", brandId }],
        }),
      );
      expect(result.status).toBe("check_label");
      expect(codes(result)).toEqual(["brand_unverified", "allergen_may_contain"]);
      expect(result.reasons[0]!.detail).toBe(brandId);
    },
  );

  it("SAF-07 a missing or malformed brandVaries flag counts as varying", () => {
    const a = ing("a", { brandVaries: undefined });
    const b = ing("b", { brandVaries: "no", brandVariants: "none" });
    const result = one(
      input({
        reference: [a, b],
        recipe: ["a", "b"],
        members: wheatMember,
        brands: [{ ingredientId: "b", brandId: "x" }],
      }),
    );
    expect(codes(result)).toEqual(["brand_not_recorded", "brand_unverified"]);
  });

  it("SAF-07 malformed recorded brands are ignored and duplicates collapse", () => {
    const raw = {
      ...input({ reference: [kecap], recipe: ["kecap"], members: wheatMember }),
      recordedBrands: [
        "kecap",
        { ingredientId: "kecap" },
        { ingredientId: "", brandId: "good" },
        { ingredientId: "kecap", brandId: "pending" },
        { ingredientId: "kecap", brandId: "pending" },
      ],
    };
    const result = (run(raw) as ReturnType<typeof evaluate>).perMember[0]!;
    expect(codes(result)).toEqual(["brand_unverified", "allergen_may_contain"]);
  });
});

describe("PRF-04 allergens", () => {
  const tagged = (id: string, contains: unknown[], mayContain: unknown[] = []): unknown =>
    ing(id, { allergens: { verification: "verified", contains, mayContain } });

  it("PRF-04 shrimp breaks both shrimp and shellfish rules; wheat breaks wheat and gluten", () => {
    const reference = [tagged("udang", ["shrimp"]), tagged("terigu", ["wheat"])] as never[];
    const result = evaluate(
      input({
        reference,
        recipe: ["udang", "terigu"],
        members: [
          member("a", rules.allergy("shrimp")),
          member("b", rules.allergy("shellfish")),
          member("c", rules.allergy("wheat")),
          member("d", rules.allergy("gluten")),
          member("e", rules.allergy("peanut")),
        ],
      }),
    );
    expect(result.perMember.map((m) => m.status)).toEqual([
      "not_safe",
      "not_safe",
      "not_safe",
      "not_safe",
      "safe",
    ]);
  });

  it("PRF-04 a generic shellfish or gluten tag is check_label for shrimp or wheat rules", () => {
    const reference = [tagged("kerang", ["shellfish"]), tagged("barli", ["gluten"])] as never[];
    const result = evaluate(
      input({
        reference,
        recipe: ["kerang", "barli"],
        members: [member("a", rules.allergy("shrimp")), member("b", rules.allergy("wheat"))],
      }),
    );
    expect(result.perMember.map((m) => [m.status, codes(m)])).toEqual([
      ["check_label", ["allergen_related"]],
      ["check_label", ["allergen_related"]],
    ]);
  });

  it("PRF-04 may-contain matches give check_label, unrelated ones nothing", () => {
    const reference = [tagged("kecap", ["soy"], ["wheat", "sesame"])] as never[];
    const result = evaluate(
      input({
        reference,
        recipe: ["kecap"],
        members: [member("a", rules.allergy("gluten")), member("b", rules.allergy("egg"))],
      }),
    );
    expect(result.perMember.map((m) => [m.status, codes(m)])).toEqual([
      ["check_label", ["allergen_may_contain"]],
      ["safe", []],
    ]);
  });

  it("PRF-04 unrecognized allergen tags are check_label for every allergy rule", () => {
    const reference = [tagged("x", ["crustacean"], ["mollusc"])] as never[];
    const result = one(
      input({ reference, recipe: ["x"], members: [member("a", rules.allergy("egg"))] }),
    );
    expect(codes(result)).toEqual(["allergen_unrecognized", "allergen_unrecognized"]);
  });

  it("PRF-04 unverified or malformed allergen data is check_label for allergy rules only", () => {
    const reference = [
      ing("a", { allergens: { verification: "unverified", contains: [], mayContain: [] } }),
      ing("b", { allergens: { verification: "verified", contains: "egg", mayContain: [] } }),
      ing("c", { allergens: { verification: "verified", contains: [], mayContain: [1] } }),
      ing("d", { allergens: null }),
    ];
    const result = evaluate(
      input({
        reference,
        recipe: ["a", "b", "c", "d"],
        members: [member("a", rules.allergy("egg")), member("b", rules.halal())],
      }),
    );
    expect(codes(result.perMember[0]!)).toEqual([
      "allergens_unverified",
      "allergens_unverified",
      "allergens_unverified",
      "allergens_unverified",
    ]);
    expect(result.perMember[1]!.status).toBe("safe");
  });
});

describe("SAF-08 halal", () => {
  const halal = (id: string, data: unknown): never => ing(id, { halal: data }) as never;

  it("SAF-08 each non-halal source is reported; a missing source list still fails", () => {
    const reference = [
      halal("babi", { verification: "verified", value: "not_halal", nonHalalSources: ["pork"] }),
      halal("x", { verification: "unverified", value: "not_halal", nonHalalSources: [] }),
    ];
    const result = one(
      input({ reference, recipe: ["babi", "x"], members: [member("m", rules.halal())] }),
    );
    expect(result.status).toBe("not_safe");
    expect(result.reasons.map((r) => [r.code, r.detail])).toEqual([
      ["halal_not_halal", "pork"],
      ["halal_not_halal", null],
    ]);
  });

  it("SAF-08 uncertain, unknown, unverified or malformed halal status is check_label", () => {
    const reference = [
      halal("a", { verification: "verified", value: "uncertain", nonHalalSources: [] }),
      halal("b", { verification: "verified", value: "unknown", nonHalalSources: [] }),
      halal("c", { verification: "unverified", value: "halal", nonHalalSources: [] }),
      halal("d", { verification: "verified", value: "maybe" }),
      halal("e", undefined),
    ];
    const result = one(
      input({
        reference,
        recipe: ["a", "b", "c", "d", "e"],
        members: [member("m", rules.halal())],
      }),
    );
    expect(result.status).toBe("check_label");
    expect(result.reasons.map((r) => [r.code, r.detail])).toEqual([
      ["halal_uncertain", "uncertain"],
      ["halal_uncertain", "unknown"],
      ["halal_uncertain", "halal"],
      ["halal_uncertain", "unknown"],
      ["halal_uncertain", "unknown"],
    ]);
  });
});

describe("PRF-03 vegetarian and vegan", () => {
  const diet = (id: string, data: unknown): never => ing(id, { diet: data }) as never;

  it("PRF-03 anything not vegetarian is not vegan, whatever the vegan field says", () => {
    const reference = [
      diet("meat", { verification: "verified", vegetarian: "not_suitable", vegan: "suitable" }),
    ];
    const result = evaluate(
      input({
        reference,
        recipe: ["meat"],
        members: [member("v", rules.vegetarian()), member("vg", rules.vegan())],
      }),
    );
    expect(result.perMember.map((m) => [m.status, m.reasons[0]!.detail])).toEqual([
      ["not_safe", "vegetarian"],
      ["not_safe", "vegan"],
    ]);
  });

  it("PRF-03 uncertain, unverified or malformed diet data is check_label", () => {
    const reference = [
      diet("a", { verification: "verified", vegetarian: "uncertain", vegan: "unknown" }),
      diet("b", { verification: "unverified", vegetarian: "suitable", vegan: "suitable" }),
      diet("c", "plant"),
    ];
    const result = evaluate(
      input({
        reference,
        recipe: ["a", "b", "c"],
        members: [member("v", rules.vegetarian()), member("vg", rules.vegan())],
      }),
    );
    for (const m of result.perMember) {
      expect(m.status).toBe("check_label");
      expect(codes(m)).toEqual(["diet_uncertain", "diet_uncertain", "diet_uncertain"]);
    }
  });
});

describe("PRF-08 SAF-09 mapped and unmapped rules", () => {
  it("PRF-08 a confirmed mapping blocks the ingredient and its appearances as a component", () => {
    const durian = ing("durian");
    const cake = ing("cake", {
      components: { verification: "verified", ingredientIds: ["durian"] },
    });
    const result = one(
      input({
        reference: [durian, cake],
        recipe: ["durian", "cake"],
        members: [member("m", rules.exclusion("durian"))],
      }),
    );
    expect(result.reasons.map((r) => [r.kind, r.code, r.detail])).toEqual([
      ["contains", "excluded_ingredient", "durian"],
      ["component", "excluded_ingredient", "durian"],
    ]);
  });

  const ruleCases: [string, unknown, ReasonCode][] = [
    [
      "unmapped free text",
      { ruleId: "r", type: "free_text", freeText: "x", mapping: { status: "unmapped" } },
      "rule_unmapped",
    ],
    [
      "proposed mapping",
      {
        ruleId: "r",
        type: "free_text",
        freeText: "x",
        mapping: { status: "proposed", ingredientIds: ["plain"] },
      },
      "rule_mapping_unconfirmed",
    ],
    [
      "mapping to an unknown ingredient",
      {
        ruleId: "r",
        type: "medical_exclusion",
        freeText: null,
        mapping: { status: "mapped", ingredientIds: ["ghost"], confirmedBy: "manager" },
      },
      "rule_mapping_unknown_ingredient",
    ],
    [
      "mapped without confirmer",
      { ruleId: "r", type: "free_text", mapping: { status: "mapped", ingredientIds: ["plain"] } },
      "rule_invalid",
    ],
    [
      "mapped with no ingredients",
      {
        ruleId: "r",
        type: "free_text",
        mapping: { status: "mapped", ingredientIds: [], confirmedBy: "manager" },
      },
      "rule_invalid",
    ],
    [
      "mapped with ingredients not a list",
      {
        ruleId: "r",
        type: "free_text",
        mapping: { status: "mapped", ingredientIds: "plain", confirmedBy: "manager" },
      },
      "rule_invalid",
    ],
    [
      "mapped with a non-string ingredient",
      {
        ruleId: "r",
        type: "free_text",
        mapping: { status: "mapped", ingredientIds: ["plain", 3], confirmedBy: "manager" },
      },
      "rule_invalid",
    ],
    ["mapping missing", { ruleId: "r", type: "medical_exclusion" }, "rule_invalid"],
    [
      "unknown mapping status",
      { ruleId: "r", type: "free_text", mapping: { status: "done" } },
      "rule_invalid",
    ],
    ["unknown rule type", { ruleId: "r", type: "keto" }, "rule_invalid"],
    [
      "allergen not on the list",
      { ruleId: "r", type: "allergy", allergen: "kiwi" },
      "rule_invalid",
    ],
    ["missing ruleId", { type: "halal" }, "rule_invalid"],
    ["rule not an object", "halal", "rule_invalid"],
  ];

  it.each(ruleCases)("SAF-09 PRF-08 %s is check_label for any recipe", (_name, rule, code) => {
    const result = one(
      input({ reference: [plain], recipe: ["plain"], members: [member("m", rule)] }),
    );
    expect(result.status).toBe("check_label");
    expect(result.reasons).toEqual([
      expect.objectContaining({ kind: "unmapped_rule", code, ingredient: null }),
    ]);
  });

  it("SAF-09 the rule reference survives in the reason", () => {
    const rule = { ruleId: "r-kiwi", type: "allergy", allergen: "kiwi" };
    const result = one(
      input({ reference: [plain], recipe: ["plain"], members: [member("m", rule)] }),
    );
    expect(result.reasons[0]!.rule).toEqual({
      ruleId: "r-kiwi",
      type: "allergy",
      allergen: "kiwi",
    });
  });
});
