import { describe, expect, it } from "vitest";

import {
  FREE_TEXT_MAX,
  HARD_RULE_BODY_MAX_BYTES,
  HARD_RULE_PADDED_BYTES,
  MAPPED_INGREDIENTS_MAX,
  RuleBodyError,
  decodeRuleBody,
  encodeRuleBody,
  parseRuleBody,
  toCekAmanRule,
  type HardRuleBody,
} from "./hard-rule-codec.js";

const at = "2026-11-11T00:00:00.000Z";
const allergy: HardRuleBody = {
  v: 1,
  type: "allergy",
  allergen: "peanut",
  freeText: null,
  mapping: null,
};
const freeText: HardRuleBody = {
  v: 1,
  type: "free_text",
  allergen: null,
  freeText: "tidak boleh contoh",
  mapping: { status: "unmapped", ingredientIds: [], confirmedBy: null, updatedAt: at },
};

describe("PRF-03 PRF-08 hard rule body", () => {
  it("round-trips every rule type", () => {
    const bodies: HardRuleBody[] = [
      allergy,
      { v: 1, type: "halal", allergen: null, freeText: null, mapping: null },
      { v: 1, type: "vegetarian", allergen: null, freeText: null, mapping: null },
      { v: 1, type: "vegan", allergen: null, freeText: null, mapping: null },
      freeText,
      {
        v: 1,
        type: "medical_exclusion",
        allergen: null,
        freeText: null,
        mapping: {
          status: "mapped",
          ingredientIds: ["example_ingredient"],
          confirmedBy: "manager",
          updatedAt: at,
        },
      },
    ];
    for (const body of bodies) expect(decodeRuleBody(encodeRuleBody(body))).toEqual(body);
  });

  it.each([
    ["unknown type", { ...allergy, type: "spicy" }],
    ["unknown allergen", { ...allergy, allergen: "sambal" }],
    ["allergy with free text", { ...allergy, freeText: "x" }],
    ["halal with an allergen", { ...allergy, type: "halal" }],
    ["extra field", { ...allergy, override: true }],
    ["missing field", { v: 1, type: "halal", allergen: null, freeText: null }],
    ["wrong version", { ...allergy, v: 2 }],
    ["empty free text", { ...freeText, freeText: "  " }],
    ["free text too long", { ...freeText, freeText: "x".repeat(201) }],
    ["free text without mapping", { ...freeText, mapping: null }],
    [
      "PRF-08 mapped without confirmer",
      {
        ...freeText,
        mapping: { status: "mapped", ingredientIds: ["a"], confirmedBy: null, updatedAt: at },
      },
    ],
    [
      "PRF-08 mapped with an AI confirmer",
      {
        ...freeText,
        mapping: { status: "mapped", ingredientIds: ["a"], confirmedBy: "ai", updatedAt: at },
      },
    ],
    [
      "PRF-08 mapped without ingredients",
      {
        ...freeText,
        mapping: { status: "mapped", ingredientIds: [], confirmedBy: "manager", updatedAt: at },
      },
    ],
    [
      "PRF-08 proposed with a confirmer",
      {
        ...freeText,
        mapping: {
          status: "proposed",
          ingredientIds: ["a"],
          confirmedBy: "manager",
          updatedAt: at,
        },
      },
    ],
    [
      "unmapped with ingredients",
      {
        ...freeText,
        mapping: { status: "unmapped", ingredientIds: ["a"], confirmedBy: null, updatedAt: at },
      },
    ],
    [
      "duplicate ingredient IDs",
      {
        ...freeText,
        mapping: {
          status: "proposed",
          ingredientIds: ["a", "a"],
          confirmedBy: null,
          updatedAt: at,
        },
      },
    ],
    [
      "non-reference ingredient ID",
      {
        ...freeText,
        mapping: {
          status: "proposed",
          ingredientIds: ["Udang Galah"],
          confirmedBy: null,
          updatedAt: at,
        },
      },
    ],
    ["bad timestamp", { ...freeText, mapping: { ...freeText.mapping, updatedAt: "yesterday" } }],
    ["not an object", ["allergy"]],
  ])("rejects %s", (_name, raw) => {
    expect(() => parseRuleBody(raw)).toThrow(RuleBodyError);
  });

  it("rejects non-JSON", () => {
    expect(() => decodeRuleBody("{not json")).toThrow(RuleBodyError);
  });

  it("ignores inherited properties (prototype pollution cannot fill a field)", () => {
    const proto = { allergen: "peanut", freeText: null, mapping: null };
    const raw = Object.assign(Object.create(proto) as object, { v: 1, type: "allergy" });
    expect(() => parseRuleBody(raw)).toThrow(RuleBodyError);
  });
});

describe("PRF-08 SAF-09 conversion to the Cek Aman rule shape", () => {
  it("maps each type to the engine input", () => {
    expect(toCekAmanRule("r1", allergy)).toEqual({
      ruleId: "r1",
      type: "allergy",
      allergen: "peanut",
    });
    expect(toCekAmanRule("r2", freeText)).toEqual({
      ruleId: "r2",
      type: "free_text",
      freeText: "tidak boleh contoh",
      mapping: { status: "unmapped" },
    });
    expect(
      toCekAmanRule("r3", {
        ...freeText,
        type: "medical_exclusion",
        freeText: null,
        mapping: { status: "proposed", ingredientIds: ["a"], confirmedBy: null, updatedAt: at },
      }),
    ).toEqual({
      ruleId: "r3",
      type: "medical_exclusion",
      freeText: null,
      mapping: { status: "proposed", ingredientIds: ["a"] },
    });
  });

  it("a mapped rule keeps its confirmer; anything less stays unconfirmed (fail closed)", () => {
    const mapped = toCekAmanRule("r4", {
      ...freeText,
      mapping: {
        status: "mapped",
        ingredientIds: ["a"],
        confirmedBy: "content_team",
        updatedAt: at,
      },
    });
    expect(mapped).toMatchObject({ mapping: { status: "mapped", confirmedBy: "content_team" } });
    const forged = toCekAmanRule("r5", {
      ...freeText,
      mapping: { status: "mapped", ingredientIds: ["a"], confirmedBy: null, updatedAt: at },
    });
    expect(forged).toMatchObject({ mapping: { status: "unmapped" } });
  });
});

describe("N1 every valid rule body fits the fixed padded size", () => {
  it("N1 the largest valid body fits HARD_RULE_PADDED_BYTES with room to spare", () => {
    // Worst case: 200 characters that JSON escapes to 6 bytes each, 20 mapped
    // IDs of the maximum 100 characters, the longest type, status and confirmer.
    const worst: HardRuleBody = {
      v: 1,
      type: "medical_exclusion",
      allergen: null,
      freeText: "\u0001".repeat(FREE_TEXT_MAX),
      mapping: {
        status: "mapped",
        ingredientIds: Array.from({ length: MAPPED_INGREDIENTS_MAX }, (_, i) =>
          `a${String(i).padStart(2, "0")}`.padEnd(100, "z"),
        ),
        confirmedBy: "content_team",
        updatedAt: "2026-11-11T00:00:00.000Z",
      },
    };
    const json = encodeRuleBody(worst);
    const bytes = Buffer.byteLength(json, "utf8");
    expect(bytes).toBeGreaterThan(3_000);
    expect(bytes).toBeLessThanOrEqual(HARD_RULE_BODY_MAX_BYTES);
    expect(HARD_RULE_BODY_MAX_BYTES).toBe(HARD_RULE_PADDED_BYTES - 4);
    // Astral characters (4 UTF-8 bytes per 2 UTF-16 units) and lone surrogates
    // (escaped to 6 bytes) are not worse than control characters.
    for (const freeText of ["😀".repeat(100), "\ud800".repeat(FREE_TEXT_MAX)]) {
      expect(Buffer.byteLength(encodeRuleBody({ ...worst, freeText }), "utf8")).toBeLessThanOrEqual(
        bytes,
      );
    }
  });
});
