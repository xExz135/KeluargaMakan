import { ID_PATTERN } from "@keluargamakan/cek-aman";

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;
const REFERENCE_ID = new RegExp(ID_PATTERN);

/** Lowercase UUID: the form every household-data ID takes (opaque, pseudonymous). */
export function isUuid(value: unknown): value is string {
  return typeof value === "string" && UUID.test(value);
}

/** Reference ingredient, brand, dish or recipe ID (Cek Aman `ID_PATTERN`). */
export function isReferenceId(value: unknown): value is string {
  return typeof value === "string" && REFERENCE_ID.test(value);
}

/**
 * DAT-06, SAF-14: the pattern of a reference data version as results record
 * it (`<data version>@sha256:<content hash>`, packages/reference-data). No
 * spaces, quotes or control characters, so a name can never be stored as a
 * version. New code uses this one constant: the log writers test against
 * it, and the reference loader refuses a dataset whose version does not
 * match (security review T-041 L4). Migration 0012 holds the same pattern as
 * a literal, so its text never changes with this constant (re-check N6); a
 * test checks they are equal. Change the pattern only with a new migration.
 */
export const REFERENCE_VERSION_PATTERN = "^[A-Za-z0-9][A-Za-z0-9._+/:@-]{0,199}$";
const REFERENCE_VERSION = new RegExp(REFERENCE_VERSION_PATTERN);

export function isReferenceVersion(value: unknown): value is string {
  return typeof value === "string" && REFERENCE_VERSION.test(value);
}
