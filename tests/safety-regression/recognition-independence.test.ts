// TEST FIXTURE: not real safety or nutrition data
import { describe, expect, it } from "vitest";

import {
  deriveRecipeHalal,
  evaluate,
  ingredientFromRecognition,
  type CekAmanInput,
  type CekAmanResult,
  type MemberRulesInput,
  type RecipeHalalInput,
  type RecognitionOutput,
} from "@keluargamakan/cek-aman";

import { fixtureMembers } from "../../data/fixtures/cek-aman/members.fixture.js";
import {
  fixtureIngredients,
  fixtureReference,
} from "../../data/fixtures/cek-aman/reference.fixture.js";
import { malformedReference, regressionCases, toInput } from "./cases.js";
import { recipeHalalCases, toLines } from "./recipe-halal-cases.js";

/** Seeded generator (mulberry32), so every run checks the same items and a failure can be replayed. */
function generator(seed: number): () => number {
  let state = seed >>> 0;
  return () => {
    state = (state + 0x6d2b79f5) >>> 0;
    let t = state;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

const ITERATIONS = 400;
const next = generator(0x5eed0006);
const pick = <T>(list: readonly T[]): T => list[Math.floor(next() * list.length)]!;
const randomText = (): string =>
  Array.from({ length: Math.floor(next() * 12) }, () =>
    pick([..."abcdefghijklmnopqrstuvwxyz -"]),
  ).join("");

const fixtureIds = fixtureIngredients.map((ingredient) => ingredient.id);
const confidences: readonly unknown[] = [
  "high",
  "medium",
  "low",
  "unknown",
  "",
  0,
  1,
  0.5,
  0.999,
  -1,
  2,
  Number.NaN,
  Number.POSITIVE_INFINITY,
  null,
  undefined,
  {},
  [],
  true,
];
const labels: readonly string[] = [
  ...fixtureIngredients.flatMap((i) => [i.displayName.id, i.displayName.en]),
  "babi",
  "halal",
  "aman",
  "safe",
  "bebas alergen",
  "",
  " ",
];

/** One random recognized item: any label, confidence, model and proposed reference ID. */
function recognition(): RecognitionOutput {
  const item = {
    label: next() < 0.7 ? pick(labels) : randomText(),
    confidence: next() < 0.8 ? pick(confidences) : next() * 4 - 2,
    modelId: next() < 0.5 ? pick(["fx-model-a", "fx-model-b", ""]) : randomText(),
  };
  const proposal = next();
  if (proposal < 0.6) return { ...item, proposedIngredientId: pick(fixtureIds) };
  if (proposal < 0.8) return { ...item, proposedIngredientId: null };
  return item;
}

/** Everything that decides safety, without the display name (the label is only ever shown). */
function decisions(result: CekAmanResult): unknown {
  return result.perMember.map((member) => ({
    memberId: member.memberId,
    status: member.status,
    reasons: member.reasons.map(({ ingredient, ...reason }) => ({
      ...reason,
      ingredient:
        ingredient === null ? null : { index: ingredient.index, id: ingredient.ingredientId },
    })),
  }));
}

/** Every member with an allergy or halal rule, plus the others (PRF-04, SAF-08). */
const allMembers: readonly MemberRulesInput[] = Object.values(fixtureMembers);

function withRecognized(input: CekAmanInput, item: RecognitionOutput): CekAmanInput {
  return {
    ...input,
    members: allMembers,
    ingredients: [...input.ingredients, ingredientFromRecognition(item)],
  };
}

/** Recognition fields smuggled onto every ingredient, past the types (REC-06 at run time). */
function smuggled(input: CekAmanInput, item: RecognitionOutput): CekAmanInput {
  return {
    ...input,
    ingredients: input.ingredients.map((ingredient) => ({ ...item, ...ingredient })),
  } as unknown as CekAmanInput;
}

describe("REC-06 SAF-10 recognition output never changes an allergen or halal result", () => {
  it("REC-06 SAF-10 property: any label, confidence, model or proposed ID gives the same decisions as a plain unresolved item", () => {
    for (let i = 0; i < ITERATIONS; i += 1) {
      const testCase = regressionCases[i % regressionCases.length]!;
      const a = recognition();
      const b = recognition();
      const plain = withRecognized(toInput(testCase), { label: "", confidence: null, modelId: "" });
      const baseline = decisions(evaluate(plain));
      const context = `${testCase.id} ${JSON.stringify([a, b])}`;
      expect(decisions(evaluate(withRecognized(toInput(testCase), a))), context).toEqual(baseline);
      expect(decisions(evaluate(withRecognized(toInput(testCase), b))), context).toEqual(baseline);
      // On resolved ingredients too, extra recognition fields are never read.
      expect(evaluate(smuggled(plain, a)), context).toEqual(evaluate(plain));
    }
  });

  it("REC-06 SAF-10 a recognized item is never Safe for any member with a hard rule, whatever it proposes", () => {
    const withRules = allMembers.filter((member) => member.hardRules.length > 0);
    for (let i = 0; i < ITERATIONS; i += 1) {
      const item = recognition();
      const result = evaluate({
        ingredients: [ingredientFromRecognition(item)],
        recordedBrands: [],
        members: withRules,
        reference: fixtureReference,
      });
      for (const member of result.perMember) {
        expect(member.status, `${member.memberId} ${JSON.stringify(item)}`).toBe("check_label");
      }
    }
  });

  it("REC-06 LIB-05 property: recognition output never changes a recipe halal status", () => {
    for (let i = 0; i < ITERATIONS; i += 1) {
      const testCase = recipeHalalCases[i % recipeHalalCases.length]!;
      const item = recognition();
      const recognizedLine = {
        lineId: "fx-line-recognized",
        ingredientId: ingredientFromRecognition(item).ingredientId,
      };
      const lines = [...toLines(testCase.lines), recognizedLine];
      const reference = testCase.malformed === true ? malformedReference : fixtureReference;
      const baseline = deriveRecipeHalal({ lines, reference });
      const noisy = {
        lines: lines.map((line) => ({ ...item, ...line })),
        reference,
      } as unknown as RecipeHalalInput;
      const context = `${testCase.id} ${JSON.stringify(item)}`;
      expect(deriveRecipeHalal(noisy), context).toEqual(baseline);
      // The recognized line is unresolved, so the recipe is never halal.
      expect(baseline.status, context).not.toBe("halal");
    }
  });
});
