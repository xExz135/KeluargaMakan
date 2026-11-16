// TEST FIXTURE: not real safety or nutrition data
//
// QA review T-025: stronger assertions for the recipe halal regression cases
// (LIB-05), recognized items mixed with resolved ones (REC-06, SAF-10), a
// typed-in status at the regression level (LIB-05) and the companion log
// record (SAF-14). Never edit an expectation to make a failing case pass
// without a safety-owner decision.
import { describe, expect, it } from "vitest";

import {
  RECIPE_HALAL_LOG_FORMAT,
  RULE_SET_VERSION,
  deriveRecipeHalal,
  deriveRecipeHalalWithLog,
  evaluate,
  ingredientFromRecognition,
  type CekAmanResult,
  type RecipeHalalInput,
  type RecipeLineInput,
  type SafetyLogContext,
} from "@keluargamakan/cek-aman";

import type { components } from "../../packages/contracts/src/generated/schema.js";
import { fixtureMembers } from "../../data/fixtures/cek-aman/members.fixture.js";
import {
  fixtureIngredients,
  fixtureReference,
} from "../../data/fixtures/cek-aman/reference.fixture.js";
import { malformedReference } from "./cases.js";
import { recipeHalalCases, toLines, type RecipeHalalCase } from "./recipe-halal-cases.js";

type RecognizedItem = components["schemas"]["RecognizedItem"];

function byId(id: string): RecipeHalalCase {
  const found = recipeHalalCases.find((c) => c.id === id);
  if (found === undefined) throw new Error(`missing case ${id}`);
  return found;
}

const referenceOf = (c: RecipeHalalCase) =>
  c.malformed === true ? malformedReference : fixtureReference;

const inputOf = (c: RecipeHalalCase): RecipeHalalInput => ({
  lines: toLines(c.lines),
  reference: referenceOf(c),
});

/** An unconfirmed contract item, matched by the API to `ingredientId` with high confidence. */
function recognized(ingredientId: string, label: string): RecognizedItem {
  return {
    id: "fx-recognized-qa",
    label,
    ingredientId,
    displayName: { id: label, en: label },
    confidence: "high",
    options: [{ ingredientId, displayName: { id: label, en: label } }],
    kitchenItemId: null,
  };
}

/** A recognized item as a recipe line: only through the converter (REC-06). */
function recognizedLine(item: RecognizedItem): RecipeLineInput {
  return {
    lineId: "fx-line-recognized",
    ingredientId: ingredientFromRecognition(item).ingredientId,
  };
}

describe("LIB-05 findings point at the line and the data that caused them", () => {
  it("HAL-017 LIB-05 SAF-07 only the kecap line without a brand is flagged", () => {
    const result = deriveRecipeHalal(inputOf(byId("HAL-017")));
    expect(result.status).toBe("check_label");
    expect(result.findings.length).toBeGreaterThan(0);
    for (const finding of result.findings) expect(finding.line?.lineId).toBe("fx-line-6");
    expect(result.findings.map((f) => f.code)).toContain("brand_not_recorded");
  });

  it("HAL-004 LIB-05 SAF-03 SAF-08 mirin fails through its alcohol component, not its own record", () => {
    const result = deriveRecipeHalal(inputOf(byId("HAL-004")));
    const notHalal = result.findings.filter((f) => f.code === "halal_not_halal");
    expect(notHalal.length).toBeGreaterThan(0);
    for (const finding of notHalal) {
      expect(finding.line?.lineId).toBe("fx-line-5");
      expect(finding.line?.ingredientId).toBe("fx_mirin");
      expect(finding.componentPath).toContain("fx_alkohol");
      expect(finding.kind).toBe("component");
    }
  });

  it("HAL-025 HAL-028 LIB-05 SAF-07 SAF-14 the not_halal finding names the brand with alcohol", () => {
    for (const id of ["HAL-025", "HAL-028"]) {
      const result = deriveRecipeHalal(inputOf(byId(id)));
      const notHalal = result.findings.filter((f) => f.code === "halal_not_halal");
      expect(notHalal.length, id).toBeGreaterThan(0);
      for (const finding of notHalal) {
        expect(finding.brandId, id).toBe("fx_brand_kecap_c");
        expect(finding.line?.ingredientId, id).toBe("fx_kecap_manis");
      }
      // "Not halal" findings come first (SAF-04 precedence).
      expect(result.findings[0]!.code, id).toBe("halal_not_halal");
    }
  });

  it("HAL-026 LIB-05 SAF-09 every custom line has its own finding", () => {
    const result = deriveRecipeHalal(inputOf(byId("HAL-026")));
    expect(result.status).toBe("check_label");
    expect(
      result.findings
        .filter((f) => f.code === "ingredient_unresolved")
        .map((f) => f.line?.lineId)
        .sort(),
    ).toEqual(["fx-line-1", "fx-line-2", "fx-line-3"]);
  });
});

describe("REC-06 SAF-10 recognized items mixed with resolved ones", () => {
  const fixtureIds = fixtureIngredients.map((i) => i.id);

  it("REC-06 LIB-05 a recognized item matched to any fixture ingredient changes nothing against a plain unresolved line", () => {
    for (const testCase of recipeHalalCases) {
      const plain = deriveRecipeHalal({
        lines: [...toLines(testCase.lines), { lineId: "fx-line-recognized", ingredientId: null }],
        reference: referenceOf(testCase),
      });
      for (const id of fixtureIds) {
        const item = recognized(id, id.replace(/^fx_/, ""));
        const mixed = deriveRecipeHalal({
          lines: [...toLines(testCase.lines), recognizedLine(item)],
          reference: referenceOf(testCase),
        });
        expect(mixed, `${testCase.id} ${id}`).toEqual(plain);
        expect(mixed.status, `${testCase.id} ${id}`).not.toBe("halal");
      }
    }
  });

  it("REC-06 LIB-05 a photo of a halal ingredient never makes a halal recipe halal, and the finding is on the recognized line only", () => {
    const result = deriveRecipeHalal({
      lines: [
        ...toLines(byId("HAL-001").lines),
        recognizedLine(recognized("fx_ayam", "ayam halal")),
      ],
      reference: fixtureReference,
    });
    expect(result.status).toBe("check_label");
    expect(result.findings.map((f) => [f.line?.lineId, f.line?.ingredientId, f.code])).toEqual([
      ["fx-line-recognized", null, "ingredient_unresolved"],
    ]);
  });

  it("REC-06 LIB-05 a photo of pork is not halal evidence either: the line is unresolved, not not_halal", () => {
    const result = deriveRecipeHalal({
      lines: [...toLines(byId("HAL-001").lines), recognizedLine(recognized("fx_babi", "babi"))],
      reference: fixtureReference,
    });
    expect(result.status).toBe("check_label");
    expect(result.findings.map((f) => f.code)).toEqual(["ingredient_unresolved"]);
  });

  it("REC-06 LIB-05 SAF-08 with angciu in the recipe, not_halal comes from the angciu line, never from the recognized one", () => {
    const result = deriveRecipeHalal({
      lines: [...toLines(byId("HAL-003").lines), recognizedLine(recognized("fx_angciu", "angciu"))],
      reference: fixtureReference,
    });
    expect(result.status).toBe("not_halal");
    for (const finding of result.findings.filter((f) => f.code === "halal_not_halal")) {
      expect(finding.line?.ingredientId).toBe("fx_angciu");
      expect(finding.line?.lineId).toBe("fx-line-6");
    }
    const onRecognized = result.findings.filter((f) => f.line?.lineId === "fx-line-recognized");
    expect(onRecognized.map((f) => f.code)).toEqual(["ingredient_unresolved"]);
  });

  /** Everything that decides safety, without the display name. */
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

  it("REC-06 SAF-10 exhaustive sweep: no confidence and no label changes any allergen or halal result", () => {
    const confidences: readonly unknown[] = [
      "high",
      "medium",
      "low",
      "certain",
      "",
      1,
      0.999,
      0,
      -1,
      Number.NaN,
      null,
      undefined,
      true,
      {},
    ];
    const labels: readonly string[] = [
      ...fixtureIngredients.flatMap((i) => [i.displayName.id, i.displayName.en]),
      "halal",
      "100% halal",
      "aman",
      "safe",
      "tanpa udang",
      "bebas alergen",
      "babi",
      "",
    ];
    const members = Object.values(fixtureMembers);
    // A mixed recipe: resolved lines with shrimp, soy and wheat, plus the recognized item.
    const resolved = ["fx_nasi", "fx_tahu", "fx_terasi", "fx_tepung_terigu"].map((id) => ({
      ingredientId: id,
      rawName: id,
    }));
    const engineInput = (extra: { ingredientId: string | null; rawName: string }) => ({
      ingredients: [...resolved, extra],
      recordedBrands: [],
      members,
      reference: fixtureReference,
    });
    const halalLines: RecipeLineInput[] = toLines(["fx_nasi", "fx_tahu", "fx_terasi"]);
    const memberBaseline = decisions(evaluate(engineInput({ ingredientId: null, rawName: "" })));
    const halalBaseline = deriveRecipeHalal({
      lines: [...halalLines, { lineId: "fx-line-recognized", ingredientId: null }],
      reference: fixtureReference,
    });
    for (const confidence of confidences) {
      for (const label of labels) {
        for (const ingredientId of ["fx_ikan", "fx_garam", "fx_babi"]) {
          const item = { ...recognized(ingredientId, label), confidence } as RecognizedItem;
          const context = `${String(confidence)} ${JSON.stringify(label)} ${ingredientId}`;
          expect(
            decisions(evaluate(engineInput(ingredientFromRecognition(item)))),
            context,
          ).toEqual(memberBaseline);
          expect(
            deriveRecipeHalal({
              lines: [...halalLines, recognizedLine(item)],
              reference: fixtureReference,
            }),
            context,
          ).toEqual(halalBaseline);
          // The same fields forced onto resolved lines past the types are never read.
          const noisyLines = halalLines.map((line) => ({ ...item, ...line }));
          expect(
            deriveRecipeHalal({
              lines: [...noisyLines, recognizedLine(item)],
              reference: fixtureReference,
            } as unknown as RecipeHalalInput),
            context,
          ).toEqual(halalBaseline);
        }
      }
    }
  });
});

describe("LIB-05 a halal status is never typed in (regression level)", () => {
  it("LIB-05 for every recipe halal case, a status on the input or on every line is ignored", () => {
    const typed = [
      { status: "halal", halalStatus: "halal", halal: true },
      { status: "not_halal", halalStatus: "not_halal", halal: false },
      { status: "check_label", halalStatus: "check_label", halal: null },
    ];
    for (const testCase of recipeHalalCases) {
      const baseline = deriveRecipeHalal(inputOf(testCase));
      for (const status of typed) {
        const input = {
          ...status,
          lines: toLines(testCase.lines).map((line) => ({ ...status, ...line })),
          reference: referenceOf(testCase),
        } as unknown as RecipeHalalInput;
        expect(deriveRecipeHalal(input), `${testCase.id} ${status.status}`).toEqual(baseline);
      }
    }
  });
});

describe("SAF-14 LIB-05 every served recipe halal status has a log record that traces it", () => {
  const context: SafetyLogContext = {
    householdId: "fx-household-qa",
    subject: { kind: "library_recipe", id: "fx-recipe-qa", version: "1" },
    evaluatedAt: "2026-11-16T12:00:00+07:00",
  };

  it("SAF-14 DAT-06 for every recipe halal case the record echoes the result, versions and every line with its brands", () => {
    for (const testCase of recipeHalalCases) {
      const input = inputOf(testCase);
      const { result, logRecord } = deriveRecipeHalalWithLog(input, context);
      expect(result, testCase.id).toEqual(deriveRecipeHalal(input));
      expect(logRecord.logFormat).toBe(RECIPE_HALAL_LOG_FORMAT);
      expect(logRecord.ruleSetVersion).toBe(RULE_SET_VERSION);
      expect(logRecord.referenceVersion).toBe(referenceOf(testCase).version);
      expect(logRecord.status).toBe(result.status);
      expect(logRecord.findings).toEqual(result.findings);
      expect(logRecord.lines, testCase.id).toEqual(
        input.lines.map((line, index) => ({
          index,
          lineId: line.lineId,
          ingredientId: line.ingredientId,
          brandIds: [...new Set(line.brandIds ?? [])],
        })),
      );
    }
  });

  it("HAL-012 SAF-14 SAF-07 a halal result with no findings is traced to the verified brand behind it", () => {
    const { result, logRecord } = deriveRecipeHalalWithLog(inputOf(byId("HAL-012")), context);
    expect(result.status).toBe("halal");
    expect(result.findings).toEqual([]);
    expect(logRecord.lines[4]).toEqual({
      index: 4,
      lineId: "fx-line-5",
      ingredientId: "fx_kecap_manis",
      brandIds: ["fx_brand_kecap_a"],
    });
  });
});
