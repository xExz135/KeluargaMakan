// TEST FIXTURE: not real safety or nutrition data. Uses the fictional regression
// fixtures only.
//
// Security re-check T-041 N4: the API gives Cek Aman a per-check subset of the
// reference (services/api/src/safety/reference-subset.ts), so it holds a copy
// of the engine's lookup rules. This suite proves, for every regression case
// and every recipe halal case, that (1) the subset gives exactly the
// full-dataset result and (2) the engine reads no reference record outside
// the subset (a read tracker wraps every record). A rule set that follows a
// new reference field fails here until the subset follows it too.
import {
  deriveRecipeHalal,
  evaluate,
  type ReferenceDataset,
  type ReferenceIngredient,
} from "@keluargamakan/cek-aman";
import { describe, expect, it } from "vitest";

import { fixtureReference } from "../../data/fixtures/cek-aman/reference.fixture.js";
import { referenceSubset } from "../../services/api/src/safety/reference-subset.js";
import { malformedReference, regressionCases, toInput } from "./cases.js";
import { recipeHalalCases, toLines } from "./recipe-halal-cases.js";

/** Wraps every record so that any read other than its `id` marks the record as read. */
function tracked(dataset: ReferenceDataset): {
  readonly dataset: ReferenceDataset;
  readonly read: Set<string>;
} {
  const read = new Set<string>();
  const wrap = (record: ReferenceIngredient): ReferenceIngredient => {
    const id = record.id;
    return new Proxy(record, {
      get(target, key, receiver) {
        if (key !== "id") read.add(id);
        return Reflect.get(target, key, receiver) as unknown;
      },
      getOwnPropertyDescriptor(target, key) {
        if (key !== "id") read.add(id);
        return Reflect.getOwnPropertyDescriptor(target, key);
      },
      has(target, key) {
        if (key !== "id") read.add(id);
        return Reflect.has(target, key);
      },
      ownKeys(target) {
        read.add(id);
        return Reflect.ownKeys(target);
      },
    });
  };
  return { dataset: { ...dataset, ingredients: dataset.ingredients.map(wrap) }, read };
}

const outcome = (run: () => unknown): unknown => {
  try {
    return run();
  } catch (error) {
    return { threw: error instanceof Error ? error.message : String(error) };
  }
};

const idsOf = (dataset: ReferenceDataset) =>
  new Set(dataset.ingredients.map((record) => record.id));

describe("N4 SAF-01 the API's reference subset matches what Cek Aman reads", () => {
  it("N4 every safety regression case: same result with the subset, and no record read outside it", () => {
    expect(regressionCases.length).toBeGreaterThan(40);
    for (const testCase of regressionCases) {
      const input = toInput(testCase);
      const rules = input.members.flatMap((member) => member.hardRules);
      const subset = referenceSubset(
        input.reference,
        input.ingredients.map((item) => item.ingredientId),
        rules,
      );
      expect(
        outcome(() => evaluate({ ...input, reference: subset })),
        testCase.id,
      ).toEqual(outcome(() => evaluate(input)));

      const { dataset, read } = tracked(input.reference);
      outcome(() => evaluate({ ...input, reference: dataset }));
      const kept = idsOf(subset);
      expect(
        [...read].filter((id) => !kept.has(id)),
        `${testCase.id} reads outside the subset`,
      ).toEqual([]);
    }
  });

  it("N4 every recipe halal case: same result with the subset, and no record read outside it", () => {
    expect(recipeHalalCases.length).toBeGreaterThan(20);
    for (const testCase of recipeHalalCases) {
      const lines = toLines(testCase.lines);
      const reference = testCase.malformed === true ? malformedReference : fixtureReference;
      const subset = referenceSubset(
        reference,
        lines.map((line) => line.ingredientId),
        [],
      );
      expect(
        outcome(() => deriveRecipeHalal({ lines, reference: subset })),
        testCase.id,
      ).toEqual(outcome(() => deriveRecipeHalal({ lines, reference })));

      const { dataset, read } = tracked(reference);
      outcome(() => deriveRecipeHalal({ lines, reference: dataset }));
      const kept = idsOf(subset);
      expect(
        [...read].filter((id) => !kept.has(id)),
        `${testCase.id} reads outside the subset`,
      ).toEqual([]);
    }
  });

  it("N4 the tracker notices a read: a record outside the subset that the engine reads is reported", () => {
    // Self-test: check a recipe against the full dataset, but compare with an
    // empty subset; every record the engine read must be reported.
    const { dataset, read } = tracked(fixtureReference);
    const first = fixtureReference.ingredients[0]!;
    outcome(() =>
      evaluate({
        ingredients: [{ ingredientId: first.id, rawName: "bahan fiksi" }],
        recordedBrands: [],
        members: [{ memberId: "fx-m", hardRules: [{ ruleId: "fx-r", type: "halal" }] }],
        reference: dataset,
      }),
    );
    expect(read.has(first.id)).toBe(true);
  });
});
