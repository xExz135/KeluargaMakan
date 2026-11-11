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
