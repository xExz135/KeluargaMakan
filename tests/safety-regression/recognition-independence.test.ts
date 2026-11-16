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

import type { components } from "../../packages/contracts/src/generated/schema.js";
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

/** Contract `RecognizedItem`, as generated from openapi.yaml (unchanged from 0.2 to 0.3). */
type RecognizedItem = components["schemas"]["RecognizedItem"];

/**
 * One random recognized item in the contract shape: any label, confidence, API
 * name match (`ingredientId`), options and kitchen item, sometimes with an AI
 * service `modelId` or a confidence outside the contract values.
 */
function recognition(): RecognitionOutput {
  const reference = (): { ingredientId: string; displayName: { id: string; en: string } } => ({
    ingredientId: pick(fixtureIds),
    displayName: { id: randomText(), en: randomText() },
  });
  const item: RecognizedItem = {
    id: `fx-recognized-${Math.floor(next() * 1000)}`,
    label: next() < 0.7 ? pick(labels) : randomText(),
    ingredientId: next() < 0.7 ? pick(fixtureIds) : null,
    displayName: next() < 0.5 ? { id: pick(labels), en: pick(labels) } : null,
    confidence: pick(["high", "medium", "low"] as const),
    options: Array.from({ length: Math.floor(next() * 4) }, reference),
    kitchenItemId: next() < 0.3 ? `fx-kitchen-${Math.floor(next() * 100)}` : null,
  };
  // The contract type is accepted as it is, without a cast (REC-06).
  const output: RecognitionOutput = item;
  const extra = next();
  if (extra < 0.3) return { ...output, confidence: pick(confidences) };
  if (extra < 0.5) return { ...output, modelId: pick(["fx-model-a", "fx-model-b", ""]) };
  return output;
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
  it("REC-06 the contract RecognizedItem cannot be spread into an engine input", () => {
    const item: RecognizedItem = {
      id: "fx-recognized-1",
      label: "tahu",
      ingredientId: "fx_tahu",
      displayName: null,
      confidence: "low",
      options: [],
      kitchenItemId: null,
    };
    // @ts-expect-error REC-06: recognition output is not an engine ingredient
    const spread: CekAmanInput["ingredients"][number] = { ...item, rawName: item.label };
    expect(spread.ingredientId).toBe("fx_tahu");
    expect(ingredientFromRecognition(item)).toEqual({ ingredientId: null, rawName: "tahu" });
  });

  it("REC-06 SAF-10 property: any contract-shaped recognized item, its ingredientId included, gives the same decisions as a plain unresolved item", () => {
    for (let i = 0; i < ITERATIONS; i += 1) {
      const testCase = regressionCases[i % regressionCases.length]!;
      const a = recognition();
      const b = recognition();
      const plain = withRecognized(toInput(testCase), { label: "" });
      const baseline = decisions(evaluate(plain));
      const context = `${testCase.id} ${JSON.stringify([a, b])}`;
      expect(decisions(evaluate(withRecognized(toInput(testCase), a))), context).toEqual(baseline);
      expect(decisions(evaluate(withRecognized(toInput(testCase), b))), context).toEqual(baseline);
      // Spread at run time together with the converter's output, the item stays
      // unresolved: the converter's ingredientId: null wins over the API's match.
      const spreadWithConverter = {
        ...toInput(testCase),
        members: allMembers,
        ingredients: [...toInput(testCase).ingredients, { ...a, ...ingredientFromRecognition(a) }],
      } as unknown as CekAmanInput;
      expect(decisions(evaluate(spreadWithConverter)), context).toEqual(baseline);
      // On resolved ingredients too, the other recognition fields are never read.
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
