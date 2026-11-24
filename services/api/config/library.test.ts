import { describe, expect, it } from "vitest";

import { defaultLibraryConfig, libraryConfigFromEnv, resolveLibraryConfig } from "./library.js";

describe("library config (T-041)", () => {
  it("LIB-08 SUG-03 defaults: 20 per page, at most 50, Indonesian only", () => {
    expect(libraryConfigFromEnv({})).toBe(defaultLibraryConfig);
    expect(defaultLibraryConfig.search).toEqual({
      defaultLimit: 20,
      maxLimit: 50,
      maxCandidatesChecked: 1000,
    });
    expect(defaultLibraryConfig.rateLimits.requestsPerHousehold).toEqual({
      limit: 120,
      windowSeconds: 60,
    });
    expect(defaultLibraryConfig.images.maxBytes).toBe(1024 * 1024);
    expect(defaultLibraryConfig.servedCuisines).toEqual(["indonesian"]);
  });

  it("LIB-08 values change through LIBRARY_CONFIG_JSON without a code change", () => {
    const config = libraryConfigFromEnv({
      LIBRARY_CONFIG_JSON: JSON.stringify({ search: { maxLimit: 10 }, maxRegionalVariants: 3 }),
    });
    expect(config.search).toEqual({ defaultLimit: 10, maxLimit: 10, maxCandidatesChecked: 1000 });
    expect(config.maxRegionalVariants).toBe(3);
  });

  it.each([
    [{ unknown: 1 }, /Unknown library config/],
    [{ search: { maxLimit: 51 } }, /1 to 50/],
    [{ search: { maxLimit: 10, defaultLimit: 11 } }, /1 to 10/],
    [{ servedCuisines: [] }, /non-empty/],
    [{ servedCuisines: ["indonesian", "indonesian"] }, /repeats/],
    [{ servedCuisines: ["korean"] }, /Cuisine/],
    [{ rateLimits: { searchPerSecond: 1 } }, /Unknown library config/],
    [{ rateLimits: { requestsPerHousehold: { limit: 0 } } }, /limit must be/],
    [{ images: { maxBytes: 6 * 1024 * 1024 } }, /maxBytes/],
    [{ search: { maxCandidatesChecked: 10 } }, /maxCandidatesChecked/],
  ])("LIB-08 refuses %j", (overrides, message) => {
    expect(() => resolveLibraryConfig(overrides)).toThrow(message);
  });

  it("LIB-08 refuses JSON that does not parse", () => {
    expect(() => libraryConfigFromEnv({ LIBRARY_CONFIG_JSON: "{" })).toThrow(/not valid JSON/);
  });
});
