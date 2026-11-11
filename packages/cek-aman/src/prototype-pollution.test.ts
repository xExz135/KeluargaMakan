// TEST FIXTURE: not real safety or nutrition data
import { afterEach, describe, expect, it } from "vitest";

import { CekAmanInputError, evaluate, evaluateWithLog, type SafetyLogContext } from "./index.js";
import { ing, input, member, rules } from "./test-fixtures.js";
import type { CekAmanInput, CekAmanResult } from "./types.js";

/**
 * Values that would turn missing data into "Safe" if the engine read inherited
 * properties: verified, halal, plant-based, no allergens, no brand variation,
 * a confirmed mapping, and a resolved ingredient ID.
 */
const looksSafe = {
  verification: "verified",
  value: "halal",
  nonHalalSources: [],
  ingredientIds: [],
  contains: [],
  mayContain: [],
  vegetarian: "suitable",
  vegan: "suitable",
  brandVaries: false,
  verified: true,
  status: "mapped",
  confirmedBy: "manager",
  ingredientId: "plain",
};
const nested = {
  components: { verification: "verified", ingredientIds: [] },
  allergens: { verification: "verified", contains: [], mayContain: [] },
  halal: { verification: "verified", value: "halal", nonHalalSources: [] },
  diet: { verification: "verified", vegetarian: "suitable", vegan: "suitable" },
  mapping: { status: "mapped", ingredientIds: ["plain"], confirmedBy: "manager" },
};

const proto = Object.prototype as Record<string, unknown>;
const polluted: string[] = [];

/** Assigns enumerable properties on Object.prototype, as a pollution bug would. */
function pollute(values: Record<string, unknown>): void {
  for (const [key, value] of Object.entries(values)) {
    if (Object.hasOwn(proto, key)) throw new Error(`Object.prototype already has ${key}`);
    proto[key] = value;
    polluted.push(key);
  }
}

function cleanUp(): void {
  for (const key of polluted.splice(0)) delete proto[key];
}

/** Runs `fn` with a polluted Object.prototype and always cleans up before returning. */
function whilePolluted<T>(values: Record<string, unknown>, fn: () => T): T {
  try {
    pollute(values);
    return fn();
  } finally {
    cleanUp();
  }
}

afterEach(() => {
  cleanUp();
  expect(Object.keys(proto)).toEqual([]);
});

const plain = ing("plain");
const allRules = [
  rules.halal(),
  rules.vegetarian(),
  rules.vegan(),
  rules.allergy("egg"),
  { ruleId: "r-free", type: "free_text", freeText: "fixture" },
];

/** A recipe whose records and entries lack every safety field. */
const bare: CekAmanInput = {
  ingredients: [
    { ingredientId: "bare", rawName: "bare" },
    { rawName: "no id" },
  ] as CekAmanInput["ingredients"],
  recordedBrands: [],
  members: [member("m", ...allRules)],
  reference: {
    schema: "keluargamakan.reference.ingredients/1",
    version: "unit-fixture-1",
    ingredients: [{ id: "bare" } as never, plain],
  },
};

describe("SAF-01 SAF-07 SAF-08 a polluted Object.prototype never makes missing data safe", () => {
  it("SAF-01 records missing every field stay check_label for every rule", () => {
    const clean = evaluate(bare);
    const dirty = whilePolluted({ ...looksSafe, ...nested }, () => evaluate(bare));
    expect(dirty).toEqual(clean);
    expect(dirty.perMember[0]!.status).toBe("check_label");
    const found = new Set(dirty.perMember[0]!.reasons.map((r) => r.code));
    for (const code of [
      "rule_invalid",
      "ingredient_unresolved",
      "brand_not_recorded",
      "components_unverified",
      "halal_uncertain",
      "diet_uncertain",
      "allergens_unverified",
    ] as const) {
      expect(found, code).toContain(code);
    }
  });

  it("SAF-01 flat inherited values are ignored as well as nested ones", () => {
    const sauce = {
      id: "sauce",
      components: {},
      allergens: {},
      halal: {},
      diet: {},
      brandVariants: [{ brandId: "b" }],
    };
    const raw = input({
      reference: [sauce as never],
      recipe: ["sauce"],
      members: [member("m", ...allRules)],
      brands: [{ ingredientId: "sauce", brandId: "b" }],
    });
    const clean = evaluate(raw);
    const dirty = whilePolluted(looksSafe, () => evaluate(raw));
    expect(dirty).toEqual(clean);
    expect(dirty.perMember[0]!.status).toBe("check_label");
    expect(dirty.perMember[0]!.reasons.map((r) => r.code)).toContain("brand_unverified");
  });

  it("SAF-09 a hole in a list is never filled from the prototype", () => {
    const raw = input({ reference: [plain], recipe: [], members: [member("m", rules.halal())] });
    const holey = { ...raw, ingredients: new Array(1) } as CekAmanInput;
    const dirty = whilePolluted({ 0: { ingredientId: "plain", rawName: "plain" } }, () =>
      evaluate(holey),
    );
    expect(dirty.perMember[0]!.status).toBe("check_label");
    expect(dirty.perMember[0]!.reasons.map((r) => r.code)).toEqual(["ingredient_unresolved"]);
  });

  it("SAF-01 inherited top-level input fields are not used", () => {
    const { reference, members, recordedBrands, ingredients } = input({
      reference: [plain],
      recipe: ["plain"],
      members: [member("m", rules.halal())],
    });
    expect(() =>
      whilePolluted({ reference, members, recordedBrands, ingredients }, () =>
        evaluate({} as CekAmanInput),
      ),
    ).toThrow(CekAmanInputError);
  });

  it("SAF-14 the log context and log record use own properties only", () => {
    const context: SafetyLogContext = {
      householdId: "hh-1",
      subject: { kind: "suggestion", id: "s-1", version: null },
      evaluatedAt: "2026-11-10T00:00:00.000Z",
    };
    expect(() =>
      whilePolluted({ householdId: "hh-evil" }, () =>
        evaluateWithLog(bare, { ...context, householdId: undefined } as never),
      ),
    ).toThrow(CekAmanInputError);
    let result: CekAmanResult | undefined;
    const { logRecord } = whilePolluted({ ...looksSafe, brandId: "inherited" }, () => {
      const out = evaluateWithLog(bare, context);
      result = out.result;
      return out;
    });
    expect(result).toEqual(evaluate(bare));
    expect(logRecord.ingredients).toEqual([
      { ingredientId: "bare", rawName: "bare" },
      { ingredientId: null, rawName: "no id" },
    ]);
    expect(logRecord.recordedBrands).toEqual([]);
  });
});
