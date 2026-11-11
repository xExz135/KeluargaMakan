import { describe, expect, it } from "vitest";

import { apiConfigFromEnv, defaultApiConfig, resolveApiConfig } from "./api.js";

describe("api config (T-017)", () => {
  it("ACC-01 defaults: a 6-digit code within the contract's 4-8 digits, short expiry, few attempts", () => {
    expect(defaultApiConfig.signInCode.length).toBe(6);
    expect(defaultApiConfig.signInCode.ttlSeconds).toBeLessThanOrEqual(15 * 60);
    expect(defaultApiConfig.signInCode.maxAttempts).toBeLessThanOrEqual(10);
    expect(Object.isFrozen(defaultApiConfig.rateLimits.codeRequestPerDestination)).toBe(true);
  });

  it("ACC-01 ACC-13 every value can be overridden without a code change", () => {
    const config = resolveApiConfig({
      signInCode: { length: 8 },
      rateLimits: { codeRequestPerClient: { limit: 3 } },
      sessions: { refreshGraceSeconds: 0 },
    });
    expect(config.signInCode.length).toBe(8);
    expect(config.signInCode.ttlSeconds).toBe(defaultApiConfig.signInCode.ttlSeconds);
    expect(config.rateLimits.codeRequestPerClient).toEqual({ limit: 3, windowSeconds: 3600 });
    expect(config.sessions.refreshGraceSeconds).toBe(0);
  });

  it("rejects unknown keys and out-of-range values", () => {
    expect(() => resolveApiConfig({ signInCode: { lenght: 6 } } as never)).toThrow(/Unknown/);
    expect(() => resolveApiConfig({ signInCode: { length: 3 } })).toThrow(/4-8/);
    expect(() => resolveApiConfig({ signInCode: { length: 9 } })).toThrow(/4-8/);
    expect(() => resolveApiConfig({ sessions: { refreshGraceSeconds: 3600 } })).toThrow(/grace/);
    expect(() => resolveApiConfig({ sessions: { accessTokenTtlSeconds: 7200 } })).toThrow(/1 hour/);
    expect(() => resolveApiConfig({ rateLimits: { refreshPerClient: { limit: 0 } } })).toThrow(
      /rate limit/,
    );
    expect(() => resolveApiConfig({ signInCode: { length: "6" } } as never)).toThrow(/number/);
  });

  it("L5 outside local and test: code length at least 6 and at most 5 attempts", () => {
    for (const appEnv of ["production", "staging", undefined, "unknown"]) {
      expect(() => resolveApiConfig({ signInCode: { length: 4 } }, { appEnv })).toThrow(
        /at least 6/,
      );
      expect(() => resolveApiConfig({ signInCode: { maxAttempts: 6 } }, { appEnv })).toThrow(
        /at most 5/,
      );
    }
    expect(
      resolveApiConfig({ signInCode: { length: 4, maxAttempts: 10 } }, { appEnv: "test" }),
    ).toBeTruthy();
    expect(() =>
      apiConfigFromEnv({ APP_ENV: "production", API_CONFIG_JSON: '{"signInCode":{"length":4}}' }),
    ).toThrow(/at least 6/);
  });

  it("M1 per-destination daily caps exist, with floors outside local and test", () => {
    expect(defaultApiConfig.rateLimits.codeVerifyFailuresPerDestination.windowSeconds).toBe(86_400);
    expect(defaultApiConfig.rateLimits.codeRequestPerDestinationDaily.windowSeconds).toBe(86_400);
    const weak = [
      { codeVerifyFailuresPerDestination: { limit: 100 } },
      { codeVerifyFailuresPerDestination: { windowSeconds: 3600 } },
      { codeRequestPerDestinationDaily: { limit: 50 } },
      { codeRequestPerDestinationDaily: { windowSeconds: 3600 } },
    ];
    for (const rateLimits of weak) {
      expect(
        () => resolveApiConfig({ rateLimits }, { appEnv: "production" }),
        JSON.stringify(rateLimits),
      ).toThrow(/outside local and test/);
      expect(resolveApiConfig({ rateLimits }, { appEnv: "local" })).toBeTruthy();
    }
  });

  it("reads overrides from API_CONFIG_JSON", () => {
    expect(apiConfigFromEnv({}).signInCode.length).toBe(6);
    expect(
      apiConfigFromEnv({ API_CONFIG_JSON: '{"signInCode":{"ttlSeconds":300}}' }).signInCode
        .ttlSeconds,
    ).toBe(300);
    expect(() => apiConfigFromEnv({ API_CONFIG_JSON: "{" })).toThrow(/not valid JSON/);
  });
});
