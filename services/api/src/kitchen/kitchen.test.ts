// TEST FIXTURE: not real safety or nutrition data. Fictional households and a
// fictional reference catalog (IDs prefixed `fx_kit_`, every safety value
// unverified); phone numbers on an unassigned range.
import "reflect-metadata";

import { randomUUID } from "node:crypto";
import { readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";

import { RequestMethod } from "@nestjs/common";
import { afterAll, beforeAll, describe, expect, it } from "vitest";

import { resolveKitchenConfig } from "../../config/kitchen.js";
import { canonicalDestination } from "../auth/destination.js";
import type { SqlExecutor } from "../db/executor.js";
import { migrate } from "../db/migrate.js";
import { DATABASE_TARGETS, type TestDatabase } from "../db/testing/databases.js";
import { CONTROLLERS } from "../http/app.js";
import {
  CapturingLogger,
  contractErrors,
  device,
  fakePhone,
  signInWithHousehold,
  startHarness,
  type Harness,
  type HouseholdSession,
  type Response,
} from "../http/testing/harness.js";
import { VerifiedReferenceCatalog } from "../reference/catalog.js";
import {
  referenceSourceFromEnv,
  referenceSourceOf,
  unavailableReference,
  type ReferenceSource,
} from "../reference/reference-data.js";
import { insertItem, lockHouseholdKitchen } from "./kitchen-store.js";
import { checkStaplesInReference } from "./staples.js";
import { buildFixtureReference, REPO_ROOT, type BuiltFixture } from "./testing/catalog-fixture.js";

const FIXTURE_SOURCE = join(REPO_ROOT, "data", "fixtures", "kitchen-catalog");
const ITEMS = "/v1/household/kitchen/items";
const SEARCH = "/v1/reference/ingredients/search";
const CATALOG = "/v1/reference/ingredients";

interface ItemBody {
  id: string;
  ingredientId: string | null;
  isCustom: boolean;
  displayName: { id: string; en: string } | null;
  customName: string | null;
  category: string;
  state: string;
  isDefaultStaple: boolean;
  changedAt: string;
}
interface ListBody {
  items: ItemBody[];
  maxItems: number;
  referenceVersion: string | null;
}
interface SearchBody {
  referenceVersion: string;
  items: {
    ingredient: { ingredientId: string; category: string | null };
    matchedName: string | null;
  }[];
}

function expectProblem(response: Response, status: number, code: string): void {
  expect(response.status, response.raw).toBe(status);
  expect(contractErrors("Problem", response.body)).toEqual([]);
  expect(response.body).toMatchObject({ status, code, detail: null });
}

/** Every route that takes a kitchen item ID in its path, as `METHOD /path`. */
function routesWithItemIds(): string[] {
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
      if (/:itemId/.test(full)) out.push(`${RequestMethod[method]} ${full}`);
    }
  }
  return out.sort();
}

let fixture: BuiltFixture;
let reference: ReferenceSource;

beforeAll(() => {
  fixture = buildFixtureReference(FIXTURE_SOURCE);
  reference = referenceSourceOf(fixture.verified);
});
afterAll(() => fixture.cleanup());

for (const target of DATABASE_TARGETS) {
  if (target.skipReason !== null) {
    describe(`kitchen API: ${target.name}`, () => {
      it.skip(`skipped: ${target.skipReason}`, () => undefined);
    });
    continue;
  }

  describe(`kitchen API: ${target.name}`, () => {
    let opened: TestDatabase;
    let db: SqlExecutor;
    let api: Harness;
    const extra: Harness[] = [];

    beforeAll(async () => {
      opened = await target.open();
      db = opened.executor;
      await migrate(db);
      api = await startHarness(db, { reference });
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

    const add = (home: HouseholdSession, body: object, key?: string, h: Harness = api) =>
      h.request("POST", ITEMS, {
        token: home.token,
        body,
        ...(key === undefined ? {} : { headers: { "idempotency-key": key } }),
      });
    const list = async (token: string, h: Harness = api) => {
      const response = await h.request("GET", ITEMS, { token });
      expect(response.status, response.raw).toBe(200);
      expect(contractErrors("KitchenItemList", response.body)).toEqual([]);
      return response.body as ListBody;
    };
    const search = (token: string, query: unknown, h: Harness = api, limit?: number) =>
      h.request("POST", SEARCH, {
        token,
        body: { query, ...(limit === undefined ? {} : { limit }) },
      });
    const idsOf = (response: Response) =>
      (response.body as SearchBody).items.map((hit) => hit.ingredient.ingredientId);

    /** Signs in with a phone number on a device; the first sign-in also creates the household. */
    async function signIn(h: Harness, phone: string, installationId: string): Promise<string> {
      const requested = await h.request("POST", "/v1/auth/code/request", {
        body: { channel: "phone", destination: phone, language: "id" },
      });
      expect(requested.status, requested.raw).toBe(202);
      const { challengeId } = requested.body as { challengeId: string };
      const code = h.sender.latestCode(canonicalDestination("phone", phone) ?? phone);
      const verified = await h.request("POST", "/v1/auth/code/verify", {
        body: { challengeId, code, device: device(installationId) },
      });
      expect(verified.status, verified.raw).toBe(200);
      const session = verified.body as { tokens: { accessToken: string }; isNewAccount: boolean };
      if (session.isNewAccount) {
        const created = await h.request("POST", "/v1/household", {
          token: session.tokens.accessToken,
          body: { timeZone: "Asia/Jakarta", language: "id", managerProfile: { name: "Ibu Uji" } },
        });
        expect(created.status, created.raw).toBe(201);
      }
      return session.tokens.accessToken;
    }

    describe("KIT-01 the saved kitchen persists across sessions and devices", () => {
      it("KIT-01 items saved on device A are the same list on device B, after signing out on A", async () => {
        const phone = fakePhone();
        const tokenA = await signIn(api, phone, randomUUID());
        const homeA = { token: tokenA } as HouseholdSession;
        expect((await add(homeA, { ingredientId: "fx_kit_tempe" })).status).toBe(201);
        expect(
          (await add(homeA, { customName: "Bumbu rahasia nenek", category: "spices_aromatics" }))
            .status,
        ).toBe(201);
        const toggled = await add(homeA, { ingredientId: "fx_kit_kemangi", state: "out" });
        expect(toggled.status).toBe(201);
        const before = await list(tokenA);
        expect(before.items).toHaveLength(3);

        const signedOut = await api.request("POST", "/v1/auth/sign-out", { token: tokenA });
        expect(signedOut.status).toBe(204);
        expect((await api.request("GET", ITEMS, { token: tokenA })).status).toBe(401);

        // Device B: another phone installation, served by another API instance.
        const serverB = await another({ reference });
        serverB.clock.advance(3600);
        const tokenB = await signIn(serverB, phone, randomUUID());
        expect(await list(tokenB, serverB)).toEqual(before);
      });
    });

    describe("KIT-03 categories", () => {
      it("KIT-03 the list is grouped in the nine categories in SRS order, with stable codes", async () => {
        const home = await signInWithHousehold(api);
        for (const body of [
          { customName: "Sisa rendang fiksi", category: "leftovers" },
          { ingredientId: "fx_kit_krim" },
          { ingredientId: "fx_kit_beras" },
          { ingredientId: "fx_kit_kecap_manis" },
          { ingredientId: "fx_kit_kemangi" },
          { ingredientId: "fx_kit_tempe" },
          { ingredientId: "fx_kit_lain", category: "frozen" },
          { customName: "Pisang fiktif", category: "fruit" },
          { ingredientId: "fx_kit_daun_salam" },
        ]) {
          const response = await add(home, body);
          expect(response.status, response.raw).toBe(201);
          expect(contractErrors("KitchenItem", response.body)).toEqual([]);
        }
        const items = (await list(home.token)).items;
        expect(items.map((item) => item.category)).toEqual([
          "protein",
          "vegetables",
          "fruit",
          "spices_aromatics",
          "staples",
          "sauces_condiments",
          "dairy",
          "frozen",
          "leftovers",
        ]);
        // The reference category is used when the catalog has a kitchen code.
        expect(items.find((i) => i.ingredientId === "fx_kit_tempe")?.category).toBe("protein");
      });

      it("KIT-03 an unknown category is refused; a catalog entry without a kitchen code needs one", async () => {
        const home = await signInWithHousehold(api);
        expectProblem(
          await add(home, { ingredientId: "fx_kit_tempe", category: "sayur" }),
          400,
          "validation_failed",
        );
        const missing = await add(home, { ingredientId: "fx_kit_lain" });
        expectProblem(missing, 400, "validation_failed");
        expect((missing.body as { errors: unknown[] }).errors).toEqual([
          { pointer: "/category", code: "required" },
        ]);
        const changed = await add(home, { ingredientId: "fx_kit_tempe" });
        const moved = await api.request("PATCH", `${ITEMS}/${(changed.body as ItemBody).id}`, {
          token: home.token,
          body: { category: "frozen" },
        });
        expect(moved.status, moved.raw).toBe(200);
        expect((moved.body as ItemBody).category).toBe("frozen");
        expect((await list(home.token)).items).toHaveLength(1);
      });
    });

    describe("KIT-04 searching the reference ingredient list", () => {
      it.each([
        ["kem", ["fx_kit_kemangi"], null],
        ["Kemangi", ["fx_kit_kemangi"], null],
        ["selasih", ["fx_kit_kemangi"], "Selasih fiksi"],
        ["surawung", ["fx_kit_kemangi"], "Surawung fiksi"],
        ["daun salam", ["fx_kit_daun_salam"], null],
        ["DAUN   SALAM", ["fx_kit_daun_salam"], null],
        ["salam", ["fx_kit_daun_salam"], null],
        ["tempe", ["fx_kit_tempe"], null],
        ["témpé", ["fx_kit_tempe"], null],
        ["ｔｅｍｐｅ", ["fx_kit_tempe"], null],
        ["gembus", ["fx_kit_tempe"], "Témpé gembus fiksi"],
        ["kecap manis", ["fx_kit_kecap_manis"], null],
        ["kecap-manis", ["fx_kit_kecap_manis"], null],
        ["manis kecap", ["fx_kit_kecap_manis"], null],
        ["ketjap", ["fx_kit_kecap_manis"], "Ketjap fiksi"],
        ["creme", ["fx_kit_krim"], "Crème fiksi"],
        ["sweet soy", ["fx_kit_kecap_manis"], null],
        ["brambang", ["fx_kit_bawang_merah"], "Brambang fiksi"],
      ])(
        "KIT-04 %j finds %j (case, accents, spacing and NFKC ignored)",
        async (query, expected, matchedName) => {
          const home = await signInWithHousehold(api);
          const response = await search(home.token, query);
          expect(response.status, response.raw).toBe(200);
          expect(contractErrors("IngredientSearchResult", response.body)).toEqual([]);
          expect(idsOf(response)).toEqual(expected);
          expect((response.body as SearchBody).items[0]?.matchedName).toBe(matchedName);
          expect((response.body as SearchBody).referenceVersion).toBe(
            fixture.verified.referenceVersion,
          );
        },
      );

      it("KIT-04 exact and starting matches come first; the limit applies; no match is an empty list", async () => {
        const home = await signInWithHousehold(api);
        const fiksi = await search(home.token, "fiksi");
        expect(idsOf(fiksi).length).toBe(9);
        const limited = await search(home.token, "fiksi", api, 2);
        expect(idsOf(limited)).toHaveLength(2);
        const bawang = await search(home.token, "ba");
        // Names starting with "ba" first (by name), then words starting with it
        // ("bay leaf", "lemon basil"), by name.
        expect(idsOf(bawang)).toEqual([
          "fx_kit_lain",
          "fx_kit_bawang_merah",
          "fx_kit_daun_salam",
          "fx_kit_kemangi",
        ]);
        const none = await search(home.token, "tidak ada yang cocok");
        expect(none.status).toBe(200);
        expect(idsOf(none)).toEqual([]);
        const punctuation = await search(home.token, "---");
        expect(punctuation.status).toBe(200);
        expect(idsOf(punctuation)).toEqual([]);
      });

      it("KIT-04 invalid queries are refused without echoing them", async () => {
        const home = await signInWithHousehold(api);
        for (const query of ["", "a".repeat(61), "tem​pe", "tempe\u0000", 5, null]) {
          const response = await search(home.token, query);
          expectProblem(response, 400, "validation_failed");
          expect(response.raw).not.toContain("tem");
        }
        expectProblem(await search(home.token, "tempe", api, 51), 400, "validation_failed");
        expectProblem(
          await api.request("POST", SEARCH, { token: home.token, body: { query: "x", extra: 1 } }),
          400,
          "validation_failed",
        );
      });

      it("KIT-04 the whole catalog is served for the phone's offline copy, without safety data", async () => {
        const home = await signInWithHousehold(api);
        const response = await api.request("GET", CATALOG, { token: home.token });
        expect(response.status, response.raw).toBe(200);
        expect(contractErrors("ReferenceIngredientCatalog", response.body)).toEqual([]);
        const body = response.body as {
          referenceVersion: string;
          items: { ingredientId: string; category: string | null; brands: unknown[] }[];
        };
        expect(body.referenceVersion).toBe(fixture.verified.referenceVersion);
        expect(body.items).toHaveLength(9);
        expect(body.items.find((i) => i.ingredientId === "fx_kit_lain")?.category).toBeNull();
        expect(body.items.find((i) => i.ingredientId === "fx_kit_kecap_manis")?.brands).toEqual([
          { brandId: "fx_kit_merek_a", name: "Merek A fiksi" },
        ]);
        expect(response.raw).not.toMatch(/allergen|halal|components|verified|diet/);
      });

      it("L7 the catalog has an ETag; a matching If-None-Match answers 304 without a body", async () => {
        const home = await signInWithHousehold(api);
        const first = await api.request("GET", CATALOG, { token: home.token });
        expect(first.status).toBe(200);
        const etag = `"${fixture.sha256}"`;
        expect(first.headers["etag"]).toBe(etag);
        expect(first.headers["cache-control"]).toBe("private, no-cache");
        expect(String(first.headers["content-type"])).toMatch(/^application\/json/);
        expect(contractErrors("ReferenceIngredientCatalog", first.body)).toEqual([]);

        for (const header of [etag, `W/${etag}`, `"other", ${etag}`, "*"]) {
          const repeat = await api.request("GET", CATALOG, {
            token: home.token,
            headers: { "if-none-match": header },
          });
          expect(repeat.status, header).toBe(304);
          expect(repeat.raw, header).toBe("");
          expect(repeat.headers["etag"]).toBe(etag);
          expect(repeat.headers["cache-control"]).toBe("private, no-cache");
        }
        for (const header of ['"other"', fixture.sha256, "", "x".repeat(2000)]) {
          const changed = await api.request("GET", CATALOG, {
            token: home.token,
            headers: { "if-none-match": header },
          });
          expect(changed.status, header).toBe(200);
          expect(changed.body).toEqual(first.body);
        }
        // The tag never replaces authentication, and no dataset is never a 304.
        expectProblem(
          await api.request("GET", CATALOG, { headers: { "if-none-match": etag } }),
          401,
          "unauthenticated",
        );
        const down = await another({ reference: unavailableReference });
        expectProblem(
          await down.request("GET", CATALOG, {
            token: home.token,
            headers: { "if-none-match": "*" },
          }),
          503,
          "reference_data_unavailable",
        );
      });

      it("KIT-04 fail closed: without a verified dataset the catalog and search answer 503, never an empty list", async () => {
        const home = await signInWithHousehold(api);
        await add(home, { ingredientId: "fx_kit_tempe" });
        const tampered = join(fixture.path, "..", "tampered.json");
        const text = readFileSync(fixture.path, "utf8").replace("Tempe fiksi", "Tempe palsu");
        writeFileSync(tampered, text);
        const cases: [string, ReferenceSource][] = [
          [
            "no dataset configured",
            referenceSourceFromEnv({ APP_ENV: "test" }, new CapturingLogger()),
          ],
          [
            "content hash does not match",
            referenceSourceFromEnv(
              { APP_ENV: "test", REFERENCE_DATA_PATH: tampered },
              new CapturingLogger(),
            ),
          ],
          [
            "pinned hash differs",
            referenceSourceFromEnv(
              {
                APP_ENV: "test",
                REFERENCE_DATA_PATH: fixture.path,
                REFERENCE_DATA_SHA256: "0".repeat(64),
              },
              new CapturingLogger(),
            ),
          ],
          [
            "a fixture outside local and test",
            referenceSourceFromEnv(
              {
                APP_ENV: "production",
                REFERENCE_DATA_PATH: fixture.path,
                REFERENCE_DATA_SHA256: fixture.sha256,
              },
              new CapturingLogger(),
            ),
          ],
        ];
        for (const [why, source] of cases) {
          expect(source.current(), why).toBeNull();
          const down = await another({ reference: source });
          expectProblem(await search(home.token, "tempe", down), 503, "reference_data_unavailable");
          expectProblem(
            await down.request("GET", CATALOG, { token: home.token }),
            503,
            "reference_data_unavailable",
          );
          // Adding a reference ingredient cannot be checked, so nothing is stored.
          expectProblem(
            await add(home, { ingredientId: "fx_kit_kemangi" }, undefined, down),
            503,
            "reference_data_unavailable",
          );
          // The saved kitchen stays readable (AI-08), with names left null.
          const saved = await list(home.token, down);
          expect(saved.referenceVersion).toBeNull();
          expect(saved.items.map((i) => [i.ingredientId, i.displayName])).toEqual([
            ["fx_kit_tempe", null],
          ]);
        }
        // Custom ingredients need no reference data.
        const down = await another({ reference: unavailableReference });
        const custom = await add(
          home,
          { customName: "Sambal fiktif", category: "sauces_condiments" },
          undefined,
          down,
        );
        expect(custom.status, custom.raw).toBe(201);
      });

      it("KIT-04 an ingredient not in the dataset is refused (400) and nothing is stored", async () => {
        const home = await signInWithHousehold(api);
        const response = await add(home, { ingredientId: "fx_kit_tidak_ada" });
        expectProblem(response, 400, "validation_failed");
        expect((response.body as { errors: unknown[] }).errors).toEqual([
          { pointer: "/ingredientId", code: "invalid_value" },
        ]);
        expect((await list(home.token)).items).toEqual([]);
      });

      it("Q49 an ingredient found by search is accepted for likes and dislikes", async () => {
        const withCatalog = await another({
          reference,
          catalog: new VerifiedReferenceCatalog(reference),
        });
        const home = await signInWithHousehold(withCatalog);
        const hit = idsOf(await search(home.token, "ketjap", withCatalog))[0];
        const saved = await withCatalog.request(
          "PUT",
          `/v1/household/profiles/${home.managerProfileId}/likes-dislikes`,
          {
            token: home.token,
            body: { likes: [{ kind: "ingredient", refId: hit }], dislikes: [] },
          },
        );
        expect(saved.status, saved.raw).toBe(200);
        expect(
          (saved.body as { likes: { displayName: { id: string } }[] }).likes[0]?.displayName.id,
        ).toBe("Kecap manis fiksi");
        const unknown = await withCatalog.request(
          "PUT",
          `/v1/household/profiles/${home.managerProfileId}/likes-dislikes`,
          {
            token: home.token,
            body: { likes: [{ kind: "ingredient", refId: "fx_kit_tidak_ada" }], dislikes: [] },
          },
        );
        expect(unknown.status).toBe(400);
      });
    });

    describe("KIT-05 custom ingredients", () => {
      it("KIT-05 a custom ingredient is stored with ingredientId null and flagged", async () => {
        const home = await signInWithHousehold(api);
        const response = await add(home, {
          customName: "  Daun Kemangi Kebun  ",
          category: "vegetables",
        });
        expect(response.status, response.raw).toBe(201);
        expect(contractErrors("KitchenItem", response.body)).toEqual([]);
        expect(response.body).toMatchObject({
          ingredientId: null,
          isCustom: true,
          customName: "Daun Kemangi Kebun",
          displayName: null,
          category: "vegetables",
          state: "available",
          isDefaultStaple: false,
        });
        const { rows } = await db.query<{ ingredient_id: string | null; custom_key: string }>(
          `SELECT ingredient_id, custom_key FROM kitchen_item WHERE id = $1`,
          [(response.body as ItemBody).id],
        );
        expect(rows).toEqual([{ ingredient_id: null, custom_key: "daun kemangi kebun" }]);
      });

      it("KIT-05 names that differ only in case, accents or spacing are the same ingredient", async () => {
        const home = await signInWithHousehold(api);
        const first = await add(home, {
          customName: "Kécap Asin Kampung",
          category: "sauces_condiments",
        });
        expect(first.status).toBe(201);
        await api.request("PATCH", `${ITEMS}/${(first.body as ItemBody).id}`, {
          token: home.token,
          body: { state: "out" },
        });
        const again = await add(home, {
          customName: "kecap  asin-KAMPUNG",
          category: "sauces_condiments",
        });
        expect(again.status, again.raw).toBe(200);
        expect(again.body).toMatchObject({
          id: (first.body as ItemBody).id,
          customName: "Kécap Asin Kampung",
          state: "available",
        });
        expect((await list(home.token)).items).toHaveLength(1);
      });

      it("KIT-05 custom names need a category and are refused when blank or with hidden characters", async () => {
        const home = await signInWithHousehold(api);
        for (const body of [
          { customName: "Bumbu fiktif" },
          { customName: "   ", category: "staples" },
          { customName: "!!!", category: "staples" },
          { customName: "Bum​bu", category: "staples" },
          { customName: "x".repeat(61), category: "staples" },
          // L1: 60 characters whose NFKC form is 18 times longer than the database key allows.
          { customName: "ﷺ".repeat(60), category: "staples" },
          { customName: "Bumbu ﷺ".repeat(10), category: "staples" },
          { customName: "Bumbu", ingredientId: "fx_kit_tempe" },
          {},
          { category: "staples" },
        ]) {
          const response = await add(home, body);
          expectProblem(response, 400, "validation_failed");
          expect(response.raw).not.toContain("Bum");
        }
        expect((await list(home.token)).items).toEqual([]);
      });
    });

    describe("KIT-07 ACC-05 default staples", () => {
      const staples = resolveKitchenConfig({
        defaultStaples: [
          { ingredientId: "fx_kit_beras", category: "staples" },
          { ingredientId: "fx_kit_bawang_merah", category: "spices_aromatics" },
          { ingredientId: "fx_kit_garam", category: "staples" },
          { ingredientId: "fx_kit_kecap_manis", category: "sauces_condiments" },
        ],
      });

      it("KIT-07 ACC-05 the configured staples are created with the household as available", async () => {
        const h = await another({ reference, kitchenConfig: staples });
        const home = await signInWithHousehold(h);
        const items = (await list(home.token, h)).items;
        expect(items.map((i) => [i.ingredientId, i.state, i.isDefaultStaple])).toEqual([
          ["fx_kit_bawang_merah", "available", true],
          ["fx_kit_beras", "available", true],
          ["fx_kit_garam", "available", true],
          ["fx_kit_kecap_manis", "available", true],
        ]);
        expect(items[0]?.displayName).toEqual({
          id: "Bawang merah fiksi",
          en: "Fiction shallot",
        });
      });

      it("KIT-07 staples stay available until the user marks them out, then come back when marked available", async () => {
        const h = await another({ reference, kitchenConfig: staples });
        const phone = fakePhone();
        const phoneId = randomUUID();
        await signIn(h, phone, phoneId);
        // Over a year later (a fresh sign-in, since sessions end): still available.
        h.clock.advance(400 * 24 * 3600);
        let home = { token: await signIn(h, phone, phoneId) } as HouseholdSession;
        const items = (await list(home.token, h)).items;
        expect(items).toHaveLength(4);
        expect(items.every((i) => i.state === "available")).toBe(true);
        const rice = items.find((i) => i.ingredientId === "fx_kit_beras") as ItemBody;
        const out = await h.request("PATCH", `${ITEMS}/${rice.id}`, {
          token: home.token,
          body: { state: "out" },
        });
        expect(out.body).toMatchObject({ state: "out", isDefaultStaple: true });
        h.clock.advance(30 * 24 * 3600);
        home = { token: await signIn(h, phone, phoneId) } as HouseholdSession;
        const later = (await list(home.token, h)).items.find((i) => i.id === rice.id);
        expect(later).toMatchObject({ state: "out", isDefaultStaple: true });
        const back = await h.request("PATCH", `${ITEMS}/${rice.id}`, {
          token: home.token,
          body: { state: "available" },
        });
        expect(back.body).toMatchObject({ state: "available", isDefaultStaple: true });
        // Adding a staple again keeps its flag and does not duplicate it.
        const readd = await add(home, { ingredientId: "fx_kit_beras" }, undefined, h);
        expect(readd.status).toBe(200);
        expect(readd.body).toMatchObject({ id: rice.id, isDefaultStaple: true });
      });

      it("KIT-07 with no staples configured (no content yet) a household starts with an empty kitchen", async () => {
        const home = await signInWithHousehold(api);
        expect((await list(home.token)).items).toEqual([]);
      });

      it("KIT-07 a staple missing from the verified reference data stops startup", () => {
        const wrong = resolveKitchenConfig({
          defaultStaples: [{ ingredientId: "fx_kit_tidak_ada", category: "staples" }],
        });
        expect(() => checkStaplesInReference(wrong, reference)).toThrow(/fx_kit_tidak_ada/);
        expect(() => checkStaplesInReference(staples, reference)).not.toThrow();
        expect(() => checkStaplesInReference(wrong, unavailableReference)).toThrow(
          /cannot be checked/,
        );
      });
    });

    describe("KIT-02 KIT-16 changes and replays", () => {
      it("KIT-02 KIT-16 a toggle is stamped with the server time; sending it again gives the same item", async () => {
        const home = await signInWithHousehold(api);
        const created = (await add(home, { ingredientId: "fx_kit_tempe" })).body as ItemBody;
        api.clock.advance(90);
        const url = `${ITEMS}/${created.id}`;
        const first = await api.request("PATCH", url, {
          token: home.token,
          body: { state: "out" },
        });
        expect(first.status, first.raw).toBe(200);
        expect(contractErrors("KitchenItem", first.body)).toEqual([]);
        expect((first.body as ItemBody).changedAt).toBe(api.clock.now().toISOString());
        const repeat = await api.request("PATCH", url, {
          token: home.token,
          body: { state: "out" },
        });
        expect(repeat.body).toMatchObject({ state: "out", id: created.id });
        expect((await list(home.token)).items).toHaveLength(1);
      });

      it("KIT-09 quantity and brand are not accepted before T-032; an empty change is refused", async () => {
        const home = await signInWithHousehold(api);
        const created = (await add(home, { ingredientId: "fx_kit_kecap_manis" })).body as ItemBody;
        const url = `${ITEMS}/${created.id}`;
        for (const body of [
          {},
          { quantity: "some" },
          { brand: { brandId: "fx_kit_merek_a" } },
          { state: "ada" },
        ]) {
          expectProblem(
            await api.request("PATCH", url, { token: home.token, body }),
            400,
            "validation_failed",
          );
        }
      });

      it("KIT-01 an Idempotency-Key replay returns the first result; reuse with another body is refused", async () => {
        const home = await signInWithHousehold(api);
        const key = randomUUID();
        const first = await add(home, { ingredientId: "fx_kit_garam" }, key);
        expect(first.status).toBe(201);
        await api.request("PATCH", `${ITEMS}/${(first.body as ItemBody).id}`, {
          token: home.token,
          body: { state: "out" },
        });
        const replay = await add(home, { ingredientId: "fx_kit_garam" }, key);
        expect(replay.status).toBe(201);
        expect((replay.body as ItemBody).id).toBe((first.body as ItemBody).id);
        // The replay returns the item as it is now and does not apply the add twice.
        expect((replay.body as ItemBody).state).toBe("out");
        expectProblem(
          await add(home, { ingredientId: "fx_kit_beras" }, key),
          409,
          "idempotency_key_reused",
        );
        // A key first used on an existing item replays as 200.
        const foundKey = randomUUID();
        expect((await add(home, { ingredientId: "fx_kit_garam" }, foundKey)).status).toBe(200);
        expect((await add(home, { ingredientId: "fx_kit_garam" }, foundKey)).status).toBe(200);
        expectProblem(
          await add(home, { ingredientId: "fx_kit_garam" }, "not-a-uuid"),
          400,
          "validation_failed",
        );
        // After the item is removed, the old key cannot recreate it silently.
        await api.request("DELETE", `${ITEMS}/${(first.body as ItemBody).id}`, {
          token: home.token,
        });
        expectProblem(
          await add(home, { ingredientId: "fx_kit_garam" }, key),
          409,
          "idempotency_key_reused",
        );
      });

      it("KIT-01 the item limit comes from configuration (409 at the limit)", async () => {
        const h = await another({
          reference,
          kitchenConfig: resolveKitchenConfig({ maxItemsPerHousehold: 30 }),
        });
        const home = await signInWithHousehold(h);
        for (let i = 0; i < 30; i += 1) {
          const response = await add(
            home,
            { customName: `Bahan fiktif ${i}`, category: "staples" },
            undefined,
            h,
          );
          expect(response.status, response.raw).toBe(201);
        }
        expectProblem(
          await add(home, { customName: "Bahan fiktif lebih", category: "staples" }, undefined, h),
          409,
          "kitchen_item_limit_reached",
        );
        // Re-adding an existing ingredient at the limit still works.
        expect(
          (await add(home, { customName: "bahan fiktif 3", category: "staples" }, undefined, h))
            .status,
        ).toBe(200);
        expect((await list(home.token, h)).maxItems).toBe(30);
      });

      it("KIT-01 an item can be removed; removing it again is 404", async () => {
        const home = await signInWithHousehold(api);
        const created = (await add(home, { ingredientId: "fx_kit_tempe" })).body as ItemBody;
        expect(
          (await api.request("DELETE", `${ITEMS}/${created.id}`, { token: home.token })).status,
        ).toBe(204);
        expectProblem(
          await api.request("DELETE", `${ITEMS}/${created.id}`, { token: home.token }),
          404,
          "not_found",
        );
        expect((await list(home.token)).items).toEqual([]);
      });

      it("KIT-01 two concurrent adds of the same ingredient store one item (household lock)", async (context) => {
        if (opened.openSession === null) {
          context.skip("PGlite has one connection; set TEST_DATABASE_URL to run");
          return;
        }
        const home = await signInWithHousehold(api);
        const session = await opened.openSession();
        try {
          await lockHouseholdKitchen(session.executor, home.householdId);
          await insertItem(session.executor, {
            householdId: home.householdId,
            accountId: home.accountId,
            ref: { kind: "reference", ingredientId: "fx_kit_tempe" },
            category: "protein",
            state: "available",
            isDefaultStaple: false,
            now: new Date(),
          });
        } catch (error) {
          await session.rollback();
          throw error;
        }
        const concurrent = add(home, { ingredientId: "fx_kit_tempe", state: "out" });
        let settled = false;
        void concurrent.then(() => (settled = true));
        await new Promise((resolve) => setTimeout(resolve, 300));
        expect(settled).toBe(false);
        await session.commit();
        const response = await concurrent;
        expect(response.status, response.raw).toBe(200);
        expect((await list(home.token)).items).toHaveLength(1);
      });
    });

    describe("NFR-09 IDOR: no item ID reaches another household", () => {
      const snapshot = async (householdId: string) =>
        (
          await db.query(
            `SELECT id, ingredient_id, custom_name, category, state, changed_at FROM kitchen_item
              WHERE household_id = $1 ORDER BY id`,
            [householdId],
          )
        ).rows;

      it("NFR-09 every kitchen route with an item ID answers 404 for another household's items and changes nothing", async () => {
        const a = await signInWithHousehold(api);
        const b = await signInWithHousehold(api);
        const bItem = ((await add(b, { ingredientId: "fx_kit_tempe" })).body as ItemBody).id;
        const bCustom = (
          (await add(b, { customName: "Rahasia B fiktif", category: "staples" })).body as ItemBody
        ).id;
        const aItem = ((await add(a, { ingredientId: "fx_kit_tempe" })).body as ItemBody).id;
        const before = await snapshot(b.householdId);

        const matrix: Record<string, (itemId: string) => Promise<Response>> = {
          "PATCH /v1/household/kitchen/items/:itemId": (id) =>
            api.request("PATCH", `${ITEMS}/${id}`, { token: a.token, body: { state: "out" } }),
          "DELETE /v1/household/kitchen/items/:itemId": (id) =>
            api.request("DELETE", `${ITEMS}/${id}`, { token: a.token }),
        };
        expect(Object.keys(matrix).sort()).toEqual(routesWithItemIds());
        for (const call of Object.values(matrix)) {
          for (const id of [
            bItem,
            bCustom,
            b.householdId,
            b.managerProfileId,
            randomUUID(),
            "not-a-uuid",
          ]) {
            expectProblem(await call(id), 404, "not_found");
          }
        }
        // IDs in a body are refused, never used.
        for (const body of [
          { ingredientId: "fx_kit_kemangi", householdId: b.householdId },
          { ingredientId: "fx_kit_kemangi", id: bItem },
          { customName: "X", category: "staples", itemId: bItem },
        ]) {
          expectProblem(await add(a, body), 400, "validation_failed");
        }
        expectProblem(
          await api.request("PATCH", `${ITEMS}/${aItem}`, {
            token: a.token,
            body: { state: "out", householdId: b.householdId },
          }),
          400,
          "validation_failed",
        );
        // The same ingredient in two households stays two items.
        expect(await snapshot(b.householdId)).toEqual(before);
        expect((await list(a.token)).items.map((i) => i.id)).toEqual([aItem]);
        expect((await list(b.token)).items.map((i) => i.id).sort()).toEqual(
          [bItem, bCustom].sort(),
        );
      });

      it("NFR-09 the kitchen needs a signed-in manager with a household", async () => {
        expectProblem(await api.request("GET", ITEMS), 401, "unauthenticated");
        expectProblem(
          await api.request("POST", SEARCH, { body: { query: "tempe" } }),
          401,
          "unauthenticated",
        );
        const phone = fakePhone();
        const requested = await api.request("POST", "/v1/auth/code/request", {
          body: { channel: "phone", destination: phone, language: "id" },
        });
        const { challengeId } = requested.body as { challengeId: string };
        const code = api.sender.latestCode(canonicalDestination("phone", phone) ?? phone);
        const verified = await api.request("POST", "/v1/auth/code/verify", {
          body: { challengeId, code, device: device() },
        });
        const token = (verified.body as { tokens: { accessToken: string } }).tokens.accessToken;
        expectProblem(await api.request("GET", ITEMS, { token }), 409, "household_required");
      });
    });

    describe("privacy", () => {
      it("custom names and search queries never appear in logs or error responses", async () => {
        const logger = api.logger;
        const home = await signInWithHousehold(api);
        await add(home, { customName: "Ramuan Rahasia Nenek", category: "spices_aromatics" });
        const duplicate = await add(home, { customName: "ramuan rahasia nenek" });
        expect(duplicate.raw).not.toMatch(/rahasia/i);
        await search(home.token, "kacangrahasia");
        await search(home.token, "rahasia​");
        expect(logger.text).not.toMatch(/rahasia/i);
        expect(logger.text).not.toContain("Ibu Uji");
        expect(logger.text).toContain("/v1/reference/ingredients/search");
      });
    });
  });
}
