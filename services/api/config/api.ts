/**
 * Operational settings for sign-in, sessions and request handling (T-017).
 *
 * These are not SRS "(target)" figures (those live in `targets.ts`), but the
 * contract says they "come from configuration" (code length, expiry, resend
 * wait, attempt limit, rate limits, token lifetimes, idempotency retention),
 * so they are configuration too. Every value can be overridden without a code
 * change; `resolveApiConfig` rejects unknown keys and out-of-range values.
 */

import { isDevelopmentEnv } from "../src/app-env.js";

/**
 * A rolling-window limit: at most `limit` events in any `windowSeconds`
 * (counted in buckets of 1/12 of the window).
 */
export interface RateLimitRule {
  /** Requests allowed per window. */
  readonly limit: number;
  readonly windowSeconds: number;
}

export interface ApiConfig {
  readonly signInCode: {
    /** Digits per code. The contract allows 4 to 8 (`SignInCodeChallenge.codeLength`). */
    readonly length: number;
    readonly ttlSeconds: number;
    /** Earliest time a new code may be requested for the same destination. */
    readonly resendWaitSeconds: number;
    /** Wrong codes allowed per challenge before it is locked (ACC-01). */
    readonly maxAttempts: number;
  };
  readonly rateLimits: {
    /** Code requests per phone number or email address (short window). */
    readonly codeRequestPerDestination: RateLimitRule;
    /** Code requests per phone number or email address per day (security review M1). */
    readonly codeRequestPerDestinationDaily: RateLimitRule;
    /**
     * Wrong codes per phone number or email address across all its challenges
     * (security review M1). When reached, no new code is sent and no pending
     * code is checked for that destination until the window has moved on.
     */
    readonly codeVerifyFailuresPerDestination: RateLimitRule;
    /** Code requests per client address. */
    readonly codeRequestPerClient: RateLimitRule;
    /** Code verifications per client address. */
    readonly codeVerifyPerClient: RateLimitRule;
    /** Refreshes per client address. */
    readonly refreshPerClient: RateLimitRule;
  };
  readonly sessions: {
    readonly accessTokenTtlSeconds: number;
    /** Sliding lifetime of a refresh token; each refresh issues a new one. */
    readonly refreshTokenTtlSeconds: number;
    /** Absolute lifetime of a session, however often it is refreshed. */
    readonly maxLifetimeSeconds: number;
    /**
     * Mobile review L5: a refresh repeated with the same token within this many
     * seconds of its first use gets a new pair instead of ending the session,
     * so a lost refresh response does not sign the user out. Later reuse
     * revokes the whole session (token family).
     */
    readonly refreshGraceSeconds: number;
    /** Lock wait inside a session transaction before a retryable 503. */
    readonly lockTimeoutMs: number;
  };
  readonly retention: {
    /** Revoked or expired sessions are purged after this many days. */
    readonly endedSessionDays: number;
    /** `Idempotency-Key` records are kept this long (contract `IdempotencyKey`). */
    readonly idempotencyKeyHours: number;
  };
}

const DAY = 24 * 60 * 60;

export const defaultApiConfig: ApiConfig = deepFreeze({
  signInCode: {
    length: 6,
    ttlSeconds: 10 * 60,
    resendWaitSeconds: 60,
    maxAttempts: 5,
  },
  rateLimits: {
    codeRequestPerDestination: { limit: 5, windowSeconds: 60 * 60 },
    codeRequestPerDestinationDaily: { limit: 10, windowSeconds: DAY },
    codeVerifyFailuresPerDestination: { limit: 10, windowSeconds: DAY },
    codeRequestPerClient: { limit: 20, windowSeconds: 60 * 60 },
    codeVerifyPerClient: { limit: 30, windowSeconds: 15 * 60 },
    refreshPerClient: { limit: 60, windowSeconds: 15 * 60 },
  },
  sessions: {
    accessTokenTtlSeconds: 15 * 60,
    refreshTokenTtlSeconds: 60 * DAY,
    maxLifetimeSeconds: 365 * DAY,
    refreshGraceSeconds: 120,
    lockTimeoutMs: 5_000,
  },
  retention: {
    endedSessionDays: 30,
    idempotencyKeyHours: 24,
  },
});

type DeepPartial<T> = { readonly [K in keyof T]?: T[K] extends object ? DeepPartial<T[K]> : T[K] };
export type ApiConfigOverrides = DeepPartial<ApiConfig>;

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function merge(defaults: unknown, overrides: unknown, path: string): unknown {
  if (overrides === undefined) return defaults;
  if (!isRecord(defaults)) {
    if (typeof overrides !== "number") throw new Error(`api config ${path} must be a number`);
    return overrides;
  }
  if (!isRecord(overrides)) throw new Error(`api config ${path} must be an object`);
  for (const key of Object.keys(overrides)) {
    if (!Object.hasOwn(defaults, key)) throw new Error(`Unknown api config: ${path}${key}`);
  }
  const out: Record<string, unknown> = {};
  for (const [key, value] of Object.entries(defaults)) {
    out[key] = merge(value, overrides[key], `${path}${key}.`);
  }
  return out;
}

function check(condition: boolean, message: string): void {
  if (!condition) throw new Error(`api config: ${message}`);
}

const positiveInt = (value: number) => Number.isInteger(value) && value >= 1;

/**
 * Floors outside APP_ENV local and test (security review L5, M1). A missing
 * or unknown APP_ENV counts as production, so these always apply there.
 */
export const PRODUCTION_FLOORS = Object.freeze({
  minCodeLength: 6,
  maxAttempts: 5,
  /** At most this many wrong codes per destination per day. */
  maxDailyVerifyFailures: 20,
  /** At most this many codes per destination per day. */
  maxDailyCodeRequests: 20,
});

function validateFloors(config: ApiConfig): void {
  const { signInCode: code, rateLimits } = config;
  check(
    code.length >= PRODUCTION_FLOORS.minCodeLength,
    "code length at least 6 outside local and test",
  );
  check(
    code.maxAttempts <= PRODUCTION_FLOORS.maxAttempts,
    "attempts at most 5 outside local and test",
  );
  const daily = (rule: RateLimitRule, max: number) =>
    rule.windowSeconds >= DAY && rule.limit <= max;
  check(
    daily(rateLimits.codeVerifyFailuresPerDestination, PRODUCTION_FLOORS.maxDailyVerifyFailures),
    "wrong codes per destination: at most 20 in a window of at least a day outside local and test",
  );
  check(
    daily(rateLimits.codeRequestPerDestinationDaily, PRODUCTION_FLOORS.maxDailyCodeRequests),
    "code requests per destination: at most 20 in a window of at least a day outside local and test",
  );
}

function validate(config: ApiConfig): void {
  const { signInCode: code, rateLimits, sessions, retention } = config;
  check(Number.isInteger(code.length) && code.length >= 4 && code.length <= 8, "code length 4-8");
  check(positiveInt(code.ttlSeconds), "code ttl");
  check(positiveInt(code.resendWaitSeconds), "resend wait");
  check(code.resendWaitSeconds <= code.ttlSeconds, "resend wait within code ttl");
  check(positiveInt(code.maxAttempts) && code.maxAttempts <= 10, "attempts 1-10");
  for (const [name, rule] of Object.entries(rateLimits)) {
    check(positiveInt(rule.limit) && positiveInt(rule.windowSeconds), `rate limit ${name}`);
  }
  check(positiveInt(sessions.accessTokenTtlSeconds), "access token ttl");
  check(sessions.accessTokenTtlSeconds <= 60 * 60, "access token ttl at most 1 hour");
  check(positiveInt(sessions.refreshTokenTtlSeconds), "refresh token ttl");
  check(sessions.refreshTokenTtlSeconds <= sessions.maxLifetimeSeconds, "refresh ttl within max");
  check(positiveInt(sessions.maxLifetimeSeconds), "session max lifetime");
  check(
    Number.isInteger(sessions.refreshGraceSeconds) &&
      sessions.refreshGraceSeconds >= 0 &&
      sessions.refreshGraceSeconds <= 15 * 60,
    "refresh grace 0-900 seconds",
  );
  check(positiveInt(sessions.lockTimeoutMs), "lock timeout");
  check(positiveInt(retention.endedSessionDays), "ended session retention");
  check(positiveInt(retention.idempotencyKeyHours), "idempotency retention");
}

/**
 * Defaults with the given values replaced. Unknown keys and invalid values
 * throw. Outside `appEnv` local and test (missing counts as production) the
 * production floors apply too.
 */
export function resolveApiConfig(
  overrides: ApiConfigOverrides = {},
  options: { readonly appEnv?: string | undefined } = {},
): ApiConfig {
  const config = merge(defaultApiConfig, overrides, "") as ApiConfig;
  validate(config);
  if (!isDevelopmentEnv(options.appEnv)) validateFloors(config);
  return deepFreeze(config);
}

/** Reads optional overrides from `API_CONFIG_JSON` (for example from Secret Manager or deploy config). */
export function apiConfigFromEnv(env: Readonly<Record<string, string | undefined>>): ApiConfig {
  const raw = env["API_CONFIG_JSON"]?.trim();
  const options = { appEnv: env["APP_ENV"] };
  if (raw === undefined || raw === "") return resolveApiConfig({}, options);
  let parsed: unknown;
  try {
    parsed = JSON.parse(raw);
  } catch {
    throw new Error("API_CONFIG_JSON is not valid JSON");
  }
  return resolveApiConfig(parsed as ApiConfigOverrides, options);
}

function deepFreeze<T>(value: T): T {
  if (value !== null && typeof value === "object") {
    for (const child of Object.values(value)) deepFreeze(child);
    Object.freeze(value);
  }
  return value;
}
