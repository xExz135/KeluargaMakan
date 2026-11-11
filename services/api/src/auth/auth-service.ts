import { randomUUID } from "node:crypto";

import type { ApiConfig } from "../../config/api.js";
import { ApiError, rateLimited, unauthenticated, validationFailed } from "../api-error.js";
import { withDbErrors } from "../db/errors.js";
import type { SqlExecutor } from "../db/executor.js";
import { isUuid } from "../db/ids.js";
import { signAccessToken, verifyAccessToken } from "./access-token.js";
import { readAccount, type AccountView, type SignInMethod } from "./accounts.js";
import type { SignInCodeSender } from "./code-sender.js";
import { constantTimeEqual, keyedHash, randomDigits, randomToken } from "./crypto.js";
import { clientRateKey } from "./client-address.js";
import { canonicalDestination, destinationRateKey, type SignInChannel } from "./destination.js";
import { RateLimiter } from "./rate-limiter.js";
import type { AuthSecrets } from "./secrets.js";

/**
 * ACC-01, ACC-03, ACC-13 sign-in and sessions.
 *
 * Privacy (T-016 L2): contact details, codes and tokens never appear in an
 * error message or log line. Database errors pass through `withDbErrors`, so
 * a constraint error cannot carry a phone number out. Lock waits, deadlocks
 * and serialization failures become the retryable `ConcurrentUpdateError`
 * (HTTP 503), never a success.
 */

export interface Clock {
  now(): Date;
}

export const systemClock: Clock = { now: () => new Date() };

export interface DeviceInfo {
  readonly installationId: string;
  readonly platform: "android";
  readonly appVersion: string;
}

export interface SignInCodeChallenge {
  readonly challengeId: string;
  readonly channel: SignInChannel;
  readonly codeLength: number;
  readonly expiresAt: Date;
  readonly resendAvailableAt: Date;
}

export interface SessionTokens {
  readonly accessToken: string;
  readonly accessTokenExpiresAt: Date;
  readonly refreshToken: string;
  readonly refreshTokenExpiresAt: Date;
}

export interface SignedIn {
  readonly tokens: SessionTokens;
  readonly account: AccountView;
  readonly isNewAccount: boolean;
}

/** Who is calling, from a valid access token on an active session. */
export interface AuthContext {
  readonly accountId: string;
  readonly sessionId: string;
  readonly householdId: string | null;
}

const REFRESH_PREFIX = "kmr1_";
const REFRESH_TOKEN_PATTERN = /^kmr1_[A-Za-z0-9_-]{43}$/;

const codeInvalid = () => new ApiError("code_invalid", 400, "The sign-in code is not valid");
const codeExpired = () => new ApiError("code_expired", 400, "The sign-in code has expired");
const attemptsExceeded = () =>
  new ApiError("code_attempts_exceeded", 400, "Too many wrong sign-in codes for this challenge");
const refreshInvalid = () =>
  new ApiError("refresh_token_invalid", 401, "The refresh token is not valid");
const codeSendingUnavailable = () =>
  new ApiError("sign_in_method_unavailable", 503, "The sign-in code could not be sent");

function minDate(a: Date, b: Date): Date {
  return a.getTime() <= b.getTime() ? a : b;
}

const addSeconds = (date: Date, seconds: number) => new Date(date.getTime() + seconds * 1000);

export interface AuthServiceDeps {
  readonly db: SqlExecutor;
  readonly config: ApiConfig;
  readonly secrets: AuthSecrets;
  readonly codeSender: SignInCodeSender;
  readonly clock?: Clock;
}

export class AuthService {
  readonly #db: SqlExecutor;
  readonly #config: ApiConfig;
  readonly #secrets: AuthSecrets;
  readonly #codeSender: SignInCodeSender;
  readonly #clock: Clock;
  readonly #limiter: RateLimiter;

  constructor(deps: AuthServiceDeps) {
    this.#db = deps.db;
    this.#config = deps.config;
    this.#secrets = deps.secrets;
    this.#codeSender = deps.codeSender;
    this.#clock = deps.clock ?? systemClock;
    this.#limiter = new RateLimiter(deps.db, deps.secrets.hashKey);
  }

  /** Runs `fn` in one transaction with the configured lock timeout. */
  #transaction<T>(fn: (tx: SqlExecutor) => Promise<T>): Promise<T> {
    return withDbErrors(() =>
      this.#db.transaction(async (tx) => {
        await tx.query(`SELECT set_config('lock_timeout', $1, true)`, [
          `${this.#config.sessions.lockTimeoutMs}ms`,
        ]);
        return fn(tx);
      }),
    );
  }

  async #limit(
    scope: Parameters<RateLimiter["hit"]>[0],
    key: string,
    rule: Parameters<RateLimiter["hit"]>[2],
    now: Date,
  ): Promise<void> {
    const decision = await this.#limiter.hit(scope, key, rule, now);
    if (!decision.allowed) throw rateLimited(decision.retryAfterSeconds);
  }

  /**
   * ACC-01: creates a challenge and sends a code. The answer is the same
   * whether or not an account exists for the destination. Only the latest
   * challenge per destination exists, and a new one is refused (429) until
   * the resend wait has passed.
   *
   * Limits (security review H1, M1): per client address (IPv6 by /64), per
   * destination per hour and per day, and no new code while the destination
   * has reached its wrong-code cap. Destination limits use the rate key, so
   * `a+x@…` or Gmail dots do not get their own budget.
   */
  async requestCode(
    input: {
      readonly channel: SignInChannel;
      readonly destination: string;
      readonly language: "id" | "en";
    },
    clientAddress: string,
  ): Promise<SignInCodeChallenge> {
    const now = this.#clock.now();
    const { rateLimits, signInCode } = this.#config;
    const destination = canonicalDestination(input.channel, input.destination);
    if (destination === null) {
      throw validationFailed([{ pointer: "/destination", code: "invalid_format" }]);
    }
    const rateKey = destinationRateKey(input.channel, destination);
    await this.#limit(
      "code_request_client",
      clientRateKey(clientAddress),
      rateLimits.codeRequestPerClient,
      now,
    );
    const failures = await this.#limiter.check(
      "code_verify_failure_destination",
      rateKey,
      rateLimits.codeVerifyFailuresPerDestination,
      now,
    );
    if (!failures.allowed) throw rateLimited(failures.retryAfterSeconds);
    await this.#limit(
      "code_request_destination",
      rateKey,
      rateLimits.codeRequestPerDestination,
      now,
    );
    await this.#limit(
      "code_request_destination_daily",
      rateKey,
      rateLimits.codeRequestPerDestinationDaily,
      now,
    );

    const challengeId = randomUUID();
    const code = randomDigits(signInCode.length);
    const expiresAt = addSeconds(now, signInCode.ttlSeconds);
    const resendAvailableAt = addSeconds(now, signInCode.resendWaitSeconds);
    const destinationHash = keyedHash(
      this.#secrets.hashKey,
      "destination",
      input.channel,
      destination,
    );

    const { rows } = await withDbErrors(() =>
      this.#db.query<{ id: string }>(
        `INSERT INTO sign_in_challenge
           (id, channel, destination, destination_hash, code_hash, attempts,
            created_at, expires_at, resend_available_at)
         VALUES ($1, $2, $3, $4, $5, 0, $6, $7, $8)
         ON CONFLICT (destination_hash) DO UPDATE SET
           id = EXCLUDED.id,
           channel = EXCLUDED.channel,
           destination = EXCLUDED.destination,
           code_hash = EXCLUDED.code_hash,
           attempts = 0,
           created_at = EXCLUDED.created_at,
           expires_at = EXCLUDED.expires_at,
           resend_available_at = EXCLUDED.resend_available_at
         WHERE sign_in_challenge.resend_available_at <= EXCLUDED.created_at
         RETURNING id`,
        [
          challengeId,
          input.channel,
          destination,
          destinationHash,
          keyedHash(this.#secrets.hashKey, "sign_in_code", challengeId, code),
          now,
          expiresAt,
          resendAvailableAt,
        ],
      ),
    );
    if (rows.length === 0) {
      const waiting = await withDbErrors(() =>
        this.#db.query<{ resend_available_at: Date }>(
          `SELECT resend_available_at FROM sign_in_challenge WHERE destination_hash = $1`,
          [destinationHash],
        ),
      );
      const until = waiting.rows[0]?.resend_available_at ?? resendAvailableAt;
      throw rateLimited(Math.max(1, Math.ceil((until.getTime() - now.getTime()) / 1000)));
    }

    try {
      await this.#codeSender.send({
        challengeId,
        channel: input.channel,
        destination: destination,
        code,
        language: input.language,
        expiresAt,
      });
    } catch {
      // The sender's error is not kept or logged: a vendor error may contain
      // the destination. Remove the unusable challenge so the user can retry.
      await withDbErrors(() =>
        this.#db.query(`DELETE FROM sign_in_challenge WHERE id = $1`, [challengeId]),
      ).catch(() => undefined);
      throw codeSendingUnavailable();
    }

    return {
      challengeId,
      channel: input.channel,
      codeLength: signInCode.length,
      expiresAt,
      resendAvailableAt,
    };
  }

  /**
   * ACC-01, ACC-03, ACC-13: verifies a code. A code works once; wrong codes
   * count towards the attempt limit (the count is committed even though the
   * request fails). The first sign-in creates a manager account without a
   * household; later sign-ins, on any device, return the same account.
   */
  async verifyCode(
    input: { readonly challengeId: string; readonly code: string; readonly device: DeviceInfo },
    clientAddress: string,
  ): Promise<SignedIn> {
    const now = this.#clock.now();
    const { rateLimits } = this.#config;
    await this.#limit(
      "code_verify_client",
      clientRateKey(clientAddress),
      rateLimits.codeVerifyPerClient,
      now,
    );
    if (!isUuid(input.challengeId)) throw codeInvalid();
    const { maxAttempts } = this.#config.signInCode;

    type Outcome =
      | { readonly kind: "error"; readonly error: ApiError }
      | {
          readonly kind: "signed_in";
          readonly accountId: string;
          readonly isNewAccount: boolean;
          readonly sessionId: string;
          readonly sessionExpiresAt: Date;
          readonly refreshToken: string;
          readonly refreshTokenExpiresAt: Date;
        };

    const outcome = await this.#transaction<Outcome>(async (tx) => {
      const { rows } = await tx.query<{
        channel: SignInChannel;
        destination: string;
        code_hash: Uint8Array;
        attempts: number;
        expires_at: Date;
      }>(
        `SELECT channel, destination, code_hash, attempts, expires_at
           FROM sign_in_challenge WHERE id = $1 FOR UPDATE`,
        [input.challengeId],
      );
      const challenge = rows[0];
      if (challenge === undefined) return { kind: "error", error: codeInvalid() };
      if (challenge.expires_at.getTime() <= now.getTime()) {
        await tx.query(`DELETE FROM sign_in_challenge WHERE id = $1`, [input.challengeId]);
        return { kind: "error", error: codeExpired() };
      }
      // M1: wrong codes are capped per destination across all its challenges.
      const rateKey = destinationRateKey(challenge.channel, challenge.destination);
      const failures = await this.#limiter.check(
        "code_verify_failure_destination",
        rateKey,
        rateLimits.codeVerifyFailuresPerDestination,
        now,
        tx,
      );
      if (!failures.allowed) {
        return { kind: "error", error: rateLimited(failures.retryAfterSeconds) };
      }
      if (challenge.attempts >= maxAttempts) return { kind: "error", error: attemptsExceeded() };

      const presented = keyedHash(
        this.#secrets.hashKey,
        "sign_in_code",
        input.challengeId,
        input.code,
      );
      if (!constantTimeEqual(presented, Buffer.from(challenge.code_hash))) {
        const updated = await tx.query<{ attempts: number }>(
          `UPDATE sign_in_challenge SET attempts = attempts + 1 WHERE id = $1 RETURNING attempts`,
          [input.challengeId],
        );
        const attempts = Number(updated.rows[0]?.attempts ?? maxAttempts);
        await this.#limiter.record(
          "code_verify_failure_destination",
          rateKey,
          rateLimits.codeVerifyFailuresPerDestination,
          now,
          tx,
        );
        return {
          kind: "error",
          error: attempts >= maxAttempts ? attemptsExceeded() : codeInvalid(),
        };
      }

      // Single use: the challenge (and the destination it held) is gone.
      await tx.query(`DELETE FROM sign_in_challenge WHERE id = $1`, [input.challengeId]);
      const account = await upsertAccount(tx, challenge.channel, challenge.destination);
      const session = await this.#startSession(
        tx,
        account.id,
        challenge.channel,
        input.device,
        now,
      );
      return {
        kind: "signed_in",
        accountId: account.id,
        isNewAccount: account.created,
        ...session,
      };
    });

    if (outcome.kind === "error") throw outcome.error;
    const account = await readAccount(this.#db, outcome.accountId);
    if (account === null) throw unauthenticated();
    return {
      account,
      isNewAccount: outcome.isNewAccount,
      tokens: {
        ...this.#accessToken(outcome.sessionId, outcome.accountId, outcome.sessionExpiresAt, now),
        refreshToken: outcome.refreshToken,
        refreshTokenExpiresAt: outcome.refreshTokenExpiresAt,
      },
    };
  }

  #accessToken(
    sessionId: string,
    accountId: string,
    sessionExpiresAt: Date,
    now: Date,
  ): Pick<SessionTokens, "accessToken" | "accessTokenExpiresAt"> {
    const expiresAt = minDate(
      addSeconds(now, this.#config.sessions.accessTokenTtlSeconds),
      sessionExpiresAt,
    );
    // Whole seconds, so the token and the response carry the same expiry.
    const accessTokenExpiresAt = new Date(Math.floor(expiresAt.getTime() / 1000) * 1000);
    return {
      accessToken: signAccessToken(this.#secrets.tokenKey, {
        sessionId,
        accountId,
        expiresAt: accessTokenExpiresAt,
      }),
      accessTokenExpiresAt,
    };
  }

  async #startSession(
    tx: SqlExecutor,
    accountId: string,
    method: SignInMethod,
    device: DeviceInfo,
    now: Date,
  ): Promise<{
    sessionId: string;
    sessionExpiresAt: Date;
    refreshToken: string;
    refreshTokenExpiresAt: Date;
  }> {
    // A new sign-in on the same installation ends the older session there.
    await tx.query(
      `UPDATE auth_session SET revoked_at = $3, revoked_reason = 'replaced'
        WHERE account_id = $1 AND installation_id = $2 AND revoked_at IS NULL`,
      [accountId, device.installationId, now],
    );
    const sessionId = randomUUID();
    const sessionExpiresAt = addSeconds(now, this.#config.sessions.maxLifetimeSeconds);
    await tx.query(
      `INSERT INTO auth_session
         (id, account_id, installation_id, platform, app_version, sign_in_method, created_at, expires_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
      [
        sessionId,
        accountId,
        device.installationId,
        device.platform,
        device.appVersion,
        method,
        now,
        sessionExpiresAt,
      ],
    );
    const issued = await this.#issueRefreshToken(tx, sessionId, null, sessionExpiresAt, now);
    return { sessionId, sessionExpiresAt, ...issued };
  }

  async #issueRefreshToken(
    tx: SqlExecutor,
    sessionId: string,
    parentId: string | null,
    sessionExpiresAt: Date,
    now: Date,
  ): Promise<{ refreshToken: string; refreshTokenExpiresAt: Date }> {
    const refreshToken = randomToken(REFRESH_PREFIX);
    const refreshTokenExpiresAt = minDate(
      addSeconds(now, this.#config.sessions.refreshTokenTtlSeconds),
      sessionExpiresAt,
    );
    await tx.query(
      `INSERT INTO auth_refresh_token (id, session_id, parent_id, token_hash, issued_at, expires_at)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [
        randomUUID(),
        sessionId,
        parentId,
        keyedHash(this.#secrets.hashKey, "refresh_token", refreshToken),
        now,
        refreshTokenExpiresAt,
      ],
    );
    return { refreshToken, refreshTokenExpiresAt };
  }

  /**
   * ACC-13 rotation. Each refresh token works once. Mobile review L5: a repeat
   * with the same token within the grace window (the response was lost) gets
   * a new pair and the unused pair from the lost response stops working. Any
   * other reuse revokes the whole session (token family).
   */
  async refresh(refreshToken: string, clientAddress: string): Promise<SessionTokens> {
    const now = this.#clock.now();
    await this.#limit(
      "refresh_client",
      clientRateKey(clientAddress),
      this.#config.rateLimits.refreshPerClient,
      now,
    );
    if (!REFRESH_TOKEN_PATTERN.test(refreshToken)) throw refreshInvalid();
    const tokenHash = keyedHash(this.#secrets.hashKey, "refresh_token", refreshToken);
    const graceMs = this.#config.sessions.refreshGraceSeconds * 1000;

    type Outcome =
      | { readonly kind: "invalid" }
      | {
          readonly kind: "rotated";
          readonly sessionId: string;
          readonly accountId: string;
          readonly sessionExpiresAt: Date;
          readonly refreshToken: string;
          readonly refreshTokenExpiresAt: Date;
        };

    const outcome = await this.#transaction<Outcome>(async (tx) => {
      // Locks the session row too, so refreshes of one family run one at a time.
      const { rows } = await tx.query<{
        id: string;
        session_id: string;
        expires_at: Date;
        used_at: Date | null;
        replaced_at: Date | null;
        account_id: string;
        session_expires_at: Date;
        session_revoked_at: Date | null;
      }>(
        `SELECT t.id, t.session_id, t.expires_at, t.used_at, t.replaced_at,
                s.account_id, s.expires_at AS session_expires_at, s.revoked_at AS session_revoked_at
           FROM auth_refresh_token t
           JOIN auth_session s ON s.id = t.session_id
          WHERE t.token_hash = $1
          FOR UPDATE`,
        [tokenHash],
      );
      const token = rows[0];
      if (token === undefined) return { kind: "invalid" };
      if (token.session_revoked_at !== null) return { kind: "invalid" };
      if (token.session_expires_at.getTime() <= now.getTime()) return { kind: "invalid" };
      if (token.expires_at.getTime() <= now.getTime()) return { kind: "invalid" };

      const revokeFamily = async (): Promise<Outcome> => {
        await tx.query(
          `UPDATE auth_session SET revoked_at = $2, revoked_reason = 'refresh_token_reuse'
            WHERE id = $1 AND revoked_at IS NULL`,
          [token.session_id, now],
        );
        return { kind: "invalid" };
      };

      // A token replaced in the grace window was never handed out successfully.
      if (token.replaced_at !== null) return revokeFamily();

      if (token.used_at === null) {
        await tx.query(`UPDATE auth_refresh_token SET used_at = $2 WHERE id = $1`, [token.id, now]);
      } else {
        if (now.getTime() - token.used_at.getTime() > graceMs) return revokeFamily();
        const children = await tx.query<{ id: string; used_at: Date | null }>(
          `SELECT id, used_at FROM auth_refresh_token
            WHERE parent_id = $1 AND replaced_at IS NULL
            FOR UPDATE`,
          [token.id],
        );
        // The pair this token was exchanged for has been used: this is a replay.
        if (children.rows.some((child) => child.used_at !== null)) return revokeFamily();
        await tx.query(
          `UPDATE auth_refresh_token SET replaced_at = $2
            WHERE parent_id = $1 AND replaced_at IS NULL`,
          [token.id, now],
        );
      }
      const issued = await this.#issueRefreshToken(
        tx,
        token.session_id,
        token.id,
        token.session_expires_at,
        now,
      );
      return {
        kind: "rotated",
        sessionId: token.session_id,
        accountId: token.account_id,
        sessionExpiresAt: token.session_expires_at,
        ...issued,
      };
    });

    if (outcome.kind === "invalid") throw refreshInvalid();
    return {
      ...this.#accessToken(outcome.sessionId, outcome.accountId, outcome.sessionExpiresAt, now),
      refreshToken: outcome.refreshToken,
      refreshTokenExpiresAt: outcome.refreshTokenExpiresAt,
    };
  }

  /** ACC-13: revokes this session. Household data stays on the server. */
  async signOut(sessionId: string): Promise<void> {
    const now = this.#clock.now();
    await withDbErrors(() =>
      this.#db.query(
        `UPDATE auth_session SET revoked_at = $2, revoked_reason = 'signed_out'
          WHERE id = $1 AND revoked_at IS NULL`,
        [sessionId, now],
      ),
    );
  }

  /** Checks a bearer access token and that its session is still active. */
  async authenticate(accessToken: string): Promise<AuthContext> {
    const now = this.#clock.now();
    const check = verifyAccessToken(this.#secrets.tokenKey, accessToken, now);
    if (check.status === "expired") {
      throw new ApiError("access_token_expired", 401, "The access token has expired");
    }
    if (check.status === "invalid") throw unauthenticated();
    const { rows } = await withDbErrors(() =>
      this.#db.query<{ household_id: string | null }>(
        `SELECT a.household_id
           FROM auth_session s
           JOIN account a ON a.id = s.account_id
          WHERE s.id = $1 AND a.id = $2 AND s.revoked_at IS NULL AND s.expires_at > $3`,
        [check.claims.sessionId, check.claims.accountId, now],
      ),
    );
    const row = rows[0];
    if (row === undefined) throw unauthenticated();
    return {
      accountId: check.claims.accountId,
      sessionId: check.claims.sessionId,
      householdId: row.household_id,
    };
  }
}

/**
 * ACC-01, ACC-03: finds or creates the manager account for a verified phone
 * number or email. Concurrent first sign-ins for one destination create one
 * account (`ON CONFLICT`); a verified channel is added to the account's
 * sign-in methods.
 */
async function upsertAccount(
  tx: SqlExecutor,
  channel: SignInChannel,
  destination: string,
): Promise<{ id: string; created: boolean }> {
  const inserted = await tx.query<{ id: string }>(
    channel === "phone"
      ? `INSERT INTO account (id, phone, sign_in_methods) VALUES ($1, $2, ARRAY['phone'])
         ON CONFLICT (phone) DO NOTHING RETURNING id`
      : `INSERT INTO account (id, email, sign_in_methods) VALUES ($1, $2, ARRAY['email'])
         ON CONFLICT (email) DO NOTHING RETURNING id`,
    [randomUUID(), destination],
  );
  const created = inserted.rows[0];
  if (created !== undefined) return { id: created.id, created: true };
  const existing = await tx.query<{ id: string }>(
    channel === "phone"
      ? `SELECT id FROM account WHERE phone = $1 FOR UPDATE`
      : `SELECT id FROM account WHERE email = $1 FOR UPDATE`,
    [destination],
  );
  const row = existing.rows[0];
  if (row === undefined) throw new ApiError("service_unavailable", 503, "Account lookup failed");
  await tx.query(
    `UPDATE account
        SET sign_in_methods = array_append(sign_in_methods, $2), updated_at = now()
      WHERE id = $1 AND NOT ($2 = ANY (sign_in_methods))`,
    [row.id, channel],
  );
  return { id: row.id, created: false };
}

/**
 * Removes expired challenges, finished rate-limit windows, sessions that
 * ended more than the retention period ago, and expired idempotency records.
 * Run by the scheduled cleanup job (job queue, later task).
 */
export async function purgeExpiredSignInRecords(
  db: SqlExecutor,
  config: ApiConfig,
  now: Date,
): Promise<{
  challenges: number;
  rateLimits: number;
  sessions: number;
  refreshTokens: number;
  idempotency: number;
}> {
  const longestWindow = Math.max(
    ...Object.values(config.rateLimits).map((rule) => rule.windowSeconds),
  );
  const sessionCutoff = addSeconds(now, -config.retention.endedSessionDays * 24 * 60 * 60);
  const idempotencyCutoff = addSeconds(now, -config.retention.idempotencyKeyHours * 60 * 60);
  return withDbErrors(async () => ({
    challenges: (await db.query(`DELETE FROM sign_in_challenge WHERE expires_at <= $1`, [now]))
      .rowCount,
    // Twice the longest window: a rolling window still counts its oldest bucket.
    rateLimits: (
      await db.query(`DELETE FROM auth_rate_limit WHERE window_start < $1`, [
        addSeconds(now, -2 * longestWindow),
      ])
    ).rowCount,
    sessions: (
      await db.query(`DELETE FROM auth_session WHERE revoked_at < $1 OR expires_at < $1`, [
        sessionCutoff,
      ])
    ).rowCount,
    // An expired refresh token can never be exchanged again; its child keeps working.
    refreshTokens: (await db.query(`DELETE FROM auth_refresh_token WHERE expires_at <= $1`, [now]))
      .rowCount,
    idempotency: (
      await db.query(`DELETE FROM idempotency_record WHERE created_at < $1`, [idempotencyCutoff])
    ).rowCount,
  }));
}
