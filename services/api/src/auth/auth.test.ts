// TEST FIXTURE: not real safety or nutrition data. Fictional destinations only.
import { randomBytes, randomUUID } from "node:crypto";

import { describe, expect, it } from "vitest";

import { ApiError } from "../api-error.js";
import { KeyServiceError } from "../db/crypto/key-provider.js";
import { ConcurrentUpdateError, RulesUnavailableError, translateDbError } from "../db/errors.js";
import { toProblem } from "../http/problem.js";
import { signAccessToken, verifyAccessToken } from "./access-token.js";
import {
  createCodeSender,
  DevCodeSender,
  UnavailableCodeSender,
  CodeSenderUnavailableError,
} from "./code-sender.js";
import { constantTimeEqual, keyedHash, randomDigits, randomToken } from "./crypto.js";
import { normalizeDestination } from "./destination.js";
import { AuthSecretsError, loadAuthSecrets } from "./secrets.js";

const key32 = () => randomBytes(32).toString("base64");

describe("APP_ENV: missing or unknown counts as production", () => {
  it("ACC-01 Q16 the development code sender is refused outside local and test", () => {
    expect(() => new DevCodeSender({ appEnv: "local" })).not.toThrow();
    expect(() => new DevCodeSender({ appEnv: "test" })).not.toThrow();
    for (const appEnv of ["staging", "production", undefined, "", "dev", "LOCAL", "testing"]) {
      expect(() => new DevCodeSender({ appEnv }), String(appEnv)).toThrow(/refused/);
      expect(() => createCodeSender({ APP_ENV: appEnv, CODE_SENDER: "dev" })).toThrow(/refused/);
    }
  });

  it("ACC-01 Q16 without CODE_SENDER no code is sent to any vendor: sign-in is unavailable", async () => {
    const sender = createCodeSender({ APP_ENV: "production" });
    expect(sender).toBeInstanceOf(UnavailableCodeSender);
    await expect(
      sender.send({
        challengeId: randomUUID(),
        channel: "phone",
        destination: "+62990000000",
        code: "123456",
        language: "id",
        expiresAt: new Date(),
      }),
    ).rejects.toBeInstanceOf(CodeSenderUnavailableError);
    expect(() => createCodeSender({ CODE_SENDER: "twilio" })).toThrow(/dev or none/);
  });

  it("ACC-01 sign-in keys are required outside local and test, and must differ", () => {
    expect(() => loadAuthSecrets({})).toThrow(AuthSecretsError);
    expect(() => loadAuthSecrets({ APP_ENV: "staging", AUTH_TOKEN_KEY: key32() })).toThrow(
      /AUTH_HASH_KEY is required/,
    );
    expect(() =>
      loadAuthSecrets({
        APP_ENV: "production",
        AUTH_TOKEN_KEY: "c2hvcnQ=",
        AUTH_HASH_KEY: key32(),
      }),
    ).toThrow(/at least 32 bytes/);
    const same = key32();
    expect(() =>
      loadAuthSecrets({ APP_ENV: "production", AUTH_TOKEN_KEY: same, AUTH_HASH_KEY: same }),
    ).toThrow(/must differ/);
    const secrets = loadAuthSecrets({
      APP_ENV: "production",
      AUTH_TOKEN_KEY: key32(),
      AUTH_HASH_KEY: key32(),
    });
    expect(secrets.tokenKey.length).toBe(32);
    // local and test fall back to random per-process keys.
    expect(loadAuthSecrets({ APP_ENV: "test" }).hashKey.length).toBe(32);
  });

  it("errors about secrets never contain the secret", () => {
    const value = "not base64 !!" + randomUUID();
    try {
      loadAuthSecrets({ APP_ENV: "production", AUTH_TOKEN_KEY: value, AUTH_HASH_KEY: key32() });
      expect.unreachable();
    } catch (error) {
      expect(String(error)).not.toContain(value);
    }
  });
});

describe("ACC-01 codes and hashes", () => {
  it("ACC-01 codes are uniformly random digits of the configured length", () => {
    for (const length of [4, 6, 8])
      expect(randomDigits(length)).toMatch(new RegExp(`^[0-9]{${length}}$`));
    const seen = new Set(Array.from({ length: 200 }, () => randomDigits(6)));
    expect(seen.size).toBeGreaterThan(190);
  });

  it("ACC-01 keyed hashes depend on the key, the purpose and the part boundaries", () => {
    const key = randomBytes(32);
    const a = keyedHash(key, "sign_in_code", "abc", "123456");
    expect(a.length).toBe(32);
    expect(a.equals(keyedHash(key, "sign_in_code", "abc", "123456"))).toBe(true);
    expect(a.equals(keyedHash(randomBytes(32), "sign_in_code", "abc", "123456"))).toBe(false);
    expect(a.equals(keyedHash(key, "refresh_token", "abc", "123456"))).toBe(false);
    expect(a.equals(keyedHash(key, "sign_in_code", "abc1", "23456"))).toBe(false);
  });

  it("ACC-01 comparison is constant-time and length-safe", () => {
    const a = randomBytes(32);
    expect(constantTimeEqual(a, Buffer.from(a))).toBe(true);
    expect(constantTimeEqual(a, randomBytes(32))).toBe(false);
    expect(constantTimeEqual(a, a.subarray(0, 31))).toBe(false);
  });

  it("ACC-01 destinations: E.164 phone numbers and lower-cased email addresses", () => {
    expect(normalizeDestination("phone", " +6299000000001 ")).toBe("+6299000000001");
    expect(normalizeDestination("phone", "081200000000")).toBeNull();
    expect(normalizeDestination("phone", "+0812")).toBeNull();
    expect(normalizeDestination("email", "Ibu@Example.Invalid")).toBe("ibu@example.invalid");
    expect(normalizeDestination("email", "no-at-sign")).toBeNull();
    expect(normalizeDestination("email", "a b@example.invalid")).toBeNull();
  });

  it("ACC-13 refresh tokens carry 256 random bits", () => {
    const token = randomToken("kmr1_");
    expect(token).toMatch(/^kmr1_[A-Za-z0-9_-]{43}$/);
    expect(randomToken("kmr1_")).not.toBe(token);
  });
});

describe("ACC-13 access tokens", () => {
  const key = randomBytes(32);
  const claims = {
    sessionId: randomUUID(),
    accountId: randomUUID(),
    expiresAt: new Date("2026-11-12T04:00:00.000Z"),
  };

  it("ACC-13 a signed token verifies until it expires", () => {
    const token = signAccessToken(key, claims);
    expect(verifyAccessToken(key, token, new Date("2026-11-12T03:59:59Z"))).toEqual({
      status: "valid",
      claims,
    });
    expect(verifyAccessToken(key, token, claims.expiresAt)).toEqual({ status: "expired" });
  });

  it("ACC-13 a token signed with another key, altered or malformed is invalid", () => {
    const now = new Date("2026-11-12T03:00:00Z");
    const token = signAccessToken(key, claims);
    expect(verifyAccessToken(randomBytes(32), token, now).status).toBe("invalid");
    const [prefix, payload = "", mac = ""] = token.split(".");
    const other = Buffer.from(
      JSON.stringify({ s: randomUUID(), a: claims.accountId, e: 4_000_000_000 }),
    ).toString("base64url");
    expect(verifyAccessToken(key, `${prefix}.${other}.${mac}`, now).status).toBe("invalid");
    expect(verifyAccessToken(key, `${prefix}.${payload}`, now).status).toBe("invalid");
    expect(verifyAccessToken(key, "", now).status).toBe("invalid");
    expect(verifyAccessToken(key, `x${token}`, now).status).toBe("invalid");
  });

  it("ACC-13 access tokens carry no contact details", () => {
    const payload = signAccessToken(key, claims).split(".")[1] ?? "";
    const decoded = JSON.parse(Buffer.from(payload, "base64url").toString("utf8")) as object;
    expect(Object.keys(decoded)).toEqual(["s", "a", "e"]);
  });
});

describe("error mapping: retryable errors are 503, never success", () => {
  const requestId = randomUUID();

  it("ConcurrentUpdateError and KeyServiceError are 503 service_unavailable with Retry-After", () => {
    for (const error of [new ConcurrentUpdateError(), new KeyServiceError("kms down +6299000")]) {
      const problem = toProblem(error, requestId);
      expect(problem.status).toBe(503);
      expect(problem.body).toMatchObject({ code: "service_unavailable", detail: null, requestId });
      expect(problem.retryAfterSeconds).toBeGreaterThan(0);
      expect(JSON.stringify(problem.body)).not.toContain("+6299000");
    }
  });

  it("QUESTIONS #39 RulesUnavailableError is 503 rules_unavailable", () => {
    const problem = toProblem(new RulesUnavailableError("decrypt_failed"), requestId);
    expect(problem.status).toBe(503);
    expect(problem.body.code).toBe("rules_unavailable");
  });

  it("T-016 L2 lock and serialization SQLSTATEs become ConcurrentUpdateError", () => {
    for (const code of ["40001", "40P01", "55P03"]) {
      expect(translateDbError({ code })).toBeInstanceOf(ConcurrentUpdateError);
    }
  });

  it("T-016 L2 a database error carrying a phone number becomes internal_error without it", () => {
    const phone = "+6299000000123";
    const error = translateDbError({
      code: "23505",
      constraint: "account_phone_key",
      detail: `Key (phone)=(${phone}) already exists.`,
      message: `duplicate ${phone}`,
    });
    const problem = toProblem(error, requestId);
    expect(problem.status).toBe(500);
    expect(problem.body.code).toBe("internal_error");
    expect(JSON.stringify(problem)).not.toContain(phone);
    expect(String(error)).not.toContain(phone);
  });

  it("an ApiError keeps its code, status and field errors; unknown errors are internal_error", () => {
    const problem = toProblem(
      new ApiError("validation_failed", 400, "x", {
        fieldErrors: [{ pointer: "/destination", code: "invalid_format" }],
      }),
      requestId,
    );
    expect(problem.body).toMatchObject({
      status: 400,
      errors: [{ pointer: "/destination", code: "invalid_format" }],
    });
    expect(toProblem(new Error("secret +6299"), requestId).body).toMatchObject({
      status: 500,
      code: "internal_error",
      detail: null,
    });
  });
});
