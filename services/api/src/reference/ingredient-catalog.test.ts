// TEST FIXTURE: not real safety or nutrition data. Fictional catalog records (fx_ IDs).
import { createBuiltDataset, verifyBuiltDataset } from "@keluargamakan/reference-data";
import { describe, expect, it } from "vitest";

import { CapturingLogger } from "../http/testing/harness.js";
import { foldName } from "./fold.js";
import { CatalogFormatError, IngredientCatalog } from "./ingredient-catalog.js";
import { referenceSourceFromEnv, referenceSourceOf } from "./reference-data.js";

function verified(ingredients: unknown[]) {
  const built = createBuiltDataset({
    version: "TEST-FIXTURE-catalog-unit-1",
    fixture: true,
    ingredients: ingredients as never,
  });
  return verifyBuiltDataset(JSON.parse(JSON.stringify(built)), {
    allowFixture: true,
    expectedSha256: null,
  });
}

const record = (id: string, name: string, extra: Record<string, unknown> = {}) => ({
  id,
  displayName: { id: name, en: `Fiction ${name}` },
  localNames: [],
  category: "staples",
  components: { verification: "unverified", ingredientIds: [] },
  allergens: { verification: "unverified", contains: [], mayContain: [] },
  halal: { verification: "unverified", value: "unknown", nonHalalSources: [] },
  diet: { verification: "unverified", vegetarian: "unknown", vegan: "unknown" },
  brandVaries: false,
  brandVariants: [],
  tkpiCode: null,
  ...extra,
});

describe("KIT-04 name folding", () => {
  it.each([
    ["Témpé", "tempe"],
    ["ＴＥＭＰＥ", "tempe"],
    ["  kecap  manis ", "kecap manis"],
    ["kecap-manis", "kecap manis"],
    ["Crème brûlée", "creme brulee"],
    ["ﬁsh", "fish"],
    ["---", ""],
  ])("%j folds to %j", (input, expected) => {
    expect(foldName(input)).toBe(expected);
  });
});

describe("KIT-04 catalog", () => {
  it("copies names, local names, category and brands, and no safety data", () => {
    const catalog = new IngredientCatalog(
      verified([
        record("fx_u_b", "Beta fiksi", {
          localNames: ["Lokal fiksi"],
          category: "fixture-other",
          brandVaries: true,
          brandVariants: [
            {
              brandId: "fx_u_brand",
              brandName: "Merek fiksi",
              verified: false,
              components: { verification: "unverified", ingredientIds: [] },
              allergens: { verification: "unverified", contains: [], mayContain: [] },
              halal: { verification: "unverified", value: "unknown", nonHalalSources: [] },
              diet: { verification: "unverified", vegetarian: "unknown", vegan: "unknown" },
            },
          ],
        }),
        record("fx_u_a", "Alfa fiksi"),
      ]),
    );
    expect(catalog.list().map((item) => item.ingredientId)).toEqual(["fx_u_a", "fx_u_b"]);
    expect(catalog.get("fx_u_b")).toEqual({
      ingredientId: "fx_u_b",
      displayName: { id: "Beta fiksi", en: "Fiction Beta fiksi" },
      localNames: ["Lokal fiksi"],
      category: null,
      brandVaries: true,
      brands: [{ brandId: "fx_u_brand", name: "Merek fiksi" }],
    });
    expect(catalog.get("fx_u_missing")).toBeNull();
    expect(catalog.search("lokal", 10)).toEqual([
      { ingredient: catalog.get("fx_u_b"), matchedName: "Lokal fiksi" },
    ]);
    expect(catalog.search("", 10)).toEqual([]);
  });

  it("fail closed: a record the catalog cannot read makes the whole dataset unavailable", () => {
    for (const broken of [
      record("fx_u_x", "X", { displayName: { id: "X" } }),
      record("fx_u_x", "X", { localNames: [1] }),
      record("fx_u_x", "X", { brandVariants: [{ brandId: "fx_b" }] }),
      record("fx_u_x", "X", { brandVaries: "yes" }),
    ]) {
      const data = verified([record("fx_u_ok", "Ok"), broken]);
      expect(() => new IngredientCatalog(data)).toThrow(CatalogFormatError);
      expect(() => referenceSourceOf(data)).toThrow(CatalogFormatError);
    }
  });

  it("a missing dataset is logged by class, and the source answers null", () => {
    const logger = new CapturingLogger();
    expect(referenceSourceFromEnv({ APP_ENV: "test" }, logger).current()).toBeNull();
    expect(logger.text).toContain('"event":"reference_data_unavailable"');
    expect(logger.text).toContain('"error":"ReferenceDataError"');
  });
});
