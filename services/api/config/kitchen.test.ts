// TEST FIXTURE: not real safety or nutrition data. Fictional reference IDs (fx_ prefix).
import { describe, expect, it } from "vitest";

import { defaultKitchenConfig, kitchenConfigFromEnv, resolveKitchenConfig } from "./kitchen.js";

describe("kitchen config (T-031)", () => {
  it("KIT-07 no default staples are authored by agents: empty and pending content review", () => {
    expect(defaultKitchenConfig.defaultStaples).toEqual([]);
    expect(defaultKitchenConfig.pendingContentReview).toBe(true);
    expect(kitchenConfigFromEnv({})).toBe(defaultKitchenConfig);
  });

  it("KIT-07 the staples come from configuration with a KIT-03 category each", () => {
    const config = kitchenConfigFromEnv({
      KITCHEN_CONFIG_JSON: JSON.stringify({
        defaultStaples: [{ ingredientId: "fx_cfg_beras", category: "staples" }],
      }),
    });
    expect(config.defaultStaples).toEqual([{ ingredientId: "fx_cfg_beras", category: "staples" }]);
    expect(config.pendingContentReview).toBe(false);
  });

  it.each([
    [{ unknown: 1 }, /Unknown kitchen config/],
    [{ defaultStaples: {} }, /must be a list/],
    [{ defaultStaples: [{ ingredientId: "Not An Id", category: "staples" }] }, /reference/],
    [{ defaultStaples: [{ ingredientId: "fx_a", category: "sayur" }] }, /KIT-03/],
    [{ defaultStaples: [{ ingredientId: "fx_a", category: "staples", extra: 1 }] }, /Unknown/],
    [
      {
        defaultStaples: [
          { ingredientId: "fx_a", category: "staples" },
          { ingredientId: "fx_a", category: "dairy" },
        ],
      },
      /repeats/,
    ],
    [{ maxItemsPerHousehold: 0 }, /maxItemsPerHousehold/],
    [{ maxItemsPerHousehold: "500" }, /maxItemsPerHousehold/],
    [{ search: { maxResults: 51 } }, /maxResults/],
    [{ search: { maxResults: 10, defaultResults: 11 } }, /defaultResults/],
  ])("refuses %j", (overrides, message) => {
    expect(() => resolveKitchenConfig(overrides)).toThrow(message);
  });

  it("refuses invalid JSON and keys from the prototype chain", () => {
    expect(() => kitchenConfigFromEnv({ KITCHEN_CONFIG_JSON: "{" })).toThrow(/not valid JSON/);
    expect(() => resolveKitchenConfig(JSON.parse('{"__proto__":{"x":1}}'))).toThrow(/Unknown/);
  });
});
