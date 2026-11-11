/**
 * Data-layer errors. Messages are for logs and error tracking: they never
 * contain names, contact details, rule wording or other health data, and no
 * member or rule IDs (security review PR #5, L7).
 */

/** Machine-readable codes, aligned with `ErrorCode` in packages/contracts/openapi.yaml. */
export type DataErrorCode =
  | "rules_unavailable"
  | "consent_required"
  | "consent_not_active"
  | "guardian_confirmation_required"
  | "manager_profile_not_deletable"
  | "mapping_not_applicable"
  | "not_found"
  | "invalid_data";

export class DataLayerError extends Error {
  readonly code: DataErrorCode;

  constructor(code: DataErrorCode, message: string, options?: { cause?: unknown }) {
    super(message, options);
    this.name = new.target.name;
    this.code = code;
  }
}

/** Why a member's hard rules could not be produced. */
export type RulesUnavailableReason =
  /** The health-data key could not unwrap the member's data key, or a value failed authentication. */
  | "decrypt_failed"
  /** The key service (Cloud KMS or the local provider) failed or is not configured. */
  | "key_unavailable"
  /** A stored rule decrypted but is not a valid rule. */
  | "malformed"
  /** Stored rows contradict the consent state (for example rules without consent). */
  | "inconsistent";

/**
 * QUESTIONS #39, security review PR #5 H2: "the rules could not be read or
 * decrypted" is never the same as "this member has no rules". Callers must
 * abort the safety check for the whole meal (contract: 503 `rules_unavailable`)
 * and must never fall back to an empty rule list, which Cek Aman would turn
 * into "Safe".
 */
export class RulesUnavailableError extends DataLayerError {
  readonly reason: RulesUnavailableReason;

  constructor(reason: RulesUnavailableReason, options?: { cause?: unknown }) {
    super("rules_unavailable", `Hard rules could not be read (${reason})`, options);
    this.reason = reason;
  }
}

/** ACC-08, QUESTIONS #13: hard rules are stored only under a given, active health-data consent. */
export class ConsentRequiredError extends DataLayerError {
  constructor(options?: { cause?: unknown }) {
    super("consent_required", "An active health-data consent record is required", options);
  }
}

/** SET-10: a child profile needs the manager's recorded guardian confirmation. */
export class GuardianConfirmationRequiredError extends DataLayerError {
  constructor(options?: { cause?: unknown }) {
    super(
      "guardian_confirmation_required",
      "A guardian confirmation record is required for a child profile",
      options,
    );
  }
}

export class ManagerProfileNotDeletableError extends DataLayerError {
  constructor(options?: { cause?: unknown }) {
    super(
      "manager_profile_not_deletable",
      "The manager's own profile is deleted only with the household",
      options,
    );
  }
}

export class MappingNotApplicableError extends DataLayerError {
  constructor() {
    super("mapping_not_applicable", "Only free-text and medical-exclusion rules have a mapping");
  }
}

export class NotFoundError extends DataLayerError {
  constructor(what: string) {
    super("not_found", `${what} not found in this household`);
  }
}

export class InvalidDataError extends DataLayerError {
  constructor(message: string) {
    super("invalid_data", message);
  }
}

/** SQLSTATEs raised by the triggers in the migrations. */
export const SQLSTATE = {
  consentRequired: "KM001",
  guardianConfirmationRequired: "KM002",
  immutable: "KM003",
  foreignKeyViolation: "23503",
} as const;

/** Constraint that keeps the manager's profile from being deleted on its own. */
export const MANAGER_PROFILE_CONSTRAINT = "household_manager_profile_fkey";

function field(error: unknown, name: string): unknown {
  return typeof error === "object" && error !== null && Object.hasOwn(error, name)
    ? (error as Record<string, unknown>)[name]
    : undefined;
}

/** Turns trigger and constraint errors from PostgreSQL into typed data-layer errors. */
export function translateDbError(error: unknown): unknown {
  const code = field(error, "code");
  if (code === SQLSTATE.consentRequired) return new ConsentRequiredError({ cause: error });
  if (code === SQLSTATE.guardianConfirmationRequired) {
    return new GuardianConfirmationRequiredError({ cause: error });
  }
  if (
    code === SQLSTATE.foreignKeyViolation &&
    field(error, "constraint") === MANAGER_PROFILE_CONSTRAINT
  ) {
    return new ManagerProfileNotDeletableError({ cause: error });
  }
  return error;
}

/** Runs `fn` and rethrows database errors as typed data-layer errors. */
export async function withDbErrors<T>(fn: () => Promise<T>): Promise<T> {
  try {
    return await fn();
  } catch (error) {
    throw translateDbError(error);
  }
}
