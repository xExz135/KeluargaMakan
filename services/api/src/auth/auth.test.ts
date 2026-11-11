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
import { clientRateKey, parseTrustedProxies, TrustedProxyConfigError } from "./client-address.js";
import { canonicalDestination, destinationRateKey } from "./destination.js";
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

  it("L1 phone numbers are canonical E.164: separators removed, trunk 0 after +62 dropped", () => {
    expect(canonicalDestination("phone", " +6299000000001 ")).toBe("+6299000000001");
    expect(canonicalDestination("phone", "+62 990-0000-0001")).toBe("+6299000000001");
    expect(canonicalDestination("phone", "+62 (990) 0000.0001")).toBe("+6299000000001");
    expect(canonicalDestination("phone", "+62099000000001")).toBe("+6299000000001");
    expect(canonicalDestination("phone", "081200000000")).toBeNull();
    expect(canonicalDestination("phone", "+0812")).toBeNull();
    expect(canonicalDestination("phone", "+62abc0000000")).toBeNull();
    expect(canonicalDestination("phone", "+\uFF16\uFF12990000000001")).toBeNull();
  });

  it("L1 email addresses: lower case, NFC, ASCII domain without a trailing dot; dots and +tags kept", () => {
    expect(canonicalDestination("email", "Ibu@Example.Invalid")).toBe("ibu@example.invalid");
    expect(canonicalDestination("email", "ibu@example.invalid.")).toBe("ibu@example.invalid");
    expect(canonicalDestination("email", "i.bu+dapur@gmail.com")).toBe("i.bu+dapur@gmail.com");
    expect(canonicalDestination("email", "ibu@b\u00FCcher.example")).toBe(
      "ibu@xn--bcher-kva.example",
    );
    for (const bad of [
      "no-at-sign",
      "a b@example.invalid",
      "@example.invalid",
      "a@",
      "a..b@example.invalid",
      ".a@example.invalid",
      "a@example",
      "a@-x.example",
    ]) {
      expect(canonicalDestination("email", bad), bad).toBeNull();
    }
  });

  it("L1 control, bidi and zero-width characters and look-alike letters are refused", () => {
    for (const bad of [
      "korban\u0000x@example.invalid",
      "kor\u0007ban@example.invalid",
      "korban@ex\u202Eample.invalid",
      "korb\u0430n@example.invalid",
      "kor\u200Bban@example.invalid",
      "korban\u0085@example.invalid",
    ]) {
      expect(canonicalDestination("email", bad), JSON.stringify(bad)).toBeNull();
    }
    expect(canonicalDestination("phone", "+6299000\u0000000001")).toBeNull();
    expect(canonicalDestination("phone", "+6299000\u202E000001")).toBeNull();
  });

  it("L1 the rate key folds +tags everywhere and Gmail dots, never the stored address", () => {
    const key = (email: string) =>
      destinationRateKey("email", canonicalDestination("email", email) ?? "");
    expect(key("ibu+1@example.invalid")).toBe(key("ibu@example.invalid"));
    expect(key("i.bu@example.invalid")).not.toBe(key("ibu@example.invalid"));
    expect(key("i.b.u+x@googlemail.com")).toBe(key("ibu@gmail.com"));
    expect(key("IBU@GMAIL.COM.")).toBe(key("ibu@gmail.com"));
    expect(destinationRateKey("phone", "+6299000000001")).toBe("phone:+6299000000001");
  });

  it("ACC-13 refresh tokens carry 256 random bits", () => {
    const token = randomToken("kmr1_");
    expect(token).toMatch(/^kmr1_[A-Za-z0-9_-]{43}$/);
    expect(randomToken("kmr1_")).not.toBe(token);
  });
});

describe("H1 client addresses and trusted proxies", () => {
  it("H1 IPv4 keys by address; IPv4-mapped IPv6 counts as IPv4", () => {
    expect(clientRateKey("198.51.100.7")).toBe("v4:198.51.100.7");
    expect(clientRateKey("::ffff:198.51.100.7")).toBe("v4:198.51.100.7");
    expect(clientRateKey("::ffff:c633:6407")).toBe("v4:198.51.100.7");
  });

  it("H1 IPv6 clients are grouped by /64", () => {
    const a = clientRateKey("2001:db8:1234:5678::1");
    expect(a).toBe("v6:2001:db8:1234:5678::/64");
    expect(clientRateKey("2001:0DB8:1234:5678:ffff:eeee:dddd:cccc")).toBe(a);
    expect(clientRateKey("2001:db8:1234:5678:0:0:0:2%eth0")).toBe(a);
    expect(clientRateKey("2001:db8:1234:5679::1")).not.toBe(a);
    expect(clientRateKey("::1")).toBe("v6:0:0:0:0::/64");
  });

  it("H1 TRUSTED_PROXY_CIDRS takes addresses and CIDR ranges", () => {
    expect(parseTrustedProxies(undefined, "production")).toEqual([]);
    expect(parseTrustedProxies(" 35.191.0.0/16, 130.211.0.0/22 ,10.0.0.1", "production")).toEqual([
      "35.191.0.0/16",
      "130.211.0.0/22",
      "10.0.0.1",
    ]);
    expect(parseTrustedProxies("2600:1900::/28", "staging")).toEqual(["2600:1900::/28"]);
    for (const bad of ["10.0.0.0/33", "not-an-ip", "10.0.0.0/8/1", "loopback", "10.0.0.0/x"]) {
      expect(() => parseTrustedProxies(bad, "test"), bad).toThrow(TrustedProxyConfigError);
    }
  });

  it("H1 trusting every hop is refused outside local and test (missing APP_ENV counts as production)", () => {
    for (const all of ["true", "*", "ALL", "0.0.0.0/0", "::/0", "10.0.0.0/8,0.0.0.0/0"]) {
      for (const appEnv of ["production", "staging", undefined, "dev"]) {
        expect(() => parseTrustedProxies(all, appEnv), `${all} ${String(appEnv)}`).toThrow(
          /refused/,
        );
      }
      expect(parseTrustedProxies(all, "local")).toBe(true);
      expect(parseTrustedProxies(all, "test")).toBe(true);
    }
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

  it("L6 a signature in non-canonical base64url is refused", () => {
    const now = new Date("2026-11-12T03:00:00Z");
    const token = signAccessToken(key, claims);
    const [prefix, payload = "", signature = ""] = token.split(".");
    expect(signature).toHaveLength(43);
    const alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";
    const last = alphabet.indexOf(signature.at(-1) ?? "A");
    // The last character carries 2 unused low bits; changing them decodes to the same MAC.
    const variant = alphabet[(last & ~3) | ((last + 1) & 3)] ?? "A";
    const alteredSignature = `${signature.slice(0, -1)}${variant}`;
    expect(
      Buffer.from(alteredSignature, "base64url").equals(Buffer.from(signature, "base64url")),
    ).toBe(true);
    expect(verifyAccessToken(key, `${prefix}.${payload}.${alteredSignature}`, now).status).toBe(
      "invalid",
    );
    expect(verifyAccessToken(key, `${token}A`, now).status).toBe("invalid");
    expect(verifyAccessToken(key, `${token}=`, now).status).toBe("invalid");
    expect(verifyAccessToken(key, token, now).status).toBe("valid");
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
