import { timingSafeEqual } from "node:crypto";

import { keyedHash } from "../auth/crypto.js";

/**
 * KIT-16 sync cursor: the household's sync position, signed with the
 * server's hash key and bound to the household and its issue time
 * (security review T-030, T-032 checklist).
 *
 * `v1.<payload>.<mac>`, both base64url. The payload holds the household ID,
 * the last sync position and the issue time; it says nothing about the
 * kitchen's contents. A cursor that is malformed, signed with another key,
 * issued for another household or older than the retention of removals is
 * not used: the sync then sends the whole kitchen (`full: true`), never
 * another household's changes and never an error the phone cannot recover
 * from.
 */

const PREFIX = "v1";
const MAC_BYTES = 16;

interface CursorPayload {
  readonly h: string;
  readonly s: string;
  readonly t: number;
}

function mac(hashKey: Buffer, payload: string): Buffer {
  return keyedHash(hashKey, "kitchen_sync_cursor", payload).subarray(0, MAC_BYTES);
}

export function encodeCursor(
  hashKey: Buffer,
  householdId: string,
  position: bigint,
  issuedAt: Date,
): string {
  const payload = Buffer.from(
    JSON.stringify({ h: householdId, s: position.toString(), t: issuedAt.getTime() }),
    "utf8",
  ).toString("base64url");
  return `${PREFIX}.${payload}.${mac(hashKey, payload).toString("base64url")}`;
}

/** The sync position, or null when the cursor must not be used (then send everything). */
export function decodeCursor(
  hashKey: Buffer,
  cursor: string | null,
  householdId: string,
  notBefore: Date,
): bigint | null {
  if (cursor === null) return null;
  const parts = cursor.split(".");
  if (parts.length !== 3 || parts[0] !== PREFIX) return null;
  const [, payload = "", signature = ""] = parts;
  const given = Buffer.from(signature, "base64url");
  const expected = mac(hashKey, payload);
  if (given.length !== expected.length || !timingSafeEqual(given, expected)) return null;
  let parsed: unknown;
  try {
    parsed = JSON.parse(Buffer.from(payload, "base64url").toString("utf8"));
  } catch {
    return null;
  }
  if (typeof parsed !== "object" || parsed === null) return null;
  const { h, s, t } = parsed as Partial<CursorPayload>;
  if (h !== householdId || typeof s !== "string" || !/^\d{1,19}$/.test(s)) return null;
  if (typeof t !== "number" || t < notBefore.getTime()) return null;
  return BigInt(s);
}
