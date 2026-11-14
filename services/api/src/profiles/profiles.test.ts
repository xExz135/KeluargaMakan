// TEST FIXTURE: not real safety or nutrition data. Fictional households,
// profiles, rules and reference ingredients (IDs prefixed `fx_api_`); phone
// numbers on an unassigned range.
import "reflect-metadata";

import { randomUUID } from "node:crypto";

import {
  evaluate,
  STANDARD_ALLERGENS,
  type ReferenceDataset,
  type ReferenceIngredient,
} from "@keluargamakan/cek-aman";
import { RequestMethod } from "@nestjs/common";
import { afterAll, beforeAll, describe, expect, it } from "vitest";

import { resolveProfileConfig } from "../../config/profiles.js";
import { CONSENT_TEXTS, HEALTH_DATA_TEXTS } from "../consent/consent-texts.js";
import { consentStateOf, latestHealthConsents } from "../db/consent.js";
import { KeyServiceError, type KeyProvider } from "../db/crypto/key-provider.js";
import type { SqlExecutor } from "../db/executor.js";
import { loadRulesForEvaluation } from "../db/hard-rules.js";
import { HealthDataKeys } from "../db/health-data-keys.js";
import { migrate } from "../db/migrate.js";
import { DATABASE_TARGETS, type TestDatabase } from "../db/testing/databases.js";
import { randomLocalKeys } from "../db/testing/seed.js";
import { CONTROLLERS } from "../http/app.js";
import {
  contractErrors,
  signInWithHousehold,
  startHarness,
  type Harness,
  type HouseholdSession,
  type Response,
} from "../http/testing/harness.js";

const HEALTH_VERSION = CONSENT_TEXTS.health_data.version;
const CHILD_VERSION = HEALTH_DATA_TEXTS.child.version;
const GUARDIAN = {
  confirmed: true,
  textVersion: CONSENT_TEXTS.guardian_confirmation.version,
  language: "id",
} as const;
const REFERENCE_VERSION = "TEST-FIXTURE-api-profiles-1";

function fixtureIngredient(
  id: string,
  name: string,
  contains: readonly string[],
): ReferenceIngredient {
  return {
    id,
    displayName: { id: `${name} fiksi`, en: `Fictional ${name}` },
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

const INGREDIENTS = [
  fixtureIngredient("fx_api_udang", "udang", ["shrimp"]),
  fixtureIngredient("fx_api_kacang", "kacang", ["peanut"]),
  fixtureIngredient("fx_api_nasi", "nasi", []),
];
const REFERENCE: ReferenceDataset = {
  schema: "keluargamakan.reference.ingredients/1",
  version: REFERENCE_VERSION,
  ingredients: INGREDIENTS,
};

function expectProblem(response: Response, status: number, code: string): void {
  expect(response.status, response.raw).toBe(status);
  expect(contractErrors("Problem", response.body)).toEqual([]);
  expect(response.body).toMatchObject({ status, code, detail: null });
}

/** A driver error as node-postgres raises it. */
function driverError(code: string): Error {
  return Object.assign(new Error("database error"), { code });
}

/** An executor that fails the statements matching `pattern` with SQLSTATE `code`. */
function failingExecutor(db: SqlExecutor, pattern: RegExp, code: string): SqlExecutor {
  const wrap = (inner: SqlExecutor): SqlExecutor => ({
    query: (text, params) =>
      pattern.test(text) ? Promise.reject(driverError(code)) : inner.query(text, params),
    execScript: (sql) => inner.execScript(sql),
    transaction: (fn) => inner.transaction((tx) => fn(wrap(tx))),
  });
  return wrap(db);
}

/** A key service that is down: every wrap and unwrap fails. */
const keyServiceDown: KeyProvider = {
  kek: (purpose) => ({
    purpose,
    keyRef: "fixture-down",
    wrap: () => Promise.reject(new KeyServiceError("key service unavailable")),
    unwrap: () => Promise.reject(new KeyServiceError("key service unavailable")),
  }),
};

interface ProfileBody {
  id: string;
  isChild: boolean;
  isManager: boolean;
  guardianConfirmation: unknown;
  portions: {
    portionSize: string;
    portionSizeIsDefault: boolean;
    ricePortion: string;
    ricePortionIsDefault: boolean;
  };
  rules: { consent: { status: string }; items: { id: string; type: string }[] };
}

/** Every route of the API that takes an ID in its path, as `METHOD /path`. */
function routesWithPathIds(): string[] {
  const out: string[] = [];
  for (const controller of CONTROLLERS) {
    const base = String(Reflect.getMetadata("path", controller) ?? "");
    const proto = controller.prototype as unknown as Record<string, unknown>;
    for (const name of Object.getOwnPropertyNames(proto)) {
      const handler = Object.getOwnPropertyDescriptor(proto, name)?.value as unknown;
      if (typeof handler !== "function") continue;
      const method = Reflect.getMetadata("method", handler) as RequestMethod | undefined;
      if (method === undefined) continue;
      const path = String(Reflect.getMetadata("path", handler) ?? "/");
      const full = `/${[base, path]
        .map((p) => p.replace(/^\/|\/$/g, ""))
        .filter(Boolean)
        .join("/")}`;
      if (/:(profileId|ruleId)/.test(full)) out.push(`${RequestMethod[method]} ${full}`);
    }
  }
  return out.sort();
}

for (const target of DATABASE_TARGETS) {
  if (target.skipReason !== null) {
    describe(`profiles API: ${target.name}`, () => {
      it.skip(`skipped: ${target.skipReason}`, () => undefined);
    });
    continue;
  }

  describe(`profiles API: ${target.name}`, () => {
    let opened: TestDatabase;
    let db: SqlExecutor;
    let api: Harness;
    const keys = new HealthDataKeys(randomLocalKeys());
    const extra: Harness[] = [];

    beforeAll(async () => {
      opened = await target.open();
      db = opened.executor;
      await migrate(db);
      await db.query(
        `INSERT INTO reference_dataset (version, schema, content_sha256, payload, is_active)
         VALUES ($1, 'keluargamakan.reference.ingredients/1', $2, $3::jsonb, true)`,
        [REFERENCE_VERSION, "a".repeat(64), JSON.stringify({ ingredients: INGREDIENTS })],
      );
      api = await startHarness(db, { keys });
    });

    afterAll(async () => {
      for (const harness of extra) await harness.close();
      await api.close();
      await opened.close();
    });

    const another = async (options: Parameters<typeof startHarness>[1]) => {
      const harness = await startHarness(db, { secrets: api.secrets, ...options });
      extra.push(harness);
      return harness;
    };

    const profilesUrl = "/v1/household/profiles";
    const profileUrl = (id: string) => `${profilesUrl}/${id}`;
    const rulesUrl = (id: string) => `${profileUrl(id)}/hard-rules`;

    const createProfile = (home: HouseholdSession, body: object, key?: string, h: Harness = api) =>
      h.request("POST", profilesUrl, {
        token: home.token,
        body,
        ...(key === undefined ? {} : { headers: { "idempotency-key": key } }),
      });
    /** The member's consent state as the app shows it (precondition for consent writes, M1). */
    const expectedConsentOf = async (home: HouseholdSession, profileId: string) => {
      const state = consentStateOf(
        (await latestHealthConsents(db, home.householdId, [profileId])).get(profileId),
      );
      return { status: state.status, consentRecordId: state.consentRecordId };
    };
    const isChildInDb = async (profileId: string) =>
      (
        await db.query<{ is_child: boolean }>(`SELECT is_child FROM profile WHERE id = $1`, [
          profileId,
        ])
      ).rows[0]?.is_child === true;
    const giveConsent = async (
      home: HouseholdSession,
      profileId: string,
      decision = "given",
      textVersion?: string,
    ) => {
      const version =
        textVersion ?? ((await isChildInDb(profileId)) ? CHILD_VERSION : HEALTH_VERSION);
      const response = await api.request("POST", `${profileUrl(profileId)}/consents/health-data`, {
        token: home.token,
        body: {
          decision,
          textVersion: version,
          language: "id",
          expectedConsent: await expectedConsentOf(home, profileId),
        },
      });
      expect(response.status, response.raw).toBe(201);
    };
    const withdrawConsent = async (home: HouseholdSession, profileId: string) =>
      api.request("POST", `${profileUrl(profileId)}/consents/health-data/withdraw`, {
        token: home.token,
        body: { expectedConsent: await expectedConsentOf(home, profileId) },
      });
    const addRule = (
      home: HouseholdSession,
      profileId: string,
      body: object,
      key?: string,
      h: Harness = api,
    ) =>
      h.request("POST", rulesUrl(profileId), {
        token: home.token,
        body,
        ...(key === undefined ? {} : { headers: { "idempotency-key": key } }),
      });
    const count = async (sql: string, params: unknown[]) =>
      Number((await db.query<{ n: string }>(sql, params)).rows[0]?.n);
    const ruleRows = (profileId: string) =>
      count(`SELECT count(*) AS n FROM hard_rule WHERE profile_id = $1`, [profileId]);

    describe("PRF-01 PRF-02 profiles", () => {
      it("PRF-01 a member is added with health data off and age-group default portions", async () => {
        const home = await signInWithHousehold(api);
        const created = await createProfile(home, { name: "Ayah", ageGroup: "adult" });
        expect(created.status, created.raw).toBe(201);
        expect(contractErrors("Profile", created.body)).toEqual([]);
        expect(created.body).toMatchObject({
          name: "Ayah",
          ageGroup: "adult",
          isChild: false,
          isManager: false,
          guardianConfirmation: null,
          portions: {
            portionSize: "normal",
            portionSizeIsDefault: true,
            ricePortion: "normal",
            ricePortionIsDefault: true,
          },
          rules: { consent: { status: "none" }, items: [] },
          preferences: { spiceLevel: null, lessOf: [], textures: [], updatedAt: null },
          likesDislikes: { likes: [], dislikes: [], updatedAt: null },
        });

        const listed = await api.request("GET", profilesUrl, { token: home.token });
        expect(listed.status).toBe(200);
        expect(contractErrors("ProfileList", listed.body)).toEqual([]);
        const list = listed.body as { items: ProfileBody[]; maxProfiles: number };
        expect(list.maxProfiles).toBe(12);
        expect(list.items.map((p) => p.isManager)).toEqual([true, false]);
        expect(list.items[0]?.id).toBe(home.managerProfileId);
      });

      it("PRF-02 at least 12 profiles; the limit comes from config", async () => {
        const home = await signInWithHousehold(api);
        for (let n = 2; n <= 12; n += 1) {
          expect(
            (await createProfile(home, { name: `Anggota ${n}`, ageGroup: "adult" })).status,
          ).toBe(201);
        }
        expectProblem(
          await createProfile(home, { name: "Ke-13", ageGroup: "adult" }),
          409,
          "profile_limit_reached",
        );
        const larger = await another({ targets: { household: { maxProfiles: 13 } }, keys });
        expect(
          (await createProfile(home, { name: "Ke-13", ageGroup: "adult" }, undefined, larger))
            .status,
        ).toBe(201);
        const listed = await larger.request("GET", profilesUrl, { token: home.token });
        expect((listed.body as { items: unknown[]; maxProfiles: number }).items).toHaveLength(13);
        expect((listed.body as { maxProfiles: number }).maxProfiles).toBe(13);
      });

      it("PRF-01 a repeated create with the same Idempotency-Key returns the same profile", async () => {
        const home = await signInWithHousehold(api);
        const key = randomUUID();
        const first = await createProfile(home, { name: "Kakek", ageGroup: "elderly" }, key);
        const again = await createProfile(home, { name: "Kakek", ageGroup: "elderly" }, key);
        expect(again.status).toBe(201);
        expect((again.body as ProfileBody).id).toBe((first.body as ProfileBody).id);
        expect(
          await count(`SELECT count(*) AS n FROM profile WHERE household_id = $1`, [
            home.householdId,
          ]),
        ).toBe(2);
        expectProblem(
          await createProfile(home, { name: "Nenek", ageGroup: "elderly" }, key),
          409,
          "idempotency_key_reused",
        );
      });

      it("PRF-01 names, avatars and portions can be edited; null portion returns to the default", async () => {
        const home = await signInWithHousehold(api);
        const id = (
          (await createProfile(home, { name: "Om", ageGroup: "adult" })).body as ProfileBody
        ).id;
        const edited = await api.request("PATCH", profileUrl(id), {
          token: home.token,
          body: {
            name: "Om Budi",
            avatar: { style: "illustration", illustrationId: "fruit_1" },
            portionSize: "large",
            ricePortion: "small",
          },
        });
        expect(edited.status, edited.raw).toBe(200);
        expect(contractErrors("Profile", edited.body)).toEqual([]);
        expect(edited.body).toMatchObject({
          name: "Om Budi",
          avatar: { style: "illustration", colorToken: null, illustrationId: "fruit_1" },
          portions: {
            portionSize: "large",
            portionSizeIsDefault: false,
            ricePortion: "small",
            ricePortionIsDefault: false,
          },
        });
        const reset = await api.request("PATCH", profileUrl(id), {
          token: home.token,
          body: { portionSize: null },
        });
        expect((reset.body as ProfileBody).portions).toMatchObject({
          portionSize: "normal",
          portionSizeIsDefault: true,
          ricePortion: "small",
        });
        for (const body of [
          {},
          { isChild: false },
          { name: "" },
          { portionSize: "huge" },
          { name: "A‮B" },
        ]) {
          expectProblem(
            await api.request("PATCH", profileUrl(id), { token: home.token, body }),
            400,
            "validation_failed",
          );
        }
      });

      it("PRF-07 portion defaults by age group come from config", async () => {
        const configured = await another({
          keys,
          profileConfig: resolveProfileConfig({
            portionDefaults: { child: { portionSize: "small", ricePortion: "small" } },
          }),
        });
        const home = await signInWithHousehold(configured);
        const child = await createProfile(
          home,
          { name: "Adik", ageGroup: "child", guardianConfirmation: GUARDIAN },
          undefined,
          configured,
        );
        expect((child.body as ProfileBody).portions).toEqual({
          portionSize: "small",
          portionSizeIsDefault: true,
          ricePortion: "small",
          ricePortionIsDefault: true,
        });
        const adult = await createProfile(
          home,
          { name: "Tante", ageGroup: "adult" },
          undefined,
          configured,
        );
        expect((adult.body as ProfileBody).portions.portionSize).toBe("normal");
      });

      it("SET-07 deleting a profile removes its rules and key; the manager's own profile cannot be deleted here", async () => {
        const home = await signInWithHousehold(api);
        const id = (
          (await createProfile(home, { name: "Sepupu", ageGroup: "adult" })).body as ProfileBody
        ).id;
        await giveConsent(home, id);
        expect((await addRule(home, id, { type: "allergy", allergen: "egg" })).status).toBe(201);
        const removed = await api.request("DELETE", profileUrl(id), { token: home.token });
        expect(removed.status).toBe(204);
        expect(await ruleRows(id)).toBe(0);
        expect(
          await count(`SELECT count(*) AS n FROM health_data_key WHERE profile_id = $1`, [id]),
        ).toBe(0);
        expectProblem(
          await api.request("GET", profileUrl(id), { token: home.token }),
          404,
          "not_found",
        );
        expectProblem(
          await api.request("DELETE", profileUrl(home.managerProfileId), { token: home.token }),
          409,
          "manager_profile_not_deletable",
        );
      });
    });

    describe("PRF-18 SET-10 children's profiles", () => {
      it("SET-10 a child profile needs the manager's guardian confirmation, and nothing is stored without it", async () => {
        const home = await signInWithHousehold(api);
        for (const ageGroup of ["infant", "child", "teen"]) {
          expectProblem(
            await createProfile(home, { name: "Anak", ageGroup }),
            409,
            "guardian_confirmation_required",
          );
          expectProblem(
            await createProfile(home, {
              name: "Anak",
              ageGroup,
              guardianConfirmation: { ...GUARDIAN, confirmed: false },
            }),
            409,
            "guardian_confirmation_required",
          );
        }
        expectProblem(
          await createProfile(home, {
            name: "Anak",
            ageGroup: "child",
            guardianConfirmation: { ...GUARDIAN, textVersion: "guardian-confirmation-draft-0" },
          }),
          409,
          "consent_text_outdated",
        );
        expect(
          await count(`SELECT count(*) AS n FROM profile WHERE household_id = $1`, [
            home.householdId,
          ]),
        ).toBe(1);
      });

      it("PRF-18 SET-10 a child is flagged, the confirmation is recorded and health data stays off", async () => {
        const home = await signInWithHousehold(api);
        const created = await createProfile(home, {
          name: "Kakak",
          ageGroup: "teen",
          guardianConfirmation: GUARDIAN,
        });
        expect(created.status, created.raw).toBe(201);
        expect(contractErrors("Profile", created.body)).toEqual([]);
        const body = created.body as ProfileBody & {
          guardianConfirmation: { textVersion: string; confirmedAt: string };
        };
        expect(body.isChild).toBe(true);
        expect(body.guardianConfirmation).toMatchObject({
          textVersion: GUARDIAN.textVersion,
          confirmedAt: api.clock.now().toISOString(),
        });
        expect(body.rules).toEqual({
          consent: {
            status: "none",
            consentRecordId: null,
            decidedAt: null,
            textVersion: null,
            deletionDueBy: null,
            renewalRequired: false,
          },
          items: [],
        });
        // Health data off by default: no rule before consent, even after the guardian confirmation.
        expectProblem(
          await addRule(home, body.id, { type: "allergy", allergen: "peanut" }),
          409,
          "consent_required",
        );
        await giveConsent(home, body.id);
        expect((await addRule(home, body.id, { type: "allergy", allergen: "peanut" })).status).toBe(
          201,
        );
      });

      it("SET-10 an adult profile takes no guardian confirmation; a change into a child age group needs one", async () => {
        const home = await signInWithHousehold(api);
        expectProblem(
          await createProfile(home, {
            name: "Paman",
            ageGroup: "adult",
            guardianConfirmation: GUARDIAN,
          }),
          400,
          "validation_failed",
        );
        const id = (
          (await createProfile(home, { name: "Remaja", ageGroup: "adult" })).body as ProfileBody
        ).id;
        expectProblem(
          await api.request("PATCH", profileUrl(id), {
            token: home.token,
            body: { ageGroup: "teen" },
          }),
          409,
          "guardian_confirmation_required",
        );
        const changed = await api.request("PATCH", profileUrl(id), {
          token: home.token,
          body: { ageGroup: "teen", guardianConfirmation: GUARDIAN },
        });
        expect(changed.status, changed.raw).toBe(200);
        expect(changed.body).toMatchObject({ ageGroup: "teen", isChild: true });
      });
    });

    describe("QUESTIONS #46 #62 owner decisions (2026-11-12)", () => {
      interface RulesBody {
        consent: { status: string; renewalRequired: boolean };
        items: { id: string }[];
      }
      const rulesOf = async (home: HouseholdSession, id: string) =>
        (await api.request("GET", rulesUrl(id), { token: home.token })).body as RulesBody;
      /** Cek Aman input for the member, as the safety pipeline reads it. */
      const shrimpResult = async (home: HouseholdSession, id: string) => {
        const [member] = await loadRulesForEvaluation(db, keys, home.householdId, [id]);
        if (member?.hardRules == null) throw new Error("rules dropped from the safety check");
        return evaluate({
          ingredients: [{ ingredientId: "fx_api_udang", rawName: "udang fiksi" }],
          recordedBrands: [],
          members: [{ memberId: id, hardRules: member.hardRules }],
          reference: REFERENCE,
        }).perMember[0]?.status;
      };
      const setAge = (home: HouseholdSession, id: string, ageGroup: string, guardian = false) =>
        api.request("PATCH", profileUrl(id), {
          token: home.token,
          body: { ageGroup, ...(guardian ? { guardianConfirmation: GUARDIAN } : {}) },
        });

      it("Q46 the manager's own profile can never take a child age group", async () => {
        const home = await signInWithHousehold(api);
        for (const ageGroup of ["infant", "child", "teen"]) {
          expectProblem(
            await setAge(home, home.managerProfileId, ageGroup, true),
            409,
            "manager_profile_must_be_adult",
          );
        }
        expect((await setAge(home, home.managerProfileId, "elderly")).status).toBe(200);
        const profile = await api.request("GET", profileUrl(home.managerProfileId), {
          token: home.token,
        });
        expect(profile.body).toMatchObject({
          ageGroup: "elderly",
          isChild: false,
          isManager: true,
        });
        // At creation the manager's profile is always an adult: no age group can be given.
        const consents = await db.query(
          `SELECT 1 FROM consent_record WHERE profile_id = $1 AND purpose = 'guardian_confirmation'`,
          [home.managerProfileId],
        );
        expect(consents.rows).toHaveLength(0);
      });

      it("Q62 adult to child: rules are kept and still applied; new health data waits for re-consent on the child text", async () => {
        const home = await signInWithHousehold(api);
        const id = (
          (await createProfile(home, { name: "Remaja", ageGroup: "adult" })).body as ProfileBody
        ).id;
        await giveConsent(home, id);
        expect((await addRule(home, id, { type: "allergy", allergen: "shrimp" })).status).toBe(201);
        expect(await shrimpResult(home, id)).toBe("not_safe");

        expect((await setAge(home, id, "teen", true)).status).toBe(200);
        const after = await rulesOf(home, id);
        expect(after.consent).toMatchObject({ status: "given", renewalRequired: true });
        expect(after.items).toHaveLength(1);
        // Fail closed: Cek Aman still applies the stored allergy.
        expect(await shrimpResult(home, id)).toBe("not_safe");
        expectProblem(await addRule(home, id, { type: "halal" }), 409, "consent_required");

        // Re-consent must use the child text.
        const adultText = await api.request("POST", `${profileUrl(id)}/consents/health-data`, {
          token: home.token,
          body: {
            decision: "given",
            textVersion: HEALTH_VERSION,
            language: "id",
            expectedConsent: await expectedConsentOf(home, id),
          },
        });
        expectProblem(adultText, 409, "consent_text_outdated");
        await giveConsent(home, id, "given", CHILD_VERSION);
        expect((await rulesOf(home, id)).consent.renewalRequired).toBe(false);
        expect((await addRule(home, id, { type: "halal" })).status).toBe(201);
        expect(await ruleRows(id)).toBe(2);
      });

      it("Q62 child to adult: a child-text consent needs renewal; an adult-text consent from before still counts", async () => {
        const home = await signInWithHousehold(api);
        // A member who was a child when consent was given.
        const child = (
          (
            await createProfile(home, {
              name: "Kakak",
              ageGroup: "teen",
              guardianConfirmation: GUARDIAN,
            })
          ).body as ProfileBody
        ).id;
        await giveConsent(home, child);
        expect((await addRule(home, child, { type: "allergy", allergen: "shrimp" })).status).toBe(
          201,
        );
        expect((await setAge(home, child, "adult")).status).toBe(200);
        const grown = await rulesOf(home, child);
        expect(grown.consent.renewalRequired).toBe(true);
        expect(grown.items).toHaveLength(1);
        expect(await shrimpResult(home, child)).toBe("not_safe");
        expectProblem(await addRule(home, child, { type: "vegan" }), 409, "consent_required");
        await giveConsent(home, child, "given", HEALTH_VERSION);
        expect((await addRule(home, child, { type: "vegan" })).status).toBe(201);

        // A member whose latest consent is on the adult text: adult, teen, adult again.
        const adult = (
          (await createProfile(home, { name: "Sepupu", ageGroup: "adult" })).body as ProfileBody
        ).id;
        await giveConsent(home, adult);
        await addRule(home, adult, { type: "halal" });
        expect((await setAge(home, adult, "teen", true)).status).toBe(200);
        expect((await rulesOf(home, adult)).consent.renewalRequired).toBe(true);
        expect((await setAge(home, adult, "adult")).status).toBe(200);
        expect((await rulesOf(home, adult)).consent.renewalRequired).toBe(false);
        expect((await addRule(home, adult, { type: "vegan" })).status).toBe(201);
      });
    });

    describe("L5 names and rule text (security review T-019)", () => {
      const HIDDEN = [
        "uda​ng", // zero-width space
        "uda⁠ng", // word joiner
        "﻿udang", // byte-order mark
        "uda­ng", // soft hyphen
        "A‮B", // bidi override
        "A\ud800B", // lone surrogate
        "A\u0007B", // control
        "AB", // private use
      ];

      it("L5 names with hidden or invalid characters are refused without echoing them; names are stored in NFC", async () => {
        const home = await signInWithHousehold(api);
        for (const name of HIDDEN) {
          const created = await createProfile(home, { name, ageGroup: "adult" });
          expectProblem(created, 400, "validation_failed");
          expect(created.raw).not.toContain(name);
          expectProblem(
            await api.request("PATCH", profileUrl(home.managerProfileId), {
              token: home.token,
              body: { name },
            }),
            400,
            "validation_failed",
          );
        }
        const decomposed = await createProfile(home, { name: "René", ageGroup: "adult" });
        expect(decomposed.status).toBe(201);
        expect((decomposed.body as { name: string }).name).toBe("René");
      });

      it("L5 rule text with hidden characters is refused; look-alike text is a duplicate", async () => {
        const home = await signInWithHousehold(api);
        const id = home.managerProfileId;
        await giveConsent(home, id);
        for (const freeText of HIDDEN) {
          const created = await addRule(home, id, { type: "free_text", freeText });
          expectProblem(created, 400, "validation_failed");
          expect(created.raw).not.toContain(freeText);
        }
        expect(
          (await addRule(home, id, { type: "free_text", freeText: "udang galah" })).status,
        ).toBe(201);
        expectProblem(
          await addRule(home, id, {
            type: "free_text",
            freeText: "ｕｄａｎｇ galah",
          }),
          409,
          "hard_rule_duplicate",
        );
        expect(await ruleRows(id)).toBe(1);
      });

      it("L5 concurrent identical rule creates store one rule (checked under the member lock)", async () => {
        const home = await signInWithHousehold(api);
        const id = home.managerProfileId;
        await giveConsent(home, id);
        const results = await Promise.all(
          [0, 1, 2].map(() => addRule(home, id, { type: "allergy", allergen: "soy" })),
        );
        expect(results.map((r) => r.status).sort()).toEqual([201, 409, 409]);
        expect(await ruleRows(id)).toBe(1);
      });
    });

    describe("PRF-05 PRF-06 soft preferences, likes and dislikes", () => {
      it("PRF-05 soft preferences are replaced as a whole and can be sent again", async () => {
        const home = await signInWithHousehold(api);
        const body = { spiceLevel: "not_spicy", lessOf: ["fried", "santan"], textures: ["soft"] };
        for (let n = 0; n < 2; n += 1) {
          const saved = await api.request(
            "PUT",
            `${profileUrl(home.managerProfileId)}/preferences`,
            {
              token: home.token,
              body,
            },
          );
          expect(saved.status, saved.raw).toBe(200);
          expect(contractErrors("SoftPreferences", saved.body)).toEqual([]);
          expect(saved.body).toMatchObject(body);
        }
        const profile = await api.request("GET", profileUrl(home.managerProfileId), {
          token: home.token,
        });
        expect(profile.body).toMatchObject({ preferences: body });
        for (const bad of [
          { spiceLevel: "hot", lessOf: [], textures: [] },
          { spiceLevel: null, lessOf: ["fried", "fried"], textures: [] },
          { spiceLevel: null, lessOf: ["oil"], textures: [] },
          { spiceLevel: null, lessOf: [] },
        ]) {
          expectProblem(
            await api.request("PUT", `${profileUrl(home.managerProfileId)}/preferences`, {
              token: home.token,
              body: bad,
            }),
            400,
            "validation_failed",
          );
        }
      });

      it("PRF-06 likes and dislikes are known ingredients with reference names; a dislike is never a hard rule", async () => {
        const home = await signInWithHousehold(api);
        const url = `${profileUrl(home.managerProfileId)}/likes-dislikes`;
        const saved = await api.request("PUT", url, {
          token: home.token,
          body: {
            likes: [{ kind: "ingredient", refId: "fx_api_nasi" }],
            dislikes: [{ kind: "ingredient", refId: "fx_api_udang" }],
          },
        });
        expect(saved.status, saved.raw).toBe(200);
        expect(contractErrors("LikesDislikes", saved.body)).toEqual([]);
        expect(saved.body).toMatchObject({
          likes: [
            { refId: "fx_api_nasi", displayName: { id: "nasi fiksi", en: "Fictional nasi" } },
          ],
          dislikes: [{ refId: "fx_api_udang" }],
        });
        expect(await ruleRows(home.managerProfileId)).toBe(0);
        const rules = await api.request("GET", rulesUrl(home.managerProfileId), {
          token: home.token,
        });
        expect(rules.body).toMatchObject({ items: [] });

        for (const body of [
          // Unknown ingredient and (until the library, T-041) any dish.
          { likes: [{ kind: "ingredient", refId: "fx_api_unknown" }], dislikes: [] },
          { likes: [{ kind: "dish", refId: "fx_api_dish" }], dislikes: [] },
          // Both liked and disliked.
          {
            likes: [{ kind: "ingredient", refId: "fx_api_nasi" }],
            dislikes: [{ kind: "ingredient", refId: "fx_api_nasi" }],
          },
          { likes: [{ kind: "ingredient", refId: "Not An ID" }], dislikes: [] },
        ]) {
          expectProblem(
            await api.request("PUT", url, { token: home.token, body }),
            400,
            "validation_failed",
          );
        }
        const replaced = await api.request("PUT", url, {
          token: home.token,
          body: { likes: [], dislikes: [] },
        });
        expect(replaced.body).toMatchObject({ likes: [], dislikes: [] });
      });
    });

    describe("PRF-03 PRF-04 ACC-08 hard rules", () => {
      it("PRF-04 the standard allergen list comes from the Cek Aman vocabulary", async () => {
        const home = await signInWithHousehold(api);
        const list = await api.request("GET", "/v1/reference/allergens", { token: home.token });
        expect(list.status).toBe(200);
        expect(contractErrors("StandardAllergenList", list.body)).toEqual([]);
        const body = list.body as { ruleSetVersion: string; items: string[] };
        expect(body.items).toEqual([...STANDARD_ALLERGENS]);
        for (const required of [
          "peanut",
          "tree_nut",
          "shellfish",
          "shrimp",
          "fish",
          "egg",
          "milk",
          "soy",
          "wheat",
          "gluten",
          "sesame",
        ]) {
          expect(body.items).toContain(required);
        }
        expect(body.ruleSetVersion).toMatch(/^cek-aman-rules\//);
      });

      it("ACC-08 no hard rule is saved without an active consent: 409 before any key work", async () => {
        const home = await signInWithHousehold(api);
        const id = home.managerProfileId;
        expectProblem(await addRule(home, id, { type: "halal" }), 409, "consent_required");
        await giveConsent(home, id, "declined");
        expectProblem(await addRule(home, id, { type: "halal" }), 409, "consent_required");
        await giveConsent(home, id);
        expect((await addRule(home, id, { type: "halal" })).status).toBe(201);
        expect((await withdrawConsent(home, id)).status).toBe(200);
        expectProblem(await addRule(home, id, { type: "halal" }), 409, "consent_required");
        expect(await ruleRows(id)).toBe(0);
        // The gate answers before the key service: even with it down the answer is 409.
        const down = await another({ keys: new HealthDataKeys(keyServiceDown) });
        expectProblem(
          await addRule(home, id, { type: "vegan" }, undefined, down),
          409,
          "consent_required",
        );
        expect(
          await count(`SELECT count(*) AS n FROM health_data_key WHERE profile_id = $1`, [id]),
        ).toBe(0);
      });

      it("PRF-03 every rule type is stored encrypted and listed; rules are added or removed, never overridden", async () => {
        const home = await signInWithHousehold(api);
        const id = home.managerProfileId;
        await giveConsent(home, id);
        const bodies = [
          { type: "allergy", allergen: "shrimp" },
          { type: "halal" },
          { type: "vegetarian" },
          { type: "vegan" },
          { type: "medical_exclusion" },
          { type: "medical_exclusion", freeText: "Pantangan dokter fiksi" },
          { type: "free_text", freeText: "Alergi buah fiksi" },
          {
            type: "free_text",
            freeText: "Pantangan kacang fiksi",
            mappedIngredientIds: ["fx_api_kacang"],
          },
        ];
        const ids: string[] = [];
        for (const body of bodies) {
          api.clock.advance(1);
          const created = await addRule(home, id, body);
          expect(created.status, created.raw).toBe(201);
          expect(contractErrors("HardRule", created.body)).toEqual([]);
          ids.push((created.body as { id: string }).id);
        }
        const mapped = (await api.request("GET", rulesUrl(id), { token: home.token })).body as {
          consent: { status: string };
          items: { id: string; mapping: unknown }[];
        };
        expect(contractErrors("ProfileRules", mapped)).toEqual([]);
        expect(mapped.consent.status).toBe("given");
        expect(mapped.items.map((r) => r.id)).toEqual(ids);
        expect(mapped.items[6]?.mapping).toMatchObject({
          status: "unmapped",
          ingredients: [],
          confirmedBy: null,
        });
        expect(mapped.items[7]?.mapping).toMatchObject({
          status: "mapped",
          confirmedBy: "manager",
          ingredients: [{ ingredientId: "fx_api_kacang", displayName: { id: "kacang fiksi" } }],
        });

        // DAT-02: no rule content in plain columns or in the stored bytes.
        const stored = await db.query<{ details_enc: Uint8Array }>(
          `SELECT details_enc FROM hard_rule WHERE profile_id = $1`,
          [id],
        );
        for (const row of stored.rows) {
          const text = Buffer.from(row.details_enc).toString("latin1");
          for (const word of ["shrimp", "halal", "vegan", "fiksi", "allergy", "fx_api_kacang"]) {
            expect(text).not.toContain(word);
          }
        }

        // No route updates a rule (SAF-12): only add and remove.
        expectProblem(
          await api.request("PATCH", `${rulesUrl(id)}/${ids[0]}`, {
            token: home.token,
            body: { type: "halal" },
          }),
          404,
          "not_found",
        );
        expectProblem(
          await api.request("PUT", `${rulesUrl(id)}/${ids[0]}`, {
            token: home.token,
            body: { type: "halal" },
          }),
          404,
          "not_found",
        );
        expect(
          (await api.request("DELETE", `${rulesUrl(id)}/${ids[0]}`, { token: home.token })).status,
        ).toBe(204);
        expectProblem(
          await api.request("DELETE", `${rulesUrl(id)}/${ids[0]}`, { token: home.token }),
          404,
          "not_found",
        );
        expect(await ruleRows(id)).toBe(bodies.length - 1);
      });

      it("PRF-03 a duplicate rule is refused with 409 hard_rule_duplicate", async () => {
        const home = await signInWithHousehold(api);
        await giveConsent(home, home.managerProfileId);
        expect(
          (await addRule(home, home.managerProfileId, { type: "allergy", allergen: "milk" }))
            .status,
        ).toBe(201);
        expectProblem(
          await addRule(home, home.managerProfileId, { type: "allergy", allergen: "milk" }),
          409,
          "hard_rule_duplicate",
        );
        expect(
          (
            await addRule(home, home.managerProfileId, {
              type: "free_text",
              freeText: "Durian  fiksi",
            })
          ).status,
        ).toBe(201);
        expectProblem(
          await addRule(home, home.managerProfileId, {
            type: "free_text",
            freeText: "durian fiksi",
          }),
          409,
          "hard_rule_duplicate",
        );
      });

      it("PRF-08 mappedIngredientIds: absent or null is unmapped, [] and unknown IDs are refused", async () => {
        const home = await signInWithHousehold(api);
        const id = home.managerProfileId;
        await giveConsent(home, id);
        const nulled = await addRule(home, id, {
          type: "free_text",
          freeText: "Satu",
          mappedIngredientIds: null,
        });
        expect(nulled.status).toBe(201);
        expect(nulled.body).toMatchObject({ mapping: { status: "unmapped", ingredients: [] } });
        for (const body of [
          { type: "free_text", freeText: "Dua", mappedIngredientIds: [] },
          { type: "free_text", freeText: "Dua", mappedIngredientIds: "fx_api_kacang" },
          { type: "free_text", freeText: "Dua", mappedIngredientIds: ["fx_api_unknown"] },
          {
            type: "free_text",
            freeText: "Dua",
            mappedIngredientIds: ["fx_api_kacang", "fx_api_kacang"],
          },
          { type: "allergy", allergen: "peanut", mappedIngredientIds: ["fx_api_kacang"] },
        ]) {
          expectProblem(await addRule(home, id, body), 400, "validation_failed");
        }
        expect(await ruleRows(id)).toBe(1);
      });

      it("PRF-03 PRF-04 invalid rule bodies are refused without storing anything", async () => {
        const home = await signInWithHousehold(api);
        const id = home.managerProfileId;
        await giveConsent(home, id);
        for (const body of [
          {},
          { type: "allergy" },
          { type: "allergy", allergen: "durian" },
          { type: "allergy", allergen: "egg", freeText: "x" },
          { type: "halal", freeText: "x" },
          { type: "halal", allergen: "egg" },
          { type: "free_text" },
          { type: "free_text", freeText: "   " },
          { type: "free_text", freeText: "x".repeat(201) },
          { type: "free_text", freeText: "teks\u0000fiksi" },
          { type: "medical_exclusion", freeText: "" },
          { type: "diet" },
          { type: "halal", confirmedBy: "content_team" },
        ]) {
          expectProblem(await addRule(home, id, body), 400, "validation_failed");
        }
        expect(await ruleRows(id)).toBe(0);
      });

      it("PRF-03 a repeated create with the same Idempotency-Key returns the same rule", async () => {
        const home = await signInWithHousehold(api);
        const id = home.managerProfileId;
        await giveConsent(home, id);
        const key = randomUUID();
        const first = await addRule(home, id, { type: "allergy", allergen: "fish" }, key);
        const again = await addRule(home, id, { type: "allergy", allergen: "fish" }, key);
        expect(again.status, again.raw).toBe(201);
        expect(again.body).toEqual(first.body);
        expect(await ruleRows(id)).toBe(1);
        expectProblem(
          await addRule(home, id, { type: "allergy", allergen: "soy" }, key),
          409,
          "idempotency_key_reused",
        );
        // DAT-02: the idempotency record holds no rule content, only the member.
        const record = await db.query<{ operation: string }>(
          `SELECT operation FROM idempotency_record WHERE idempotency_key = $1`,
          [key],
        );
        expect(record.rows).toEqual([{ operation: "create_hard_rule" }]);
      });

      it("PRF-08 SAF-09 an unmapped free-text rule fails closed in Cek Aman (check_label, unmapped_rule)", async () => {
        const home = await signInWithHousehold(api);
        const id = home.managerProfileId;
        await giveConsent(home, id);
        expect(
          (await addRule(home, id, { type: "free_text", freeText: "Alergi fiksi" })).status,
        ).toBe(201);
        const members = await loadRulesForEvaluation(db, keys, home.householdId, [id]);
        const hardRules = members[0]?.hardRules;
        if (hardRules == null) throw new Error("rules missing");
        const result = evaluate({
          ingredients: [{ ingredientId: "fx_api_nasi", rawName: "nasi fiksi" }],
          recordedBrands: [],
          members: [{ memberId: id, hardRules }],
          reference: REFERENCE,
        });
        expect(result.perMember[0]?.status).toBe("check_label");
        expect(result.perMember[0]?.reasons.map((r) => r.kind)).toContain("unmapped_rule");
      });
    });

    describe("QUESTIONS #39 reads of hard rules fail closed", () => {
      it("Q39 rules that cannot be decrypted give 503 rules_unavailable with Retry-After, never an empty list", async () => {
        const home = await signInWithHousehold(api);
        await giveConsent(home, home.managerProfileId);
        await addRule(home, home.managerProfileId, { type: "allergy", allergen: "sesame" });
        const wrongKey = await another({ keys: new HealthDataKeys(randomLocalKeys()) });
        for (const url of [
          profilesUrl,
          profileUrl(home.managerProfileId),
          rulesUrl(home.managerProfileId),
        ]) {
          const response = await wrongKey.request("GET", url, { token: home.token });
          expectProblem(response, 503, "rules_unavailable");
          expect(response.headers["retry-after"]).toBe("1");
        }
      });

      it("Q39 a key service outage gives 503 on reads (rules_unavailable) and writes (service_unavailable)", async () => {
        const home = await signInWithHousehold(api);
        await giveConsent(home, home.managerProfileId);
        await addRule(home, home.managerProfileId, { type: "allergy", allergen: "wheat" });
        const down = await another({ keys: new HealthDataKeys(keyServiceDown) });
        expectProblem(
          await down.request("GET", rulesUrl(home.managerProfileId), { token: home.token }),
          503,
          "rules_unavailable",
        );
        // A member who already has rules: their key cannot be unwrapped before the lock.
        expectProblem(
          await addRule(
            home,
            home.managerProfileId,
            { type: "allergy", allergen: "gluten" },
            undefined,
            down,
          ),
          503,
          "service_unavailable",
        );
        // A member with consent but no key yet: the new key cannot be wrapped.
        const member = (
          (await createProfile(home, { name: "Baru", ageGroup: "adult" })).body as ProfileBody
        ).id;
        await giveConsent(home, member);
        const write = await addRule(
          home,
          member,
          { type: "allergy", allergen: "gluten" },
          undefined,
          down,
        );
        expectProblem(write, 503, "service_unavailable");
        expect(write.headers["retry-after"]).toBe("1");
        expect(await ruleRows(home.managerProfileId)).toBe(1);
        expect(await ruleRows(member)).toBe(0);
      });

      it("Q39 a concurrent update or lock wait gives 503 service_unavailable with Retry-After and stores nothing", async () => {
        const home = await signInWithHousehold(api);
        await giveConsent(home, home.managerProfileId);
        const serialization = failingExecutor(db, /LEFT JOIN LATERAL/, "40001");
        const readHarness = await startHarness(serialization, { secrets: api.secrets, keys });
        extra.push(readHarness);
        const read = await readHarness.request("GET", rulesUrl(home.managerProfileId), {
          token: home.token,
        });
        expectProblem(read, 503, "service_unavailable");
        expect(read.headers["retry-after"]).toBe("1");

        const lockTimeout = failingExecutor(db, /FOR NO KEY UPDATE/, "55P03");
        const writeHarness = await startHarness(lockTimeout, { secrets: api.secrets, keys });
        extra.push(writeHarness);
        const write = await addRule(
          home,
          home.managerProfileId,
          { type: "vegan" },
          undefined,
          writeHarness,
        );
        expectProblem(write, 503, "service_unavailable");
        expect(await ruleRows(home.managerProfileId)).toBe(0);
      });
    });

    describe("NFR-09 IDOR: no ID in a path or body reaches another household", () => {
      async function snapshot(householdId: string): Promise<unknown> {
        const tables = [
          `SELECT id, name, age_group, portion_size, rice_portion, avatar_style, updated_at FROM profile WHERE household_id = $1 ORDER BY id`,
          `SELECT id, details_enc, updated_at FROM hard_rule WHERE household_id = $1 ORDER BY id`,
          `SELECT id, withdrawn_at FROM consent_record WHERE household_id = $1 ORDER BY seq`,
          `SELECT s.profile_id, s.spice_level, s.less_of, s.updated_at FROM soft_preference s JOIN profile p ON p.id = s.profile_id WHERE p.household_id = $1 ORDER BY s.profile_id`,
          `SELECT l.profile_id, l.kind, l.ref_id, l.sentiment FROM profile_like_dislike l JOIN profile p ON p.id = l.profile_id WHERE p.household_id = $1 ORDER BY 1, 2, 3`,
          `SELECT id FROM health_data_key WHERE household_id = $1 ORDER BY id`,
        ];
        const out: unknown[] = [];
        for (const sql of tables) out.push((await db.query(sql, [householdId])).rows);
        return out;
      }

      it("NFR-09 every profile, preference, rule and consent route answers 404 for another household's IDs and changes nothing", async () => {
        const a = await signInWithHousehold(api);
        const b = await signInWithHousehold(api);
        const bChild = (
          (
            await createProfile(b, {
              name: "Anak B",
              ageGroup: "child",
              guardianConfirmation: GUARDIAN,
            })
          ).body as ProfileBody
        ).id;
        await giveConsent(b, bChild);
        const bRule = (
          (await addRule(b, bChild, { type: "allergy", allergen: "tree_nut" })).body as {
            id: string;
          }
        ).id;
        await api.request("PUT", `${profileUrl(bChild)}/preferences`, {
          token: b.token,
          body: { spiceLevel: "spicy", lessOf: [], textures: [] },
        });
        await giveConsent(a, a.managerProfileId);
        const aRule = (
          (await addRule(a, a.managerProfileId, { type: "halal" })).body as { id: string }
        ).id;
        const before = await snapshot(b.householdId);

        const v = HEALTH_VERSION;
        // Valid bodies with the foreign member's real consent state, so a 404
        // can only come from household scoping, never from validation.
        const realState = (p: string) => expectedConsentOf(b, p);
        // One entry per route that takes an ID, with every foreign ID combination.
        const matrix: Record<string, (profileId: string, ruleId: string) => Promise<Response>> = {
          "GET /v1/household/profiles/:profileId": (p) =>
            api.request("GET", profileUrl(p), { token: a.token }),
          "PATCH /v1/household/profiles/:profileId": (p) =>
            api.request("PATCH", profileUrl(p), { token: a.token, body: { name: "Diubah" } }),
          "DELETE /v1/household/profiles/:profileId": (p) =>
            api.request("DELETE", profileUrl(p), { token: a.token }),
          "PUT /v1/household/profiles/:profileId/preferences": (p) =>
            api.request("PUT", `${profileUrl(p)}/preferences`, {
              token: a.token,
              body: { spiceLevel: null, lessOf: [], textures: [] },
            }),
          "PUT /v1/household/profiles/:profileId/likes-dislikes": (p) =>
            api.request("PUT", `${profileUrl(p)}/likes-dislikes`, {
              token: a.token,
              body: { likes: [], dislikes: [{ kind: "ingredient", refId: "fx_api_nasi" }] },
            }),
          "GET /v1/household/profiles/:profileId/hard-rules": (p) =>
            api.request("GET", rulesUrl(p), { token: a.token }),
          "POST /v1/household/profiles/:profileId/hard-rules": (p) =>
            addRule(a, p, { type: "allergy", allergen: "sesame" }),
          "DELETE /v1/household/profiles/:profileId/hard-rules/:ruleId": (p, r) =>
            api.request("DELETE", `${rulesUrl(p)}/${r}`, { token: a.token }),
          "GET /v1/household/profiles/:profileId/consents": (p) =>
            api.request("GET", `${profileUrl(p)}/consents`, { token: a.token }),
          "POST /v1/household/profiles/:profileId/consents/health-data": async (p) =>
            api.request("POST", `${profileUrl(p)}/consents/health-data`, {
              token: a.token,
              body: {
                decision: "declined",
                textVersion: v,
                language: "id",
                expectedConsent: await realState(p),
              },
            }),
          "POST /v1/household/profiles/:profileId/consents/health-data/withdraw": async (p) =>
            api.request("POST", `${profileUrl(p)}/consents/health-data/withdraw`, {
              token: a.token,
              body: { expectedConsent: await realState(p) },
            }),
        };
        // The matrix covers every route with an ID in its path.
        expect(Object.keys(matrix).sort()).toEqual(routesWithPathIds());

        const combinations: [string, string][] = [
          [b.managerProfileId, bRule],
          [bChild, bRule],
          // A's own profile with B's rule ID, and B's profile with A's rule ID.
          [a.managerProfileId, bRule],
          [bChild, aRule],
          // IDs that cannot exist, including the other household's own ID.
          [b.householdId, bRule],
          [randomUUID(), randomUUID()],
          ["not-a-uuid", "also-not"],
        ];
        for (const [route, call] of Object.entries(matrix)) {
          for (const [profileId, ruleId] of combinations) {
            const ownProfile = profileId === a.managerProfileId;
            if (ownProfile && !route.includes(":ruleId")) continue;
            expectProblem(await call(profileId, ruleId), 404, "not_found");
          }
        }

        // Household or profile IDs in a body are refused, never used.
        for (const [url, body] of [
          [profilesUrl, { name: "X", ageGroup: "adult", householdId: b.householdId }],
          [rulesUrl(a.managerProfileId), { type: "vegan", profileId: bChild }],
          [rulesUrl(a.managerProfileId), { type: "vegan", householdId: b.householdId }],
        ] as const) {
          expectProblem(
            await api.request("POST", url, { token: a.token, body }),
            400,
            "validation_failed",
          );
        }
        expectProblem(
          await api.request("PATCH", profileUrl(a.managerProfileId), {
            token: a.token,
            body: { name: "X", id: bChild },
          }),
          400,
          "validation_failed",
        );

        expect(await snapshot(b.householdId)).toEqual(before);
        const aList = (await api.request("GET", profilesUrl, { token: a.token })).body as {
          items: { id: string }[];
        };
        expect(aList.items.map((p) => p.id)).toEqual([a.managerProfileId]);
      });
    });

    describe("privacy", () => {
      it("names and rule contents never appear in logs or error responses", async () => {
        const home = await signInWithHousehold(api);
        const created = await createProfile(home, { name: "Nama Rahasia", ageGroup: "adult" });
        const id = (created.body as ProfileBody).id;
        await giveConsent(home, id);
        await addRule(home, id, { type: "free_text", freeText: "Teks aturan rahasia" });
        const duplicate = await addRule(home, id, {
          type: "free_text",
          freeText: "Teks aturan rahasia",
        });
        expect(duplicate.raw).not.toContain("rahasia");
        const down = await another({ keys: new HealthDataKeys(keyServiceDown) });
        const failed = await down.request("GET", profilesUrl, { token: home.token });
        expect(failed.raw).not.toContain("Rahasia");
        for (const logger of [api.logger, down.logger]) {
          expect(logger.text).not.toContain("Rahasia");
          expect(logger.text).not.toContain("rahasia");
          expect(logger.text).not.toContain("Ibu Uji");
        }
      });
    });
  });
}
