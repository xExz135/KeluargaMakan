// TEST FIXTURE: not real safety or nutrition data
import { describe, expect, it } from "vitest";

import { evaluate } from "../evaluate.js";
import { ing, input, member, rules } from "../test-fixtures.js";
import type { RecipeIngredientInput } from "../types.js";
import { deriveRecipeHalal, type RecipeLineInput } from "./halal.js";
import { ingredientFromRecognition, type RecognitionOutput } from "./recognition.js";

/**
 * Contract 0.3 `RecognizedItem` as generated (packages/contracts). Copied here
 * because this package has no dependencies; the regression suite checks the
 * generated type itself.
 */
interface ContractRecognizedItem {
  id: string;
  label: string;
  ingredientId: string | null;
  displayName: { id: string; en: string } | null;
  confidence: "high" | "medium" | "low";
  options: { ingredientId: string; displayName: { id: string; en: string } }[];
  kitchenItemId: string | null;
}

/** The API matched the label to a verified, halal, allergen-free ingredient, unconfirmed. */
const recognized: ContractRecognizedItem = {
  id: "fx-recognized-1",
  label: "tahu",
  ingredientId: "fx-plain",
  displayName: { id: "Fiksi tahu", en: "Fiction tofu" },
  confidence: "high",
  options: [{ ingredientId: "fx-plain", displayName: { id: "Fiksi", en: "Fiction" } }],
  kitchenItemId: null,
};

describe("REC-06 recognized items enter Cek Aman unresolved", () => {
  it("REC-06 accepts the contract RecognizedItem as it is and drops its ingredientId, options, confidence and IDs", () => {
    const asOutput: RecognitionOutput = recognized;
    expect(ingredientFromRecognition(asOutput)).toEqual({ ingredientId: null, rawName: "tahu" });
    expect(ingredientFromRecognition({ ...recognized, modelId: "fx-model-1" })).toEqual({
      ingredientId: null,
      rawName: "tahu",
    });
  });

  it("REC-06 SAF-10 a label never resolves the item, even one that names a reference ingredient exactly", () => {
    // Fictional reference data: each label below would resolve to a verified,
    // halal, allergen-free ingredient if the converter matched on labels.
    const reference = [ing("fx-plain"), ing("tahu"), ing("fx-tempe")];
    const labels = [
      "fx-plain",
      "tahu",
      "fx-tempe",
      " tahu ",
      "TAHU",
      "Fiksi fx-plain",
      "Fiction fx-plain",
      "Fiksi tahu",
    ];
    const members = [member("m-halal", rules.halal()), member("m-soy", rules.allergy("soy"))];
    for (const label of labels) {
      const item = { ...recognized, label, ingredientId: null, options: [] };
      const converted = ingredientFromRecognition(item);
      expect(converted, label).toEqual({ ingredientId: null, rawName: label });
      const result = evaluate({
        ...input({ reference, recipe: [], members }),
        ingredients: [converted],
      });
      for (const verdict of result.perMember) {
        expect(verdict.status, `${label} ${verdict.memberId}`).toBe("check_label");
        expect(verdict.reasons.map((r) => r.code)).toEqual(["ingredient_unresolved"]);
      }
    }
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

  it("REC-06 SAF-10 a recognized item matched to a verified, halal, allergen-free ID is never safe", () => {
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
    const spread: RecipeIngredientInput = { ...recognized, rawName: "tahu" };
    const withConfidence: RecipeLineInput = {
      lineId: "l1",
      ingredientId: "fx-plain",
      // @ts-expect-error REC-06: a confidence never travels with a line
      confidence: "high",
    };
    // The converter's output wins over anything spread with it at run time.
    const converted: RecipeIngredientInput = {
      ...(recognized as object),
      ...ingredientFromRecognition(recognized),
    };
    const reference = [ing("fx-plain")];
    const members = [member("m", rules.halal())];
    expect(
      evaluate({ ...input({ reference, recipe: [], members }), ingredients: [converted] })
        .perMember[0]!.status,
    ).toBe("check_label");
    // Forced past the types, the recognition fields themselves are not read; the
    // ingredientId is, which is why only the converter may bring an item in.
    expect(
      evaluate({ ...input({ reference, recipe: [], members }), ingredients: [spread] }),
    ).toEqual(evaluate(input({ reference, recipe: ["fx-plain"], members })));
    const dataset = input({ reference, recipe: [], members }).reference;
    expect(deriveRecipeHalal({ lines: [withConfidence], reference: dataset }).status).toBe("halal");
  });
});
