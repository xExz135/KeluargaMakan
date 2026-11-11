import { randomBytes } from "node:crypto";

import { isDevelopmentEnv } from "../app-env.js";

/**
 * Server-side secrets for sign-in (no secrets in the repo: they come from the
 * environment, filled from Secret Manager in staging and production).
 *
 * - `AUTH_TOKEN_KEY`: signs access tokens.
 * - `AUTH_HASH_KEY`: keys the hashes of codes, refresh tokens, destinations,
 *   client addresses and idempotent request bodies, so a database copy alone
 *   cannot brute-force a 6-digit code or link a hash to a phone number.
 *
 * Both are base64, at least 32 bytes, and must differ. Outside `local` and
 * `test` a missing or weak key stops the API from starting (a missing or
 * unknown `APP_ENV` counts as production). In `local` and `test`, missing
 * keys are replaced by random ones for this process only.
 */
export interface AuthSecrets {
  readonly tokenKey: Buffer;
  readonly hashKey: Buffer;
}

export class AuthSecretsError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "AuthSecretsError";
  }
}

const MIN_KEY_BYTES = 32;

function decodeKey(name: string, value: string | undefined, development: boolean): Buffer {
  const raw = value?.trim() ?? "";
  if (raw === "") {
    if (development) return randomBytes(MIN_KEY_BYTES);
    throw new AuthSecretsError(`${name} is required outside APP_ENV local and test`);
  }
  if (!/^[A-Za-z0-9+/_-]+={0,2}$/.test(raw)) throw new AuthSecretsError(`${name} is not base64`);
  const key = Buffer.from(raw, "base64");
  if (key.length < MIN_KEY_BYTES) {
    throw new AuthSecretsError(`${name} must be at least ${MIN_KEY_BYTES} bytes`);
  }
  return key;
}

export function loadAuthSecrets(env: Readonly<Record<string, string | undefined>>): AuthSecrets {
  const development = isDevelopmentEnv(env["APP_ENV"]);
  const tokenKey = decodeKey("AUTH_TOKEN_KEY", env["AUTH_TOKEN_KEY"], development);
  const hashKey = decodeKey("AUTH_HASH_KEY", env["AUTH_HASH_KEY"], development);
  if (tokenKey.equals(hashKey)) {
    throw new AuthSecretsError("AUTH_TOKEN_KEY and AUTH_HASH_KEY must differ");
  }
  return { tokenKey, hashKey };
}
