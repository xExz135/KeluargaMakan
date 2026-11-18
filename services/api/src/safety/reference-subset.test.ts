// TEST FIXTURE: not real safety or nutrition data. Fictional ingredients and members
// (data/fixtures/cek-aman) and generated fictional records.
import { randomUUID } from "node:crypto";

import {
  deriveRecipeHalal,
  evaluate,
  type HardRule,
  type ReferenceDataset,
} from "@keluargamakan/cek-aman";
import type { VerifiedReference } from "@keluargamakan/reference-data";
import { describe, expect, it } from "vitest";

import { referenceSourceOf, type LoadedReference } from "../reference/reference-data.js";
import { checkFood, referenceSubset, type FoodCandidate } from "./checked-serving.js";
import type { CheckEater } from "./eaters.js";

function loaded(data: ReferenceDataset): LoadedReference {
  const verified: VerifiedReference = {
    version: data.version,
    contentHash: "0".repeat(64),
    fixture: true,
    ingredientCount: data.ingredients.length,
    referenceVersion: data.version,
    reference: data,
  };
  const current = referenceSourceOf(verified).current();
  if (current === null) throw new Error("no reference");
  return current;
}

/** A small deterministic generator, so a failure can be reproduced. */
function random(seed: number): () => number {
  let state = seed;
  return () => {
    state = (state * 1_103_515_245 + 12_345) % 2_147_483_648;
    return state / 2_147_483_648;
  };
}

describe("M1 SAF-01 the per-check reference subset gives exactly the full-dataset result", () => {
  const next = random(41);
  const pick = <T>(list: readonly T[]): T => list[Math.floor(next() * list.length)]!;
  const allergens = ["peanut", "shrimp", "shellfish", "milk", "soy", "wheat", "gluten", "egg"];
  const verification = () => (next() < 0.8 ? "verified" : "unverified");
  const N = 120;
  const ids = Array.from({ length: N }, (_, i) => `fx_g${i}`);
  const safety = () => {
    const halal = pick(["halal", "halal", "not_halal", "uncertain", "unknown"]);
    return {
      // Components point at other records, at missing ones, and sometimes back (cycles).
      components: {
        verification: verification(),
        ingredientIds: Array.from({ length: Math.floor(next() * 3) }, () =>
          next() < 0.1 ? "fx_g_missing" : pick(ids),
        ),
      },
      allergens: {
        verification: verification(),
        contains: next() < 0.3 ? [pick(allergens)] : [],
        mayContain: next() < 0.2 ? [pick(allergens)] : [],
      },
      halal: {
        verification: verification(),
        value: halal,
        nonHalalSources: halal === "not_halal" ? [pick(["alcohol", "pork"])] : [],
      },
      diet: {
        verification: verification(),
        vegetarian: pick(["suitable", "not_suitable", "uncertain"]),
        vegan: pick(["suitable", "not_suitable", "unknown"]),
      },
    };
  };
  const records = ids.map((id) => {
    const brandVaries = next() < 0.25;
    return {
      id,
      displayName: { id: `${id} fiksi`, en: `${id} fiction` },
      localNames: [],
      category: "protein",
      ...safety(),
      brandVaries,
      brandVariants: brandVaries
        ? Array.from({ length: 1 + Math.floor(next() * 2) }, (_, b) => ({
            brandId: `${id}_b${b}`,
            brandName: `Merek ${b} fiksi`,
            verified: next() < 0.7,
            ...safety(),
          }))
        : [],
      tkpiCode: null,
    };
  });
  const reference = loaded({
    schema: "keluargamakan.reference.ingredients/1",
    version: "TEST-FIXTURE-subset-1",
    ingredients: records,
  } as unknown as ReferenceDataset);
  const brands = records.flatMap((record) =>
    record.brandVariants.map((variant) => ({ ingredientId: record.id, brandId: variant.brandId })),
  );
  const rules: HardRule[] = [
    ...allergens.map((allergen, i) => ({
      ruleId: `fx-a${i}`,
      type: "allergy" as const,
      allergen: allergen as never,
    })),
    { ruleId: "fx-h", type: "halal" },
    { ruleId: "fx-v", type: "vegetarian" },
    { ruleId: "fx-vg", type: "vegan" },
    {
      ruleId: "fx-m",
      type: "medical_exclusion",
      freeText: null,
      mapping: {
        status: "mapped",
        ingredientIds: [ids[3]!, ids[40]!],
        confirmedBy: "content_team",
      },
    },
    {
      ruleId: "fx-f",
      type: "free_text",
      freeText: "aturan fiksi",
      mapping: { status: "mapped", ingredientIds: ["fx_g_missing"], confirmedBy: "manager" },
    },
    {
      ruleId: "fx-p",
      type: "free_text",
      freeText: "usulan fiksi",
      mapping: { status: "proposed", ingredientIds: [ids[7]!] },
    },
  ];
  const eaters: CheckEater[] = [0, 1, 2].map((m) => ({
    memberId: `fx-member-${m}`,
    rulesConsent: "given",
    hardRules: rules.filter((_, i) => i % 3 === m),
    rulesStamp: "fixture",
  }));

  it("SAF-01 500 generated recipes with every rule type and recorded brands", () => {
    for (let n = 0; n < 500; n++) {
      const candidate: FoodCandidate = {
        subject: { kind: "library_recipe", id: `fx_r${n}`, version: "1" },
        lines: Array.from({ length: 1 + Math.floor(next() * 8) }, (_, index) => ({
          lineId: `l${index}`,
          ingredientId: next() < 0.05 ? null : next() < 0.05 ? "fx_g_missing" : pick(ids),
          rawName: `Bahan ${index} fiksi`,
        })),
      };
      const recordedBrands = brands.filter(() => next() < 0.4);
      const subset = referenceSubset(reference, candidate, eaters);
      expect(subset.ingredients.length).toBeLessThanOrEqual(records.length);
      const input = (data: ReferenceDataset) => ({
        ingredients: candidate.lines.map((line) => ({
          ingredientId: line.ingredientId,
          rawName: line.rawName,
        })),
        recordedBrands,
        members: eaters.map((eater) => ({ memberId: eater.memberId, hardRules: eater.hardRules })),
        reference: data,
      });
      expect(evaluate(input(subset)), `recipe ${n}`).toEqual(
        evaluate(input(reference.verified.reference)),
      );
      const halal = (data: ReferenceDataset) =>
        deriveRecipeHalal({
          lines: candidate.lines.map((line) => ({
            lineId: line.lineId,
            ingredientId: line.ingredientId,
            brandIds: recordedBrands
              .filter((brand) => brand.ingredientId === line.ingredientId)
              .map((brand) => brand.brandId),
          })),
          reference: data,
        });
      expect(halal(subset), `recipe ${n}`).toEqual(halal(reference.verified.reference));
    }
  });
});

describe("M1 NFR-03 checking a whole library stays within a time budget", () => {
  it("NFR-03 300 recipes x 20 lines x 6 eaters (2 rules each) against 5,000 ingredients", () => {
    const N = 5000;
    const record = (id: string, contains: string[]) => ({
      id,
      displayName: { id: `${id} fiksi`, en: `${id} fiction` },
      localNames: [],
      category: "protein",
      components: { verification: "verified", ingredientIds: [] },
      allergens: { verification: "verified", contains, mayContain: [] },
      halal: { verification: "verified", value: "halal", nonHalalSources: [] },
      diet: { verification: "verified", vegetarian: "suitable", vegan: "suitable" },
      brandVaries: false,
      brandVariants: [],
      tkpiCode: null,
    });
    const big = loaded({
      schema: "keluargamakan.reference.ingredients/1",
      version: "TEST-FIXTURE-big@sha256:00",
      ingredients: Array.from({ length: N }, (_, i) =>
        record(`fx_p_i${i}`, i % 50 === 0 ? ["shrimp"] : []),
      ),
    } as unknown as ReferenceDataset);
    const eaters: CheckEater[] = Array.from({ length: 6 }, (_, i) => ({
      memberId: randomUUID(),
      rulesConsent: "given",
      rulesStamp: "fixture",
      hardRules: [
        { ruleId: `r${i}a`, type: "allergy", allergen: "peanut" },
        { ruleId: `r${i}b`, type: "halal" },
      ],
    }));
    const context = {
      householdId: randomUUID(),
      eaters,
      recordedBrands: new Map<string, string[]>(),
      reference: big,
      evaluatedAt: new Date(),
    };
    const start = performance.now();
    let checked = 0;
    for (let r = 0; r < 300; r++) {
      const candidate: FoodCandidate = {
        subject: { kind: "library_recipe", id: `fx_p_r${r}`, version: "1" },
        lines: Array.from({ length: 20 }, (_, l) => ({
          lineId: `l${l}`,
          ingredientId: `fx_p_i${(r * 7 + l * 13) % N}`,
          rawName: `Bahan ${l} fiksi`,
        })),
      };
      if (checkFood(context, candidate) !== null) checked += 1;
    }
    const elapsed = performance.now() - start;
    expect(checked).toBe(300);
    // The review measured 1,293 ms before the fix; generous for slow CI.
    expect(elapsed).toBeLessThan(1000);
  });
});
