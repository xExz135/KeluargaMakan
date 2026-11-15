import { describe, expect, it } from "vitest";

import { isDevelopmentEnv, resolveAppEnv } from "./app-env.js";
import { parseTrustedProxies } from "./auth/client-address.js";
import { loadAuthSecrets } from "./auth/secrets.js";
import {
  requireReferenceOutsideDevelopment,
  unavailableReference,
} from "./reference/reference-data.js";

/**
 * Security review 2026-11-15 I2: APP_ENV is matched exactly. Only `local`
 * and `test` unlock the development shortcuts; whitespace and case variants
 * are unknown values and count as production. (The dev code sender, local
 * key provider, fixture catalog and config floors are covered in
 * local/local-server.test.ts.)
 */
const VARIANTS = [" local", "local ", "LOCAL", "Local", "test\n", " test", "\tlocal", "TEST"];

describe("NFR-10 exact APP_ENV matching", () => {
  it("resolves the four names exactly", () => {
    expect(resolveAppEnv("local")).toBe("local");
    expect(resolveAppEnv("test")).toBe("test");
    expect(resolveAppEnv("staging")).toBe("staging");
    expect(resolveAppEnv("production")).toBe("production");
    expect(isDevelopmentEnv("local")).toBe(true);
    expect(isDevelopmentEnv("test")).toBe(true);
  });

  it.each([...VARIANTS, " staging", undefined, ""])("%j counts as production", (value) => {
    expect(resolveAppEnv(value)).toBe("production");
    expect(isDevelopmentEnv(value)).toBe(false);
  });

  it.each(VARIANTS)("%j needs real auth keys", (APP_ENV) => {
    expect(() => loadAuthSecrets({ APP_ENV })).toThrow(/required outside APP_ENV local and test/);
    expect(() => loadAuthSecrets({ APP_ENV: "local" })).not.toThrow();
  });

  it.each(VARIANTS)("%j refuses trusting every proxy hop", (APP_ENV) => {
    expect(() => parseTrustedProxies("*", APP_ENV)).toThrow(/refused in APP_ENV production/);
  });

  it.each(VARIANTS)("%j does not start without a verified reference dataset", (APP_ENV) => {
    expect(() => requireReferenceOutsideDevelopment(unavailableReference, APP_ENV)).toThrow(
      /required outside APP_ENV local and test/,
    );
    expect(() => requireReferenceOutsideDevelopment(unavailableReference, "local")).not.toThrow();
  });
});
