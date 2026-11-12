import { describe, expect, it } from "vitest";

import { defaultProfileConfig, profileConfigFromEnv, resolveProfileConfig } from "./profiles.js";

describe("profile config (PRF-07)", () => {
  it("PRF-07 every age group has a default; the neutral placeholder waits for the content team (QUESTIONS #30)", () => {
    for (const group of ["infant", "child", "teen", "adult", "elderly"] as const) {
      expect(defaultProfileConfig.portionDefaults[group]).toEqual({
        portionSize: "normal",
        ricePortion: "normal",
      });
    }
    expect(defaultProfileConfig.pendingContentReview).toBe(true);
  });

  it("PRF-07 defaults per age group change without a code change", () => {
    const config = profileConfigFromEnv({
      PROFILE_CONFIG_JSON:
        '{"portionDefaults":{"infant":{"portionSize":"small","ricePortion":"small"}}}',
    });
    expect(config.portionDefaults.infant).toEqual({ portionSize: "small", ricePortion: "small" });
    expect(config.portionDefaults.adult.portionSize).toBe("normal");
    expect(config.pendingContentReview).toBe(true);
  });

  it("PRF-07 unknown keys, age groups and values stop startup", () => {
    expect(() => resolveProfileConfig({ other: {} })).toThrow(/Unknown profile config/);
    expect(() => resolveProfileConfig({ portionDefaults: { toddler: {} } })).toThrow(
      /Unknown age group/,
    );
    expect(() =>
      resolveProfileConfig({
        portionDefaults: { child: { portionSize: "tiny", ricePortion: "small" } },
      }),
    ).toThrow(/small, normal or large/);
    expect(() => profileConfigFromEnv({ PROFILE_CONFIG_JSON: "{" })).toThrow(/not valid JSON/);
  });
});
