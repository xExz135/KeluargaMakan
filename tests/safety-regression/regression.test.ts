// TEST FIXTURE: not real safety or nutrition data
import { describe, expect, it } from "vitest";

import {
  RULE_SET_VERSION,
  evaluate,
  type CekAmanInput,
  type MemberRulesInput,
} from "@keluargamakan/cek-aman";

import { fixtureMembers } from "../../data/fixtures/cek-aman/members.fixture.js";
import {
  FIXTURE_REFERENCE_VERSION,
  fixtureIngredients,
  fixtureReference,
} from "../../data/fixtures/cek-aman/reference.fixture.js";
import { NOT_SAFE_KINDS, regressionCases, toInput, type RegressionCase } from "./cases.js";

const label = (c: RegressionCase): string => `${c.id} [${c.requirements.join(", ")}] ${c.title}`;

const membersWithRules: readonly MemberRulesInput[] = Object.values(fixtureMembers).filter(
  (member) => member.hardRules.length > 0,
);

describe("NFR-07 Cek Aman regression cases", () => {
  it("NFR-07 the suite has cases and unique IDs", () => {
    expect(regressionCases.length).toBeGreaterThan(30);
    expect(new Set(regressionCases.map((c) => c.id)).size).toBe(regressionCases.length);
  });

  it.each(regressionCases.map((c) => [label(c), c] as const))("%s", (_name, testCase) => {
    const result = evaluate(toInput(testCase));
    const expected = Object.entries(testCase.expect);

    // PRF-11: results for exactly the selected members, in order.
    expect(result.perMember.map((m) => m.memberId)).toEqual(
      expected.map(([key]) => fixtureMembers[key as keyof typeof fixtureMembers].memberId),
    );
    expect(result.ruleSetVersion).toBe(RULE_SET_VERSION);
    // DAT-06: the version of the dataset actually used.
    expect(result.referenceVersion).toBe(testCase.reference?.version ?? FIXTURE_REFERENCE_VERSION);

    expected.forEach(([key, expectation], index) => {
      const [status, ...codes] = expectation;
      const member = result.perMember[index]!;
      expect(member.status, `${key} status`).toBe(status);
      const found = member.reasons.map((reason) => reason.code);
      for (const code of codes) expect(found, `${key} reasons`).toContain(code);
      if (status === "safe") expect(member.reasons).toEqual([]);
    });
  });
});

describe("SAF acceptance criteria", () => {
  it("SAF-03 SAF-06 acceptance: every known unsafe combination is blocked in 100% of cases", () => {
    let blocked = 0;
    for (const testCase of regressionCases) {
      const result = evaluate(toInput(testCase));
      Object.values(testCase.expect).forEach((expectation, index) => {
        if (expectation[0] !== "not_safe") return;
        expect(result.perMember[index]!.status, label(testCase)).toBe("not_safe");
        blocked += 1;
      });
    }
    expect(blocked).toBeGreaterThanOrEqual(20);
  });

  it("SAF-09 acceptance: an ingredient without verified component data is never safe for a member with a hard rule", () => {
    const unverified = fixtureIngredients.filter((i) => i.components.verification !== "verified");
    expect(unverified.length).toBeGreaterThan(0);
    for (const ingredient of unverified) {
      const result = evaluate({
        ingredients: [{ ingredientId: ingredient.id, rawName: ingredient.displayName.id }],
        recordedBrands: [],
        members: membersWithRules,
        reference: fixtureReference,
      });
      for (const member of result.perMember) {
        expect(member.status, `${ingredient.id} for ${member.memberId}`).not.toBe("safe");
      }
    }
  });

  it("SAF-07 acceptance: every brand-variant ingredient without a recorded brand is never safe for a member with a hard rule", () => {
    const varying = fixtureIngredients.filter((i) => i.brandVaries);
    expect(varying.length).toBeGreaterThan(0);
    for (const ingredient of varying) {
      const result = evaluate({
        ingredients: [{ ingredientId: ingredient.id, rawName: ingredient.displayName.id }],
        recordedBrands: [],
        members: membersWithRules,
        reference: fixtureReference,
      });
      for (const member of result.perMember) {
        expect(member.status, `${ingredient.id} for ${member.memberId}`).not.toBe("safe");
      }
    }
  });

  it("SAF-09 KIT-05 acceptance: custom and unknown ingredients are never safe for any member with a hard rule", () => {
    const result = evaluate({
      ingredients: [
        { ingredientId: "fx_nasi", rawName: "nasi" },
        { ingredientId: null, rawName: "bahan buatan sendiri" },
        { ingredientId: "fx_unknown_id", rawName: "bahan lain" },
      ],
      recordedBrands: [],
      members: membersWithRules,
      reference: fixtureReference,
    });
    expect(result.perMember).toHaveLength(membersWithRules.length);
    for (const member of result.perMember) expect(member.status).not.toBe("safe");
  });

  it("PRF-11 acceptance: choosing Only me removes all other members' rules from the request", () => {
    const recipe = ["fx_terasi", "fx_babi", "fx_durian", "fx_ayam"];
    const input = (members: readonly MemberRulesInput[]): CekAmanInput => ({
      ingredients: recipe.map((id) => ({ ingredientId: id, rawName: id })),
      recordedBrands: [],
      members,
      reference: fixtureReference,
    });
    const family = evaluate(input(Object.values(fixtureMembers)));
    expect(family.perMember.some((m) => m.status === "not_safe")).toBe(true);
    const onlyMe = evaluate(input([fixtureMembers.ibu]));
    expect(onlyMe.perMember).toEqual([{ memberId: "fx-member-ibu", status: "safe", reasons: [] }]);
  });

  it("SAF-04 SAF-05 a Not safe result names the ingredient and the rule it breaks", () => {
    const result = evaluate({
      ingredients: [{ ingredientId: "fx_terasi", rawName: "terasi" }],
      recordedBrands: [],
      members: [fixtureMembers.kakak],
      reference: fixtureReference,
    });
    const [first] = result.perMember[0]!.reasons;
    expect(first).toMatchObject({
      kind: "contains",
      code: "allergen_contains",
      detail: "shrimp",
      ingredient: { index: 0, ingredientId: "fx_terasi", rawName: "terasi" },
      rule: { ruleId: "fx-rule-kakak-shrimp", type: "allergy", allergen: "shrimp" },
    });
  });

  it("SAF-04 every reason of a Check the label result is an uncertainty, and Not safe outranks it", () => {
    for (const testCase of regressionCases) {
      for (const member of evaluate(toInput(testCase)).perMember) {
        const hasNotSafe = member.reasons.some((r) => NOT_SAFE_KINDS.includes(r.kind));
        if (member.status === "check_label") expect(hasNotSafe).toBe(false);
        if (member.status === "not_safe") {
          expect(NOT_SAFE_KINDS).toContain(member.reasons[0]!.kind);
        }
      }
    }
  });
});
