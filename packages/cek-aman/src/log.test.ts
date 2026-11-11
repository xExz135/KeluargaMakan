// TEST FIXTURE: not real safety or nutrition data
import { describe, expect, it } from "vitest";

import {
  CekAmanInputError,
  RULE_SET_VERSION,
  SAFETY_LOG_FORMAT,
  evaluate,
  evaluateWithLog,
  type SafetyLogContext,
} from "./index.js";
import { ing, input, member, rules } from "./test-fixtures.js";
import type { CekAmanInput } from "./types.js";

const context: SafetyLogContext = {
  householdId: "hh-1",
  subject: { kind: "suggestion", id: "s-1", version: null },
  evaluatedAt: "2026-11-10T00:00:00.000Z",
};

const sample = input({
  reference: [ing("a"), ing("b")],
  recipe: ["a", null],
  members: [
    member("m1", rules.halal(), {
      ruleId: "r-free",
      type: "free_text",
      freeText: "private wording",
      mapping: { status: "mapped", ingredientIds: ["b"], confirmedBy: "manager" },
    }),
    member("m2"),
  ],
  brands: [
    { ingredientId: "a", brandId: "brand-a" },
    { ingredientId: "other", brandId: "brand-x" },
  ],
});

describe("SAF-14 DAT-06 evaluateWithLog", () => {
  it("SAF-14 returns the same result as evaluate plus a traceable log record", () => {
    const { result, logRecord } = evaluateWithLog(sample, context);
    expect(result).toEqual(evaluate(sample));
    expect(logRecord).toEqual({
      logFormat: SAFETY_LOG_FORMAT,
      householdId: "hh-1",
      subject: { kind: "suggestion", id: "s-1", version: null },
      evaluatedAt: "2026-11-10T00:00:00.000Z",
      ruleSetVersion: RULE_SET_VERSION,
      referenceVersion: "unit-fixture-1",
      ingredients: [
        { ingredientId: "a", rawName: "a" },
        { ingredientId: null, rawName: "custom" },
      ],
      recordedBrands: [{ ingredientId: "a", brandId: "brand-a" }],
      members: [
        {
          memberId: "m1",
          status: "check_label",
          rules: [
            {
              ruleId: "r-halal",
              type: "halal",
              allergen: null,
              mappingStatus: null,
              mappedIngredientIds: [],
            },
            {
              ruleId: "r-free",
              type: "free_text",
              allergen: null,
              mappingStatus: "mapped",
              mappedIngredientIds: ["b"],
            },
          ],
          reasons: result.perMember[0]!.reasons,
        },
        { memberId: "m2", status: "safe", rules: [], reasons: [] },
      ],
    });
    expect(JSON.stringify(logRecord)).not.toContain("private wording");
  });

  it("SAF-14 keeps a subject version and summarizes malformed rules and ingredients safely", () => {
    const raw = {
      ...sample,
      ingredients: ["junk", { ingredientId: "", rawName: 5 }],
      recordedBrands: ["junk", { ingredientId: "a", brandId: "brand-a" }],
      members: [
        member("m1", "junk", { ruleId: "r", type: "free_text", mapping: { ingredientIds: "b" } }),
      ],
    } as unknown as CekAmanInput;
    const { logRecord } = evaluateWithLog(raw, {
      ...context,
      subject: { kind: "planned_meal", id: "p-1", version: "7" },
    });
    expect(logRecord.subject.version).toBe("7");
    expect(logRecord.ingredients).toEqual([
      { ingredientId: null, rawName: "" },
      { ingredientId: null, rawName: "" },
    ]);
    expect(logRecord.recordedBrands).toEqual([]);
    expect(logRecord.members[0]!.rules).toEqual([
      { ruleId: "", type: "", allergen: null, mappingStatus: null, mappedIngredientIds: [] },
      {
        ruleId: "r",
        type: "free_text",
        allergen: null,
        mappingStatus: null,
        mappedIngredientIds: [],
      },
    ]);
  });

  it("SAF-14 logs only well-formed recorded brands, as evaluate() uses them", () => {
    const raw = {
      ...sample,
      recordedBrands: [
        { ingredientId: 7, brandId: "brand-x" },
        { ingredientId: "a", brandId: 5 },
        { ingredientId: "a", brandId: "" },
        { ingredientId: "a", brandId: "brand-a" },
      ],
    } as unknown as CekAmanInput;
    expect(evaluateWithLog(raw, context).logRecord.recordedBrands).toEqual([
      { ingredientId: "a", brandId: "brand-a" },
    ]);
  });

  const badContexts: [string, unknown][] = [
    ["context missing", undefined],
    ["subject missing", { ...context, subject: undefined }],
    ["unknown subject kind", { ...context, subject: { ...context.subject, kind: "chat" } }],
    ["subject id missing", { ...context, subject: { kind: "suggestion", id: "" } }],
    ["household missing", { ...context, householdId: "" }],
    ["timestamp missing", { ...context, evaluatedAt: 0 }],
  ];
  it.each(badContexts)("SAF-14 refuses to evaluate without a traceable context: %s", (_n, bad) => {
    expect(() => evaluateWithLog(sample, bad as SafetyLogContext)).toThrow(CekAmanInputError);
  });
});
