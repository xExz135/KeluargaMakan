// TEST FIXTURE: not real safety or nutrition data
import { describe, expect, it } from "vitest";

import { evaluate } from "../evaluate.js";
import { ing, input, member, rules } from "../test-fixtures.js";
import type { RecipeIngredientInput } from "../types.js";
import { deriveRecipeHalal, type RecipeLineInput } from "./halal.js";
import { ingredientFromRecognition, type RecognitionOutput } from "./recognition.js";

const recognized: RecognitionOutput = {
  label: "tahu",
  confidence: "high",
  modelId: "fx-model-1",
  proposedIngredientId: "fx-plain",
};

describe("REC-06 recognized items enter Cek Aman unresolved", () => {
  it("REC-06 keeps only the label, as the name shown, and drops confidence, model and proposed ID", () => {
    expect(ingredientFromRecognition(recognized)).toEqual({ ingredientId: null, rawName: "tahu" });
  });

  it("REC-06 a missing, inherited or non-string label gives an empty name", () => {
    const proto = Object.prototype as Record<string, unknown>;
    expect(Object.hasOwn(proto, "label")).toBe(false);
    try {
      proto["label"] = "inherited";
      expect(ingredientFromRecognition({} as RecognitionOutput)).toEqual({
        ingredientId: null,
        rawName: "",
      });
    } finally {
      delete proto["label"];
    }
    expect(ingredientFromRecognition({ label: 7 } as unknown as RecognitionOutput).rawName).toBe(
      "",
    );
    expect(ingredientFromRecognition(null as unknown as RecognitionOutput).rawName).toBe("");
  });

  it("REC-06 SAF-10 a recognized item that proposes a verified, halal, allergen-free ID is never safe", () => {
    const reference = [ing("fx-plain")];
    const result = evaluate({
      ...input({
        reference,
        recipe: [],
        members: [member("m-halal", rules.halal()), member("m-soy", rules.allergy("soy"))],
      }),
      ingredients: [ingredientFromRecognition(recognized)],
    });
    for (const verdict of result.perMember) {
      expect(verdict.status).toBe("check_label");
      expect(verdict.reasons.map((r) => r.code)).toEqual(["ingredient_unresolved"]);
    }
  });

  it("REC-06 recognition fields cannot be put on an engine ingredient or a recipe line", () => {
    // @ts-expect-error REC-06: a recognized item is not an engine ingredient
    const spread: RecipeIngredientInput = {
      ...recognized,
      ingredientId: "fx-plain",
      rawName: "tahu",
    };
    const withConfidence: RecipeLineInput = {
      lineId: "l1",
      ingredientId: "fx-plain",
      // @ts-expect-error REC-06: a confidence never travels with a line
      confidence: 1,
    };
    // Even when forced past the types, the extra fields are not read.
    const reference = [ing("fx-plain")];
    const members = [member("m", rules.halal())];
    expect(
      evaluate({ ...input({ reference, recipe: [], members }), ingredients: [spread] }),
    ).toEqual(evaluate(input({ reference, recipe: ["fx-plain"], members })));
    const dataset = input({ reference, recipe: [], members }).reference;
    expect(deriveRecipeHalal({ lines: [withConfidence], reference: dataset }).status).toBe("halal");
  });
});
