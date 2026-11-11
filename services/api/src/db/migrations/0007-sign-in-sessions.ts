import type { Migration } from "./types.js";

/**
 * T-017 sign-in and sessions (ACC-01, ACC-13), all SRS 18.1 Account data, plus
 * the `Idempotency-Key` records the contract promises for household creation.
 * Every column is listed in `schema-trace.ts`.
 *
 * - ACC-01: a sign-in challenge holds an HMAC of the code (keyed with a secret
 *   from the secret manager, never the code itself), an attempt counter and
 *   an expiry. It is deleted when the code is used, so a code works once, and
 *   purged when it expires. Only the latest challenge per destination exists.
 * - ACC-01: rate-limit counters are keyed by an HMAC of the destination or
 *   client address, never the value itself.
 * - ACC-13: a session is one signed-in installation (a refresh token family).
 *   Refresh tokens are stored as HMACs; each one works once, and reuse outside
 *   the grace window revokes the whole session. Deleting the account deletes
 *   its sessions.
 */
export const migration0007: Migration = {
  version: 7,
  name: "sign-in-sessions",
  sql: String.raw`
CREATE TABLE sign_in_challenge (
  id uuid PRIMARY KEY,
  channel text NOT NULL CHECK (channel IN ('phone', 'email')),
  destination text NOT NULL CHECK (
    (channel = 'phone' AND destination ~ '^\+[1-9][0-9]{6,14}$')
    OR (
      channel = 'email'
      AND char_length(destination) BETWEEN 3 AND 254
      AND destination = lower(destination)
      AND destination ~ '^[^@\s]+@[^@\s]+$'
    )
  ),
  destination_hash bytea NOT NULL CHECK (octet_length(destination_hash) = 32),
  code_hash bytea NOT NULL CHECK (octet_length(code_hash) = 32),
  attempts integer NOT NULL DEFAULT 0 CHECK (attempts >= 0),
  created_at timestamptz NOT NULL,
  expires_at timestamptz NOT NULL,
  resend_available_at timestamptz NOT NULL,
  CONSTRAINT sign_in_challenge_times_check CHECK (
    expires_at > created_at AND resend_available_at >= created_at
  ),
  CONSTRAINT sign_in_challenge_destination_key UNIQUE (destination_hash)
);

CREATE INDEX sign_in_challenge_expires_idx ON sign_in_challenge (expires_at);

CREATE TABLE auth_rate_limit (
  scope text NOT NULL CHECK (scope ~ '^[a-z_]{1,40}$'),
  key_hash bytea NOT NULL CHECK (octet_length(key_hash) = 32),
  window_start timestamptz NOT NULL,
  hits integer NOT NULL CHECK (hits >= 1),
  PRIMARY KEY (scope, key_hash, window_start)
);

CREATE INDEX auth_rate_limit_window_idx ON auth_rate_limit (window_start);

CREATE TABLE auth_session (
  id uuid PRIMARY KEY,
  account_id uuid NOT NULL REFERENCES account (id) ON DELETE CASCADE,
  installation_id uuid NOT NULL,
  platform text NOT NULL CHECK (platform IN ('android')),
  app_version text NOT NULL CHECK (char_length(app_version) BETWEEN 1 AND 32),
  sign_in_method text NOT NULL CHECK (sign_in_method IN ('phone', 'email', 'google')),
  created_at timestamptz NOT NULL,
  expires_at timestamptz NOT NULL CHECK (expires_at > created_at),
  revoked_at timestamptz,
  revoked_reason text CHECK (
    revoked_reason IS NULL OR revoked_reason IN ('signed_out', 'refresh_token_reuse', 'replaced')
  ),
  CONSTRAINT auth_session_revoked_check CHECK ((revoked_at IS NULL) = (revoked_reason IS NULL))
);

CREATE INDEX auth_session_account_idx ON auth_session (account_id, installation_id);
CREATE INDEX auth_session_expires_idx ON auth_session (expires_at);

CREATE TABLE auth_refresh_token (
  id uuid PRIMARY KEY,
  session_id uuid NOT NULL REFERENCES auth_session (id) ON DELETE CASCADE,
  parent_id uuid REFERENCES auth_refresh_token (id) ON DELETE SET NULL,
  token_hash bytea NOT NULL CHECK (octet_length(token_hash) = 32),
  issued_at timestamptz NOT NULL,
  expires_at timestamptz NOT NULL CHECK (expires_at > issued_at),
  used_at timestamptz,
  replaced_at timestamptz,
  CONSTRAINT auth_refresh_token_hash_key UNIQUE (token_hash),
  -- A token is either exchanged (used) or replaced within the grace window, never both.
  CONSTRAINT auth_refresh_token_state_check CHECK (used_at IS NULL OR replaced_at IS NULL)
);

CREATE INDEX auth_refresh_token_session_idx ON auth_refresh_token (session_id);
CREATE INDEX auth_refresh_token_parent_idx ON auth_refresh_token (parent_id);

CREATE TABLE idempotency_record (
  account_id uuid NOT NULL REFERENCES account (id) ON DELETE CASCADE,
  idempotency_key uuid NOT NULL,
  operation text NOT NULL CHECK (operation ~ '^[a-z_]{1,40}$'),
  request_hash bytea NOT NULL CHECK (octet_length(request_hash) = 32),
  resource_id uuid NOT NULL,
  created_at timestamptz NOT NULL,
  PRIMARY KEY (account_id, idempotency_key)
);

CREATE INDEX idempotency_record_created_idx ON idempotency_record (created_at);
`,
};
