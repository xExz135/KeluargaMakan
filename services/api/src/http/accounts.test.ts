// TEST FIXTURE: not real safety or nutrition data. Fictional phone numbers on
// an unassigned range, addresses on example.invalid, fictional households.
import { createHash, randomUUID } from "node:crypto";

import { afterAll, afterEach, beforeAll, describe, expect, it } from "vitest";

import { CodeSenderUnavailableError, type SignInCodeSender } from "../auth/code-sender.js";
import { purgeExpiredSignInRecords } from "../auth/auth-service.js";
import type { SqlExecutor } from "../db/executor.js";
import { migrate } from "../db/migrate.js";
import { DATABASE_TARGETS, type TestDatabase } from "../db/testing/databases.js";
import {
  contractErrors,
  device,
  fakeEmail,
  fakePhone,
  startHarness,
  type Harness,
  type Response,
} from "./testing/harness.js";

interface Tokens {
  accessToken: string;
  refreshToken: string;
  accessTokenExpiresAt: string;
  refreshTokenExpiresAt: string;
}
interface SessionBody {
  tokens: Tokens;
  account: { id: string; householdId: string | null; signInMethods: string[] };
  isNewAccount: boolean;
}

const HOUSEHOLD = {
  name: "Keluarga Uji",
  city: "Kota Fiksi",
  timeZone: "Asia/Jakarta",
  language: "id",
  managerProfile: { name: "Ibu", avatar: { style: "initials", colorToken: "avatar_1" } },
} as const;

/** A sender that fails, like a vendor outage. */
const failingSender: SignInCodeSender = {
  send: () => Promise.reject(new CodeSenderUnavailableError()),
};

/** A driver error as node-postgres raises it: an Error with SQLSTATE and constraint fields. */
function driverError(fields: Readonly<Record<string, string>>): Error {
  return Object.assign(new Error(fields["message"] ?? "database error"), fields);
}

/** An executor that fails the statements matching `pattern` with a database error. */
function failingExecutor(
  db: SqlExecutor,
  pattern: RegExp,
  fields: Readonly<Record<string, string>>,
): SqlExecutor {
  const wrap = (inner: SqlExecutor): SqlExecutor => ({
    query: (text, params) =>
      pattern.test(text) ? Promise.reject(driverError(fields)) : inner.query(text, params),
    execScript: (sql) => inner.execScript(sql),
    transaction: (fn) => inner.transaction((tx) => fn(wrap(tx))),
  });
  return wrap(db);
}

function expectProblem(response: Response, status: number, code: string): void {
  expect(response.status, response.raw).toBe(status);
  expect(response.headers["content-type"]).toMatch(/^application\/problem\+json/);
  expect(contractErrors("Problem", response.body)).toEqual([]);
  expect(response.body).toMatchObject({ status, code, detail: null });
}

for (const target of DATABASE_TARGETS) {
  if (target.skipReason !== null) {
    describe(`accounts API: ${target.name}`, () => {
      it.skip(`skipped: ${target.skipReason}`, () => undefined);
    });
    continue;
  }

  describe(`accounts API: ${target.name}`, () => {
    let opened: TestDatabase;
    let db: SqlExecutor;
    let api: Harness;
    const extra: Harness[] = [];

    beforeAll(async () => {
      opened = await target.open();
      db = opened.executor;
      await migrate(db);
      api = await startHarness(db);
    });

    afterEach(async () => {
      for (const harness of extra.splice(0)) await harness.close();
    });

    afterAll(async () => {
      await api.close();
      await opened.close();
    });

    const another = async (options: Parameters<typeof startHarness>[1] = {}) => {
      const harness = await startHarness(db, options);
      extra.push(harness);
      return harness;
    };

    const requestCode = (
      h: Harness,
      destination: string,
      channel: "phone" | "email" = "phone",
      ip?: string,
    ) =>
      h.request("POST", "/v1/auth/code/request", {
        body: { channel, destination, language: "id" },
        ...(ip === undefined ? {} : { ip }),
      });

    const verify = (h: Harness, challengeId: string, code: string, installationId?: string) =>
      h.request("POST", "/v1/auth/code/verify", {
        body: { challengeId, code, device: device(installationId) },
      });

    /** Requests and verifies a code; returns the session. */
    async function signIn(
      h: Harness,
      destination: string,
      channel: "phone" | "email" = "phone",
      installationId?: string,
    ): Promise<SessionBody> {
      const requested = await requestCode(h, destination, channel);
      expect(requested.status, requested.raw).toBe(202);
      const { challengeId } = requested.body as { challengeId: string };
      const code = h.sender.latestCode(
        channel === "email" ? destination.toLowerCase() : destination,
      );
      if (code === null) throw new Error("no code sent");
      const verified = await verify(h, challengeId, code, installationId);
      expect(verified.status, verified.raw).toBe(200);
      expect(contractErrors("Session", verified.body)).toEqual([]);
      return verified.body as SessionBody;
    }

    const refresh = (h: Harness, refreshToken: string) =>
      h.request("POST", "/v1/auth/refresh", { body: { refreshToken } });

    const createHousehold = (h: Harness, token: string, key?: string, body: object = HOUSEHOLD) =>
      h.request("POST", "/v1/household", {
        token,
        body,
        ...(key === undefined ? {} : { headers: { "idempotency-key": key } }),
      });

    describe("ACC-01 sign-in with a phone number or email and a verification code", () => {
      it("ACC-01 a phone number gets a code and the verified code creates a manager account without a household", async () => {
        const phone = fakePhone();
        const requested = await requestCode(api, phone);
        expect(requested.status).toBe(202);
        expect(contractErrors("SignInCodeChallenge", requested.body)).toEqual([]);
        expect(requested.raw).not.toContain(phone);
        expect(requested.body).toMatchObject({ channel: "phone", codeLength: 6 });

        const session = await signIn(api, fakePhone());
        expect(session.isNewAccount).toBe(true);
        expect(session.account).toMatchObject({ householdId: null, signInMethods: ["phone"] });
      });

      it("ACC-01 an email address works the same way and is stored in lower case", async () => {
        const email = fakeEmail();
        const session = await signIn(api, email.toUpperCase(), "email");
        expect(session.account).toMatchObject({ signInMethods: ["email"] });
        const account = await api.request("GET", "/v1/account", {
          token: session.tokens.accessToken,
        });
        expect(account.status).toBe(200);
        expect(contractErrors("Account", account.body)).toEqual([]);
        expect(account.body).toMatchObject({ email, phone: null, role: "manager" });
      });

      it("ACC-01 the code request answers the same whether or not an account exists", async () => {
        const phone = fakePhone();
        const first = await requestCode(api, phone);
        api.clock.advance(api.config.signInCode.resendWaitSeconds);
        await signIn(api, fakePhone());
        const known = await requestCode(api, phone);
        expect(first.status).toBe(known.status);
        expect(Object.keys(first.body as object).sort()).toEqual(
          Object.keys(known.body as object).sort(),
        );
      });

      it("ACC-01 a later sign-in returns the same account (isNewAccount false)", async () => {
        const phone = fakePhone();
        const first = await signIn(api, phone);
        api.clock.advance(api.config.signInCode.resendWaitSeconds);
        const second = await signIn(api, phone);
        expect(second.isNewAccount).toBe(false);
        expect(second.account.id).toBe(first.account.id);
      });

      it("ACC-01 a code works once", async () => {
        const phone = fakePhone();
        const requested = await requestCode(api, phone);
        const { challengeId } = requested.body as { challengeId: string };
        const code = api.sender.latestCode(phone) ?? "";
        expect((await verify(api, challengeId, code)).status).toBe(200);
        expectProblem(await verify(api, challengeId, code), 400, "code_invalid");
      });

      it("ACC-01 a code expires after the configured time", async () => {
        const phone = fakePhone();
        const { challengeId } = (await requestCode(api, phone)).body as { challengeId: string };
        api.clock.advance(api.config.signInCode.ttlSeconds);
        expectProblem(
          await verify(api, challengeId, api.sender.latestCode(phone) ?? ""),
          400,
          "code_expired",
        );
      });

      it("ACC-01 wrong codes count towards the attempt limit; then even the right code is refused", async () => {
        const phone = fakePhone();
        const { challengeId } = (await requestCode(api, phone)).body as { challengeId: string };
        const code = api.sender.latestCode(phone) ?? "";
        const wrong = code === "000000" ? "111111" : "000000";
        const { maxAttempts } = api.config.signInCode;
        for (let i = 1; i < maxAttempts; i += 1) {
          expectProblem(await verify(api, challengeId, wrong), 400, "code_invalid");
        }
        expectProblem(await verify(api, challengeId, wrong), 400, "code_attempts_exceeded");
        expectProblem(await verify(api, challengeId, code), 400, "code_attempts_exceeded");
      });

      it("ACC-01 only the latest code works, and a new code waits for the resend time", async () => {
        const phone = fakePhone();
        const first = (await requestCode(api, phone)).body as { challengeId: string };
        const firstCode = api.sender.latestCode(phone) ?? "";
        const early = await requestCode(api, phone);
        expectProblem(early, 429, "rate_limited");
        expect(Number(early.headers["retry-after"])).toBeGreaterThan(0);
        api.clock.advance(api.config.signInCode.resendWaitSeconds);
        const second = await requestCode(api, phone);
        expect(second.status).toBe(202);
        expectProblem(await verify(api, first.challengeId, firstCode), 400, "code_invalid");
      });

      it("ACC-01 codes are stored only as keyed hashes", async () => {
        const phone = fakePhone();
        const { challengeId } = (await requestCode(api, phone)).body as { challengeId: string };
        const code = api.sender.latestCode(phone) ?? "";
        const { rows } = await db.query<{ code_hash: Uint8Array }>(
          `SELECT code_hash FROM sign_in_challenge WHERE id = $1`,
          [challengeId],
        );
        const stored = Buffer.from(rows[0]?.code_hash ?? []);
        expect(stored.length).toBe(32);
        expect(stored.toString("utf8")).not.toContain(code);
        expect(stored.equals(createHash("sha256").update(code).digest())).toBe(false);
        const all = await db.query(`SELECT * FROM sign_in_challenge WHERE id = $1`, [challengeId]);
        expect(JSON.stringify(all.rows)).not.toContain(`"${code}"`);
      });

      it("ACC-01 code requests are rate-limited per destination", async () => {
        const h = await another({
          config: {
            signInCode: { resendWaitSeconds: 1 },
            rateLimits: { codeRequestPerDestination: { limit: 2, windowSeconds: 3600 } },
          },
        });
        const phone = fakePhone();
        expect((await requestCode(h, phone, "phone", "198.51.100.1")).status).toBe(202);
        h.clock.advance(1);
        expect((await requestCode(h, phone, "phone", "198.51.100.2")).status).toBe(202);
        h.clock.advance(1);
        const limited = await requestCode(h, phone, "phone", "198.51.100.3");
        expectProblem(limited, 429, "rate_limited");
        expect(Number(limited.headers["retry-after"])).toBeGreaterThan(0);
        expect((limited.body as { retryAfterSeconds: number }).retryAfterSeconds).toBeGreaterThan(
          0,
        );
      });

      it("ACC-01 code requests and verifications are rate-limited per client address", async () => {
        const h = await another({
          config: {
            rateLimits: {
              codeRequestPerClient: { limit: 2, windowSeconds: 3600 },
              codeVerifyPerClient: { limit: 2, windowSeconds: 900 },
            },
          },
        });
        const ip = "203.0.113.7";
        expect((await requestCode(h, fakePhone(), "phone", ip)).status).toBe(202);
        expect((await requestCode(h, fakePhone(), "phone", ip)).status).toBe(202);
        expectProblem(await requestCode(h, fakePhone(), "phone", ip), 429, "rate_limited");
        expect((await requestCode(h, fakePhone(), "phone", "203.0.113.8")).status).toBe(202);

        const body = { challengeId: randomUUID(), code: "123456", device: device() };
        const verifyFrom = () => h.request("POST", "/v1/auth/code/verify", { body, ip });
        expectProblem(await verifyFrom(), 400, "code_invalid");
        expectProblem(await verifyFrom(), 400, "code_invalid");
        expectProblem(await verifyFrom(), 429, "rate_limited");
      });

      it("ACC-01 Q16 when the code cannot be sent the answer is 503 and no challenge is left", async () => {
        const h = await another({ codeSender: failingSender });
        const phone = fakePhone();
        const response = await requestCode(h, phone);
        expectProblem(response, 503, "sign_in_method_unavailable");
        expect(response.raw).not.toContain(phone);
        const { rows } = await db.query(`SELECT 1 FROM sign_in_challenge WHERE destination = $1`, [
          phone,
        ]);
        expect(rows).toEqual([]);
      });

      it("ACC-01 an invalid destination is refused without echoing it", async () => {
        const response = await api.request("POST", "/v1/auth/code/request", {
          body: { channel: "phone", destination: "0812-not-e164", language: "id" },
        });
        expectProblem(response, 400, "validation_failed");
        expect(response.raw).not.toContain("0812-not-e164");
        expect(response.body).toMatchObject({
          errors: [{ pointer: "/destination", code: "invalid_format" }],
        });
      });

      it("INT-13 Google sign-in answers 503 sign_in_method_unavailable until T-018, so phone or email is offered", async () => {
        const response = await api.request("POST", "/v1/auth/google", {
          body: { idToken: "fixture", device: device() },
        });
        expectProblem(response, 503, "sign_in_method_unavailable");
      });
    });

    describe("ACC-03 exactly one manager account per household", () => {
      it("ACC-03 the signed-in account becomes the only manager, with the manager's own adult profile", async () => {
        const session = await signIn(api, fakePhone());
        const created = await createHousehold(api, session.tokens.accessToken);
        expect(created.status, created.raw).toBe(201);
        expect(contractErrors("Household", created.body)).toEqual([]);
        const household = created.body as {
          id: string;
          managerAccountId: string;
          managerProfileId: string;
        };
        expect(household.managerAccountId).toBe(session.account.id);

        const accounts = await db.query<{ id: string; role: string }>(
          `SELECT id, role FROM account WHERE household_id = $1`,
          [household.id],
        );
        expect(accounts.rows).toEqual([{ id: session.account.id, role: "manager" }]);
        const profiles = await db.query<{ id: string; age_group: string }>(
          `SELECT id, age_group FROM profile WHERE household_id = $1`,
          [household.id],
        );
        expect(profiles.rows).toEqual([{ id: household.managerProfileId, age_group: "adult" }]);

        const account = await api.request("GET", "/v1/account", {
          token: session.tokens.accessToken,
        });
        expect(account.body).toMatchObject({ householdId: household.id });
      });

      it("ACC-03 an account has at most one household", async () => {
        const session = await signIn(api, fakePhone());
        expect((await createHousehold(api, session.tokens.accessToken)).status).toBe(201);
        expectProblem(
          await createHousehold(api, session.tokens.accessToken),
          409,
          "household_exists",
        );
      });

      it("ACC-03 a repeated create with the same Idempotency-Key returns the same household", async () => {
        const session = await signIn(api, fakePhone());
        const key = randomUUID();
        const first = await createHousehold(api, session.tokens.accessToken, key);
        const again = await createHousehold(api, session.tokens.accessToken, key);
        expect(first.status).toBe(201);
        expect(again.status).toBe(201);
        expect((again.body as { id: string }).id).toBe((first.body as { id: string }).id);
        expectProblem(
          await createHousehold(api, session.tokens.accessToken, key, {
            ...HOUSEHOLD,
            city: "Lain",
          }),
          409,
          "idempotency_key_reused",
        );
      });

      it("ACC-03 a second account cannot be attached to a household as manager", async () => {
        const session = await signIn(api, fakePhone());
        const { id } = (await createHousehold(api, session.tokens.accessToken)).body as {
          id: string;
        };
        const other = await signIn(api, fakePhone());
        const error = await db
          .query(`UPDATE account SET household_id = $1 WHERE id = $2`, [id, other.account.id])
          .then(
            () => null,
            (caught: unknown) => caught as { code?: string },
          );
        expect(error?.code).toBe("23505");
      });

      it("ACC-03 GET household before creating one returns 409 household_required", async () => {
        const session = await signIn(api, fakePhone());
        expectProblem(
          await api.request("GET", "/v1/household", { token: session.tokens.accessToken }),
          409,
          "household_required",
        );
      });

      it("ACC-03 the household can be updated; null clears the city", async () => {
        const session = await signIn(api, fakePhone());
        await createHousehold(api, session.tokens.accessToken);
        const updated = await api.request("PATCH", "/v1/household", {
          token: session.tokens.accessToken,
          body: { city: null, language: "en" },
        });
        expect(updated.status, updated.raw).toBe(200);
        expect(contractErrors("Household", updated.body)).toEqual([]);
        expect(updated.body).toMatchObject({ city: null, language: "en", name: HOUSEHOLD.name });
        expectProblem(
          await api.request("PATCH", "/v1/household", {
            token: session.tokens.accessToken,
            body: { timeZone: "Not/AZone" },
          }),
          400,
          "validation_failed",
        );
      });

      it("ACC-03 household requests are refused without a valid access token", async () => {
        expectProblem(await api.request("GET", "/v1/household"), 401, "unauthenticated");
        expectProblem(
          await api.request("GET", "/v1/household", { token: "kma1.bad.token" }),
          401,
          "unauthenticated",
        );
      });
    });

    describe("ACC-13 sign out, then sign in on another device, without losing household data", () => {
      it("ACC-13 integration: household data survives sign-out and a sign-in on a new device", async () => {
        const phone = fakePhone();
        const phoneA = randomUUID();
        const phoneB = randomUUID();
        const onA = await signIn(api, phone, "phone", phoneA);
        const created = (await createHousehold(api, onA.tokens.accessToken)).body as {
          id: string;
          managerProfileId: string;
        };
        // More household data, written directly (profiles are T-020).
        await db.query(
          `INSERT INTO profile (household_id, name, age_group) VALUES ($1, 'Ayah', 'adult')`,
          [created.id],
        );
        const before = await api.request("GET", "/v1/household", { token: onA.tokens.accessToken });

        const signedOut = await api.request("POST", "/v1/auth/sign-out", {
          token: onA.tokens.accessToken,
        });
        expect(signedOut.status).toBe(204);
        expectProblem(
          await api.request("GET", "/v1/household", { token: onA.tokens.accessToken }),
          401,
          "unauthenticated",
        );
        expectProblem(await refresh(api, onA.tokens.refreshToken), 401, "refresh_token_invalid");

        api.clock.advance(api.config.signInCode.resendWaitSeconds);
        const onB = await signIn(api, phone, "phone", phoneB);
        expect(onB.isNewAccount).toBe(false);
        expect(onB.account.id).toBe(onA.account.id);
        expect(onB.account.householdId).toBe(created.id);
        const after = await api.request("GET", "/v1/household", { token: onB.tokens.accessToken });
        expect(after.status).toBe(200);
        expect(after.body).toEqual(before.body);
        const { rows } = await db.query<{ n: number | string }>(
          `SELECT count(*) AS n FROM profile WHERE household_id = $1`,
          [created.id],
        );
        expect(Number(rows[0]?.n)).toBe(2);
      });

      it("ACC-13 a sign-in on one phone does not end the session on another", async () => {
        const phone = fakePhone();
        const onA = await signIn(api, phone, "phone", randomUUID());
        api.clock.advance(api.config.signInCode.resendWaitSeconds);
        await signIn(api, phone, "phone", randomUUID());
        expect(
          (await api.request("GET", "/v1/account", { token: onA.tokens.accessToken })).status,
        ).toBe(200);
      });

      it("ACC-13 signing in again on the same installation ends the older session there", async () => {
        const phone = fakePhone();
        const installation = randomUUID();
        const first = await signIn(api, phone, "phone", installation);
        api.clock.advance(api.config.signInCode.resendWaitSeconds);
        await signIn(api, phone, "phone", installation);
        expectProblem(
          await api.request("GET", "/v1/account", { token: first.tokens.accessToken }),
          401,
          "unauthenticated",
        );
      });

      it("ACC-13 an expired access token is refused with access_token_expired; refresh gives a new one", async () => {
        const session = await signIn(api, fakePhone());
        api.clock.advance(api.config.sessions.accessTokenTtlSeconds);
        expectProblem(
          await api.request("GET", "/v1/account", { token: session.tokens.accessToken }),
          401,
          "access_token_expired",
        );
        const refreshed = await refresh(api, session.tokens.refreshToken);
        expect(refreshed.status, refreshed.raw).toBe(200);
        expect(contractErrors("SessionTokens", refreshed.body)).toEqual([]);
        const tokens = refreshed.body as Tokens;
        expect(tokens.refreshToken).not.toBe(session.tokens.refreshToken);
        expect(
          (await api.request("GET", "/v1/account", { token: tokens.accessToken })).status,
        ).toBe(200);
      });
    });

    describe("ACC-13 refresh-token rotation, grace window and family revocation (mobile review L5)", () => {
      it("ACC-13 a lost refresh response does not sign the user out: a repeat within the grace window gets a new pair", async () => {
        const session = await signIn(api, fakePhone());
        const lost = (await refresh(api, session.tokens.refreshToken)).body as Tokens;
        api.clock.advance(api.config.sessions.refreshGraceSeconds - 1);
        const repeated = await refresh(api, session.tokens.refreshToken);
        expect(repeated.status, repeated.raw).toBe(200);
        const fresh = repeated.body as Tokens;
        expect(fresh.refreshToken).not.toBe(lost.refreshToken);
        // The new pair keeps working.
        const next = await refresh(api, fresh.refreshToken);
        expect(next.status).toBe(200);
        expect(
          (await api.request("GET", "/v1/account", { token: (next.body as Tokens).accessToken }))
            .status,
        ).toBe(200);
      });

      it("ACC-13 the pair from the lost response stops working, and presenting it revokes the session", async () => {
        const session = await signIn(api, fakePhone());
        const lost = (await refresh(api, session.tokens.refreshToken)).body as Tokens;
        const fresh = (await refresh(api, session.tokens.refreshToken)).body as Tokens;
        expectProblem(await refresh(api, lost.refreshToken), 401, "refresh_token_invalid");
        expectProblem(await refresh(api, fresh.refreshToken), 401, "refresh_token_invalid");
        expectProblem(
          await api.request("GET", "/v1/account", { token: fresh.accessToken }),
          401,
          "unauthenticated",
        );
      });

      it("ACC-13 reuse after the new pair was used revokes the whole token family", async () => {
        const session = await signIn(api, fakePhone());
        const second = (await refresh(api, session.tokens.refreshToken)).body as Tokens;
        const third = (await refresh(api, second.refreshToken)).body as Tokens;
        expectProblem(
          await refresh(api, session.tokens.refreshToken),
          401,
          "refresh_token_invalid",
        );
        expectProblem(await refresh(api, third.refreshToken), 401, "refresh_token_invalid");
        expectProblem(
          await api.request("GET", "/v1/account", { token: third.accessToken }),
          401,
          "unauthenticated",
        );
        const { rows } = await db.query<{ revoked_reason: string }>(
          `SELECT revoked_reason FROM auth_session s JOIN account a ON a.id = s.account_id
            WHERE a.id = $1`,
          [session.account.id],
        );
        expect(rows.map((row) => row.revoked_reason)).toEqual(["refresh_token_reuse"]);
      });

      it("ACC-13 reuse after the grace window revokes the whole token family", async () => {
        const session = await signIn(api, fakePhone());
        const second = (await refresh(api, session.tokens.refreshToken)).body as Tokens;
        api.clock.advance(api.config.sessions.refreshGraceSeconds + 1);
        expectProblem(
          await refresh(api, session.tokens.refreshToken),
          401,
          "refresh_token_invalid",
        );
        expectProblem(await refresh(api, second.refreshToken), 401, "refresh_token_invalid");
      });

      it("ACC-13 refresh tokens are stored only as keyed hashes; unknown tokens are refused", async () => {
        const session = await signIn(api, fakePhone());
        const { rows } = await db.query(
          `SELECT t.* FROM auth_refresh_token t JOIN auth_session s ON s.id = t.session_id
            WHERE s.account_id = $1`,
          [session.account.id],
        );
        expect(JSON.stringify(rows)).not.toContain(session.tokens.refreshToken.slice(5, 20));
        expectProblem(await refresh(api, "kmr1_" + "A".repeat(43)), 401, "refresh_token_invalid");
        expectProblem(await refresh(api, "not-a-token"), 401, "refresh_token_invalid");
      });
    });

    describe("retryable errors are 503, never success", () => {
      it("ConcurrentUpdateError (lock wait, deadlock, serialization) on refresh is 503 with Retry-After and changes nothing", async () => {
        const session = await signIn(api, fakePhone());
        // Same database and secrets; the write that marks the token used fails.
        const failing = await startHarness(
          failingExecutor(db, /UPDATE auth_refresh_token SET used_at/, {
            code: "40001",
            message: "could not serialize access",
          }),
          { secrets: api.secrets },
        );
        extra.push(failing);
        const response = await refresh(failing, session.tokens.refreshToken);
        expectProblem(response, 503, "service_unavailable");
        expect(Number(response.headers["retry-after"])).toBeGreaterThan(0);
        expect(response.body).toMatchObject({ retryAfterSeconds: 1 });
        // Rolled back: the token was not consumed, so the session still refreshes.
        expect((await refresh(api, session.tokens.refreshToken)).status).toBe(200);
      });

      it("ConcurrentUpdateError on code verification is 503 and does not count an attempt", async () => {
        const failing = await startHarness(
          failingExecutor(db, /FROM sign_in_challenge WHERE id = \$1 FOR UPDATE/, {
            code: "55P03",
          }),
        );
        extra.push(failing);
        const phone = fakePhone();
        const { challengeId } = (await requestCode(failing, phone)).body as { challengeId: string };
        const response = await verify(failing, challengeId, "000000");
        expectProblem(response, 503, "service_unavailable");
        const { rows } = await db.query<{ attempts: number }>(
          `SELECT attempts FROM sign_in_challenge WHERE id = $1`,
          [challengeId],
        );
        expect(rows[0]?.attempts).toBe(0);
      });
    });

    describe("privacy: no contact details, codes or tokens in logs or error messages (T-016 L2)", () => {
      it("a database error that carries a phone number is answered and logged without it", async () => {
        const phone = fakePhone();
        const failing = await startHarness(
          failingExecutor(db, /INSERT INTO sign_in_challenge/, {
            code: "23505",
            constraint: "sign_in_challenge_destination_key",
            detail: `Key (destination)=(${phone}) already exists.`,
            message: `duplicate key value ${phone}`,
          }),
        );
        extra.push(failing);
        const response = await requestCode(failing, phone);
        expectProblem(response, 500, "internal_error");
        expect(response.raw).not.toContain(phone);
        expect(failing.logger.text).not.toContain(phone);
        expect(failing.logger.text).toContain("DatabaseError:23505");
      });

      it("no flow logs a destination, code or token", async () => {
        const h = await another();
        const phone = fakePhone();
        const email = fakeEmail();
        const session = await signIn(h, phone);
        h.clock.advance(1);
        await signIn(h, email, "email");
        const rotated = (await refresh(h, session.tokens.refreshToken)).body as Tokens;
        await createHousehold(h, rotated.accessToken);
        await h.request("POST", "/v1/auth/sign-out", { token: rotated.accessToken });
        await requestCode(h, phone);
        const secrets = [
          phone,
          email,
          h.sender.latestCode(phone) ?? "",
          session.tokens.accessToken,
          session.tokens.refreshToken,
          rotated.refreshToken,
        ];
        expect(h.logger.lines.length).toBeGreaterThan(5);
        for (const secret of secrets) expect(h.logger.text).not.toContain(secret);
      });

      it("malformed JSON and unknown routes answer with a Problem", async () => {
        expectProblem(
          await api.request("POST", "/v1/auth/code/request", { rawBody: "{not json" }),
          400,
          "validation_failed",
        );
        expectProblem(await api.request("GET", "/v1/nowhere"), 404, "not_found");
      });
    });

    describe("cleanup", () => {
      it("ACC-01 ACC-13 expired challenges, old rate-limit windows and ended sessions are purged", async () => {
        const h = await another();
        const phone = fakePhone();
        await requestCode(h, phone);
        const session = await signIn(h, fakePhone());
        await h.request("POST", "/v1/auth/sign-out", { token: session.tokens.accessToken });
        const later = new Date(h.clock.now().getTime() + 31 * 24 * 3600_000);
        const purged = await purgeExpiredSignInRecords(db, h.config, later);
        expect(purged.challenges).toBeGreaterThanOrEqual(1);
        expect(purged.rateLimits).toBeGreaterThanOrEqual(1);
        expect(purged.sessions).toBeGreaterThanOrEqual(1);
        const { rows } = await db.query(`SELECT 1 FROM auth_session WHERE account_id = $1`, [
          session.account.id,
        ]);
        expect(rows).toEqual([]);
      });
    });

    describe("two connections (PostgreSQL only)", () => {
      it("ACC-13 a refresh that waits on a locked session fails fast with a retryable 503", async (context) => {
        if (opened.openSession === null) {
          context.skip("PGlite has one connection; set TEST_DATABASE_URL to run");
          return;
        }
        const h = await another({ config: { sessions: { lockTimeoutMs: 200 } } });
        const session = await signIn(h, fakePhone());
        const holder = await opened.openSession();
        try {
          await holder.executor.query(
            `SELECT 1 FROM auth_session WHERE account_id = $1 FOR UPDATE`,
            [session.account.id],
          );
          expectProblem(await refresh(h, session.tokens.refreshToken), 503, "service_unavailable");
        } finally {
          await holder.rollback();
        }
        expect((await refresh(h, session.tokens.refreshToken)).status).toBe(200);
      });

      it("ACC-01 concurrent first sign-ins for one phone number create one account", async (context) => {
        if (opened.openSession === null) {
          context.skip("PGlite has one connection; set TEST_DATABASE_URL to run");
          return;
        }
        const phone = fakePhone();
        const holder = await opened.openSession();
        let committed = false;
        try {
          await holder.executor.query(
            `INSERT INTO account (phone, sign_in_methods) VALUES ($1, ARRAY['phone'])`,
            [phone],
          );
          const pending = signIn(api, phone);
          await new Promise((resolve) => setTimeout(resolve, 200));
          await holder.commit();
          committed = true;
          const session = await pending;
          expect(session.isNewAccount).toBe(false);
        } finally {
          if (!committed) await holder.rollback();
        }
        const { rows } = await db.query(`SELECT id FROM account WHERE phone = $1`, [phone]);
        expect(rows).toHaveLength(1);
      });
    });
  });
}
