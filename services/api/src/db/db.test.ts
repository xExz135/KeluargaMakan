// TEST FIXTURE: not real safety or nutrition data. Fictional households, rules
// and ingredients only.
import { randomBytes, randomUUID } from "node:crypto";

import { inspect } from "node:util";

import {
  evaluateWithLog,
  type CekAmanInput,
  type HardRule as CekAmanHardRule,
  type ReferenceIngredient,
} from "@keluargamakan/cek-aman";
import { afterAll, beforeAll, describe, expect, it } from "vitest";

import { defaultTargets } from "../../config/targets.js";
import {
  consentStateOf,
  latestHealthConsents,
  listConsentRecords,
  recordGuardianConfirmation,
  recordHealthConsent,
  rulesConsentState,
  withdrawHealthConsent,
  ConsentNotActiveError,
} from "./consent.js";
import { encryptField, decryptField } from "./crypto/data-key-cipher.js";
import {
  DecryptionError,
  KeyServiceError,
  type KeyEncryptionKey,
  type KeyProvider,
} from "./crypto/key-provider.js";
import { LocalKeyProvider } from "./crypto/local-key-provider.js";
import {
  deleteHousehold,
  deleteProfile,
  enforceHealthConsent,
  purgeExpiredMeals,
  purgeExpiredSafetyLogs,
} from "./deletion.js";
import {
  ConsentRequiredError,
  DatabaseError,
  GuardianConfirmationRequiredError,
  InvalidDataError,
  ManagerProfileNotDeletableError,
  MappingNotApplicableError,
  NotFoundError,
  RulesUnavailableError,
  translateDbError,
} from "./errors.js";
import type { SqlExecutor } from "./executor.js";
import {
  confirmRuleMapping,
  deleteHardRule,
  insertHardRule,
  listProfileRules,
  loadRulesForEvaluation,
} from "./hard-rules.js";
import { HealthDataKeys } from "./health-data-keys.js";
import { MigrationError, migrate } from "./migrate.js";
import { MIGRATIONS } from "./migrations/index.js";
import { insertSafetyLog, readSafetyLog } from "./safety-log.js";
import { SCHEMA_TRACE } from "./schema-trace.js";
import { DATABASE_TARGETS, type TestDatabase } from "./testing/databases.js";
import {
  addProfile,
  randomLocalKeys,
  seedHousehold,
  type SeededHousehold,
} from "./testing/seed.js";

const FREE_TEXT = "tidak boleh bahan fiksi contoh";
const RAW_NAME = "Sambal Fiksi Bu Contoh 0800-0000";

/** A fictional verified ingredient that contains shrimp (test fixture only). */
function fixtureIngredient(id: string, contains: readonly string[]): ReferenceIngredient {
  return {
    id,
    displayName: { id: `Fiksi ${id}`, en: `Fiction ${id}` },
    localNames: [],
    category: "fixture",
    components: { verification: "verified", ingredientIds: [] },
    allergens: { verification: "verified", contains: contains as never, mayContain: [] },
    halal: { verification: "verified", value: "halal", nonHalalSources: [] },
    diet: { verification: "verified", vegetarian: "suitable", vegan: "suitable" },
    brandVaries: false,
    brandVariants: [],
    tkpiCode: null,
  };
}

async function expectRejects<E>(
  promise: Promise<unknown>,
  type: new (...args: never[]) => E,
): Promise<E> {
  const error: unknown = await promise.then(
    () => undefined,
    (caught: unknown) => caught,
  );
  expect(error).toBeInstanceOf(type);
  return error as E;
}

async function dbErrorCode(promise: Promise<unknown>): Promise<unknown> {
  const error: unknown = await promise.then(
    () => undefined,
    (caught: unknown) => caught,
  );
  expect(error, "expected the database to refuse").toBeDefined();
  return (error as { code?: unknown }).code;
}

/** A provider whose health key is replaced, to simulate a wrong key or a KMS outage. */
function withHealthKek(kek: KeyEncryptionKey): KeyProvider {
  return { kek: () => kek };
}

for (const target of DATABASE_TARGETS) {
  if (target.skipReason !== null) {
    describe(`database: ${target.name}`, () => {
      it.skip(`skipped: ${target.skipReason}`, () => undefined);
    });
    continue;
  }

  describe(`database: ${target.name}`, () => {
    let opened: TestDatabase;
    let close: () => Promise<void>;
    let db: SqlExecutor;
    let provider: LocalKeyProvider;
    let keys: HealthDataKeys;

    beforeAll(async () => {
      opened = await target.open();
      db = opened.executor;
      close = () => opened.close();
      await migrate(db);
      provider = randomLocalKeys();
      keys = new HealthDataKeys(provider);
    });

    afterAll(async () => {
      await close();
    });

    const giveConsent = (home: SeededHousehold, profileId: string) =>
      recordHealthConsent(db, {
        householdId: home.householdId,
        profileId,
        decision: "given",
        textVersion: "health-data-draft-1",
        language: "id",
        recordedByAccountId: home.accountId,
      });

    const count = async (sql: string, params: readonly unknown[] = []) =>
      Number((await db.query<{ n: string | number }>(sql, params)).rows[0]?.n ?? 0);

    describe("migrations", () => {
      it("are idempotent", async () => {
        expect((await migrate(db)).applied).toEqual([]);
      });

      it("refuse an edited migration", async () => {
        const [first, ...rest] = MIGRATIONS;
        if (first === undefined) throw new Error("no migrations");
        await expectRejects(
          migrate(db, [{ ...first, sql: `${first.sql}\n-- edited` }, ...rest]),
          MigrationError,
        );
      });

      it("refuse a database newer than the code", async () => {
        await expectRejects(migrate(db, MIGRATIONS.slice(0, 2)), MigrationError);
      });
    });

    describe("SRS 18 traceability", () => {
      it("SRS 18 every stored column traces to an SRS 18.1 entity, and the map lists nothing extra", async () => {
        const { rows } = await db.query<{ table_name: string; column_name: string }>(
          `SELECT table_name, column_name FROM information_schema.columns
            WHERE table_schema = current_schema()`,
        );
        const actual = new Set(rows.map((row) => `${row.table_name}.${row.column_name}`));
        const traced = new Set(
          Object.entries(SCHEMA_TRACE).flatMap(([table, trace]) =>
            Object.keys(trace.columns).map((column) => `${table}.${column}`),
          ),
        );
        expect(
          [...actual].filter((column) => !traced.has(column)),
          "untraced columns",
        ).toEqual([]);
        expect(
          [...traced].filter((column) => !actual.has(column)),
          "traced but missing",
        ).toEqual([]);
      });

      it("DAT-02 hard rule columns hold no plain health fields", async () => {
        const { rows } = await db.query<{ column_name: string; data_type: string }>(
          `SELECT column_name, data_type FROM information_schema.columns
            WHERE table_schema = current_schema() AND table_name = 'hard_rule'`,
        );
        const plain = rows.filter(
          (row) => !["uuid", "bytea", "timestamp with time zone"].includes(row.data_type),
        );
        expect(plain).toEqual([]);
      });
    });

    describe("households, accounts and profiles", () => {
      it("ACC-03 allows exactly one manager account per household", async () => {
        const home = await seedHousehold(db);
        const code = await dbErrorCode(
          db.query(
            `INSERT INTO account (household_id, email, sign_in_methods)
             VALUES ($1, 'second-manager@example.invalid', ARRAY['email'])`,
            [home.householdId],
          ),
        );
        expect(code).toBe("23505");
      });

      it("PRF-18 derives isChild from the age group and refuses a written value", async () => {
        const home = await seedHousehold(db);
        const teen = await addProfile(db, home, "teen");
        const elderly = await addProfile(db, home, "elderly");
        const { rows } = await db.query<{ id: string; is_child: boolean }>(
          `SELECT id, is_child FROM profile WHERE id = ANY($1::uuid[])`,
          [[teen, elderly, home.managerProfileId]],
        );
        const byId = new Map(rows.map((row) => [row.id, row.is_child]));
        expect(byId.get(teen)).toBe(true);
        expect(byId.get(elderly)).toBe(false);
        expect(byId.get(home.managerProfileId)).toBe(false);
        expect(
          await dbErrorCode(db.query(`UPDATE profile SET is_child = false WHERE id = $1`, [teen])),
        ).toBe("428C9");
      });

      it("SET-10 a child profile without a recorded guardian confirmation is refused", async () => {
        const home = await seedHousehold(db);
        const error = translateDbError(
          await addProfile(db, home, "child", { withGuardianConfirmation: false }).then(
            () => undefined,
            (caught: unknown) => caught,
          ),
        );
        expect(error).toBeInstanceOf(GuardianConfirmationRequiredError);
        const adult = await addProfile(db, home, "adult");
        const change = db.query(`UPDATE profile SET age_group = 'infant' WHERE id = $1`, [adult]);
        expect(
          translateDbError(
            await change.then(
              () => undefined,
              (caught: unknown) => caught,
            ),
          ),
        ).toBeInstanceOf(GuardianConfirmationRequiredError);
      });

      it("SET-10 guardian confirmation is stored as a consent record", async () => {
        const home = await seedHousehold(db);
        const adult = await addProfile(db, home, "adult");
        const record = await recordGuardianConfirmation(db, {
          householdId: home.householdId,
          profileId: adult,
          textVersion: "guardian-draft-1",
          language: "en",
          recordedByAccountId: home.accountId,
        });
        expect(record).toMatchObject({ purpose: "guardian_confirmation", decision: "given" });
        await db.query(`UPDATE profile SET age_group = 'child' WHERE id = $1`, [adult]);
      });

      it("PRF-01 stores an avatar (initials or illustration), never both", async () => {
        const home = await seedHousehold(db);
        const code = await dbErrorCode(
          db.query(
            `UPDATE profile SET avatar_style = 'initials', avatar_illustration_id = 'leaf' WHERE id = $1`,
            [home.managerProfileId],
          ),
        );
        expect(code).toBe("23514");
      });

      it("SET-07 the manager's own profile cannot be deleted on its own", async () => {
        const home = await seedHousehold(db);
        await expectRejects(
          deleteProfile(db, home.householdId, home.managerProfileId),
          ManagerProfileNotDeletableError,
        );
      });

      it("NFR-09 rows cannot mix households", async () => {
        const a = await seedHousehold(db);
        const b = await seedHousehold(db);
        const meal = randomUUID();
        await db.query(
          `INSERT INTO meal (id, household_id, eaten_on, slot, recipe_id) VALUES ($1, $2, '2026-11-10', 'lunch', 'fixture_recipe')`,
          [meal, a.householdId],
        );
        expect(
          await dbErrorCode(
            db.query(
              `INSERT INTO meal_member (meal_id, household_id, profile_id) VALUES ($1, $2, $3)`,
              [meal, a.householdId, b.managerProfileId],
            ),
          ),
        ).toBe("23503");
      });
    });

    describe("ACC-08 SET-03 consent records", () => {
      it("SET-03 moves through none, given and withdrawn, with the deletion deadline from config", async () => {
        const home = await seedHousehold(db);
        const profile = await addProfile(db, home, "adult");
        expect((await rulesConsentState(db, home.householdId, profile)).status).toBe("none");
        const given = await giveConsent(home, profile);
        expect(given).toMatchObject({ textVersion: "health-data-draft-1", language: "id" });
        expect((await rulesConsentState(db, home.householdId, profile)).status).toBe("given");

        const withdrawnAt = new Date(Date.now() + 60_000);
        const days = defaultTargets.dataManagement.healthConsentWithdrawalDeletionDays.value;
        const withdrawn = await withdrawHealthConsent(db, {
          householdId: home.householdId,
          profileId: profile,
          withdrawnAt,
          deletionWindowDays: days,
        });
        expect(withdrawn.deletionDueBy?.toISOString()).toBe(
          new Date(withdrawnAt.getTime() + days * 86_400_000).toISOString(),
        );
        const state = await rulesConsentState(db, home.householdId, profile);
        expect(state).toMatchObject({ status: "withdrawn", consentRecordId: given.id });
        expect(state.deletionDueBy).toEqual(withdrawn.deletionDueBy);
        await expectRejects(
          withdrawHealthConsent(db, {
            householdId: home.householdId,
            profileId: profile,
            withdrawnAt,
            deletionWindowDays: days,
          }),
          ConsentNotActiveError,
        );
      });

      it("QUESTIONS #47 a decline is stored with no rule data, and the latest decision wins", async () => {
        const home = await seedHousehold(db);
        const profile = await addProfile(db, home, "adult");
        await recordHealthConsent(db, {
          householdId: home.householdId,
          profileId: profile,
          decision: "declined",
          textVersion: "health-data-draft-1",
          language: "en",
          recordedByAccountId: home.accountId,
        });
        expect((await rulesConsentState(db, home.householdId, profile)).status).toBe("declined");
        await giveConsent(home, profile);
        expect((await rulesConsentState(db, home.householdId, profile)).status).toBe("given");
        expect(await listConsentRecords(db, home.householdId, profile)).toHaveLength(2);
      });

      it("SET-03 consent records are append-only", async () => {
        const home = await seedHousehold(db);
        const record = await giveConsent(home, home.managerProfileId);
        for (const change of [
          `decision = 'declined'`,
          `text_version = 'other'`,
          `decided_at = now() - interval '1 day'`,
          `profile_id = '${randomUUID()}'`,
        ]) {
          expect(
            await dbErrorCode(
              db.query(`UPDATE consent_record SET ${change} WHERE id = $1`, [record.id]),
            ),
            change,
          ).toBe("KM003");
        }
      });

      it("SET-03 a withdrawal needs a deletion deadline and only applies to given health consent", async () => {
        const home = await seedHousehold(db);
        const record = await giveConsent(home, home.managerProfileId);
        expect(
          await dbErrorCode(
            db.query(`UPDATE consent_record SET withdrawn_at = now() WHERE id = $1`, [record.id]),
          ),
        ).toBe("23514");
      });

      it("refuses a consent record for another household's profile", async () => {
        const a = await seedHousehold(db);
        const b = await seedHousehold(db);
        await expectRejects(giveConsent(a, b.managerProfileId), NotFoundError);
      });
    });

    describe("PRF-03 DAT-02 hard rules", () => {
      it("ACC-08 no hard rule is stored without an active health-data consent", async () => {
        const home = await seedHousehold(db);
        const profile = await addProfile(db, home, "adult");
        const insert = () =>
          insertHardRule(db, keys, {
            householdId: home.householdId,
            profileId: profile,
            rule: { type: "halal" },
            mappingConfirmedBy: null,
          });
        await expectRejects(insert(), ConsentRequiredError);
        await recordHealthConsent(db, {
          householdId: home.householdId,
          profileId: profile,
          decision: "declined",
          textVersion: "health-data-draft-1",
          language: "id",
          recordedByAccountId: home.accountId,
        });
        await expectRejects(insert(), ConsentRequiredError);
        expect(
          await count(`SELECT count(*) AS n FROM hard_rule WHERE profile_id = $1`, [profile]),
        ).toBe(0);
      });

      it("ACC-08 the database refuses a hard rule written around the data layer", async () => {
        const home = await seedHousehold(db);
        const profile = await addProfile(db, home, "adult");
        const consent = await giveConsent(home, profile);
        const key = await keys.getOrCreate(db, home.householdId, profile);
        await withdrawHealthConsent(db, {
          householdId: home.householdId,
          profileId: profile,
          withdrawnAt: new Date(Date.now() + 60_000),
          deletionWindowDays: 30,
        });
        // The withdrawal deleted the key; a raw insert under the old consent is refused.
        const code = await dbErrorCode(
          db.query(
            `INSERT INTO hard_rule (id, household_id, profile_id, health_key_id, consent_record_id, details_enc)
             VALUES ($1, $2, $3, $4, $5, $6)`,
            [randomUUID(), home.householdId, profile, key.keyId, consent.id, randomBytes(40)],
          ),
        );
        expect(code).toBe("KM001");
      });

      it("PRF-03 stores, lists and converts every rule type for Cek Aman", async () => {
        const home = await seedHousehold(db);
        const profile = await addProfile(db, home, "child");
        await giveConsent(home, profile);
        const add = (
          rule: Parameters<typeof insertHardRule>[2]["rule"],
          confirmer: "manager" | null = null,
        ) =>
          insertHardRule(db, keys, {
            householdId: home.householdId,
            profileId: profile,
            rule,
            mappingConfirmedBy: confirmer,
          });
        await add({ type: "allergy", allergen: "shrimp" });
        await add({ type: "halal" });
        await add({ type: "free_text", freeText: FREE_TEXT });
        await add({ type: "medical_exclusion", mappedIngredientIds: ["fixture_paste"] }, "manager");

        const listed = await listProfileRules(db, keys, home.householdId, profile);
        expect(listed.consent.status).toBe("given");
        expect(listed.items.map((rule) => rule.type)).toEqual([
          "allergy",
          "halal",
          "free_text",
          "medical_exclusion",
        ]);
        expect(listed.items[2]?.mapping).toMatchObject({ status: "unmapped", confirmedBy: null });
        expect(listed.items[3]?.mapping).toMatchObject({
          status: "mapped",
          confirmedBy: "manager",
        });

        const [member] = await loadRulesForEvaluation(db, keys, home.householdId, [profile]);
        expect(member?.consent).toBe("given");
        expect(member?.hardRules).toEqual([
          { ruleId: listed.items[0]?.id, type: "allergy", allergen: "shrimp" },
          { ruleId: listed.items[1]?.id, type: "halal" },
          {
            ruleId: listed.items[2]?.id,
            type: "free_text",
            freeText: FREE_TEXT,
            mapping: { status: "unmapped" },
          },
          {
            ruleId: listed.items[3]?.id,
            type: "medical_exclusion",
            freeText: null,
            mapping: { status: "mapped", ingredientIds: ["fixture_paste"], confirmedBy: "manager" },
          },
        ]);
      });

      it("PRF-08 a mapping at entry needs a server-side confirmer, and confirmation is server-side", async () => {
        const home = await seedHousehold(db);
        await giveConsent(home, home.managerProfileId);
        await expectRejects(
          insertHardRule(db, keys, {
            householdId: home.householdId,
            profileId: home.managerProfileId,
            rule: { type: "free_text", freeText: FREE_TEXT, mappedIngredientIds: ["fixture_a"] },
            mappingConfirmedBy: null,
          }),
          InvalidDataError,
        );
        const rule = await insertHardRule(db, keys, {
          householdId: home.householdId,
          profileId: home.managerProfileId,
          rule: { type: "free_text", freeText: FREE_TEXT },
          mappingConfirmedBy: null,
        });
        const confirmed = await confirmRuleMapping(db, keys, {
          householdId: home.householdId,
          profileId: home.managerProfileId,
          ruleId: rule.id,
          ingredientIds: ["fixture_a", "fixture_b"],
          confirmedBy: "content_team",
        });
        expect(confirmed.mapping).toMatchObject({
          status: "mapped",
          ingredientIds: ["fixture_a", "fixture_b"],
          confirmedBy: "content_team",
        });
        const allergy = await insertHardRule(db, keys, {
          householdId: home.householdId,
          profileId: home.managerProfileId,
          rule: { type: "allergy", allergen: "egg" },
          mappingConfirmedBy: null,
        });
        await expectRejects(
          confirmRuleMapping(db, keys, {
            householdId: home.householdId,
            profileId: home.managerProfileId,
            ruleId: allergy.id,
            ingredientIds: ["fixture_a"],
            confirmedBy: "manager",
          }),
          MappingNotApplicableError,
        );
        expect(await deleteHardRule(db, home.householdId, home.managerProfileId, allergy.id)).toBe(
          true,
        );
      });

      it("PRF-11 QUESTIONS #36 returns exactly the selected members, and tells no rules apart from no consent", async () => {
        const home = await seedHousehold(db);
        const noConsent = await addProfile(db, home, "adult");
        const declined = await addProfile(db, home, "adult");
        await recordHealthConsent(db, {
          householdId: home.householdId,
          profileId: declined,
          decision: "declined",
          textVersion: "health-data-draft-1",
          language: "id",
          recordedByAccountId: home.accountId,
        });
        await giveConsent(home, home.managerProfileId);
        const members = await loadRulesForEvaluation(db, keys, home.householdId, [
          declined,
          home.managerProfileId,
          noConsent,
        ]);
        expect(members).toEqual([
          { profileId: declined, consent: "declined", hardRules: null },
          { profileId: home.managerProfileId, consent: "given", hardRules: [] },
          { profileId: noConsent, consent: "none", hardRules: null },
        ]);
      });

      it("NFR-09 refuses a member from another household", async () => {
        const a = await seedHousehold(db);
        const b = await seedHousehold(db);
        await expectRejects(
          loadRulesForEvaluation(db, keys, a.householdId, [a.managerProfileId, b.managerProfileId]),
          NotFoundError,
        );
        await expectRejects(
          loadRulesForEvaluation(db, keys, a.householdId, ["Siti"]),
          NotFoundError,
        );
      });

      describe("DAT-02 the general key cannot read health data", () => {
        let home: SeededHousehold;
        let profile: string;

        beforeAll(async () => {
          home = await seedHousehold(db);
          profile = await addProfile(db, home, "adult");
          await giveConsent(home, profile);
          await insertHardRule(db, keys, {
            householdId: home.householdId,
            profileId: profile,
            rule: { type: "free_text", freeText: FREE_TEXT },
            mappingConfirmedBy: null,
          });
          await insertHardRule(db, keys, {
            householdId: home.householdId,
            profileId: profile,
            rule: { type: "allergy", allergen: "sesame" },
            mappingConfirmedBy: null,
          });
        });

        it("DAT-02 stored rows contain no readable rule data", async () => {
          const { rows } = await db.query<{ t: string }>(
            `SELECT encode(details_enc, 'escape') || row_to_json(r)::text AS t FROM hard_rule r WHERE profile_id = $1`,
            [profile],
          );
          expect(rows).toHaveLength(2);
          for (const row of rows) {
            expect(row.t).not.toContain(FREE_TEXT);
            expect(row.t).not.toContain("sesame");
            expect(row.t).not.toContain("allergy");
            expect(row.t).not.toContain("free_text");
          }
        });

        it("DAT-02 the general key cannot unwrap the member's data key", async () => {
          const { rows } = await db.query<{ id: string; key_ref: string; wrapped_key: Uint8Array }>(
            `SELECT id, key_ref, wrapped_key FROM health_data_key WHERE profile_id = $1`,
            [profile],
          );
          const row = rows[0];
          if (row === undefined) throw new Error("no key row");
          const general = provider.kek("general");
          const context = `health_data_key:${row.id}:${profile}:${home.householdId}`;
          await expectRejects(
            general.unwrap({ keyRef: row.key_ref, wrapped: row.wrapped_key }, context),
            DecryptionError,
          );
          await expectRejects(
            general.unwrap({ keyRef: general.keyRef, wrapped: row.wrapped_key }, context),
            DecryptionError,
          );
          // The health key itself can.
          expect(
            (
              await provider
                .kek("health")
                .unwrap({ keyRef: row.key_ref, wrapped: row.wrapped_key }, context)
            ).byteLength,
          ).toBe(32);
        });

        it("DAT-02 a data layer holding only the general key gets rules_unavailable, never rules", async () => {
          expect(() => new HealthDataKeys(withHealthKek(provider.kek("general")))).toThrow(
            /health-data key/,
          );
          // Even a general key presented as the health key cannot read anything.
          const disguised: KeyEncryptionKey = {
            purpose: "health",
            keyRef: provider.kek("general").keyRef,
            wrap: (dek, ctx) => provider.kek("general").wrap(dek, ctx),
            unwrap: (wrapped, ctx) => provider.kek("general").unwrap(wrapped, ctx),
          };
          const generalOnly = new HealthDataKeys(withHealthKek(disguised));
          const error = await expectRejects(
            loadRulesForEvaluation(db, generalOnly, home.householdId, [profile]),
            RulesUnavailableError,
          );
          expect(error.reason).toBe("decrypt_failed");
        });

        it("Q39 a different or rotated-away health key surfaces as rules_unavailable", async () => {
          const otherKeys = new HealthDataKeys(
            new LocalKeyProvider(
              { general: randomBytes(32), health: randomBytes(32) },
              { appEnv: "test" },
            ),
          );
          for (const read of [
            () => loadRulesForEvaluation(db, otherKeys, home.householdId, [profile]),
            () => listProfileRules(db, otherKeys, home.householdId, profile),
          ]) {
            const error = await expectRejects(read(), RulesUnavailableError);
            expect(error.reason).toBe("decrypt_failed");
            expect(error.code).toBe("rules_unavailable");
            expect(error.message).not.toContain(profile);
          }
        });

        it("Q39 a key service outage surfaces as rules_unavailable (key_unavailable)", async () => {
          const health = provider.kek("health");
          const outage: KeyEncryptionKey = {
            purpose: "health",
            keyRef: health.keyRef,
            wrap: (dek, ctx) => health.wrap(dek, ctx),
            unwrap: () => Promise.reject(new KeyServiceError("Cloud KMS unavailable")),
          };
          const error = await expectRejects(
            loadRulesForEvaluation(
              db,
              new HealthDataKeys(withHealthKek(outage)),
              home.householdId,
              [profile],
            ),
            RulesUnavailableError,
          );
          expect(error.reason).toBe("key_unavailable");
        });
      });

      it("H1 Q39 a withdrawal committed between any two statements never yields given with missing rules", async () => {
        // Probe P2 from the review, at every statement boundary of the read.
        for (let at = 0; at < 4; at += 1) {
          const home = await seedHousehold(db);
          const profile = await addProfile(db, home, "adult");
          await giveConsent(home, profile);
          await insertHardRule(db, keys, {
            householdId: home.householdId,
            profileId: profile,
            rule: { type: "allergy", allergen: "shrimp" },
            mappingConfirmedBy: null,
          });
          let statements = 0;
          const racing: SqlExecutor = {
            async query<R extends object>(text: string, params?: readonly unknown[]) {
              if (statements === at) {
                await withdrawHealthConsent(db, {
                  householdId: home.householdId,
                  profileId: profile,
                  withdrawnAt: new Date(Date.now() + 60_000),
                  deletionWindowDays: 30,
                });
              }
              statements += 1;
              return db.query<R>(text, params);
            },
            execScript: (sql) => db.execScript(sql),
            transaction: (fn) => fn(racing),
          };
          const outcome: unknown = await loadRulesForEvaluation(racing, keys, home.householdId, [
            profile,
          ]).then(
            (members) => members[0],
            (error: unknown) => error,
          );
          if (outcome instanceof RulesUnavailableError) continue;
          const member = outcome as Awaited<ReturnType<typeof loadRulesForEvaluation>>[number];
          if (member.consent === "given") {
            expect(member.hardRules, `withdrawal at statement ${at}`).toHaveLength(1);
          } else {
            expect(member).toEqual({ profileId: profile, consent: "withdrawn", hardRules: null });
          }
          if (at === 0) expect(member.consent).toBe("withdrawn");
        }
      });

      it("H1 reads consent, key and rules in one statement", async () => {
        const home = await seedHousehold(db);
        await giveConsent(home, home.managerProfileId);
        await insertHardRule(db, keys, {
          householdId: home.householdId,
          profileId: home.managerProfileId,
          rule: { type: "vegan" },
          mappingConfirmedBy: null,
        });
        let statements = 0;
        const counting: SqlExecutor = {
          query<R extends object>(text: string, params?: readonly unknown[]) {
            statements += 1;
            return db.query<R>(text, params);
          },
          execScript: (sql) => db.execScript(sql),
          transaction: (fn) => fn(counting),
        };
        const [member] = await loadRulesForEvaluation(counting, keys, home.householdId, [
          home.managerProfileId,
        ]);
        expect(member?.hardRules).toHaveLength(1);
        expect(statements).toBe(1);
      });

      it("Q39 a corrupted rule fails the whole read instead of dropping that rule", async () => {
        const home = await seedHousehold(db);
        const other = await addProfile(db, home, "adult");
        await giveConsent(home, home.managerProfileId);
        await giveConsent(home, other);
        await insertHardRule(db, keys, {
          householdId: home.householdId,
          profileId: home.managerProfileId,
          rule: { type: "vegan" },
          mappingConfirmedBy: null,
        });
        const broken = await insertHardRule(db, keys, {
          householdId: home.householdId,
          profileId: other,
          rule: { type: "allergy", allergen: "peanut" },
          mappingConfirmedBy: null,
        });
        await insertHardRule(db, keys, {
          householdId: home.householdId,
          profileId: other,
          rule: { type: "halal" },
          mappingConfirmedBy: null,
        });
        await db.query(
          `UPDATE hard_rule SET details_enc = set_byte(details_enc, 19, 255 - get_byte(details_enc, 19)) WHERE id = $1`,
          [broken.id],
        );
        const error = await expectRejects(
          loadRulesForEvaluation(db, keys, home.householdId, [home.managerProfileId, other]),
          RulesUnavailableError,
        );
        expect(error.reason).toBe("decrypt_failed");
      });

      it("Q39 a rule moved to another member's row does not decrypt", async () => {
        const home = await seedHousehold(db);
        const other = await addProfile(db, home, "adult");
        await giveConsent(home, home.managerProfileId);
        await giveConsent(home, other);
        const source = await insertHardRule(db, keys, {
          householdId: home.householdId,
          profileId: home.managerProfileId,
          rule: { type: "allergy", allergen: "milk" },
          mappingConfirmedBy: null,
        });
        const target = await insertHardRule(db, keys, {
          householdId: home.householdId,
          profileId: other,
          rule: { type: "halal" },
          mappingConfirmedBy: null,
        });
        await db.query(
          `UPDATE hard_rule SET details_enc = (SELECT details_enc FROM hard_rule WHERE id = $1) WHERE id = $2`,
          [source.id, target.id],
        );
        const error = await expectRejects(
          loadRulesForEvaluation(db, keys, home.householdId, [other]),
          RulesUnavailableError,
        );
        expect(error.reason).toBe("decrypt_failed");
      });

      it("Q39 a decrypted but malformed rule surfaces as rules_unavailable (malformed)", async () => {
        const home = await seedHousehold(db);
        await giveConsent(home, home.managerProfileId);
        const rule = await insertHardRule(db, keys, {
          householdId: home.householdId,
          profileId: home.managerProfileId,
          rule: { type: "halal" },
          mappingConfirmedBy: null,
        });
        const key = await keys.getOrCreate(db, home.householdId, home.managerProfileId);
        const context = `hard_rule:${rule.id}:${home.managerProfileId}:${home.householdId}`;
        expect(
          decryptField(
            key.dataKey,
            (
              await db.query<{ d: Uint8Array }>(
                `SELECT details_enc AS d FROM hard_rule WHERE id = $1`,
                [rule.id],
              )
            ).rows[0]?.d ?? new Uint8Array(),
            context,
          ),
        ).toContain("halal");
        await db.query(`UPDATE hard_rule SET details_enc = $2 WHERE id = $1`, [
          rule.id,
          encryptField(
            key.dataKey,
            JSON.stringify({ v: 1, type: "halal", override: true }),
            context,
          ),
        ]);
        const error = await expectRejects(
          listProfileRules(db, keys, home.householdId, home.managerProfileId),
          RulesUnavailableError,
        );
        expect(error.reason).toBe("malformed");
      });
    });

    describe("SAF-14 DAT-05 safety result log", () => {
      const reference = {
        schema: "keluargamakan.reference.ingredients/1",
        version: "fixture-ref-1",
        ingredients: [
          fixtureIngredient("fixture_paste", ["shrimp"]),
          fixtureIngredient("fixture_rice", []),
        ],
      };

      function recordFor(
        home: SeededHousehold,
        profileId: string,
        hardRules: readonly CekAmanHardRule[],
      ) {
        const input: CekAmanInput = {
          ingredients: [
            { ingredientId: "fixture_paste", rawName: "terasi fiksi" },
            { ingredientId: null, rawName: RAW_NAME },
          ],
          recordedBrands: [],
          members: [{ memberId: profileId, hardRules }],
          reference,
        };
        return evaluateWithLog(input, {
          householdId: home.householdId,
          subject: { kind: "library_recipe", id: "fixture_recipe", version: "1" },
          evaluatedAt: new Date().toISOString(),
        });
      }

      async function rulesOf(home: SeededHousehold, profileId: string) {
        const [member] = await loadRulesForEvaluation(db, keys, home.householdId, [profileId]);
        if (member?.hardRules == null) throw new Error("member has no rules");
        return member.hardRules;
      }

      async function logFor(home: SeededHousehold, profileId: string): Promise<string> {
        const { result, logRecord } = recordFor(home, profileId, await rulesOf(home, profileId));
        expect(result.perMember[0]?.status).toBe("not_safe");
        return insertSafetyLog(db, keys, logRecord);
      }

      async function memberWithShrimpRule(): Promise<{ home: SeededHousehold; profile: string }> {
        const home = await seedHousehold(db);
        const profile = await addProfile(db, home, "adult");
        await giveConsent(home, profile);
        await insertHardRule(db, keys, {
          householdId: home.householdId,
          profileId: profile,
          rule: { type: "allergy", allergen: "shrimp" },
          mappingConfirmedBy: null,
        });
        await insertHardRule(db, keys, {
          householdId: home.householdId,
          profileId: profile,
          rule: { type: "free_text", freeText: FREE_TEXT },
          mappingConfirmedBy: null,
        });
        return { home, profile };
      }

      const withdraw = (home: SeededHousehold, profile: string) =>
        withdrawHealthConsent(db, {
          householdId: home.householdId,
          profileId: profile,
          withdrawnAt: new Date(Date.now() + 60_000),
          deletionWindowDays:
            defaultTargets.dataManagement.healthConsentWithdrawalDeletionDays.value,
        });

      it("SAF-14 DAT-06 logs versions in plain, and status, reasons and ingredients only under the health key", async () => {
        const { home, profile } = await memberWithShrimpRule();
        const logId = await logFor(home, profile);
        const log = await readSafetyLog(db, keys, home.householdId, logId);
        expect(log).toMatchObject({
          householdId: home.householdId,
          ruleSetVersion: expect.any(String) as unknown,
          referenceVersion: "fixture-ref-1",
          subject: { kind: "library_recipe", id: "fixture_recipe", version: "1" },
        });
        const member = log.members[0];
        expect(member?.memberKeyId).not.toBe(profile);
        expect(member?.details).toMatchObject({
          status: "not_safe",
          ingredientIds: ["fixture_paste", null],
          recordedBrands: [],
        });
        expect(member?.details?.reasonCodes).toEqual(expect.arrayContaining(["allergen_contains"]));
        expect(member?.details?.rules.map((rule) => rule.type)).toEqual(["allergy", "free_text"]);
      });

      it("H3 DAT-02 plain safety log columns hold no result, reason or ingredient", async () => {
        const { rows } = await db.query<{ table_name: string; column_name: string }>(
          `SELECT table_name, column_name FROM information_schema.columns
            WHERE table_schema = current_schema() AND table_name IN ('safety_log', 'safety_log_member')
            ORDER BY table_name, column_name`,
        );
        expect(rows.map((row) => `${row.table_name}.${row.column_name}`)).toEqual([
          "safety_log.created_at",
          "safety_log.evaluated_at",
          "safety_log.household_id",
          "safety_log.id",
          "safety_log.log_format",
          "safety_log.reference_version",
          "safety_log.rule_set_version",
          "safety_log.subject_id",
          "safety_log.subject_kind",
          "safety_log.subject_version",
          "safety_log_member.details_enc",
          "safety_log_member.log_id",
          "safety_log_member.member_index",
          "safety_log_member.member_key_id",
          "safety_log_member.redacted_at",
        ]);
      });

      it("H3 PR #5 M2 with SQL only, a member's name joins to no rule type, reason, status or ingredient", async () => {
        const { home, profile } = await memberWithShrimpRule();
        const logId = await logFor(home, profile);
        // Probe P4 from the review: join the log to the member's name without any key.
        const { rows } = await db.query<{ t: string }>(
          `SELECT row_to_json(p)::text || row_to_json(l)::text
                  || encode(m.details_enc, 'escape') || row_to_json(m)::text AS t
             FROM safety_log_member m
             JOIN safety_log l ON l.id = m.log_id
             JOIN health_data_key k ON k.id = m.member_key_id
             JOIN profile p ON p.id = k.profile_id
            WHERE l.id = $1`,
          [logId],
        );
        const stored = rows[0]?.t ?? "";
        expect(stored).toContain("Profil Uji");
        for (const secret of [
          RAW_NAME,
          "terasi fiksi",
          FREE_TEXT,
          "shrimp",
          "allergen",
          "allergy",
          "not_safe",
          "check_label",
          "fixture_paste",
        ]) {
          expect(stored, secret).not.toContain(secret);
        }
        const decrypted = JSON.stringify(await readSafetyLog(db, keys, home.householdId, logId));
        expect(decrypted).not.toContain(RAW_NAME);
        expect(decrypted).not.toContain(FREE_TEXT);
        expect(decrypted).toContain("shrimp");
      });

      it("PR #5 M2c refuses non-opaque IDs and versions, and members of another household", async () => {
        const { home, profile } = await memberWithShrimpRule();
        const other = await seedHousehold(db);
        const base = recordFor(home, profile, []).logRecord;
        await expectRejects(
          insertSafetyLog(db, keys, {
            ...base,
            members: [{ ...base.members[0]!, memberId: "Siti Aminah" }],
          }),
          InvalidDataError,
        );
        await expectRejects(
          insertSafetyLog(db, keys, { ...base, householdId: "Keluarga Contoh" }),
          InvalidDataError,
        );
        await expectRejects(
          insertSafetyLog(db, keys, { ...base, subject: { ...base.subject, id: "Resep Bu Siti" } }),
          InvalidDataError,
        );
        await expectRejects(
          insertSafetyLog(db, keys, { ...base, referenceVersion: "versi Bu Siti 0812" }),
          InvalidDataError,
        );
        await expectRejects(
          insertSafetyLog(db, keys, { ...base, householdId: other.householdId }),
          NotFoundError,
        );
      });

      it("M4 a log is read only within its own household", async () => {
        const { home, profile } = await memberWithShrimpRule();
        const other = await seedHousehold(db);
        const logId = await logFor(home, profile);
        await expectRejects(readSafetyLog(db, keys, other.householdId, logId), NotFoundError);
        const keyId = (await readSafetyLog(db, keys, home.householdId, logId)).members[0]
          ?.memberKeyId;
        expect((await keys.loadByKeyIds(db, other.householdId, [keyId ?? ""])).size).toBe(0);
      });

      it("SAF-14 log rows are append-only, and a member row is redacted at most once", async () => {
        const { home, profile } = await memberWithShrimpRule();
        const logId = await logFor(home, profile);
        expect(
          await dbErrorCode(
            db.query(`UPDATE safety_log SET reference_version = 'x' WHERE id = $1`, [logId]),
          ),
        ).toBe("KM003");
        expect(
          await dbErrorCode(
            db.query(`UPDATE safety_log_member SET member_index = 7 WHERE log_id = $1`, [logId]),
          ),
        ).toBe("KM003");
        expect(
          await dbErrorCode(
            db.query(`UPDATE safety_log_member SET details_enc = $2 WHERE log_id = $1`, [
              logId,
              randomBytes(64),
            ]),
          ),
        ).toBe("KM003");
        await db.query(
          `UPDATE safety_log_member SET details_enc = NULL, redacted_at = now() WHERE log_id = $1`,
          [logId],
        );
        expect(
          await dbErrorCode(
            db.query(
              `UPDATE safety_log_member SET member_key_id = gen_random_uuid() WHERE log_id = $1`,
              [logId],
            ),
          ),
        ).toBe("KM003");
      });

      it("DAT-05 logs are purged after the configured retention", async () => {
        const { home, profile } = await memberWithShrimpRule();
        const logId = await logFor(home, profile);
        const years = defaultTargets.dataManagement.safetyLogRetentionYears.value;
        await purgeExpiredSafetyLogs(db, new Date(), years);
        expect(await count(`SELECT count(*) AS n FROM safety_log WHERE id = $1`, [logId])).toBe(1);
        const later = new Date();
        later.setUTCFullYear(later.getUTCFullYear() + years);
        later.setUTCDate(later.getUTCDate() + 1);
        expect(await purgeExpiredSafetyLogs(db, later, years)).toBeGreaterThanOrEqual(1);
        expect(
          await count(`SELECT count(*) AS n FROM safety_log_member WHERE log_id = $1`, [logId]),
        ).toBe(0);
      });

      describe("H4 a log written after a withdrawal keeps nothing", () => {
        it("H4 creates no data key and stores no details (probe P1)", async () => {
          const { home, profile } = await memberWithShrimpRule();
          const hardRules = await rulesOf(home, profile);
          await withdraw(home, profile);
          const logId = await insertSafetyLog(
            db,
            keys,
            recordFor(home, profile, hardRules).logRecord,
          );
          expect(
            await count(`SELECT count(*) AS n FROM health_data_key WHERE profile_id = $1`, [
              profile,
            ]),
          ).toBe(0);
          const log = await readSafetyLog(db, keys, home.householdId, logId);
          expect(log.members[0]?.details).toBeNull();
          expect(
            await count(`SELECT count(*) AS n FROM health_data_key WHERE id = $1`, [
              log.members[0]?.memberKeyId,
            ]),
          ).toBe(0);
          expect(await enforceHealthConsent(db)).toBe(0);
        });

        it("H4 after withdrawal and new consent, the withdrawn-era rules are not stored under the new key", async () => {
          const { home, profile } = await memberWithShrimpRule();
          const oldRules = await rulesOf(home, profile);
          await withdraw(home, profile);
          await giveConsent(home, profile);
          await insertHardRule(db, keys, {
            householdId: home.householdId,
            profileId: profile,
            rule: { type: "halal" },
            mappingConfirmedBy: null,
          });
          const logId = await insertSafetyLog(
            db,
            keys,
            recordFor(home, profile, oldRules).logRecord,
          );
          expect(
            (await readSafetyLog(db, keys, home.householdId, logId)).members[0]?.details,
          ).toBeNull();
          // With the current rules the details are stored again.
          const fresh = await insertSafetyLog(
            db,
            keys,
            recordFor(home, profile, await rulesOf(home, profile)).logRecord,
          );
          const details = (await readSafetyLog(db, keys, home.householdId, fresh)).members[0]
            ?.details;
          expect(details?.rules.map((rule) => rule.type)).toEqual(["halal"]);
        });

        it("H4 a member without consent or without a key gets no details and no key", async () => {
          const home = await seedHousehold(db);
          const declined = await addProfile(db, home, "adult");
          await recordHealthConsent(db, {
            householdId: home.householdId,
            profileId: declined,
            decision: "declined",
            textVersion: "health-data-draft-1",
            language: "id",
            recordedByAccountId: home.accountId,
          });
          await giveConsent(home, home.managerProfileId); // consent, no rules, so no key
          for (const profile of [declined, home.managerProfileId]) {
            const logId = await insertSafetyLog(db, keys, recordFor(home, profile, []).logRecord);
            expect(
              (await readSafetyLog(db, keys, home.householdId, logId)).members[0]?.details,
            ).toBeNull();
          }
          expect(
            await count(`SELECT count(*) AS n FROM health_data_key WHERE household_id = $1`, [
              home.householdId,
            ]),
          ).toBe(0);
        });

        it("H4 the database refuses a data key or log details without an active consent", async () => {
          const { home, profile } = await memberWithShrimpRule();
          const logId = await logFor(home, profile);
          const keyId = (await readSafetyLog(db, keys, home.householdId, logId)).members[0]
            ?.memberKeyId;
          await withdraw(home, profile);
          await expectRejects(
            keys.getOrCreate(db, home.householdId, profile),
            ConsentRequiredError,
          );
          expect(
            await dbErrorCode(
              db.query(
                `INSERT INTO health_data_key (id, household_id, profile_id, key_ref, wrapped_key)
                 VALUES ($1, $2, $3, 'local:health:0', $4)`,
                [randomUUID(), home.householdId, profile, randomBytes(64)],
              ),
            ),
          ).toBe("KM001");
          expect(
            await dbErrorCode(
              db.query(
                `INSERT INTO safety_log_member (log_id, member_index, member_key_id, details_enc)
                 VALUES ($1, 5, $2, $3)`,
                [logId, keyId, randomBytes(64)],
              ),
            ),
          ).toBe("KM001");
        });
      });

      describe("SET-04 SET-07 SET-08 deletion and redaction", () => {
        it("SET-04 withdrawing consent deletes the rules and data key and redacts and unlinks the log at once", async () => {
          const { home, profile } = await memberWithShrimpRule();
          const logId = await logFor(home, profile);
          const second = await logFor(home, profile);
          const oldKeyId = (await readSafetyLog(db, keys, home.householdId, logId)).members[0]
            ?.memberKeyId;
          await withdraw(home, profile);
          expect(
            await count(`SELECT count(*) AS n FROM hard_rule WHERE profile_id = $1`, [profile]),
          ).toBe(0);
          expect(
            await count(`SELECT count(*) AS n FROM health_data_key WHERE profile_id = $1`, [
              profile,
            ]),
          ).toBe(0);
          const after = await readSafetyLog(db, keys, home.householdId, logId);
          const afterSecond = await readSafetyLog(db, keys, home.householdId, second);
          expect(after.members[0]?.details).toBeNull();
          // M3: redacted rows get fresh random IDs, so they no longer link to each other.
          expect(after.members[0]?.memberKeyId).not.toBe(oldKeyId);
          expect(after.members[0]?.memberKeyId).not.toBe(afterSecond.members[0]?.memberKeyId);
          expect(
            await count(`SELECT count(*) AS n FROM safety_log_member WHERE member_key_id = $1`, [
              oldKeyId,
            ]),
          ).toBe(0);
          expect(await loadRulesForEvaluation(db, keys, home.householdId, [profile])).toEqual([
            { profileId: profile, consent: "withdrawn", hardRules: null },
          ]);

          // New consent starts a new key.
          await giveConsent(home, profile);
          const fresh = await keys.getOrCreate(db, home.householdId, profile);
          expect(fresh.keyId).not.toBe(oldKeyId);
        });

        it("SET-04 declining consent also deletes the data key and rules", async () => {
          const { home, profile } = await memberWithShrimpRule();
          await recordHealthConsent(db, {
            householdId: home.householdId,
            profileId: profile,
            decision: "declined",
            textVersion: "health-data-draft-1",
            language: "id",
            recordedByAccountId: home.accountId,
          });
          expect(
            await count(`SELECT count(*) AS n FROM health_data_key WHERE profile_id = $1`, [
              profile,
            ]),
          ).toBe(0);
          expect(
            await count(`SELECT count(*) AS n FROM hard_rule WHERE profile_id = $1`, [profile]),
          ).toBe(0);
        });

        it("SET-04 the deletion job backstop finds nothing after the triggers ran, and removes a stray key", async () => {
          const { home, profile } = await memberWithShrimpRule();
          await withdraw(home, profile);
          expect(await enforceHealthConsent(db)).toBe(0);
          // A stray key can only appear with triggers off (for example a restore).
          await db.transaction(async (tx) => {
            await tx.query(`SET LOCAL session_replication_role = replica`);
            await tx.query(
              `INSERT INTO health_data_key (id, household_id, profile_id, key_ref, wrapped_key)
               VALUES ($1, $2, $3, 'local:health:0', $4)`,
              [randomUUID(), home.householdId, profile, randomBytes(64)],
            );
          });
          expect(await enforceHealthConsent(db)).toBe(1);
        });

        it("SET-07 deleting a profile removes all of its data and redacts its log details", async () => {
          const { home, profile } = await memberWithShrimpRule();
          const logId = await logFor(home, profile);
          const meal = randomUUID();
          await db.query(
            `INSERT INTO meal (id, household_id, eaten_on, slot, recipe_id) VALUES ($1, $2, '2026-11-10', 'dinner', 'fixture_recipe')`,
            [meal, home.householdId],
          );
          await db.query(
            `INSERT INTO meal_member (meal_id, household_id, profile_id) VALUES ($1, $2, $3)`,
            [meal, home.householdId, profile],
          );
          await db.query(
            `INSERT INTO feedback (meal_id, household_id, overall) VALUES ($1, $2, 'mixed')`,
            [meal, home.householdId],
          );
          await db.query(
            `INSERT INTO feedback_member (meal_id, profile_id, rating) VALUES ($1, $2, 'no')`,
            [meal, profile],
          );
          await db.query(
            `INSERT INTO soft_preference (profile_id, spice_level) VALUES ($1, 'spicy')`,
            [profile],
          );
          await db.query(
            `INSERT INTO profile_like_dislike (profile_id, kind, ref_id, sentiment) VALUES ($1, 'dish', 'fixture_dish', 'like')`,
            [profile],
          );

          expect(await deleteProfile(db, home.householdId, profile)).toBe(true);

          for (const table of [
            "hard_rule",
            "health_data_key",
            "soft_preference",
            "profile_like_dislike",
            "meal_member",
            "feedback_member",
          ]) {
            expect(
              await count(`SELECT count(*) AS n FROM ${table} WHERE profile_id = $1`, [profile]),
              table,
            ).toBe(0);
          }
          expect(await count(`SELECT count(*) AS n FROM meal WHERE id = $1`, [meal])).toBe(1);
          const log = await readSafetyLog(db, keys, home.householdId, logId);
          expect(log.members[0]?.details).toBeNull();
          // QUESTIONS #33 default: consent records are kept, unlinked from the deleted profile.
          expect(
            await count(
              `SELECT count(*) AS n FROM consent_record WHERE household_id = $1 AND profile_id IS NULL`,
              [home.householdId],
            ),
          ).toBe(1);
        });

        it("SET-08 deleting the household removes all household data and leaves an unlinked log without results", async () => {
          const { home, profile } = await memberWithShrimpRule();
          const logId = await logFor(home, profile);
          const keyId = (await readSafetyLog(db, keys, home.householdId, logId)).members[0]
            ?.memberKeyId;
          const kitchenItem = randomUUID();
          await db.query(
            `INSERT INTO kitchen_item (id, household_id, ingredient_id, category, changed_by_account_id)
             VALUES ($1, $2, 'fixture_rice', 'staples', $3)`,
            [kitchenItem, home.householdId, home.accountId],
          );
          const set = randomUUID();
          await db.query(
            `INSERT INTO ingredient_set (id, household_id, name) VALUES ($1, $2, 'Belanja mingguan')`,
            [set, home.householdId],
          );
          await db.query(
            `INSERT INTO ingredient_set_item (set_id, household_id, kitchen_item_id) VALUES ($1, $2, $3)`,
            [set, home.householdId, kitchenItem],
          );

          expect(await deleteHousehold(db, home.householdId)).toBe(true);

          const scoped = Object.entries(SCHEMA_TRACE)
            .filter(
              ([table, trace]) =>
                "household_id" in trace.columns &&
                table !== "safety_log" &&
                table !== "consent_record",
            )
            .map(([table]) => table);
          for (const table of scoped) {
            expect(
              await count(`SELECT count(*) AS n FROM ${table} WHERE household_id = $1`, [
                home.householdId,
              ]),
              table,
            ).toBe(0);
          }
          expect(
            await count(`SELECT count(*) AS n FROM account WHERE id = $1`, [home.accountId]),
          ).toBe(0);
          expect(
            await count(
              `SELECT count(*) AS n FROM consent_record WHERE household_id = $1 OR profile_id = $2`,
              [home.householdId, profile],
            ),
          ).toBe(0);
          const { rows } = await db.query<{
            household_id: string | null;
            member_key_id: string;
            details_enc: Uint8Array | null;
          }>(
            `SELECT l.household_id, m.member_key_id, m.details_enc
               FROM safety_log l JOIN safety_log_member m ON m.log_id = l.id WHERE l.id = $1`,
            [logId],
          );
          expect(rows).toHaveLength(1);
          expect(rows[0]).toMatchObject({ household_id: null, details_enc: null });
          expect(rows[0]?.member_key_id).not.toBe(keyId);
        });
      });
    });

    describe("Dapur Saya, meals and reference data", () => {
      it("KIT-04 KIT-05 a kitchen item is a reference or a custom ingredient, once per household", async () => {
        const home = await seedHousehold(db);
        await db.query(
          `INSERT INTO kitchen_item (household_id, ingredient_id, category, is_default_staple) VALUES ($1, 'fixture_rice', 'staples', true)`,
          [home.householdId],
        );
        expect(
          await dbErrorCode(
            db.query(
              `INSERT INTO kitchen_item (household_id, ingredient_id, category) VALUES ($1, 'fixture_rice', 'staples')`,
              [home.householdId],
            ),
          ),
        ).toBe("23505");
        expect(
          await dbErrorCode(
            db.query(
              `INSERT INTO kitchen_item (household_id, ingredient_id, custom_name, category) VALUES ($1, 'fixture_x', 'Sambal', 'sauces_condiments')`,
              [home.householdId],
            ),
          ),
        ).toBe("23514");
        await db.query(
          `INSERT INTO kitchen_item (household_id, custom_name, category, quantity) VALUES ($1, 'Sambal Rumah', 'sauces_condiments', 'some')`,
          [home.householdId],
        );
        expect(
          await dbErrorCode(
            db.query(
              `INSERT INTO kitchen_item (household_id, custom_name, category) VALUES ($1, ' sambal rumah ', 'sauces_condiments')`,
              [home.householdId],
            ),
          ),
        ).toBe("23505");
      });

      it("Q19 DAT-04 cooked-meal records are purged after the configured retention", async () => {
        const home = await seedHousehold(db);
        const years = defaultTargets.dataManagement.mealHistoryRetentionYears.value;
        const now = new Date("2026-11-11T00:00:00.000Z");
        const old = randomUUID();
        const recent = randomUUID();
        await db.query(
          `INSERT INTO meal (id, household_id, eaten_on, slot, recipe_id)
           VALUES ($1, $3, '2024-11-10', 'lunch', 'fixture_recipe'), ($2, $3, '2026-11-10', 'dinner', 'fixture_recipe')`,
          [old, recent, home.householdId],
        );
        await db.query(
          `INSERT INTO feedback (meal_id, household_id, overall) VALUES ($1, $2, 'yes')`,
          [old, home.householdId],
        );
        await purgeExpiredMeals(db, now, years);
        expect(
          await count(`SELECT count(*) AS n FROM meal WHERE id = ANY($1::uuid[])`, [[old, recent]]),
        ).toBe(1);
        expect(await count(`SELECT count(*) AS n FROM feedback WHERE meal_id = $1`, [old])).toBe(0);
      });

      it("DAT-06 reference datasets are immutable and only one is active", async () => {
        const hash = (n: number) => String(n).padStart(64, "0");
        await db.query(
          `INSERT INTO reference_dataset (version, schema, content_sha256, payload, is_active)
           VALUES ('fixture-1', 'keluargamakan.reference.ingredients/1', $1, '{"ingredients":[]}', true),
                  ('fixture-2', 'keluargamakan.reference.ingredients/1', $2, '{"ingredients":[]}', false)`,
          [hash(1), hash(2)],
        );
        expect(
          await dbErrorCode(
            db.query(`UPDATE reference_dataset SET is_active = true WHERE version = 'fixture-2'`),
          ),
        ).toBe("23505");
        expect(
          await dbErrorCode(
            db.query(`UPDATE reference_dataset SET payload = '{}' WHERE version = 'fixture-1'`),
          ),
        ).toBe("KM003");
        await db.transaction(async (tx) => {
          await tx.query(
            `UPDATE reference_dataset SET is_active = false WHERE version = 'fixture-1'`,
          );
          await tx.query(
            `UPDATE reference_dataset SET is_active = true WHERE version = 'fixture-2'`,
          );
        });
      });
    });

    it("L1 a corrupted but authentic body never reaches an error message", async () => {
      const home = await seedHousehold(db);
      await giveConsent(home, home.managerProfileId);
      const rule = await insertHardRule(db, keys, {
        householdId: home.householdId,
        profileId: home.managerProfileId,
        rule: { type: "halal" },
        mappingConfirmedBy: null,
      });
      const key = await keys.getOrCreate(db, home.householdId, home.managerProfileId);
      const leaked = '{"allergen":shrimp-secret';
      await db.query(`UPDATE hard_rule SET details_enc = $2 WHERE id = $1`, [
        rule.id,
        encryptField(
          key.dataKey,
          leaked,
          `hard_rule:${rule.id}:${home.managerProfileId}:${home.householdId}`,
        ),
      ]);
      const ruleError = await expectRejects(
        listProfileRules(db, keys, home.householdId, home.managerProfileId),
        RulesUnavailableError,
      );
      expect(inspect(ruleError, { depth: 5 })).not.toContain("shrimp-secret");

      const { rows } = await db.query<{ id: string }>(
        `INSERT INTO safety_log (household_id, log_format, subject_kind, subject_id, evaluated_at,
                                 rule_set_version, reference_version)
         VALUES ($1, 'keluargamakan.safety-log/1', 'suggestion', 'fixture_recipe', now(), 'r1', 'd1')
         RETURNING id`,
        [home.householdId],
      );
      const logId = rows[0]?.id ?? "";
      await db.query(
        `INSERT INTO safety_log_member (log_id, member_index, member_key_id, details_enc)
         VALUES ($1, 0, $2, $3)`,
        [
          logId,
          key.keyId,
          encryptField(key.dataKey, leaked, `safety_log_member:${logId}:0:${key.keyId}`),
        ],
      );
      const logError = await expectRejects(
        readSafetyLog(db, keys, home.householdId, logId),
        InvalidDataError,
      );
      expect(inspect(logError, { depth: 5 })).not.toContain("shrimp-secret");
    });

    it("L2 database errors reach logs without contact details, values or the driver error", async () => {
      const home = await seedHousehold(db);
      const { rows } = await db.query<{ phone: string }>(
        `SELECT phone FROM account WHERE id = $1`,
        [home.accountId],
      );
      const phone = rows[0]?.phone ?? "";
      expect(phone).not.toBe("");
      const raw: unknown = await db
        .query(`INSERT INTO account (phone, sign_in_methods) VALUES ($1, ARRAY['phone'])`, [phone])
        .then(
          () => undefined,
          (caught: unknown) => caught,
        );
      const error = translateDbError(raw);
      expect(error).toBeInstanceOf(DatabaseError);
      expect(error).toMatchObject({ code: "23505", constraint: "account_phone_key" });
      const everything = [
        String(error),
        JSON.stringify(error),
        inspect(error, { depth: 5 }),
        (error as Error).stack ?? "",
      ].join("\n");
      expect(everything).not.toContain(phone.slice(1));
      expect((error as Error).cause).toBeUndefined();
      const badId: unknown = await db.query(`SELECT $1::uuid`, ["Siti Aminah"]).then(
        () => undefined,
        (caught: unknown) => caught,
      );
      expect(inspect(translateDbError(badId))).not.toContain("Siti");
    });

    it("L6 consent records cannot be deleted", async () => {
      const home = await seedHousehold(db);
      const record = await giveConsent(home, home.managerProfileId);
      expect(
        await dbErrorCode(db.query(`DELETE FROM consent_record WHERE id = $1`, [record.id])),
      ).toBe("KM003");
    });

    it("L4 consent and kitchen rows cannot point at another household's account or profile", async () => {
      const a = await seedHousehold(db);
      const b = await seedHousehold(db);
      expect(
        await dbErrorCode(
          db.query(
            `INSERT INTO consent_record (household_id, profile_id, purpose, decision, text_version, language, recorded_by_account_id)
             VALUES ($1, $2, 'health_data', 'given', 'v1', 'id', $3)`,
            [a.householdId, a.managerProfileId, b.accountId],
          ),
        ),
      ).toBe("23503");
      expect(
        await dbErrorCode(
          db.query(
            `INSERT INTO consent_record (household_id, profile_id, purpose, decision, text_version, language, recorded_by_account_id)
             VALUES ($1, $2, 'health_data', 'given', 'v1', 'id', $3)`,
            [a.householdId, b.managerProfileId, a.accountId],
          ),
        ),
      ).toBe("23503");
      expect(
        await dbErrorCode(
          db.query(
            `INSERT INTO kitchen_item (household_id, ingredient_id, category, changed_by_account_id)
             VALUES ($1, 'fixture_rice', 'staples', $2)`,
            [a.householdId, b.accountId],
          ),
        ),
      ).toBe("23503");
    });

    describe("H4 concurrent health-data writes (two connections; PostgreSQL only)", () => {
      const settledWithin = async (promise: Promise<unknown>, ms: number) => {
        let settled = false;
        promise.then(
          () => (settled = true),
          () => (settled = true),
        );
        await new Promise((resolve) => setTimeout(resolve, ms));
        return settled;
      };

      it("H4 a withdrawal waits for an in-flight first rule and then deletes it", async (context) => {
        if (opened.openSession === null) {
          context.skip("PGlite has one connection; set TEST_DATABASE_URL to run");
          return;
        }
        const home = await seedHousehold(db);
        const profile = await addProfile(db, home, "adult");
        await giveConsent(home, profile);
        const session = await opened.openSession();
        try {
          await insertHardRule(session.executor, keys, {
            householdId: home.householdId,
            profileId: profile,
            rule: { type: "allergy", allergen: "shrimp" },
            mappingConfirmedBy: null,
          });
        } catch (error) {
          await session.rollback();
          throw error;
        }
        const withdrawal = withdrawHealthConsent(db, {
          householdId: home.householdId,
          profileId: profile,
          withdrawnAt: new Date(Date.now() + 60_000),
          deletionWindowDays: 30,
        });
        expect(await settledWithin(withdrawal, 300)).toBe(false);
        await session.commit();
        await withdrawal;
        expect(
          await count(`SELECT count(*) AS n FROM hard_rule WHERE profile_id = $1`, [profile]),
        ).toBe(0);
        expect(
          await count(`SELECT count(*) AS n FROM health_data_key WHERE profile_id = $1`, [profile]),
        ).toBe(0);
      });

      it("H4 a rule write waits for an in-flight withdrawal and is then refused", async (context) => {
        if (opened.openSession === null) {
          context.skip("PGlite has one connection; set TEST_DATABASE_URL to run");
          return;
        }
        const home = await seedHousehold(db);
        const profile = await addProfile(db, home, "adult");
        await giveConsent(home, profile);
        const session = await opened.openSession();
        await withdrawHealthConsent(session.executor, {
          householdId: home.householdId,
          profileId: profile,
          withdrawnAt: new Date(Date.now() + 60_000),
          deletionWindowDays: 30,
        });
        const write = insertHardRule(db, keys, {
          householdId: home.householdId,
          profileId: profile,
          rule: { type: "halal" },
          mappingConfirmedBy: null,
        });
        expect(await settledWithin(write, 300)).toBe(false);
        await session.commit();
        await expectRejects(write, ConsentRequiredError);
      });
    });

    it("latest consent lookup ignores other households", async () => {
      const a = await seedHousehold(db);
      const b = await seedHousehold(db);
      await giveConsent(a, a.managerProfileId);
      const map = await latestHealthConsents(db, b.householdId, [a.managerProfileId]);
      expect(consentStateOf(map.get(a.managerProfileId)).status).toBe("none");
    });
  });
}
