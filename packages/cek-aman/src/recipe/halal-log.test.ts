// TEST FIXTURE: not real safety or nutrition data
import { describe, expect, it } from "vitest";

import { CekAmanInputError } from "../errors.js";
import type { SafetyLogContext } from "../log.js";
import { RULE_SET_VERSION } from "../rule-set.js";
import { ing } from "../test-fixtures.js";
import type { ReferenceDataset, ReferenceIngredient } from "../types.js";
import { deriveRecipeHalal, type RecipeHalalInput } from "./halal.js";
import { RECIPE_HALAL_LOG_FORMAT, deriveRecipeHalalWithLog } from "./halal-log.js";

const brand = (brandId: string, verified: boolean): Record<string, unknown> => ({
  brandId,
  brandName: `Fiksi ${brandId}`,
  verified,
  components: { verification: "verified", ingredientIds: [] },
  allergens: { verification: "verified", contains: [], mayContain: [] },
  halal: { verification: "verified", value: "halal", nonHalalSources: [] },
  diet: { verification: "verified", vegetarian: "suitable", vegan: "suitable" },
});

// Fictional ingredients; every value is invented for these tests.
const reference: ReferenceDataset = {
  schema: "keluargamakan.reference.ingredients/1",
  version: "unit-fixture-halal-log-1",
  ingredients: [
    ing("fx-plain"),
    ing("fx-sauce", {
      brandVaries: true,
      halal: { verification: "verified", value: "uncertain", nonHalalSources: [] },
      brandVariants: [brand("fx-brand-ok", true)],
    }),
  ] as ReferenceIngredient[],
};

const context: SafetyLogContext = {
  householdId: "fx-household-1",
  subject: { kind: "library_recipe", id: "fx-recipe-1", version: "3" },
  evaluatedAt: "2026-11-16T12:00:00+07:00",
};

const halalWithBrand: RecipeHalalInput = {
  lines: [
    { lineId: "l-rice", ingredientId: "fx-plain" },
    { lineId: "l-sauce", ingredientId: "fx-sauce", brandIds: ["fx-brand-ok", "fx-brand-ok"] },
    { lineId: "l-custom", ingredientId: null },
  ],
  reference,
};

describe("SAF-14 LIB-05 recipe halal log record", () => {
  it("SAF-14 DAT-06 a served result comes with a record of every line, its ingredient and its brands", () => {
    const { result, logRecord } = deriveRecipeHalalWithLog(halalWithBrand, context);
    expect(result).toEqual(deriveRecipeHalal(halalWithBrand));
    expect(logRecord).toEqual({
      logFormat: RECIPE_HALAL_LOG_FORMAT,
      householdId: "fx-household-1",
      subject: { kind: "library_recipe", id: "fx-recipe-1", version: "3" },
      evaluatedAt: "2026-11-16T12:00:00+07:00",
      ruleSetVersion: RULE_SET_VERSION,
      referenceVersion: "unit-fixture-halal-log-1",
      status: "check_label",
      lines: [
        { index: 0, lineId: "l-rice", ingredientId: "fx-plain", brandIds: [] },
        { index: 1, lineId: "l-sauce", ingredientId: "fx-sauce", brandIds: ["fx-brand-ok"] },
        { index: 2, lineId: "l-custom", ingredientId: null, brandIds: [] },
      ],
      findings: result.findings,
    });
  });

  it("SAF-14 SAF-07 a halal result with no findings can still be traced to the brand behind it", () => {
    const { result, logRecord } = deriveRecipeHalalWithLog(
      { lines: halalWithBrand.lines.slice(0, 2), reference },
      context,
    );
    expect(result).toMatchObject({ status: "halal", findings: [] });
    expect(logRecord.lines[1]).toEqual({
      index: 1,
      lineId: "l-sauce",
      ingredientId: "fx-sauce",
      brandIds: ["fx-brand-ok"],
    });
  });

  it("SAF-14 the context is checked first, so no result is produced without a traceable record", () => {
    const broken = [
      { ...context, householdId: "" },
      { ...context, evaluatedAt: "" },
      { ...context, subject: { ...context.subject, kind: "photo" } },
      { ...context, subject: { ...context.subject, id: "" } },
      undefined,
    ];
    for (const bad of broken) {
      expect(() =>
        deriveRecipeHalalWithLog(
          { lines: [], reference: undefined } as unknown as RecipeHalalInput,
          bad as SafetyLogContext,
        ),
      ).toThrow(/safety log|food item kind/);
    }
    expect(() =>
      deriveRecipeHalalWithLog({ lines: "x" } as unknown as RecipeHalalInput, context),
    ).toThrow(CekAmanInputError);
  });

  it("SAF-14 AI-03 the record holds no names given on lines", () => {
    const lines = [
      { lineId: "l1", ingredientId: "fx-plain", rawName: "Sambal Bu Rina" },
    ] as unknown as RecipeHalalInput["lines"];
    const { logRecord } = deriveRecipeHalalWithLog({ lines, reference }, context);
    expect(JSON.stringify(logRecord)).not.toMatch(/Rina/);
  });

  it("SAF-12 deriveRecipeHalalWithLog takes exactly the input and the context", () => {
    expect(deriveRecipeHalalWithLog.length).toBe(2);
  });
});
