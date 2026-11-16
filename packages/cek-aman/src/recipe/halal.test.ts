// TEST FIXTURE: not real safety or nutrition data
import { describe, expect, it } from "vitest";

import { CekAmanInputError } from "../errors.js";
import { evaluate } from "../evaluate.js";
import { RULE_SET_VERSION } from "../rule-set.js";
import { ing, member, rules } from "../test-fixtures.js";
import type { ReferenceDataset, ReferenceIngredient } from "../types.js";
import {
  RECIPE_HALAL_STATUSES,
  deriveRecipeHalal,
  type RecipeHalalInput,
  type RecipeHalalResult,
  type RecipeLineInput,
} from "./halal.js";

const verifiedHalalNo = (...sources: string[]): Record<string, unknown> => ({
  halal: { verification: "verified", value: "not_halal", nonHalalSources: sources },
});

const variant = (brandId: string, verified: boolean, overrides: Record<string, unknown> = {}) => ({
  brandId,
  brandName: `Fiksi ${brandId}`,
  verified,
  components: { verification: "verified", ingredientIds: [] },
  allergens: { verification: "verified", contains: [], mayContain: [] },
  halal: { verification: "verified", value: "halal", nonHalalSources: [] },
  diet: { verification: "verified", vegetarian: "suitable", vegan: "suitable" },
  ...overrides,
});

// Fictional ingredients; every value is invented for these tests.
const reference: ReferenceDataset = {
  schema: "keluargamakan.reference.ingredients/1",
  version: "unit-fixture-recipe-1",
  ingredients: [
    ing("fx-plain"),
    ing("fx-plain-2"),
    ing("fx-pork", verifiedHalalNo("pork")),
    ing("fx-alcohol", verifiedHalalNo("alcohol")),
    ing("fx-animal", verifiedHalalNo("non_halal_animal")),
    ing("fx-uncertain", {
      halal: { verification: "verified", value: "uncertain", nonHalalSources: [] },
    }),
    ing("fx-halal-unverified", {
      halal: { verification: "unverified", value: "halal", nonHalalSources: [] },
    }),
    ing("fx-wine-sauce", {
      components: { verification: "verified", ingredientIds: ["fx-alcohol"] },
    }),
    ing("fx-components-unverified", {
      components: { verification: "unverified", ingredientIds: [] },
    }),
    ing("fx-missing-component", {
      components: { verification: "verified", ingredientIds: ["fx-nowhere"] },
    }),
    ing("fx-cycle-a", { components: { verification: "verified", ingredientIds: ["fx-cycle-b"] } }),
    ing("fx-cycle-b", { components: { verification: "verified", ingredientIds: ["fx-cycle-a"] } }),
    ing("fx-brand-varies-component", { brandVaries: true }),
    ing("fx-with-varying-component", {
      components: { verification: "verified", ingredientIds: ["fx-brand-varies-component"] },
    }),
    ing("fx-sauce", {
      brandVaries: true,
      halal: { verification: "verified", value: "uncertain", nonHalalSources: [] },
      brandVariants: [
        variant("fx-brand-ok", true),
        variant("fx-brand-wine", true, verifiedHalalNo("alcohol")),
        variant("fx-brand-unverified", false),
      ],
    }),
  ] as ReferenceIngredient[],
};

let lineCount = 0;
const line = (ingredientId: string | null, ...brandIds: string[]): RecipeLineInput => {
  lineCount += 1;
  return brandIds.length === 0
    ? { lineId: `line-${lineCount}`, ingredientId }
    : { lineId: `line-${lineCount}`, ingredientId, brandIds };
};

const derive = (...lines: RecipeLineInput[]): RecipeHalalResult =>
  deriveRecipeHalal({ lines, reference });

const codes = (result: RecipeHalalResult): string[] => result.findings.map((f) => f.code);

describe("LIB-05 recipe halal status derived from reference ingredient data", () => {
  it("LIB-05 the status values are those of contract 0.3 HalalStatus", () => {
    expect(RECIPE_HALAL_STATUSES).toEqual(["halal", "not_halal", "check_label"]);
  });

  it("LIB-05 SAF-14 every line verified halal gives halal with no findings, and carries both versions", () => {
    expect(derive(line("fx-plain"), line("fx-plain-2"))).toEqual({
      status: "halal",
      findings: [],
      ruleSetVersion: RULE_SET_VERSION,
      referenceVersion: "unit-fixture-recipe-1",
    });
  });

  it("LIB-05 a recipe with no lines gives check_label (no_ingredients), never halal", () => {
    const result = derive();
    expect(result.status).toBe("check_label");
    expect(result.findings).toEqual([
      {
        kind: "unknown",
        code: "no_ingredients",
        line: null,
        componentPath: [],
        brandId: null,
        detail: null,
      },
    ]);
    expect(result.referenceVersion).toBe("unit-fixture-recipe-1");
  });

  it("LIB-05 SAF-09 an unresolved or custom line gives check_label with its line reference", () => {
    const result = deriveRecipeHalal({
      lines: [
        { lineId: "l-rice", ingredientId: "fx-plain" },
        { lineId: "l-custom", ingredientId: null },
      ],
      reference,
    });
    expect(result.status).toBe("check_label");
    expect(result.findings).toEqual([
      {
        kind: "unknown",
        code: "ingredient_unresolved",
        line: { index: 1, lineId: "l-custom", ingredientId: null },
        componentPath: [],
        brandId: null,
        detail: null,
      },
    ]);
  });

  it("LIB-05 SAF-09 an empty or non-string ingredient ID counts as unresolved", () => {
    const lines = [
      { lineId: "a", ingredientId: "" },
      { lineId: "b", ingredientId: 42 },
      { lineId: "c" },
    ] as unknown as RecipeLineInput[];
    const result = deriveRecipeHalal({ lines, reference });
    expect(result.status).toBe("check_label");
    expect(result.findings.map((f) => [f.code, f.line])).toEqual([
      ["ingredient_unresolved", { index: 0, lineId: "a", ingredientId: null }],
      ["ingredient_unresolved", { index: 1, lineId: "b", ingredientId: null }],
      ["ingredient_unresolved", { index: 2, lineId: "c", ingredientId: null }],
    ]);
  });

  it("LIB-05 SAF-09 a line whose ID is not in the reference data gives check_label", () => {
    const result = derive(line("fx-plain"), line("fx-unknown"));
    expect(result.status).toBe("check_label");
    expect(codes(result)).toEqual(["ingredient_not_in_reference"]);
  });

  it.each([
    ["pork", "fx-pork"],
    ["alcohol", "fx-alcohol"],
    ["non_halal_animal", "fx-animal"],
  ])("LIB-05 SAF-08 a %s ingredient gives not_halal", (source, id) => {
    const result = derive(line("fx-plain"), line(id));
    expect(result.status).toBe("not_halal");
    expect(result.findings).toEqual([
      expect.objectContaining({ kind: "contains", code: "halal_not_halal", detail: source }),
    ]);
  });

  it("LIB-05 SAF-03 SAF-08 a non-halal component gives not_halal with the component path", () => {
    const result = derive(line("fx-wine-sauce"));
    expect(result.status).toBe("not_halal");
    expect(result.findings).toEqual([
      expect.objectContaining({
        kind: "component",
        code: "halal_not_halal",
        componentPath: ["fx-alcohol"],
        detail: "alcohol",
      }),
    ]);
  });

  it.each([
    ["uncertain halal value", "fx-uncertain", "halal_uncertain"],
    ["unverified halal data", "fx-halal-unverified", "halal_uncertain"],
    ["unverified component data", "fx-components-unverified", "components_unverified"],
    [
      "a component missing from the reference",
      "fx-missing-component",
      "component_not_in_reference",
    ],
    ["a component cycle", "fx-cycle-a", "component_cycle"],
    ["a component whose brand varies", "fx-with-varying-component", "component_brand_varies"],
  ])("LIB-05 SAF-08 fail closed: %s gives check_label", (_name, id, code) => {
    const result = derive(line(id));
    expect(result.status).toBe("check_label");
    expect(codes(result)).toContain(code);
  });

  it("LIB-05 SAF-07 a brand-varying ingredient without a brand gives check_label", () => {
    const result = derive(line("fx-sauce"));
    expect(result.status).toBe("check_label");
    expect(codes(result)).toEqual(["brand_not_recorded", "halal_uncertain"]);
    expect(derive({ lineId: "l", ingredientId: "fx-sauce", brandIds: [] }).status).toBe(
      "check_label",
    );
  });

  it("LIB-05 SAF-07 a verified brand variant replaces the generic data", () => {
    expect(derive(line("fx-sauce", "fx-brand-ok"))).toMatchObject({
      status: "halal",
      findings: [],
    });
    const wine = derive(line("fx-sauce", "fx-brand-wine"));
    expect(wine.status).toBe("not_halal");
    expect(wine.findings).toEqual([
      expect.objectContaining({
        code: "halal_not_halal",
        brandId: "fx-brand-wine",
        detail: "alcohol",
      }),
    ]);
  });

  it("LIB-05 SAF-07 an unverified or unknown brand gives check_label", () => {
    for (const brandId of ["fx-brand-unverified", "fx-brand-nowhere"]) {
      const result = derive(line("fx-sauce", brandId));
      expect(result.status, brandId).toBe("check_label");
      expect(result.findings[0]).toMatchObject({ code: "brand_unverified", detail: brandId });
    }
  });

  it("LIB-05 SAF-07 a brand counts for its own line only, never for another line of the same ingredient", () => {
    const result = deriveRecipeHalal({
      lines: [
        { lineId: "l-branded", ingredientId: "fx-sauce", brandIds: ["fx-brand-ok"] },
        { lineId: "l-unbranded", ingredientId: "fx-sauce" },
      ],
      reference,
    });
    expect(result.status).toBe("check_label");
    expect(result.findings.every((f) => f.line?.lineId === "l-unbranded")).toBe(true);
    expect(codes(result)).toContain("brand_not_recorded");
  });

  it("LIB-05 SAF-07 a brand on an ingredient that does not vary by brand, or on an unresolved line, is ignored", () => {
    expect(derive(line("fx-plain", "fx-brand-ok")).status).toBe("halal");
    const unresolved = derive(line(null, "fx-brand-ok"));
    expect(codes(unresolved)).toEqual(["ingredient_unresolved"]);
    expect(unresolved.findings[0]!.brandId).toBeNull();
  });

  it("LIB-05 SAF-04 not_halal outranks check_label; not-halal findings come first, then line order", () => {
    const result = deriveRecipeHalal({
      lines: [
        { lineId: "l1", ingredientId: null },
        { lineId: "l2", ingredientId: "fx-uncertain" },
        { lineId: "l3", ingredientId: "fx-pork" },
        { lineId: "l4", ingredientId: "fx-plain" },
        { lineId: "l5", ingredientId: "fx-wine-sauce" },
      ],
      reference,
    });
    expect(result.status).toBe("not_halal");
    expect(result.findings.map((f) => [f.line?.lineId, f.code])).toEqual([
      ["l3", "halal_not_halal"],
      ["l5", "halal_not_halal"],
      ["l1", "ingredient_unresolved"],
      ["l2", "halal_uncertain"],
    ]);
  });

  it("LIB-05 SAF-07 SAF-08 the derivation matches the engine's halal rule for every ingredient and set of recorded brands", () => {
    const ids = [...reference.ingredients.map((i) => i.id), "fx-unknown"];
    const brandSets = [
      [],
      ["fx-brand-ok"],
      ["fx-brand-wine"],
      ["fx-brand-unverified"],
      ["fx-brand-ok", "fx-brand-wine"],
      ["fx-brand-wine", "fx-brand-ok"],
      ["fx-brand-ok", "fx-brand-unverified"],
      ["fx-brand-ok", "fx-brand-ok"],
    ];
    for (const id of [...ids, null]) {
      for (const brandIds of brandSets) {
        const engine = evaluate({
          ingredients: [{ ingredientId: id, rawName: "" }],
          recordedBrands:
            id === null ? [] : brandIds.map((brandId) => ({ ingredientId: id, brandId })),
          members: [member("m", rules.halal())],
          reference,
        }).perMember[0]!;
        const derived = derive(line(id, ...brandIds));
        const expected = { safe: "halal", not_safe: "not_halal", check_label: "check_label" };
        const context = `${id} ${brandIds.join("+")}`;
        expect(derived.status, context).toBe(expected[engine.status]);
        expect(
          derived.findings.map((f) => [f.kind, f.code, f.componentPath, f.brandId, f.detail]),
          context,
        ).toEqual(
          engine.reasons.map((r) => [r.kind, r.code, r.componentPath, r.brandId, r.detail]),
        );
      }
    }
  });

  it("LIB-05 SAF-07 with several recorded brands the worst one wins", () => {
    const both = derive(line("fx-sauce", "fx-brand-ok", "fx-brand-wine"));
    expect(both.status).toBe("not_halal");
    expect(both.findings[0]).toMatchObject({ code: "halal_not_halal", brandId: "fx-brand-wine" });
    const unverified = derive(line("fx-sauce", "fx-brand-ok", "fx-brand-unverified"));
    expect(unverified.status).toBe("check_label");
    expect(codes(unverified)).toContain("brand_unverified");
  });

  it("LIB-05 SAF-07 malformed brand lists or entries are ignored, which fails closed", () => {
    for (const brandIds of ["fx-brand-ok", { 0: "fx-brand-ok" }, [42, "", null]]) {
      const result = deriveRecipeHalal({
        lines: [{ lineId: "l", ingredientId: "fx-sauce", brandIds } as unknown as RecipeLineInput],
        reference,
      });
      expect(result.status, JSON.stringify(brandIds)).toBe("check_label");
      expect(codes(result)).toContain("brand_not_recorded");
    }
  });

  it("LIB-05 DAT-06 the reference is read once per recipe and the versions come from that read", () => {
    let versionReads = 0;
    let listReads = 0;
    const shifting = {
      schema: reference.schema,
      get version(): string {
        versionReads += 1;
        return `unit-fixture-v${versionReads}`;
      },
      get ingredients(): readonly ReferenceIngredient[] {
        listReads += 1;
        return reference.ingredients;
      },
    } as ReferenceDataset;
    const result = deriveRecipeHalal({
      lines: [line("fx-plain"), line("fx-plain-2"), line("fx-pork")],
      reference: shifting,
    });
    expect([versionReads, listReads]).toEqual([1, 1]);
    expect(result.referenceVersion).toBe("unit-fixture-v1");
    expect(result.status).toBe("not_halal");
  });
});

describe("LIB-05 the halal status is never typed in", () => {
  it("LIB-05 a status given on the input or on a line is ignored", () => {
    const attempt = {
      lines: [
        {
          lineId: "l1",
          ingredientId: "fx-pork",
          halal: true,
          halalStatus: "halal",
          status: "halal",
        },
        { lineId: "l2", ingredientId: null, halalStatus: "halal", verified: true },
      ],
      reference,
      status: "halal",
      halalStatus: "halal",
      override: true,
    } as unknown as RecipeHalalInput;
    const baseline = deriveRecipeHalal({
      lines: [
        { lineId: "l1", ingredientId: "fx-pork" },
        { lineId: "l2", ingredientId: null },
      ],
      reference,
    });
    expect(deriveRecipeHalal(attempt)).toEqual(baseline);
    expect(baseline.status).toBe("not_halal");
  });

  it("LIB-05 the input types have no field that can hold a status", () => {
    const lines: RecipeLineInput[] = [{ lineId: "l1", ingredientId: "fx-plain" }];
    // @ts-expect-error LIB-05: a recipe-level status cannot be passed in
    const withStatus: RecipeHalalInput = { lines, reference, status: "halal" };
    // @ts-expect-error LIB-05: a stored halal status cannot be passed in
    const withHalalStatus: RecipeHalalInput = { lines, reference, halalStatus: "halal" };
    // @ts-expect-error LIB-05: a line cannot carry a halal flag
    const lineWithHalal: RecipeLineInput = { lineId: "l2", ingredientId: "fx-pork", halal: true };
    // @ts-expect-error SAF-07: a single chosen brand is not accepted; pass every brand in brandIds
    const oneBrand: RecipeLineInput = { lineId: "l3", ingredientId: "fx-sauce", brandId: "x" };
    expect(deriveRecipeHalal({ lines: [oneBrand], reference }).status).toBe("check_label");
    expect(deriveRecipeHalal(withStatus).status).toBe("halal");
    expect(deriveRecipeHalal(withHalalStatus).status).toBe("halal");
    expect(deriveRecipeHalal({ lines: [lineWithHalal], reference }).status).toBe("not_halal");
  });

  it("LIB-05 deriveRecipeHalal takes exactly one argument (SAF-12)", () => {
    expect(deriveRecipeHalal.length).toBe(1);
  });
});

describe("LIB-05 SAF-14 the result can be logged", () => {
  it("LIB-05 names given on lines never appear in the result", () => {
    const lines = [
      {
        lineId: "l1",
        ingredientId: "fx-pork",
        rawName: "Babi Bu Rina",
        displayName: "Daging Rahasia",
      },
      { lineId: "l2", ingredientId: null, rawName: "Sambal Bu Rina" },
    ] as unknown as RecipeLineInput[];
    const text = JSON.stringify(deriveRecipeHalal({ lines, reference }));
    expect(text).not.toMatch(/Rina|Rahasia/);
  });
});

describe("LIB-05 input that cannot be read fails closed with no result", () => {
  it.each([
    ["no input", undefined],
    ["lines that are not a list", { lines: "fx-plain", reference }],
    ["a line that is not an object", { lines: ["fx-plain"], reference }],
    ["a line without a lineId", { lines: [{ ingredientId: "fx-plain" }], reference }],
    ["an empty lineId", { lines: [{ lineId: "", ingredientId: "fx-plain" }], reference }],
    [
      "a duplicate lineId",
      {
        lines: [
          { lineId: "l1", ingredientId: "fx-plain" },
          { lineId: "l1", ingredientId: "fx-plain-2" },
        ],
        reference,
      },
    ],
    ["no reference data", { lines: [{ lineId: "l1", ingredientId: "fx-plain" }] }],
    ["no reference data for an empty recipe", { lines: [] }],
    ["reference data without a version", { lines: [], reference: { ...reference, version: "" } }],
  ])("LIB-05 %s throws CekAmanInputError", (_name, input) => {
    expect(() => deriveRecipeHalal(input as unknown as RecipeHalalInput)).toThrow(
      CekAmanInputError,
    );
  });

  it("LIB-05 AI-03 an error names the line position, never the caller's lineId", () => {
    const lineId = "Sambal Bu Rina 0812-0000-0000";
    const lines = [
      { lineId, ingredientId: "fx-plain" },
      { lineId, ingredientId: "fx-plain" },
    ];
    expect(() => deriveRecipeHalal({ lines, reference })).toThrow(
      "recipe line 1 repeats an earlier lineId",
    );
    expect(() =>
      deriveRecipeHalal({ lines: [{ lineId: "" } as RecipeLineInput], reference }),
    ).toThrow("recipe line 0 needs a lineId");
  });
});

describe("LIB-05 SAF-01 pure and deterministic", () => {
  it("LIB-05 same input, same output, and the input is never modified", () => {
    const deepFreeze = <T>(value: T): T => {
      if (typeof value === "object" && value !== null) {
        Object.values(value).forEach(deepFreeze);
        Object.freeze(value);
      }
      return value;
    };
    const input = deepFreeze(
      structuredClone({
        lines: [
          { lineId: "l1", ingredientId: "fx-sauce", brandIds: ["fx-brand-ok"] },
          { lineId: "l2", ingredientId: "fx-wine-sauce" },
          { lineId: "l3", ingredientId: null },
        ],
        reference,
      }),
    ) as RecipeHalalInput;
    expect(deriveRecipeHalal(input)).toEqual(deriveRecipeHalal(input));
  });

  it("LIB-05 SAF-01 inherited line fields never stand in for missing ones", () => {
    const proto = Object.prototype as Record<string, unknown>;
    const keys = { lineId: "fx-inherited", ingredientId: "fx-plain", brandIds: ["fx-brand-ok"] };
    for (const key of Object.keys(keys)) expect(Object.hasOwn(proto, key)).toBe(false);
    try {
      Object.assign(proto, keys);
      const result = deriveRecipeHalal({
        lines: [{ lineId: "l1" } as RecipeLineInput, { lineId: "l2", ingredientId: "fx-sauce" }],
        reference,
      });
      expect(result.status).toBe("check_label");
      expect(codes(result)).toEqual([
        "ingredient_unresolved",
        "brand_not_recorded",
        "halal_uncertain",
      ]);
      expect(() => deriveRecipeHalal({ lines: [{} as RecipeLineInput], reference })).toThrow(
        CekAmanInputError,
      );
    } finally {
      for (const key of Object.keys(keys)) delete proto[key];
    }
  });
});
