// TEST FIXTURE: not real safety or nutrition data
import { afterEach, describe, expect, it } from "vitest";

import { evaluate, type CekAmanInput, type MemberRulesInput } from "@keluargamakan/cek-aman";

import { fixtureMembers } from "../../data/fixtures/cek-aman/members.fixture.js";
import { fixtureIngredients } from "../../data/fixtures/cek-aman/reference.fixture.js";
import { regressionCases, toInput } from "./cases.js";

/** Inherited values that would make missing data look verified, halal, plant-based and brand-stable. */
const looksSafe: Record<string, unknown> = {
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
  components: { verification: "verified", ingredientIds: [] },
  allergens: { verification: "verified", contains: [], mayContain: [] },
  halal: { verification: "verified", value: "halal", nonHalalSources: [] },
  diet: { verification: "verified", vegetarian: "suitable", vegan: "suitable" },
};

const proto = Object.prototype as Record<string, unknown>;

function cleanUp(): void {
  for (const key of Object.keys(looksSafe)) delete proto[key];
}

/** Runs `fn` with a polluted Object.prototype and always cleans up before returning. */
function whilePolluted<T>(fn: () => T): T {
  for (const key of Object.keys(looksSafe)) {
    if (Object.hasOwn(proto, key)) throw new Error(`Object.prototype already has ${key}`);
  }
  try {
    Object.assign(proto, looksSafe);
    return fn();
  } finally {
    cleanUp();
  }
}

afterEach(() => {
  cleanUp();
  expect(Object.keys(proto)).toEqual([]);
});

const membersWithRules: readonly MemberRulesInput[] = Object.values(fixtureMembers).filter(
  (member) => member.hardRules.length > 0,
);

describe("SAF-01 NFR-07 Cek Aman with a polluted Object.prototype", () => {
  it("NFR-07 every regression case gives the same result as with a clean prototype", () => {
    const baseline = regressionCases.map((testCase) => evaluate(toInput(testCase)));
    const polluted = whilePolluted(() =>
      regressionCases.map((testCase) => evaluate(toInput(testCase))),
    );
    expect(polluted).toEqual(baseline);
  });

  it("SAF-07 SAF-08 SAF-09 a reference record stripped of its safety data is never safe, even with inherited safe-looking values", () => {
    const stripped = fixtureIngredients.map(({ id, displayName }) => ({ id, displayName }));
    const inputFor = (id: string): CekAmanInput => ({
      ingredients: [{ ingredientId: id, rawName: id }],
      recordedBrands: [],
      members: membersWithRules,
      reference: {
        schema: "keluargamakan.reference.ingredients/1",
        version: "TEST-FIXTURE-stripped",
        ingredients: stripped as never,
      },
    });
    const results = whilePolluted(() =>
      stripped.map(({ id }) => [id, evaluate(inputFor(id))] as const),
    );
    expect(results.length).toBeGreaterThan(20);
    for (const [id, result] of results) {
      for (const member of result.perMember) {
        expect(member.status, `${id} for ${member.memberId}`).not.toBe("safe");
      }
    }
  });
});
