// TEST FIXTURE: not real safety or nutrition data. Fictional households,
// profiles and rules; phone numbers on an unassigned range.
import { randomUUID } from "node:crypto";

import { afterAll, beforeAll, describe, expect, it } from "vitest";

import { consentStateOf, latestHealthConsents } from "../db/consent.js";
import { ConsentRequiredError } from "../db/errors.js";
import type { SqlExecutor } from "../db/executor.js";
import { insertHardRule } from "../db/hard-rules.js";
import { HealthDataKeys } from "../db/health-data-keys.js";
import { migrate } from "../db/migrate.js";
import { DATABASE_TARGETS, type TestDatabase } from "../db/testing/databases.js";
import { addProfile, randomLocalKeys } from "../db/testing/seed.js";
import {
  contractErrors,
  signInWithHousehold,
  startHarness,
  type Harness,
  type HouseholdSession,
  type Response,
} from "../http/testing/harness.js";
import { AGE_GROUPS, dataHandlingFor } from "./child-data-policy.js";
import { assertHealthDataWritable } from "./consent-service.js";
import { CONSENT_TEXTS } from "./consent-texts.js";

const HEALTH_VERSION = CONSENT_TEXTS.health_data.version;
const WITHDRAWAL_DAYS = 7;

function expectProblem(response: Response, status: number, code: string): void {
  expect(response.status, response.raw).toBe(status);
  expect(contractErrors("Problem", response.body)).toEqual([]);
  expect(response.body).toMatchObject({ status, code, detail: null });
}

for (const target of DATABASE_TARGETS) {
  if (target.skipReason !== null) {
    describe(`consent API: ${target.name}`, () => {
      it.skip(`skipped: ${target.skipReason}`, () => undefined);
    });
    continue;
  }

  describe(`consent API: ${target.name}`, () => {
    let opened: TestDatabase;
    let db: SqlExecutor;
    let api: Harness;
    const keys = new HealthDataKeys(randomLocalKeys());

    beforeAll(async () => {
      opened = await target.open();
      db = opened.executor;
      await migrate(db);
      api = await startHarness(db, {
        targets: { dataManagement: { healthConsentWithdrawalDeletionDays: WITHDRAWAL_DAYS } },
      });
    });

    afterAll(async () => {
      await api.close();
      await opened.close();
    });

    const consentsUrl = (profileId: string) => `/v1/household/profiles/${profileId}/consents`;
    const decide = (
      home: HouseholdSession,
      profileId: string,
      body: object = { decision: "given", textVersion: HEALTH_VERSION, language: "id" },
      idempotencyKey?: string,
    ) =>
      api.request("POST", `${consentsUrl(profileId)}/health-data`, {
        token: home.token,
        body,
        ...(idempotencyKey === undefined ? {} : { headers: { "idempotency-key": idempotencyKey } }),
      });
    const withdraw = (home: HouseholdSession, profileId: string) =>
      api.request("POST", `${consentsUrl(profileId)}/health-data/withdraw`, { token: home.token });
    const stateOf = async (home: HouseholdSession, profileId: string) =>
      consentStateOf((await latestHealthConsents(db, home.householdId, [profileId])).get(profileId))
        .status;
    const ruleCount = async (profileId: string) =>
      Number(
        (
          await db.query<{ n: string }>(
            `SELECT count(*) AS n FROM hard_rule WHERE profile_id = $1`,
            [profileId],
          )
        ).rows[0]?.n,
      );

    describe("ACC-08 consent texts", () => {
      it("ACC-08 the current health-data text is served in both languages, marked as a draft", async () => {
        const home = await signInWithHousehold(api);
        for (const language of ["id", "en"]) {
          const text = await api.request(
            "GET",
            `/v1/consent-texts/health_data?language=${language}`,
            { token: home.token },
          );
          expect(text.status, text.raw).toBe(200);
          expect(contractErrors("ConsentText", text.body)).toEqual([]);
          expect(text.body).toMatchObject({
            purpose: "health_data",
            version: HEALTH_VERSION,
            language,
            isDraft: true,
          });
        }
        const guardian = await api.request(
          "GET",
          "/v1/consent-texts/guardian_confirmation?language=id",
          { token: home.token },
        );
        expect(contractErrors("ConsentText", guardian.body)).toEqual([]);
      });

      it("ACC-08 unknown purpose is 404, a missing language 400, and no token 401", async () => {
        const home = await signInWithHousehold(api);
        expectProblem(
          await api.request("GET", "/v1/consent-texts/marketing?language=id", {
            token: home.token,
          }),
          404,
          "not_found",
        );
        expectProblem(
          await api.request("GET", "/v1/consent-texts/health_data", { token: home.token }),
          400,
          "validation_failed",
        );
        expectProblem(
          await api.request("GET", "/v1/consent-texts/health_data?language=id"),
          401,
          "unauthenticated",
        );
      });
    });

    describe("SET-03 consent recorded per member with date and text version", () => {
      it("SET-03 a given consent is recorded with the date, version, language and manager", async () => {
        const home = await signInWithHousehold(api);
        const recorded = await decide(home, home.managerProfileId);
        expect(recorded.status, recorded.raw).toBe(201);
        expect(contractErrors("ConsentRecord", recorded.body)).toEqual([]);
        expect(recorded.body).toMatchObject({
          profileId: home.managerProfileId,
          purpose: "health_data",
          decision: "given",
          textVersion: HEALTH_VERSION,
          language: "id",
          decidedAt: api.clock.now().toISOString(),
          recordedByAccountId: home.accountId,
          withdrawnAt: null,
          deletionDueBy: null,
        });
        expect(await stateOf(home, home.managerProfileId)).toBe("given");

        const listed = await api.request("GET", consentsUrl(home.managerProfileId), {
          token: home.token,
        });
        expect(listed.status).toBe(200);
        expect(contractErrors("ConsentRecordList", listed.body)).toEqual([]);
        expect((listed.body as { items: { id: string }[] }).items.map((r) => r.id)).toEqual([
          (recorded.body as { id: string }).id,
        ]);
      });

      it("SET-03 consent is per member: one member's consent does not cover another", async () => {
        const home = await signInWithHousehold(api);
        const other = await addProfile(db, home, "adult");
        expect((await decide(home, home.managerProfileId)).status).toBe(201);
        expect(await stateOf(home, other)).toBe("none");
      });

      it("SET-03 an outdated or unknown text version is refused and nothing is recorded", async () => {
        const home = await signInWithHousehold(api);
        expectProblem(
          await decide(home, home.managerProfileId, {
            decision: "given",
            textVersion: "health-data-draft-0",
            language: "id",
          }),
          409,
          "consent_text_outdated",
        );
        expect(await stateOf(home, home.managerProfileId)).toBe("none");
      });

      it("SET-03 nothing is pre-given: a decision must be explicit and well formed", async () => {
        const home = await signInWithHousehold(api);
        for (const body of [
          {},
          { textVersion: HEALTH_VERSION, language: "id" },
          { decision: "yes", textVersion: HEALTH_VERSION, language: "id" },
          { decision: "given", textVersion: HEALTH_VERSION, language: "id", profileId: "x" },
        ]) {
          expectProblem(await decide(home, home.managerProfileId, body), 400, "validation_failed");
        }
        expect(await stateOf(home, home.managerProfileId)).toBe("none");
      });

      it("SET-03 a decline is recorded and stores no rules (QUESTIONS #47)", async () => {
        const home = await signInWithHousehold(api);
        const declined = await decide(home, home.managerProfileId, {
          decision: "declined",
          textVersion: HEALTH_VERSION,
          language: "en",
        });
        expect(declined.status).toBe(201);
        expect(declined.body).toMatchObject({ decision: "declined", language: "en" });
        expect(await stateOf(home, home.managerProfileId)).toBe("declined");
        await expect(
          assertHealthDataWritable(db, home.householdId, home.managerProfileId),
        ).rejects.toBeInstanceOf(ConsentRequiredError);
      });

      it("SET-03 a repeated decision with the same Idempotency-Key returns the first record", async () => {
        const home = await signInWithHousehold(api);
        const key = randomUUID();
        const first = await decide(home, home.managerProfileId, undefined, key);
        const again = await decide(home, home.managerProfileId, undefined, key);
        expect(again.status).toBe(201);
        expect(again.body).toEqual(first.body);
        const listed = await api.request("GET", consentsUrl(home.managerProfileId), {
          token: home.token,
        });
        expect((listed.body as { items: unknown[] }).items).toHaveLength(1);
        expectProblem(
          await decide(
            home,
            home.managerProfileId,
            { decision: "declined", textVersion: HEALTH_VERSION, language: "id" },
            key,
          ),
          409,
          "idempotency_key_reused",
        );
      });
    });

    describe("SET-03, SET-04 consent can be withdrawn at any time", () => {
      it("SET-04 withdrawal destroys the member's key and rules at once and sets the deletion deadline from config", async () => {
        const home = await signInWithHousehold(api);
        expect((await decide(home, home.managerProfileId)).status).toBe(201);
        await insertHardRule(db, keys, {
          householdId: home.householdId,
          profileId: home.managerProfileId,
          rule: { type: "allergy", allergen: "peanut" },
          mappingConfirmedBy: null,
        });
        expect(await ruleCount(home.managerProfileId)).toBe(1);

        api.clock.advance(60);
        const withdrawn = await withdraw(home, home.managerProfileId);
        expect(withdrawn.status, withdrawn.raw).toBe(200);
        expect(contractErrors("ConsentRecord", withdrawn.body)).toEqual([]);
        const now = api.clock.now();
        expect(withdrawn.body).toMatchObject({
          decision: "given",
          withdrawnAt: now.toISOString(),
          deletionDueBy: new Date(now.getTime() + WITHDRAWAL_DAYS * 86_400_000).toISOString(),
        });
        expect(await ruleCount(home.managerProfileId)).toBe(0);
        const keyRows = await db.query(`SELECT 1 FROM health_data_key WHERE profile_id = $1`, [
          home.managerProfileId,
        ]);
        expect(keyRows.rows).toHaveLength(0);
        expect(await stateOf(home, home.managerProfileId)).toBe("withdrawn");
        await expect(
          assertHealthDataWritable(db, home.householdId, home.managerProfileId),
        ).rejects.toBeInstanceOf(ConsentRequiredError);

        expectProblem(await withdraw(home, home.managerProfileId), 409, "consent_not_active");
      });

      it("SET-03 withdrawing without a current consent is 409 consent_not_active", async () => {
        const home = await signInWithHousehold(api);
        expectProblem(await withdraw(home, home.managerProfileId), 409, "consent_not_active");
      });

      it("SET-03 consent can be given again after a withdrawal, as a new record", async () => {
        const home = await signInWithHousehold(api);
        await decide(home, home.managerProfileId);
        await withdraw(home, home.managerProfileId);
        api.clock.advance(1);
        expect((await decide(home, home.managerProfileId)).status).toBe(201);
        expect(await stateOf(home, home.managerProfileId)).toBe("given");
        const listed = await api.request("GET", consentsUrl(home.managerProfileId), {
          token: home.token,
        });
        const items = (listed.body as { items: { withdrawnAt: string | null }[] }).items;
        expect(items).toHaveLength(2);
        expect(items[0]?.withdrawnAt).toBeNull();
        expect(items[1]?.withdrawnAt).not.toBeNull();
      });
    });

    describe("ACC-08 no health data without an active consent", () => {
      it("ACC-08 the health-data gate refuses none, declined and withdrawn, and allows given", async () => {
        const home = await signInWithHousehold(api);
        const member = await addProfile(db, home, "adult");
        await expect(assertHealthDataWritable(db, home.householdId, member)).rejects.toBeInstanceOf(
          ConsentRequiredError,
        );
        await decide(home, member);
        await expect(
          assertHealthDataWritable(db, home.householdId, member),
        ).resolves.toBeUndefined();
        await withdraw(home, member);
        await expect(assertHealthDataWritable(db, home.householdId, member)).rejects.toBeInstanceOf(
          ConsentRequiredError,
        );
      });
    });

    describe("SET-10, PRF-18 children's profiles", () => {
      it("SET-10 PRF-18 infant, child and teen are children: guardian confirmation required, health data off by default, never for marketing", () => {
        for (const ageGroup of AGE_GROUPS) {
          const handling = dataHandlingFor(ageGroup);
          const child = ageGroup === "infant" || ageGroup === "child" || ageGroup === "teen";
          expect(handling).toEqual({
            isChild: child,
            healthDataByDefault: "off",
            guardianConfirmationRequired: child,
            marketingUseAllowed: false,
          });
        }
      });

      it("PRF-18 the policy agrees with the database's generated child flag", async () => {
        const home = await signInWithHousehold(api);
        for (const ageGroup of AGE_GROUPS) {
          const id = await addProfile(db, home, ageGroup);
          const { rows } = await db.query<{ is_child: boolean }>(
            `SELECT is_child FROM profile WHERE id = $1`,
            [id],
          );
          expect(rows[0]?.is_child, ageGroup).toBe(dataHandlingFor(ageGroup).isChild);
        }
      });

      it("SET-10 a child's profile starts with health data off; consent is recorded by the manager after the guardian confirmation", async () => {
        const home = await signInWithHousehold(api);
        const child = await addProfile(db, home, "child");
        expect(await stateOf(home, child)).toBe("none");
        await expect(assertHealthDataWritable(db, home.householdId, child)).rejects.toBeInstanceOf(
          ConsentRequiredError,
        );
        expect((await decide(home, child)).status).toBe(201);
        const listed = await api.request("GET", consentsUrl(child), { token: home.token });
        const purposes = (listed.body as { items: { purpose: string }[] }).items.map(
          (r) => r.purpose,
        );
        expect(purposes).toEqual(["health_data", "guardian_confirmation"]);
      });

      it("SET-10 a child profile cannot exist without the guardian confirmation (database)", async () => {
        const home = await signInWithHousehold(api);
        await expect(
          addProfile(db, home, "teen", { withGuardianConfirmation: false }),
        ).rejects.toMatchObject({ code: "KM002" });
      });
    });

    describe("NFR-09 IDOR: another household's consent cannot be read or changed", () => {
      it("NFR-09 every consent endpoint answers 404 for another household's profile and changes nothing", async () => {
        const a = await signInWithHousehold(api);
        const b = await signInWithHousehold(api);
        const bChild = await addProfile(db, b, "child");
        expect((await decide(b, b.managerProfileId)).status).toBe(201);
        const before = await db.query(
          `SELECT id, withdrawn_at FROM consent_record WHERE household_id = $1 ORDER BY seq`,
          [b.householdId],
        );

        for (const profileId of [b.managerProfileId, bChild]) {
          expectProblem(
            await api.request("GET", consentsUrl(profileId), { token: a.token }),
            404,
            "not_found",
          );
          expectProblem(await decide(a, profileId), 404, "not_found");
          expectProblem(
            await decide(a, profileId, {
              decision: "declined",
              textVersion: HEALTH_VERSION,
              language: "id",
            }),
            404,
            "not_found",
          );
          expectProblem(await withdraw(a, profileId), 404, "not_found");
        }
        // IDs that cannot exist answer the same way as another household's.
        for (const profileId of ["not-a-uuid", randomUUID(), b.householdId]) {
          expectProblem(await withdraw(a, profileId), 404, "not_found");
        }
        // The household cannot be named in the body either.
        expectProblem(
          await decide(a, a.managerProfileId, {
            decision: "given",
            textVersion: HEALTH_VERSION,
            language: "id",
            householdId: b.householdId,
          }),
          400,
          "validation_failed",
        );

        const after = await db.query(
          `SELECT id, withdrawn_at FROM consent_record WHERE household_id = $1 ORDER BY seq`,
          [b.householdId],
        );
        expect(after.rows).toEqual(before.rows);
        expect(await stateOf(b, b.managerProfileId)).toBe("given");
        expect(await stateOf(a, a.managerProfileId)).toBe("none");
      });
    });

    describe("privacy", () => {
      it("profile names never appear in logs or error responses", async () => {
        const home = await signInWithHousehold(api);
        await decide(home, home.managerProfileId);
        const failed = await withdraw(home, randomUUID());
        expect(failed.raw).not.toContain("Ibu Uji");
        expect(api.logger.text).not.toContain("Ibu Uji");
        expect(api.logger.text).not.toContain("Profil Uji");
      });
    });
  });
}
