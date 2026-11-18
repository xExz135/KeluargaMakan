// TEST FIXTURE: not real safety or nutrition data. Fictional recipes
// (data/fixtures/library), fictional ingredients (data/fixtures/library-reference)
// and fictional members.
import "reflect-metadata";

import { readFileSync } from "node:fs";
import { join } from "node:path";

import { afterAll, beforeAll, describe, expect, it } from "vitest";

import { resolveLibraryConfig } from "../../config/library.js";
import { CONSENT_TEXTS } from "../consent/consent-texts.js";
import { consentStateOf, latestHealthConsents } from "../db/consent.js";
import type { SqlExecutor } from "../db/executor.js";
import { migrate } from "../db/migrate.js";
import { readRecipeHalalLog } from "../db/recipe-halal-log.js";
import { readSafetyLog } from "../db/safety-log.js";
import { pgliteTarget, type TestDatabase } from "../db/testing/databases.js";
import { HealthDataKeys } from "../db/health-data-keys.js";
import { randomLocalKeys } from "../db/testing/seed.js";
import {
  contractErrors,
  signInWithHousehold,
  startHarness,
  type Harness,
  type HouseholdSession,
  type Response,
} from "../http/testing/harness.js";
import {
  buildFixtureReference,
  REPO_ROOT,
  type BuiltFixture,
} from "../kitchen/testing/catalog-fixture.js";
import { referenceSourceOf } from "../reference/reference-data.js";
import {
  insertFixtureImage,
  loadFixtureLibrary,
  publishFixtureRecipe,
  retireFixtureRecipe,
  withdrawFixtureImage,
  type FixtureLibrary,
  type FixtureRecipe,
} from "./testing/fixture-library.js";

const FIXTURE: FixtureLibrary = JSON.parse(
  readFileSync(join(REPO_ROOT, "data", "fixtures", "library", "recipes.json"), "utf8"),
) as FixtureLibrary;
const HEALTH_VERSION = CONSENT_TEXTS.health_data.version;
const ALL = [
  "fx_rcp_ayam_angciu",
  "fx_rcp_gado_gado",
  "fx_rcp_nasi_goreng",
  "fx_rcp_nasi_goreng_padang",
  "fx_rcp_sayur_lodeh",
];

interface MemberResult {
  memberId: string;
  rulesConsent: string;
  status: string;
  condition: unknown;
  reasons: {
    kind: string;
    code: string;
    rule: { type: string; allergen: string | null };
    ingredient: { lineId: string; ingredientId: string | null; rawName: string } | null;
    componentPath: { ingredientId: string }[];
  }[];
}
interface Safety {
  checkId: string;
  checkedAt: string;
  ruleSetVersion: string;
  referenceVersion: string;
  members: MemberResult[];
  halalStatus: { status: string; findings: { code: string }[] };
}
interface Item {
  recipe: { recipeId: string; version: number; testRecord: { testedBy: string } | null };
  safety: Safety;
}
interface SearchBody {
  items: Item[];
  nextCursor: string | null;
  totalCount: number;
  hiddenNotSafe: { count: number; memberIds: string[] };
  libraryVersion: string;
}

let fixture: BuiltFixture;
let opened: TestDatabase;
let db: SqlExecutor;
let keys: HealthDataKeys;
let api: Harness;
let home: HouseholdSession;

beforeAll(async () => {
  fixture = buildFixtureReference(join(REPO_ROOT, "data", "fixtures", "library-reference"));
  opened = await pgliteTarget.open();
  db = opened.executor;
  await migrate(db);
  await loadFixtureLibrary(db, FIXTURE);
  keys = new HealthDataKeys(randomLocalKeys());
  api = await startHarness(db, { reference: referenceSourceOf(fixture.verified), keys });
  home = await signInWithHousehold(api);
});

afterAll(async () => {
  await api.close();
  await opened.close();
  fixture.cleanup();
});

// ---------------------------------------------------------------- helpers

const searchUrl = "/v1/library/recipes/search";
const detailUrl = (recipeId: string) => `/v1/library/recipes/${recipeId}/detail`;
const onlyMe = { mode: "only_me", memberIds: [] };
const selected = (...memberIds: string[]) => ({ mode: "selected", memberIds });

function search(session: HouseholdSession, body: object, h: Harness = api): Promise<Response> {
  return h.request("POST", searchUrl, { token: session.token, body });
}

async function searchOk(session: HouseholdSession, body: object): Promise<SearchBody> {
  const response = await search(session, body);
  expect(response.status, response.raw).toBe(200);
  expect(contractErrors("LibrarySearchResult", response.body)).toEqual([]);
  return response.body as SearchBody;
}

const ids = (body: SearchBody) => body.items.map((item) => item.recipe.recipeId);
const itemOf = (body: SearchBody, recipeId: string) => {
  const item = body.items.find((entry) => entry.recipe.recipeId === recipeId);
  if (item === undefined) throw new Error(`${recipeId} not listed`);
  return item;
};

function expectProblem(response: Response, status: number, code: string): void {
  expect(response.status, response.raw).toBe(status);
  expect((response.body as { code?: string }).code).toBe(code);
}

/** A member with health-data consent and the given hard rules (fictional). */
async function memberWithRules(
  session: HouseholdSession,
  name: string,
  rules: readonly object[],
): Promise<string> {
  const created = await api.request("POST", "/v1/household/profiles", {
    token: session.token,
    body: { name, ageGroup: "adult" },
  });
  expect(created.status, created.raw).toBe(201);
  const profileId = (created.body as { id: string }).id;
  if (rules.length === 0) return profileId;
  const state = consentStateOf(
    (await latestHealthConsents(db, session.householdId, [profileId])).get(profileId),
  );
  const consent = await api.request(
    "POST",
    `/v1/household/profiles/${profileId}/consents/health-data`,
    {
      token: session.token,
      body: {
        decision: "given",
        textVersion: HEALTH_VERSION,
        language: "id",
        expectedConsent: { status: state.status, consentRecordId: state.consentRecordId },
      },
    },
  );
  expect(consent.status, consent.raw).toBe(201);
  for (const rule of rules) {
    const added = await api.request("POST", `/v1/household/profiles/${profileId}/hard-rules`, {
      token: session.token,
      body: rule,
    });
    expect(added.status, added.raw).toBe(201);
  }
  return profileId;
}

async function addKitchenItem(
  session: HouseholdSession,
  ingredientId: string,
  brand: object | null = null,
): Promise<string> {
  const created = await api.request("POST", "/v1/household/kitchen/items", {
    token: session.token,
    body: { ingredientId },
  });
  expect(created.status, created.raw).toBe(201);
  const id = (created.body as { id: string }).id;
  if (brand !== null) {
    const patched = await api.request("PATCH", `/v1/household/kitchen/items/${id}`, {
      token: session.token,
      body: { brand },
    });
    expect(patched.status, patched.raw).toBe(200);
  }
  return id;
}

const count = async (sql: string, params: readonly unknown[]) =>
  Number((await db.query<{ n: string | number }>(sql, params)).rows[0]?.n ?? 0);

/** An executor that fails every recipe halal log write, to prove nothing is served then. */
function failingHalalLog(inner: SqlExecutor): SqlExecutor {
  const wrap = (executor: SqlExecutor): SqlExecutor => ({
    async query(text, params) {
      if (text.includes("INSERT INTO recipe_halal_log")) throw new Error("injected write failure");
      return executor.query(text, params);
    },
    execScript: (sql) => executor.execScript(sql),
    transaction: (fn) => executor.transaction((tx) => fn(wrap(tx))),
  });
  return wrap(inner);
}

// ---------------------------------------------------------------- search

describe("LIB-08 SAF-02 library search", () => {
  it("LIB-08 LIB-01 SAF-02 browse lists every servable recipe, each with a completed Cek Aman result for the eaters", async () => {
    const body = await searchOk(home, { eaters: onlyMe });
    expect(ids(body).sort()).toEqual(ALL);
    expect(body.totalCount).toBe(5);
    expect(body.hiddenNotSafe).toEqual({ count: 0, memberIds: [] });
    expect(body.libraryVersion).toMatch(/^lib-\d+$/);
    for (const item of body.items) {
      expect(item.recipe.testRecord?.testedBy).toContain("TEST FIXTURE");
      expect(item.safety.members.map((member) => member.memberId)).toEqual([home.managerProfileId]);
      expect(item.safety.referenceVersion).toBe(fixture.verified.referenceVersion);
      expect(item.safety.members[0]?.condition).toBeNull();
    }
  });

  it("SAF-14 T-025 N2 every listed item's checkId names a logged check and its recipe halal record", async () => {
    const body = await searchOk(home, { eaters: onlyMe, limit: 2 });
    expect(body.items).toHaveLength(2);
    const checkIds = body.items.map((item) => item.safety.checkId);
    expect(new Set(checkIds).size).toBe(2);
    for (const item of body.items) {
      const log = await readSafetyLog(db, keys, home.householdId, item.safety.checkId);
      const halal = await readRecipeHalalLog(db, home.householdId, item.safety.checkId);
      expect(log.subject).toEqual({
        kind: "library_recipe",
        id: item.recipe.recipeId,
        version: String(item.recipe.version),
      });
      expect(log.ruleSetVersion).toBe(item.safety.ruleSetVersion);
      expect(log.referenceVersion).toBe(item.safety.referenceVersion);
      expect(halal.referenceVersion).toBe(item.safety.referenceVersion);
      expect(halal.status).toBe(item.safety.halalStatus.status);
      expect(halal.evaluatedAt.toISOString()).toBe(item.safety.checkedAt);
    }
  });

  it("QUESTIONS #36 a member without health-data consent has no rules checked and says so", async () => {
    const body = await searchOk(home, { eaters: onlyMe, query: "gado" });
    const member = itemOf(body, "fx_rcp_gado_gado").safety.members[0];
    expect(member).toMatchObject({ rulesConsent: "none", status: "safe", reasons: [] });
  });

  it("PRF-09 PRF-11 only the selected eaters are checked, in selection order", async () => {
    const session = await signInWithHousehold(api);
    const kakak = await memberWithRules(session, "Kakak", [
      { type: "allergy", allergen: "shrimp" },
    ]);
    const ayah = await memberWithRules(session, "Ayah", []);
    const forAyah = await searchOk(session, { eaters: selected(ayah) });
    expect(forAyah.hiddenNotSafe.count).toBe(0);
    for (const item of forAyah.items) {
      expect(item.safety.members.map((member) => member.memberId)).toEqual([ayah]);
    }
    const both = await searchOk(session, { eaters: selected(ayah, kakak), includeNotSafe: true });
    for (const item of both.items) {
      expect(item.safety.members.map((member) => member.memberId)).toEqual([ayah, kakak]);
    }
    const family = await searchOk(session, { eaters: { mode: "whole_family", memberIds: [] } });
    // whole_family: the household's profiles in the profile list order.
    const listed = (
      (await api.request("GET", "/v1/household/profiles", { token: session.token })).body as {
        items: { id: string }[];
      }
    ).items.map((profile) => profile.id);
    expect(listed).toHaveLength(3);
    expect(listed[0]).toBe(session.managerProfileId);
    expect(family.items[0]?.safety.members.map((member) => member.memberId)).toEqual(listed);
  });

  it("SUG-04 SAF-04 SAF-05 Not safe recipes are left out and counted; with includeNotSafe they carry their Not safe result", async () => {
    const session = await signInWithHousehold(api);
    const kakak = await memberWithRules(session, "Kakak", [
      { type: "allergy", allergen: "shrimp" },
    ]);
    const hidden = await searchOk(session, { eaters: selected(kakak) });
    expect(ids(hidden)).not.toContain("fx_rcp_nasi_goreng");
    expect(ids(hidden)).not.toContain("fx_rcp_nasi_goreng_padang");
    expect(hidden.hiddenNotSafe).toEqual({ count: 2, memberIds: [kakak] });
    expect(hidden.totalCount).toBe(3);

    const shown = await searchOk(session, { eaters: selected(kakak), includeNotSafe: true });
    expect(shown.hiddenNotSafe).toEqual({ count: 0, memberIds: [] });
    const result = itemOf(shown, "fx_rcp_nasi_goreng").safety.members[0];
    expect(result?.status).toBe("not_safe");
    // Names the ingredient, the hidden component and the rule (SAF-03, SAF-04).
    const reason = result?.reasons.find(
      (entry) => entry.ingredient?.lineId === "l4" && entry.componentPath.length > 0,
    );
    expect(reason).toMatchObject({
      kind: "component",
      code: "allergen_contains",
      rule: { type: "allergy", allergen: "shrimp" },
      ingredient: { lineId: "l4", ingredientId: "fx_lib_terasi", rawName: "Terasi fiksi" },
      componentPath: [{ ingredientId: "fx_lib_udang" }],
    });
  });

  it("SAF-09 an ingredient line that does not resolve gives Check the label", async () => {
    const session = await signInWithHousehold(api);
    const member = await memberWithRules(session, "Ibu", [{ type: "halal" }]);
    const body = await searchOk(session, { eaters: selected(member), query: "gado" });
    const item = itemOf(body, "fx_rcp_gado_gado");
    expect(item.safety.members[0]?.status).toBe("check_label");
    expect(item.safety.members[0]?.reasons.map((reason) => reason.code)).toContain(
      "ingredient_unresolved",
    );
    expect(item.safety.halalStatus.status).toBe("check_label");
  });

  it("LIB-05 SAF-08 the halal status is derived by Cek Aman from the ingredient data", async () => {
    const body = await searchOk(home, { eaters: onlyMe });
    const angciu = itemOf(body, "fx_rcp_ayam_angciu").safety.halalStatus;
    expect(angciu.status).toBe("not_halal");
    expect(angciu.findings.map((finding) => finding.code)).toContain("halal_not_halal");
    expect(itemOf(body, "fx_rcp_sayur_lodeh").safety.halalStatus).toEqual({
      status: "halal",
      findings: [],
    });
    // Kecap varies by brand and the household recorded none (SAF-07).
    const kecap = itemOf(body, "fx_rcp_nasi_goreng").safety.halalStatus;
    expect(kecap.status).toBe("check_label");
    expect(kecap.findings.map((finding) => finding.code)).toContain("brand_not_recorded");
  });

  it("QUESTIONS #87 #91 SAF-07 the halal status and member results use the brands the household recorded, never one from the library line", async () => {
    const session = await signInWithHousehold(api);
    const member = await memberWithRules(session, "Ibu", [{ type: "halal" }]);
    const itemId = await addKitchenItem(session, "fx_lib_kecap", {
      brandId: "fx_lib_kecap_terperiksa",
    });
    const recorded = itemOf(
      await searchOk(session, { eaters: selected(member), query: "nasi goreng fiksi" }),
      "fx_rcp_nasi_goreng",
    );
    expect(recorded.safety.halalStatus).toEqual({ status: "halal", findings: [] });
    expect(recorded.safety.members[0]?.status).toBe("safe");
    const halalLog = await readRecipeHalalLog(db, session.householdId, recorded.safety.checkId);
    expect(halalLog.lines.find((line) => line.lineId === "l5")?.brandIds).toEqual([
      "fx_lib_kecap_terperiksa",
    ]);
    expect(halalLog.lines.find((line) => line.lineId === "l1")?.brandIds).toEqual([]);

    // An unverified brand gives Check the label for both.
    await api.request("PATCH", `/v1/household/kitchen/items/${itemId}`, {
      token: session.token,
      body: { brand: { brandId: "fx_lib_kecap_belum" } },
    });
    const unverified = itemOf(
      await searchOk(session, { eaters: selected(member), query: "nasi goreng fiksi" }),
      "fx_rcp_nasi_goreng",
    );
    expect(unverified.safety.halalStatus.status).toBe("check_label");
    expect(unverified.safety.members[0]?.status).toBe("check_label");

    // A brand on an item that ran out is not passed (QUESTIONS #91).
    await api.request("PATCH", `/v1/household/kitchen/items/${itemId}`, {
      token: session.token,
      body: { brand: { brandId: "fx_lib_kecap_terperiksa" }, state: "out" },
    });
    const out = itemOf(
      await searchOk(session, { eaters: selected(member), query: "nasi goreng fiksi" }),
      "fx_rcp_nasi_goreng",
    );
    expect(out.safety.halalStatus.status).toBe("check_label");
    expect(out.safety.members[0]?.status).toBe("check_label");
  });

  it("LIB-08 search matches names and ingredients (local names included) and filters by region, meal type and time", async () => {
    expect(ids(await searchOk(home, { eaters: onlyMe, query: "LODEH" }))).toEqual([
      "fx_rcp_sayur_lodeh",
    ]);
    // "Brambang fiksi" is a local name of the shallot, used in four recipes.
    expect(ids(await searchOk(home, { eaters: onlyMe, query: "brambang" })).sort()).toEqual([
      "fx_rcp_ayam_angciu",
      "fx_rcp_nasi_goreng",
      "fx_rcp_nasi_goreng_padang",
      "fx_rcp_sayur_lodeh",
    ]);
    // A name match comes before an ingredient match.
    const rice = ids(await searchOk(home, { eaters: onlyMe, query: "nasi" }));
    expect(rice.slice(0, 2).sort()).toEqual(["fx_rcp_nasi_goreng", "fx_rcp_nasi_goreng_padang"]);
    expect(ids(await searchOk(home, { eaters: onlyMe, regionIds: ["fx_reg_sumbar"] }))).toEqual([
      "fx_rcp_nasi_goreng_padang",
    ]);
    expect(ids(await searchOk(home, { eaters: onlyMe, mealTypes: ["snack"] }))).toEqual([
      "fx_rcp_gado_gado",
    ]);
    expect(ids(await searchOk(home, { eaters: onlyMe, timeAvailable: "up_to_30" })).sort()).toEqual(
      ["fx_rcp_gado_gado", "fx_rcp_nasi_goreng", "fx_rcp_nasi_goreng_padang"],
    );
    expect(ids(await searchOk(home, { eaters: onlyMe, timeAvailable: "over_60" }))).toHaveLength(5);
    expect(ids(await searchOk(home, { eaters: onlyMe, query: "tidak ada resep ini" }))).toEqual([]);
  });

  it("LIB-08 pages follow a signed cursor that works only with the same body and household", async () => {
    const first = await searchOk(home, { eaters: onlyMe, limit: 2 });
    expect(first.items).toHaveLength(2);
    expect(first.totalCount).toBe(5);
    const cursor = first.nextCursor;
    expect(cursor).toMatch(/^[A-Za-z0-9_-]{1,512}$/);
    const second = await searchOk(home, { eaters: onlyMe, limit: 2, cursor });
    const third = await searchOk(home, { eaters: onlyMe, limit: 2, cursor: second.nextCursor });
    expect(third.nextCursor).toBeNull();
    expect([...ids(first), ...ids(second), ...ids(third)].sort()).toEqual(ALL);

    // The cursor never carries the search text in clear.
    const withQuery = await searchOk(home, { eaters: onlyMe, query: "fiksi", limit: 1 });
    const decoded = Buffer.from((withQuery.nextCursor ?? "").slice(2), "base64url").toString(
      "latin1",
    );
    expect(decoded).not.toContain("fiksi");

    expectProblem(
      await search(home, { eaters: onlyMe, limit: 3, cursor }),
      400,
      "validation_failed",
    );
    expectProblem(
      await search(home, { eaters: onlyMe, limit: 2, query: "nasi", cursor }),
      400,
      "validation_failed",
    );
    const other = await signInWithHousehold(api);
    expectProblem(
      await search(other, { eaters: onlyMe, limit: 2, cursor }),
      400,
      "validation_failed",
    );
    const tampered = `${(cursor ?? "").slice(0, -2)}AA`;
    expectProblem(
      await search(home, { eaters: onlyMe, limit: 2, cursor: tampered }),
      400,
      "validation_failed",
    );
  });

  it("LIB-08 the request is validated: search text with hidden characters, unknown keys and bad eaters are refused", async () => {
    expectProblem(await search(home, { eaters: onlyMe, query: "nasi​" }), 400, "validation_failed");
    expectProblem(await search(home, { eaters: onlyMe, query: "" }), 400, "validation_failed");
    expectProblem(await search(home, { eaters: onlyMe, shopping: true }), 400, "validation_failed");
    expectProblem(await search(home, {}), 400, "validation_failed");
    expectProblem(await search(home, { eaters: selected() }), 400, "validation_failed");
    expectProblem(
      await search(home, { eaters: { mode: "only_me", memberIds: [home.managerProfileId] } }),
      400,
      "validation_failed",
    );
    expectProblem(await search(home, { eaters: onlyMe, limit: 51 }), 400, "validation_failed");
    expectProblem(
      await search(home, { eaters: onlyMe, mealTypes: ["lunch", "lunch"] }),
      400,
      "validation_failed",
    );
  });

  it("LIB-08 the search text and recipe names never reach a log line", async () => {
    const secret = "kueteruntukuji";
    await searchOk(home, { eaters: onlyMe, query: secret });
    await searchOk(home, { eaters: onlyMe, query: "lodeh" });
    expect(api.logger.text).not.toContain(secret);
    expect(api.logger.text).not.toMatch(/lodeh|Nasi goreng|fiksi/i);
  });

  it("NFR-09 a selected member of another household answers 404 like an unknown ID", async () => {
    const other = await signInWithHousehold(api);
    expectProblem(
      await search(home, { eaters: selected(other.managerProfileId) }),
      404,
      "not_found",
    );
    expectProblem(
      await search(home, { eaters: selected("00000000-0000-4000-8000-000000000000") }),
      404,
      "not_found",
    );
    expectProblem(await search(home, { eaters: selected("bukan-uuid") }), 404, "not_found");
  });

  it("T-025 N4 SAF-14 a failed log write serves no item and stores no log", async () => {
    const failing = await startHarness(failingHalalLog(db), {
      reference: referenceSourceOf(fixture.verified),
      keys,
    });
    try {
      const session = await signInWithHousehold(failing);
      const response = await search(session, { eaters: onlyMe }, failing);
      expect(response.status).toBe(500);
      expect(response.raw).not.toContain("fx_rcp_");
      const detail = await failing.request("POST", detailUrl("fx_rcp_sayur_lodeh"), {
        token: session.token,
        body: { eaters: onlyMe },
      });
      expect(detail.status).toBe(500);
      expect(detail.raw).not.toContain("fx_rcp_");
      expect(
        await count(`SELECT count(*) AS n FROM safety_log WHERE household_id = $1`, [
          session.householdId,
        ]),
      ).toBe(0);
    } finally {
      await failing.close();
    }
  });

  it("L1 SAF-12 when an eater's rules change during a request, it checks once more; a second change answers 503 and serves nothing", async () => {
    const session = await signInWithHousehold(api);
    const kakak = await memberWithRules(session, "Kakak", [
      { type: "allergy", allergen: "shrimp" },
    ]);
    let changes = 0;
    const changing = (limit: number) => {
      const wrap = (executor: SqlExecutor): SqlExecutor => ({
        async query(text, params) {
          if (text.includes("health_rules_stamp(p.id) AS rules_stamp") && changes < limit) {
            changes += 1;
            // A rule edit lands between the check and its log write.
            await executor.query(
              `UPDATE hard_rule SET updated_at = updated_at + interval '1 second' WHERE profile_id = $1`,
              [kakak],
            );
          }
          return executor.query(text, params);
        },
        execScript: (sql) => executor.execScript(sql),
        transaction: (fn) => executor.transaction((tx) => fn(wrap(tx))),
      });
      return wrap(db);
    };
    for (const [limit, status] of [
      [1, 200],
      [Number.POSITIVE_INFINITY, 503],
    ] as const) {
      changes = 0;
      const h = await startHarness(changing(limit), {
        reference: referenceSourceOf(fixture.verified),
        keys,
        secrets: api.secrets,
      });
      try {
        const before = await count(`SELECT count(*) AS n FROM safety_log WHERE household_id = $1`, [
          session.householdId,
        ]);
        const response = await search(session, { eaters: selected(kakak), limit: 2 }, h);
        expect(response.status, response.raw).toBe(status);
        const after = await count(`SELECT count(*) AS n FROM safety_log WHERE household_id = $1`, [
          session.householdId,
        ]);
        expect(after - before).toBe(status === 200 ? 2 : 0);
        if (status === 503) {
          expect((response.body as { code: string }).code).toBe("service_unavailable");
          expect(response.headers["retry-after"]).toBeDefined();
          expect(changes).toBe(2);
        }
      } finally {
        await h.close();
      }
    }
  });

  it("SAF-02 AI-08 without verified reference data the answer is 503, never an unchecked list", async () => {
    const noReference = await startHarness(db, { keys });
    try {
      const session = await signInWithHousehold(noReference);
      expectProblem(
        await search(session, { eaters: onlyMe }, noReference),
        503,
        "reference_data_unavailable",
      );
      expectProblem(
        await noReference.request("POST", detailUrl("fx_rcp_sayur_lodeh"), {
          token: session.token,
          body: { eaters: onlyMe },
        }),
        503,
        "reference_data_unavailable",
      );
      // The region list carries no food item and still works.
      const regions = await noReference.request("GET", "/v1/library/regions", {
        token: session.token,
      });
      expect(regions.status).toBe(200);
    } finally {
      await noReference.close();
    }
  });

  it("SUG-03 LIB-10 a cuisine not served in this phase is never listed", async () => {
    const config = resolveLibraryConfig({ servedCuisines: ["japanese"] });
    const japaneseOnly = await startHarness(db, {
      reference: referenceSourceOf(fixture.verified),
      keys,
      libraryConfig: config,
    });
    try {
      const session = await signInWithHousehold(japaneseOnly);
      const body = (await search(session, { eaters: onlyMe }, japaneseOnly)).body as SearchBody;
      expect(body.items).toEqual([]);
    } finally {
      await japaneseOnly.close();
    }
  });
});

// ---------------------------------------------------------------- recipe screen

describe("CKM-01 LIB-03 LIB-04 recipe detail", () => {
  it("CKM-01 LIB-03 the recipe screen shows ingredients with kitchen state, steps with timers, servings for the eaters and the result", async () => {
    const session = await signInWithHousehold(api);
    const ayah = await memberWithRules(session, "Ayah", []);
    await addKitchenItem(session, "fx_lib_nasi");
    const response = await api.request("POST", detailUrl("fx_rcp_nasi_goreng"), {
      token: session.token,
      body: { eaters: { mode: "whole_family", memberIds: [] } },
    });
    expect(response.status, response.raw).toBe(200);
    expect(contractErrors("RecipeDetail", response.body)).toEqual([]);
    const detail = response.body as {
      recipe: { recipeId: string; baseServings: number; totalMinutes: number; tags: object };
      ingredients: { lineId: string; inKitchen: string; quantity: { amount: number | null } }[];
      steps: { stepId: string; timerSeconds: number | null }[];
      servings: number;
      kitchenMatch: { availableCount: number; missingCount: number; missing: { lineId: string }[] };
      safety: Safety;
      variant: unknown;
      adaptation: unknown;
      nutritionPerServing: unknown;
      regionalVariants: Item[];
      aiAvailability: string;
    };
    expect(detail.recipe).toMatchObject({ recipeId: "fx_rcp_nasi_goreng", baseServings: 4 });
    expect(detail.recipe.totalMinutes).toBe(25);
    expect(detail.recipe.tags).toEqual({ fried: true, santan: false, spiceLevel: "medium" });
    // SUG-16: two eaters, so 600 g for four becomes 300 g.
    expect(detail.servings).toBe(2);
    expect(detail.ingredients.find((line) => line.lineId === "l1")).toMatchObject({
      inKitchen: "available",
      quantity: { amount: 300 },
    });
    expect(detail.ingredients.find((line) => line.lineId === "l4")?.inKitchen).toBe("missing");
    // The optional chili is not counted as missing (KitchenMatch).
    expect(detail.kitchenMatch.missing.map((line) => line.lineId)).toEqual(["l2", "l4", "l5"]);
    expect(detail.kitchenMatch).toMatchObject({ availableCount: 1, missingCount: 3 });
    expect(detail.steps.map((step) => [step.stepId, step.timerSeconds])).toEqual([
      ["s1", 120],
      ["s2", null],
      ["s3", 60],
    ]);
    expect(detail.safety.members.map((member) => member.memberId)).toEqual([
      session.managerProfileId,
      ayah,
    ]);
    expect(detail.variant).toBeNull();
    expect(detail.adaptation).toBeNull();
    expect(detail.nutritionPerServing).toEqual({ status: "unavailable", ranges: [] });
    expect(detail.aiAvailability).toBe("off");

    // LIB-04: the regional version, with its own logged result.
    expect(detail.regionalVariants.map((item) => item.recipe.recipeId)).toEqual([
      "fx_rcp_nasi_goreng_padang",
    ]);
    const variantCheck = detail.regionalVariants[0]?.safety.checkId ?? "";
    expect(variantCheck).not.toBe(detail.safety.checkId);
    expect((await readSafetyLog(db, keys, session.householdId, variantCheck)).subject.id).toBe(
      "fx_rcp_nasi_goreng_padang",
    );
    expect(
      (await readRecipeHalalLog(db, session.householdId, detail.safety.checkId)).subject.id,
    ).toBe("fx_rcp_nasi_goreng");

    // From the variant, the base dish is listed.
    const fromVariant = await api.request("POST", detailUrl("fx_rcp_nasi_goreng_padang"), {
      token: session.token,
      body: { eaters: onlyMe },
    });
    expect(
      (fromVariant.body as { regionalVariants: Item[] }).regionalVariants.map(
        (item) => item.recipe.recipeId,
      ),
    ).toEqual(["fx_rcp_nasi_goreng"]);
  });

  it("SAF-12 a Not safe recipe opens with its Not safe result; nothing overrides it", async () => {
    const session = await signInWithHousehold(api);
    const kakak = await memberWithRules(session, "Kakak", [
      { type: "allergy", allergen: "shrimp" },
    ]);
    const response = await api.request("POST", detailUrl("fx_rcp_nasi_goreng"), {
      token: session.token,
      body: { eaters: selected(kakak) },
    });
    expect(response.status, response.raw).toBe(200);
    const detail = response.body as { safety: Safety; regionalVariants: Item[] };
    expect(detail.safety.members[0]?.status).toBe("not_safe");
    expect(detail.regionalVariants[0]?.safety.members[0]?.status).toBe("not_safe");
  });

  it("SAF-11 NFR-09 adaptations, substitutions and variants are not served yet: 409 for any ID, and nothing is logged", async () => {
    const session = await signInWithHousehold(api);
    const open = (body: object) =>
      api.request("POST", detailUrl("fx_rcp_nasi_goreng"), {
        token: session.token,
        body: { eaters: onlyMe, ...body },
      });
    expectProblem(await open({ adaptationId: "a1b2" }), 409, "adaptation_expired");
    expectProblem(await open({ substitutionIds: ["sub-1"] }), 409, "substitution_not_available");
    // Even the fixture's real portion variant (security review T-040 N1).
    expectProblem(
      await open({ variantId: "fx_var_tanpa_terasi" }),
      409,
      "substitution_not_available",
    );
    expect(
      await count(`SELECT count(*) AS n FROM safety_log WHERE household_id = $1`, [
        session.householdId,
      ]),
    ).toBe(0);
  });

  it("LIB-01 an unknown recipe answers 404, and a bad body 400", async () => {
    expectProblem(
      await api.request("POST", detailUrl("fx_rcp_tidak_ada"), {
        token: home.token,
        body: { eaters: onlyMe },
      }),
      404,
      "not_found",
    );
    expectProblem(
      await api.request("POST", detailUrl("BUKAN ID"), {
        token: home.token,
        body: { eaters: onlyMe },
      }),
      404,
      "not_found",
    );
    expectProblem(
      await api.request("POST", detailUrl("fx_rcp_sayur_lodeh"), { token: home.token, body: {} }),
      400,
      "validation_failed",
    );
  });
});

// ---------------------------------------------------------------- versions and retirement

describe("LIB-01 LIB-11 DAT-06 versions and retirement", () => {
  const extra: FixtureRecipe = {
    recipeId: "fx_rcp_uji_versi",
    baseRecipeId: null,
    testRecord: { testedBy: "Tim Uji Fiksi (TEST FIXTURE)", testedOn: "2026-10-02" },
    content: {
      ...(FIXTURE.recipes.find((recipe) => recipe.recipeId === "fx_rcp_sayur_lodeh")?.content ??
        FIXTURE.recipes[0]!.content),
      name: { id: "Sup versi fiksi", en: "Fiction version soup" },
    },
  };

  it("LIB-11 DAT-06 a new version replaces the old one, and the library version moves", async () => {
    const before = await searchOk(home, { eaters: onlyMe });
    await publishFixtureRecipe(db, extra);
    const first = await searchOk(home, { eaters: onlyMe, query: "sup versi" });
    expect(first.libraryVersion).not.toBe(before.libraryVersion);
    expect(first.items.map((item) => item.recipe.version)).toEqual([1]);
    await publishFixtureRecipe(db, extra);
    const second = await searchOk(home, { eaters: onlyMe, query: "sup versi" });
    expect(second.items.map((item) => item.recipe.version)).toEqual([2]);
    const log = await readSafetyLog(db, keys, home.householdId, second.items[0]!.safety.checkId);
    expect(log.subject.version).toBe("2");
  });

  it("LIB-01 LIB-11 a retired recipe is never listed or opened", async () => {
    await retireFixtureRecipe(db, extra.recipeId);
    const after = await searchOk(home, { eaters: onlyMe, query: "sup versi" });
    expect(after.items).toEqual([]);
    expectProblem(
      await api.request("POST", detailUrl(extra.recipeId), {
        token: home.token,
        body: { eaters: onlyMe },
      }),
      404,
      "not_found",
    );
  });
});

// ---------------------------------------------------------------- regions and images

describe("LIB-04 LIB-08 regions, LIB-03 images", () => {
  it("LIB-04 LIB-08 the region list holds the regions of servable recipes", async () => {
    const response = await api.request("GET", "/v1/library/regions", { token: home.token });
    expect(response.status, response.raw).toBe(200);
    expect(contractErrors("LibraryRegionList", response.body)).toEqual([]);
    expect(
      (response.body as { items: { regionId: string }[] }).items.map((r) => r.regionId),
    ).toEqual(["fx_reg_jawa", "fx_reg_sumbar"]);
  });

  it("LIB-03 T-040 L8 an image is served private, no-cache, with a 304 only for the exact tag sent", async () => {
    const url = "/v1/library/images/fx_img_nasi_goreng";
    const first = await api.request("GET", url, { token: home.token });
    expect(first.status).toBe(200);
    expect(first.headers["content-type"]).toBe("image/webp");
    expect(first.headers["cache-control"]).toBe("private, no-cache");
    const etag = String(first.headers["etag"]);
    expect(etag).toMatch(/^"[0-9a-f]{64}"$/);
    expect(first.raw).toBe("fixture-image:fx_img_nasi_goreng");

    const same = await api.request("GET", url, {
      token: home.token,
      headers: { "if-none-match": etag },
    });
    expect(same.status).toBe(304);
    expect(same.raw).toBe("");
    for (const tag of ["*", `W/${etag}`, '"lain"']) {
      const other = await api.request("GET", url, {
        token: home.token,
        headers: { "if-none-match": tag },
      });
      expect(other.status, tag).toBe(200);
    }
    // Authentication comes first, even with a matching tag.
    const anonymous = await api.request("GET", url, { headers: { "if-none-match": etag } });
    expect(anonymous.status).toBe(401);
  });

  it("LIB-03 T-040 L8 an unknown, unused or withdrawn image answers 404", async () => {
    await insertFixtureImage(db, "fx_img_tidak_dipakai");
    for (const imageId of ["fx_img_tidak_ada", "fx_img_tidak_dipakai", "BAD ID"]) {
      expectProblem(
        await api.request("GET", `/v1/library/images/${encodeURIComponent(imageId)}`, {
          token: home.token,
        }),
        404,
        "not_found",
      );
    }
    await withdrawFixtureImage(db, "fx_img_nasi_goreng");
    expectProblem(
      await api.request("GET", "/v1/library/images/fx_img_nasi_goreng", { token: home.token }),
      404,
      "not_found",
    );
    // The recipe no longer lists the withdrawn image.
    const body = await searchOk(home, { eaters: onlyMe, query: "nasi goreng fiksi" });
    expect(
      (itemOf(body, "fx_rcp_nasi_goreng").recipe as unknown as { images: unknown[] }).images,
    ).toEqual([]);
  });

  it("NFR-09 every library route needs a signed-in caller with a household", async () => {
    for (const [method, url] of [
      ["POST", searchUrl],
      ["GET", "/v1/library/regions"],
      ["GET", "/v1/library/images/fx_img_nasi_goreng"],
      ["POST", detailUrl("fx_rcp_sayur_lodeh")],
    ] as const) {
      expectProblem(
        await api.request(method, url, { body: { eaters: onlyMe } }),
        401,
        "unauthenticated",
      );
    }
  });
});
