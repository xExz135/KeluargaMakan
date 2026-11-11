import { createHmac, randomBytes, randomInt, timingSafeEqual } from "node:crypto";

/** Purposes of keyed hashes. A hash for one purpose never matches another. */
export type HashPurpose =
  "sign_in_code" | "destination" | "rate_limit" | "refresh_token" | "idempotent_request";

/**
 * HMAC-SHA256 under the server's hash key, over the purpose and each part
 * with its length, so different part lists can never produce the same input.
 */
export function keyedHash(key: Buffer, purpose: HashPurpose, ...parts: readonly string[]): Buffer {
  const mac = createHmac("sha256", key);
  for (const part of [purpose, ...parts]) {
    const bytes = Buffer.from(part, "utf8");
    const length = Buffer.alloc(4);
    length.writeUInt32BE(bytes.length);
    mac.update(length);
    mac.update(bytes);
  }
  return mac.digest();
}

/** Constant-time comparison; different lengths compare unequal without leaking where. */
export function constantTimeEqual(a: Uint8Array, b: Uint8Array): boolean {
  if (a.length !== b.length) {
    // Compare against itself so the time does not depend on where they differ.
    timingSafeEqual(a, a);
    return false;
  }
  return timingSafeEqual(a, b);
}

/** A uniformly random numeric code (no modulo bias: `randomInt` per digit). */
export function randomDigits(length: number): string {
  let code = "";
  for (let i = 0; i < length; i += 1) code += String(randomInt(0, 10));
  return code;
}

/** 256 random bits, base64url, with a short type prefix. */
export function randomToken(prefix: string): string {
  return `${prefix}${randomBytes(32).toString("base64url")}`;
}
