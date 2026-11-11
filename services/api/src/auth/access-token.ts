import { createHmac } from "node:crypto";

import { isUuid } from "../db/ids.js";
import { constantTimeEqual } from "./crypto.js";

/**
 * Short-lived bearer access token: `kma1.<payload>.<mac>`, where the payload
 * names the session and account and the expiry, and the MAC is HMAC-SHA256
 * under `AUTH_TOKEN_KEY`. It carries no contact details. Every request also
 * checks that the session is still active, so sign-out and token-family
 * revocation take effect at once (ACC-13).
 */
const PREFIX = "kma1";

export interface AccessTokenClaims {
  readonly sessionId: string;
  readonly accountId: string;
  readonly expiresAt: Date;
}

export type AccessTokenCheck =
  | { readonly status: "valid"; readonly claims: AccessTokenClaims }
  | { readonly status: "expired" }
  | { readonly status: "invalid" };

function mac(key: Buffer, payload: string): Buffer {
  return createHmac("sha256", key).update(`${PREFIX}.${payload}`).digest();
}

export function signAccessToken(key: Buffer, claims: AccessTokenClaims): string {
  const payload = Buffer.from(
    JSON.stringify({
      s: claims.sessionId,
      a: claims.accountId,
      e: Math.floor(claims.expiresAt.getTime() / 1000),
    }),
  ).toString("base64url");
  return `${PREFIX}.${payload}.${mac(key, payload).toString("base64url")}`;
}

export function verifyAccessToken(key: Buffer, token: string, now: Date): AccessTokenCheck {
  if (token.length > 1024) return { status: "invalid" };
  const parts = token.split(".");
  if (parts.length !== 3 || parts[0] !== PREFIX) return { status: "invalid" };
  const [, payload = "", signature = ""] = parts;
  if (!/^[A-Za-z0-9_-]+$/.test(payload) || !/^[A-Za-z0-9_-]+$/.test(signature)) {
    return { status: "invalid" };
  }
  if (!constantTimeEqual(Buffer.from(signature, "base64url"), mac(key, payload))) {
    return { status: "invalid" };
  }
  let decoded: unknown;
  try {
    decoded = JSON.parse(Buffer.from(payload, "base64url").toString("utf8"));
  } catch {
    return { status: "invalid" };
  }
  if (typeof decoded !== "object" || decoded === null) return { status: "invalid" };
  const { s, a, e } = decoded as Record<string, unknown>;
  if (!isUuid(s) || !isUuid(a) || typeof e !== "number" || !Number.isInteger(e)) {
    return { status: "invalid" };
  }
  const expiresAt = new Date(e * 1000);
  if (expiresAt.getTime() <= now.getTime()) return { status: "expired" };
  return { status: "valid", claims: { sessionId: s, accountId: a, expiresAt } };
}
