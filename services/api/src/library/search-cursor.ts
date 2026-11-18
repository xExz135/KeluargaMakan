import { timingSafeEqual } from "node:crypto";

import { keyedHash } from "../auth/crypto.js";
import type { LibrarySearchInput } from "./requests.js";

/**
 * LIB-08 search page cursor (security review T-040, Info "Cursors"): a
 * signed page position that never carries the search text or the filters
 * in clear, only a keyed hash of the request it belongs to.
 *
 * `L1` + base64url(payload + 16-byte MAC), with the contract's
 * `PageCursor` alphabet. The payload is the household, a keyed hash of the
 * request body without the cursor, and the offset of the next page. A
 * cursor that is malformed, signed with another key, made for another
 * household or for a different request body is refused (400 `/cursor`).
 */

const PREFIX = "L1";
const MAC_BYTES = 16;
const BODY_HASH_BYTES = 16;
const MAX_OFFSET = 1_000_000;

function bodyHash(hashKey: Buffer, householdId: string, input: LibrarySearchInput): string {
  const canonical = JSON.stringify({
    eaters: { mode: input.eaters.mode, memberIds: [...input.eaters.memberIds] },
    query: input.query,
    regionIds: [...input.regionIds].sort(),
    mealTypes: [...input.mealTypes].sort(),
    timeAvailable: input.timeAvailable,
    includeNotSafe: input.includeNotSafe,
    limit: input.limit,
  });
  return keyedHash(hashKey, "library_search_cursor", "body", householdId, canonical)
    .subarray(0, BODY_HASH_BYTES)
    .toString("base64url");
}

function mac(hashKey: Buffer, payload: Buffer): Buffer {
  return keyedHash(hashKey, "library_search_cursor", "mac", payload.toString("base64url")).subarray(
    0,
    MAC_BYTES,
  );
}

export function encodeSearchCursor(
  hashKey: Buffer,
  householdId: string,
  input: LibrarySearchInput,
  offset: number,
): string {
  const payload = Buffer.from(
    JSON.stringify({ h: householdId, b: bodyHash(hashKey, householdId, input), o: offset }),
    "utf8",
  );
  return `${PREFIX}${Buffer.concat([payload, mac(hashKey, payload)]).toString("base64url")}`;
}

/** The offset the cursor points at, or null when it must be refused. */
export function decodeSearchCursor(
  hashKey: Buffer,
  householdId: string,
  input: LibrarySearchInput,
  cursor: string,
): number | null {
  if (!cursor.startsWith(PREFIX)) return null;
  const bytes = Buffer.from(cursor.slice(PREFIX.length), "base64url");
  if (bytes.length <= MAC_BYTES) return null;
  const payload = bytes.subarray(0, bytes.length - MAC_BYTES);
  const given = bytes.subarray(bytes.length - MAC_BYTES);
  const expected = mac(hashKey, payload);
  if (!timingSafeEqual(given, expected)) return null;
  let parsed: unknown;
  try {
    parsed = JSON.parse(payload.toString("utf8"));
  } catch {
    return null;
  }
  if (typeof parsed !== "object" || parsed === null) return null;
  const { h, b, o } = parsed as { h?: unknown; b?: unknown; o?: unknown };
  if (h !== householdId || b !== bodyHash(hashKey, householdId, input)) return null;
  if (typeof o !== "number" || !Number.isInteger(o) || o < 1 || o > MAX_OFFSET) return null;
  return o;
}
