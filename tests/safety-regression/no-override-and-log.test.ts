// TEST FIXTURE: not real safety or nutrition data
import { describe, expect, it } from "vitest";

import {
  RULE_SET_VERSION,
  SAFETY_LOG_FORMAT,
  evaluate,
  evaluateWithLog,
  type CekAmanInput,
} from "@keluargamakan/cek-aman";

import { fixtureMembers } from "../../data/fixtures/cek-aman/members.fixture.js";
import {
  FIXTURE_REFERENCE_VERSION,
  fixtureReference,
} from "../../data/fixtures/cek-aman/reference.fixture.js";

const terasiForKakak: CekAmanInput = {
  ingredients: [
    { ingredientId: "fx_nasi", rawName: "nasi" },
    { ingredientId: "fx_terasi", rawName: "terasi" },
  ],
  recordedBrands: [],
  members: [fixtureMembers.kakak, fixtureMembers.ibu],
  reference: fixtureReference,
};

describe("SAF-12 no override of a Not safe result", () => {
  it("SAF-12 evaluate takes exactly one argument", () => {
    expect(evaluate.length).toBe(1);
  });

  it("SAF-12 override-like fields anywhere in the input are ignored", () => {
    const baseline = evaluate(terasiForKakak);
    expect(baseline.perMember[0]!.status).toBe("not_safe");
    const attempt = {
      ...terasiForKakak,
      override: true,
      forceSafe: true,
      members: terasiForKakak.members.map((member) => ({
        ...member,
        acknowledged: true,
        overrideNotSafe: true,
        hardRules: member.hardRules.map((rule) => ({ ...rule, active: false, override: true })),
      })),
      ingredients: terasiForKakak.ingredients.map((item) => ({ ...item, markedSafeByUser: true })),
    } as CekAmanInput;
    expect(evaluate(attempt)).toEqual(baseline);
  });

  it("SAF-12 a second argument is ignored", () => {
    const call = evaluate as unknown as (input: CekAmanInput, options: unknown) => unknown;
    expect(call(terasiForKakak, { override: true, status: "safe" })).toEqual(
      evaluate(terasiForKakak),
    );
  });
});

describe("SAF-14 DAT-06 safety result log", () => {
  const context = {
    householdId: "fx-household-1",
    subject: { kind: "library_recipe", id: "fx-recipe-nasi-goreng", version: "3" },
    evaluatedAt: "2026-11-10T12:00:00.000Z",
  } as const;

  it("SAF-14 DAT-06 every result is logged with the rule set and reference data versions", () => {
    const { result, logRecord } = evaluateWithLog(terasiForKakak, context);
    expect(result).toEqual(evaluate(terasiForKakak));
    expect(logRecord).toMatchObject({
      logFormat: SAFETY_LOG_FORMAT,
      householdId: "fx-household-1",
      subject: context.subject,
      evaluatedAt: context.evaluatedAt,
      ruleSetVersion: RULE_SET_VERSION,
      referenceVersion: FIXTURE_REFERENCE_VERSION,
    });
    expect(logRecord.members.map((m) => [m.memberId, m.status])).toEqual([
      ["fx-member-kakak", "not_safe"],
      ["fx-member-ibu", "safe"],
    ]);
    expect(logRecord.members[0]!.reasons).toEqual(result.perMember[0]!.reasons);
  });

  it("SAF-14 AI-03 the log holds rule IDs but no free-text rule wording", () => {
    const { logRecord } = evaluateWithLog(
      { ...terasiForKakak, members: [fixtureMembers.om, fixtureMembers.nenek] },
      context,
    );
    const text = JSON.stringify(logRecord);
    expect(text).toContain("fx-rule-om-freetext");
    expect(text).not.toContain("fixture: allergic to a fruit");
    expect(text).not.toContain("fixture: avoid durian");
  });
});
