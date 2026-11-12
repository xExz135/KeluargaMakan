import { describe, expect, it } from "vitest";

import { defaultTargets, resolveTargets, targetsFromEnv } from "./targets.js";
import type { Target } from "./targets.js";

const allTargets = (): [string, Target<unknown>][] =>
  Object.entries(defaultTargets).flatMap(([group, entries]) =>
    Object.entries(entries as Record<string, Target<unknown>>).map(
      ([key, entry]) => [`${group}.${key}`, entry] as [string, Target<unknown>],
    ),
  );

describe("targets config", () => {
  it("every target names its SRS requirement and status", () => {
    for (const [name, entry] of allTargets()) {
      expect(entry.srsId, name).toMatch(/^[A-Z]{2,4}-\d{2}/);
      expect(["target", "confirmed"], name).toContain(entry.status);
      expect(entry.unit, name).not.toBe("");
    }
  });

  it("SUG-07 SUG-13 use the SRS target values by default", () => {
    expect(defaultTargets.suggestions.repetitionWindowDays.value).toBe(3);
    expect(defaultTargets.suggestions.latencyP90Ms.value).toBe(5_000);
  });

  it("DAT-05 DAT-04 SET-04 retention and deletion windows use the SRS target values (QUESTIONS #19)", () => {
    expect(defaultTargets.dataManagement.safetyLogRetentionYears.value).toBe(2);
    expect(defaultTargets.dataManagement.mealHistoryRetentionYears.value).toBe(2);
    expect(defaultTargets.dataManagement.mealHistoryRetentionYears.srsId).toBe("DAT-04");
    expect(defaultTargets.dataManagement.healthConsentWithdrawalDeletionDays.value).toBe(30);
  });

  it("AI-09 has no plan limit until the business model sets one", () => {
    expect(defaultTargets.aiCost.monthlyLimitPerHousehold.value).toBeNull();
  });

  it("overrides replace values without a code change and keep traceability", () => {
    const resolved = resolveTargets({ notifications: { maxPerDayDefault: 1 } });
    expect(resolved.notifications.maxPerDayDefault.value).toBe(1);
    expect(resolved.notifications.maxPerDayDefault.srsId).toBe("NTF-03");
    expect(resolved.household.maxProfiles.value).toBe(12);
    expect(defaultTargets.notifications.maxPerDayDefault.value).toBe(2);
  });

  it("rejects unknown override keys", () => {
    expect(() => resolveTargets({ nope: {} } as never)).toThrow(/Unknown target group/);
    expect(() => resolveTargets({ household: { maxProfile: 3 } } as never)).toThrow(
      /Unknown target: household\.maxProfile/,
    );
  });

  it("PRF-02 the profile limit is a target with a floor of 12", () => {
    expect(defaultTargets.household.maxProfiles).toMatchObject({
      value: 12,
      srsId: "PRF-02",
      status: "target",
    });
    expect(resolveTargets({ household: { maxProfiles: 16 } }).household.maxProfiles.value).toBe(16);
    for (const value of [11, 0, -1, 12.5, 101]) {
      expect(() => resolveTargets({ household: { maxProfiles: value } }), String(value)).toThrow(
        /PRF-02/,
      );
    }
  });

  it("SET-04 the withdrawal deletion window cannot exceed 30 days", () => {
    expect(() =>
      resolveTargets({ dataManagement: { healthConsentWithdrawalDeletionDays: 31 } }),
    ).toThrow(/SET-04/);
  });

  it("TARGETS_JSON overrides values and rejects bad JSON", () => {
    expect(
      targetsFromEnv({ TARGETS_JSON: '{"household":{"maxProfiles":14}}' }).household.maxProfiles
        .value,
    ).toBe(14);
    expect(targetsFromEnv({}).household.maxProfiles.value).toBe(12);
    expect(() => targetsFromEnv({ TARGETS_JSON: "{" })).toThrow(/not valid JSON/);
    expect(() => targetsFromEnv({ TARGETS_JSON: "[]" })).toThrow(/must be an object/);
  });

  it("is immutable", () => {
    expect(Object.isFrozen(defaultTargets.household.maxProfiles)).toBe(true);
  });
});
