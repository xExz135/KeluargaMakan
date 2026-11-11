import type { ErrorCode, Schemas } from "@keluargamakan/contracts";

export type FieldErrorCode = Schemas["FieldErrorCode"];

export interface FieldError {
  /** JSON Pointer into the request body. Never contains the submitted value. */
  readonly pointer: string;
  readonly code: FieldErrorCode;
}

/**
 * An error the API answers with a contract `Problem`. Messages are fixed,
 * English, for developers and logs: they never contain contact details, names,
 * codes, tokens or health data (T-016 L2 pattern).
 */
export class ApiError extends Error {
  readonly code: ErrorCode;
  readonly status: number;
  readonly retryAfterSeconds: number | null;
  readonly fieldErrors: readonly FieldError[];

  constructor(
    code: ErrorCode,
    status: number,
    message: string,
    options: {
      readonly retryAfterSeconds?: number;
      readonly fieldErrors?: readonly FieldError[];
    } = {},
  ) {
    super(message);
    this.name = "ApiError";
    this.code = code;
    this.status = status;
    this.retryAfterSeconds = options.retryAfterSeconds ?? null;
    this.fieldErrors = options.fieldErrors ?? [];
  }
}

export const validationFailed = (fieldErrors: readonly FieldError[]) =>
  new ApiError("validation_failed", 400, "Request validation failed", { fieldErrors });

export const rateLimited = (retryAfterSeconds: number) =>
  new ApiError("rate_limited", 429, "Rate limit reached", { retryAfterSeconds });

export const unauthenticated = () =>
  new ApiError("unauthenticated", 401, "Missing, invalid or revoked credentials");
