import type { ErrorCode, Problem } from "@keluargamakan/contracts";

import { ApiError } from "../api-error.js";
import { KeyServiceError } from "../db/crypto/key-provider.js";
import {
  ConcurrentUpdateError,
  DataLayerError,
  DatabaseError,
  RulesUnavailableError,
} from "../db/errors.js";

/**
 * Turns any thrown value into a contract `Problem` (RFC 9457). `title` is a
 * fixed text per code and `detail` is null, so nothing from the request or
 * from a lower layer (driver messages, vendor errors) reaches the response.
 *
 * Retryable failures are 503 with `Retry-After`, never a success:
 * `ConcurrentUpdateError` and `KeyServiceError` are `service_unavailable`,
 * `RulesUnavailableError` is `rules_unavailable` (QUESTIONS #39).
 */
export interface ProblemResponse {
  readonly status: number;
  readonly body: Problem;
  readonly retryAfterSeconds: number | null;
  /** For logs: the error class or code, never its message. */
  readonly logName: string;
}

const TITLES: Readonly<Partial<Record<ErrorCode, string>>> = {
  validation_failed: "Validation failed",
  code_invalid: "Sign-in code invalid",
  code_expired: "Sign-in code expired",
  code_attempts_exceeded: "Too many sign-in code attempts",
  unauthenticated: "Unauthenticated",
  access_token_expired: "Access token expired",
  refresh_token_invalid: "Refresh token invalid",
  forbidden: "Forbidden",
  not_found: "Not found",
  household_required: "Household required",
  household_exists: "Household exists",
  idempotency_key_reused: "Idempotency key reused",
  rate_limited: "Too many requests",
  rules_unavailable: "Rules unavailable",
  sign_in_method_unavailable: "Sign-in method unavailable",
  service_unavailable: "Service unavailable",
  internal_error: "Internal error",
};

/** Seconds a client should wait after a retryable 503. Operational default. */
export const RETRY_AFTER_SECONDS = 1;

const DATA_LAYER_STATUS: Readonly<Partial<Record<string, [number, ErrorCode]>>> = {
  consent_required: [409, "consent_required"],
  consent_not_active: [409, "consent_not_active"],
  guardian_confirmation_required: [409, "guardian_confirmation_required"],
  manager_profile_not_deletable: [409, "manager_profile_not_deletable"],
  mapping_not_applicable: [409, "mapping_not_applicable"],
  not_found: [404, "not_found"],
  invalid_data: [400, "validation_failed"],
};

function problem(
  status: number,
  code: ErrorCode,
  requestId: string,
  extra: { retryAfterSeconds?: number | null; errors?: Problem["errors"] } = {},
): Problem {
  return {
    type: `urn:keluargamakan:problem:${code}`,
    title: TITLES[code] ?? code,
    status,
    code,
    detail: null,
    requestId,
    ...(extra.retryAfterSeconds === undefined || extra.retryAfterSeconds === null
      ? {}
      : { retryAfterSeconds: extra.retryAfterSeconds }),
    ...(extra.errors === undefined || extra.errors.length === 0 ? {} : { errors: extra.errors }),
  };
}

function httpStatusOf(error: unknown): number | null {
  if (typeof error !== "object" || error === null) return null;
  const candidate =
    (error as { getStatus?: () => unknown }).getStatus?.() ??
    (error as { statusCode?: unknown }).statusCode;
  return typeof candidate === "number" && candidate >= 400 && candidate <= 599 ? candidate : null;
}

export function toProblem(error: unknown, requestId: string): ProblemResponse {
  const unavailable = (code: ErrorCode, logName: string): ProblemResponse => ({
    status: 503,
    body: problem(503, code, requestId, { retryAfterSeconds: RETRY_AFTER_SECONDS }),
    retryAfterSeconds: RETRY_AFTER_SECONDS,
    logName,
  });

  if (error instanceof ApiError) {
    return {
      status: error.status,
      body: problem(error.status, error.code, requestId, {
        retryAfterSeconds: error.retryAfterSeconds,
        errors: [...error.fieldErrors],
      }),
      retryAfterSeconds: error.retryAfterSeconds,
      logName: error.code,
    };
  }
  if (error instanceof ConcurrentUpdateError) {
    return unavailable("service_unavailable", "ConcurrentUpdateError");
  }
  if (error instanceof RulesUnavailableError) {
    return unavailable("rules_unavailable", "RulesUnavailableError");
  }
  if (error instanceof KeyServiceError)
    return unavailable("service_unavailable", "KeyServiceError");
  if (error instanceof DataLayerError) {
    const mapped = DATA_LAYER_STATUS[error.code];
    if (mapped !== undefined) {
      const [status, code] = mapped;
      return {
        status,
        body: problem(status, code, requestId),
        retryAfterSeconds: null,
        logName: code,
      };
    }
  }
  if (error instanceof DatabaseError) {
    return {
      status: 500,
      body: problem(500, "internal_error", requestId),
      retryAfterSeconds: null,
      logName: `DatabaseError:${error.code}`,
    };
  }

  // Framework errors: unknown route, malformed JSON, body too large, wrong media type.
  const status = httpStatusOf(error);
  if (status !== null && status < 500) {
    const code: ErrorCode =
      status === 401
        ? "unauthenticated"
        : status === 403
          ? "forbidden"
          : status === 404 || status === 405
            ? "not_found"
            : status === 429
              ? "rate_limited"
              : "validation_failed";
    return {
      status,
      body: problem(status, code, requestId),
      retryAfterSeconds: null,
      logName: code,
    };
  }
  return {
    status: 500,
    body: problem(500, "internal_error", requestId),
    retryAfterSeconds: null,
    logName: error instanceof Error ? error.name : "unknown",
  };
}
