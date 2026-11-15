// TEST FIXTURE: not real safety or nutrition data. Fictional households and a
// fictional reference catalog (IDs prefixed `fx_kit_`, every safety value
// unverified); phone numbers on an unassigned range.
import "reflect-metadata";

import { randomUUID } from "node:crypto";
import { join } from "node:path";

import { RequestMethod } from "@nestjs/common";
import { afterAll, beforeAll, describe, expect, it } from "vitest";

import { resolveKitchenConfig } from "../../config/kitchen.js";
import type { SqlExecutor } from "../db/executor.js";
import { migrate } from "../db/migrate.js";
import { DATABASE_TARGETS, type TestDatabase } from "../db/testing/databases.js";
import { CONTROLLERS } from "../http/app.js";
import {
  contractErrors,
  signInWithHousehold,
  startHarness,
  type Harness,
  type HouseholdSession,
  type Response,
} from "../http/testing/harness.js";
import {
  referenceSourceOf,
  unavailableReference,
  type ReferenceSource,
} from "../reference/reference-data.js";
import { insertItem, lockHouseholdKitchen, purgeKitchenSyncRecords } from "./kitchen-store.js";
import { buildFixtureReference, REPO_ROOT, type BuiltFixture } from "./testing/catalog-fixture.js";

const ITEMS = "/v1/household/kitchen/items";
const SETS = "/v1/household/kitchen/sets";
const SYNC = "/v1/household/kitchen/sync";
const HOUR = 3600;
const DAY = 24 * HOUR;

interface ItemBody {
  id: string;
  ingredientId: string | null;
  customName: string | null;
  category: string;
  state: string;
  quantity: string | null;
  brand: { brandId: string | null; name: string } | null;
  usageRank: number | null;
  changedAt: string;
}
interface SetBody {
  id: string;
  name: string;
  itemIds: string[];
}
interface SyncBody {
  cursor: string;
  full: boolean;
  items: ItemBody[];
  removedItemIds: string[];
  results: { changeId: string; outcome: string; itemId: string | null; errorCode: string | null }[];
}

function expectProblem(response: Response, status: number, code: string): void {
  expect(response.status, response.raw).toBe(status);
  expect(contractErrors("Problem", response.body)).toEqual([]);
  expect(response.body).toMatchObject({ status, code, detail: null });
}

/** Every route that takes a set ID in its path, as `METHOD /path`. */
function routesWithSetIds(): string[] {
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
      if (/:setId/.test(full)) out.push(`${RequestMethod[method]} ${full}`);
    }
  }
  return out.sort();
}

let fixture: BuiltFixture;
let reference: ReferenceSource;

beforeAll(() => {
  fixture = buildFixtureReference(join(REPO_ROOT, "data", "fixtures", "kitchen-catalog"));
  reference = referenceSourceOf(fixture.verified);
});
afterAll(() => fixture.cleanup());

for (const target of DATABASE_TARGETS) {
  if (target.skipReason !== null) {
    describe(`kitchen sets and sync: ${target.name}`, () => {
      it.skip(`skipped: ${target.skipReason}`, () => undefined);
    });
    continue;
  }

  describe(`kitchen sets and sync: ${target.name}`, () => {
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
      const harness = await startHarness(db, { secrets: api.secrets, reference, ...options });
      extra.push(harness);
      return harness;
    };

    const add = async (home: HouseholdSession, body: object, h: Harness = api) => {
      const response = await h.request("POST", ITEMS, { token: home.token, body });
      expect([200, 201], response.raw).toContain(response.status);
      return response.body as ItemBody;
    };
    const patch = (home: HouseholdSession, id: string, body: object, h: Harness = api) =>
      h.request("PATCH", `${ITEMS}/${id}`, { token: home.token, body });
    const list = async (home: HouseholdSession, h: Harness = api) => {
      const response = await h.request("GET", ITEMS, { token: home.token });
      expect(response.status, response.raw).toBe(200);
      expect(contractErrors("KitchenItemList", response.body)).toEqual([]);
      return (response.body as { items: ItemBody[] }).items;
    };
    const sync = async (
      home: HouseholdSession,
      body: { cursor: string | null; changes: object[] },
      h: Harness = api,
    ) => {
      const response = await h.request("POST", SYNC, { token: home.token, body });
      expect(response.status, response.raw).toBe(200);
      expect(contractErrors("KitchenSyncResponse", response.body)).toEqual([]);
      return response.body as SyncBody;
    };
    const change = (fields: Record<string, unknown>) => ({
      changeId: randomUUID(),
      operation: "upsert",
      ageMs: 0,
      ...fields,
    });
    const editedAtOf = async (itemId: string) =>
      (
        await db.query<{ client_changed_at: Date }>(
          `SELECT client_changed_at FROM kitchen_item WHERE id = $1`,
          [itemId],
        )
      ).rows[0]?.client_changed_at;

    // ---------------------------------------------------------------- KIT-06

    describe("KIT-06 the most used ingredients come first in each category", () => {
      it("KIT-06 running out and coming back are uses; the most used item ranks first", async () => {
        const home = await signInWithHousehold(api);
        const salam = await add(home, { ingredientId: "fx_kit_daun_salam" });
        const bawang = await add(home, { ingredientId: "fx_kit_bawang_merah" });
        const custom = await add(home, {
          customName: "Bumbu fiktif",
          category: "spices_aromatics",
        });
        const tempe = await add(home, { ingredientId: "fx_kit_tempe" });
        expect((await list(home)).map((i) => i.usageRank)).toEqual([null, null, null, null]);

        for (const state of ["out", "available", "out"]) await patch(home, bawang.id, { state });
        await patch(home, salam.id, { state: "out" });
        // The same state again is not a use.
        await patch(home, salam.id, { state: "out" });
        await patch(home, tempe.id, { state: "out" });

        const items = await list(home);
        expect(items.map((i) => [i.id, i.category, i.usageRank])).toEqual([
          [tempe.id, "protein", 1],
          [bawang.id, "spices_aromatics", 1],
          [salam.id, "spices_aromatics", 2],
          [custom.id, "spices_aromatics", null],
        ]);
        const scores = await db.query<{ id: string; use_score: number }>(
          `SELECT id, use_score FROM kitchen_item WHERE id = ANY($1::uuid[])`,
          [[salam.id, bawang.id]],
        );
        expect(Object.fromEntries(scores.rows.map((r) => [r.id, Math.round(r.use_score)]))).toEqual(
          {
            [salam.id]: 1,
            [bawang.id]: 3,
          },
        );
        // A single-item response carries the rank in the whole kitchen.
        const one = await patch(home, custom.id, { quantity: "some" });
        expect((one.body as ItemBody).usageRank).toBeNull();
      });

      it("KIT-06 old uses count less: the half-life comes from configuration", async () => {
        const h = await another({ kitchenConfig: resolveKitchenConfig({ usageHalfLifeDays: 7 }) });
        const home = await signInWithHousehold(h);
        const old = await add(home, { ingredientId: "fx_kit_garam" }, h);
        const recent = await add(home, { ingredientId: "fx_kit_beras" }, h);
        for (const state of ["out", "available", "out", "available"]) {
          await patch(home, old.id, { state }, h);
        }
        h.clock.advance(90 * DAY);
        // The first session has expired; sign in again.
        const session = { ...home, token: await freshToken(h, home) };
        await patch(session, recent.id, { state: "out" }, h);
        const items = await list(session, h);
        expect(items.map((i) => [i.ingredientId, i.usageRank])).toEqual([
          ["fx_kit_beras", 1],
          // 4 uses 90 days ago at a 7-day half-life count about 0.0005: no longer ranked.
          ["fx_kit_garam", null],
        ]);
      });
    });

    /** Signs the household's manager in again (after a clock jump ended the session). */
    async function freshToken(h: Harness, home: HouseholdSession): Promise<string> {
      const { rows } = await db.query<{ phone: string }>(
        `SELECT phone FROM account WHERE id = $1`,
        [home.accountId],
      );
      const phone = rows[0]?.phone;
      if (phone === undefined) throw new Error("no phone");
      const requested = await h.request("POST", "/v1/auth/code/request", {
        body: { channel: "phone", destination: phone, language: "id" },
      });
      const { challengeId } = requested.body as { challengeId: string };
      const code = h.sender.latestCode(phone);
      const verified = await h.request("POST", "/v1/auth/code/verify", {
        body: {
          challengeId,
          code,
          device: { installationId: randomUUID(), platform: "android", appVersion: "0.1.0" },
        },
      });
      expect(verified.status, verified.raw).toBe(200);
      return (verified.body as { tokens: { accessToken: string } }).tokens.accessToken;
    }

    // ---------------------------------------------------------------- KIT-08

    describe("KIT-08 ingredient sets", () => {
      it("KIT-08 a set marks every item available in one call; nothing else changes", async () => {
        const home = await signInWithHousehold(api);
        const beras = await add(home, { ingredientId: "fx_kit_beras", state: "out" });
        const garam = await add(home, { ingredientId: "fx_kit_garam", state: "out" });
        const tempe = await add(home, { ingredientId: "fx_kit_tempe", state: "available" });
        const outside = await add(home, { ingredientId: "fx_kit_kemangi", state: "out" });

        const created = await api.request("POST", SETS, {
          token: home.token,
          body: { name: "  Belanja mingguan ", itemIds: [beras.id, garam.id, tempe.id] },
        });
        expect(created.status, created.raw).toBe(201);
        expect(contractErrors("IngredientSet", created.body)).toEqual([]);
        const set = created.body as SetBody;
        expect(set.name).toBe("Belanja mingguan");
        expect(set.itemIds.sort()).toEqual([beras.id, garam.id, tempe.id].sort());

        api.clock.advance(60);
        const marked = await api.request("POST", `${SETS}/${set.id}/mark-available`, {
          token: home.token,
        });
        expect(marked.status, marked.raw).toBe(200);
        expect(contractErrors("KitchenItemList", marked.body)).toEqual([]);
        const markedItems = (marked.body as { items: ItemBody[] }).items;
        expect(markedItems.map((i) => i.id).sort()).toEqual(set.itemIds.sort());
        expect(markedItems.every((i) => i.state === "available")).toBe(true);
        expect(markedItems.every((i) => i.changedAt === api.clock.now().toISOString())).toBe(true);

        const after = Object.fromEntries((await list(home)).map((i) => [i.id, i.state]));
        expect(after).toEqual({
          [beras.id]: "available",
          [garam.id]: "available",
          [tempe.id]: "available",
          [outside.id]: "out",
        });
        // Again: the same states.
        const again = await api.request("POST", `${SETS}/${set.id}/mark-available`, {
          token: home.token,
        });
        expect(
          (again.body as { items: ItemBody[] }).items.every((i) => i.state === "available"),
        ).toBe(true);

        const listed = await api.request("GET", SETS, { token: home.token });
        expect(listed.status).toBe(200);
        expect(contractErrors("IngredientSetList", listed.body)).toEqual([]);
        expect(listed.body).toMatchObject({ maxSets: 20, items: [{ id: set.id }] });
      });

      it("KIT-08 a set is renamed and its items replaced; deleting it keeps the items", async () => {
        const home = await signInWithHousehold(api);
        const a = await add(home, { ingredientId: "fx_kit_beras" });
        const b = await add(home, { ingredientId: "fx_kit_garam" });
        const set = (
          await api.request("POST", SETS, {
            token: home.token,
            body: { name: "Pagi", itemIds: [a.id] },
          })
        ).body as SetBody;
        const replaced = await api.request("PUT", `${SETS}/${set.id}`, {
          token: home.token,
          body: { name: "Sarapan", itemIds: [b.id] },
        });
        expect(replaced.status, replaced.raw).toBe(200);
        expect(replaced.body).toMatchObject({ name: "Sarapan", itemIds: [b.id] });
        // Removing an item takes it out of its sets.
        expect(
          (await api.request("DELETE", `${ITEMS}/${b.id}`, { token: home.token })).status,
        ).toBe(204);
        const listed = (await api.request("GET", SETS, { token: home.token })).body as {
          items: SetBody[];
        };
        expect(listed.items[0]?.itemIds).toEqual([]);
        expect(
          (await api.request("DELETE", `${SETS}/${set.id}`, { token: home.token })).status,
        ).toBe(204);
        expect((await list(home)).map((i) => i.id)).toEqual([a.id]);
        expectProblem(
          await api.request("DELETE", `${SETS}/${set.id}`, { token: home.token }),
          404,
          "not_found",
        );
      });

      it("KIT-08 invalid sets are refused; the set limit comes from configuration; replays return the set", async () => {
        const h = await another({
          kitchenConfig: resolveKitchenConfig({ maxSetsPerHousehold: 1 }),
        });
        const home = await signInWithHousehold(h);
        const item = await add(home, { ingredientId: "fx_kit_beras" }, h);
        for (const body of [
          { name: "", itemIds: [] },
          { name: "Set​", itemIds: [] },
          { name: "x".repeat(41), itemIds: [] },
          { name: "Set", itemIds: [item.id, item.id] },
          { name: "Set", itemIds: ["bukan-uuid"] },
          { name: "Set", itemIds: Array.from({ length: 201 }, () => randomUUID()) },
          { name: "Set" },
          { name: "Set", itemIds: [], householdId: home.householdId },
        ]) {
          expectProblem(
            await h.request("POST", SETS, { token: home.token, body }),
            400,
            "validation_failed",
          );
        }
        expectProblem(
          await h.request("POST", SETS, {
            token: home.token,
            body: { name: "Set", itemIds: [randomUUID()] },
          }),
          404,
          "not_found",
        );
        const key = randomUUID();
        const first = await h.request("POST", SETS, {
          token: home.token,
          body: { name: "Mingguan", itemIds: [item.id] },
          headers: { "idempotency-key": key },
        });
        expect(first.status).toBe(201);
        const replay = await h.request("POST", SETS, {
          token: home.token,
          body: { name: "Mingguan", itemIds: [item.id] },
          headers: { "idempotency-key": key },
        });
        expect(replay.status).toBe(201);
        expect((replay.body as SetBody).id).toBe((first.body as SetBody).id);
        expectProblem(
          await h.request("POST", SETS, {
            token: home.token,
            body: { name: "Lain", itemIds: [] },
            headers: { "idempotency-key": key },
          }),
          409,
          "idempotency_key_reused",
        );
        expectProblem(
          await h.request("POST", SETS, {
            token: home.token,
            body: { name: "Kedua", itemIds: [] },
          }),
          409,
          "ingredient_set_limit_reached",
        );
      });
    });

    // ---------------------------------------------------------------- KIT-09

    describe("KIT-09 SAF-07 quantity and brand", () => {
      it("KIT-09 quantity is set and cleared", async () => {
        const home = await signInWithHousehold(api);
        const item = await add(home, { ingredientId: "fx_kit_beras" });
        const set = await patch(home, item.id, { quantity: "plenty" });
        expect(set.status, set.raw).toBe(200);
        expect(contractErrors("KitchenItem", set.body)).toEqual([]);
        expect(set.body).toMatchObject({ quantity: "plenty", state: "available" });
        expect((await patch(home, item.id, { state: "out" })).body).toMatchObject({
          quantity: "plenty",
        });
        expect((await patch(home, item.id, { quantity: null })).body).toMatchObject({
          quantity: null,
        });
      });

      it("SAF-07 a brand links only to a brand of the ingredient in the verified dataset; typed text stays text", async () => {
        const home = await signInWithHousehold(api);
        const kecap = await add(home, { ingredientId: "fx_kit_kecap_manis" });
        const beras = await add(home, { ingredientId: "fx_kit_beras" });
        const custom = await add(home, {
          customName: "Saus fiktif",
          category: "sauces_condiments",
        });

        const linked = await patch(home, kecap.id, { brand: { brandId: "fx_kit_merek_a" } });
        expect(linked.status, linked.raw).toBe(200);
        expect(linked.body).toMatchObject({
          brand: { brandId: "fx_kit_merek_a", name: "Merek A fiksi" },
        });

        for (const [id, brand] of [
          [kecap.id, { brandId: "fx_kit_merek_tidak_ada" }],
          // A brand of another ingredient, or of none at all.
          [beras.id, { brandId: "fx_kit_merek_a" }],
          [custom.id, { brandId: "fx_kit_merek_a" }],
          [kecap.id, { customName: "Merek​" }],
          [kecap.id, { brandId: "fx_kit_merek_a", customName: "x" }],
        ] as const) {
          expectProblem(await patch(home, id, { brand }), 400, "validation_failed");
        }
        // The refused changes left the linked brand in place.
        expect((await list(home)).find((i) => i.id === kecap.id)?.brand).toEqual({
          brandId: "fx_kit_merek_a",
          name: "Merek A fiksi",
        });

        const typed = await patch(home, kecap.id, { brand: { customName: "  Merek Warung " } });
        expect(typed.body).toMatchObject({ brand: { brandId: null, name: "Merek Warung" } });
        const { rows } = await db.query<{
          brand_id: string | null;
          brand_custom_name: string | null;
        }>(`SELECT brand_id, brand_custom_name FROM kitchen_item WHERE id = $1`, [kecap.id]);
        expect(rows).toEqual([{ brand_id: null, brand_custom_name: "Merek Warung" }]);
        // Typed text is allowed on a custom item too, and null clears the brand.
        expect(
          (await patch(home, custom.id, { brand: { customName: "Merek fiktif" } })).status,
        ).toBe(200);
        expect((await patch(home, kecap.id, { brand: null })).body).toMatchObject({ brand: null });
      });

      it("SAF-07 without a verified dataset a reference brand cannot be checked (503); typed text still works", async () => {
        const home = await signInWithHousehold(api);
        const kecap = await add(home, { ingredientId: "fx_kit_kecap_manis" });
        const down = await another({ reference: unavailableReference });
        expectProblem(
          await patch(home, kecap.id, { brand: { brandId: "fx_kit_merek_a" } }, down),
          503,
          "reference_data_unavailable",
        );
        expect((await patch(home, kecap.id, { brand: { customName: "Merek" } }, down)).status).toBe(
          200,
        );
      });
    });

    // ---------------------------------------------------------------- KIT-16

    describe("KIT-16 sync", () => {
      it("KIT-16 a first sync sends the whole kitchen and a cursor; the next sends only changes", async () => {
        const home = await signInWithHousehold(api);
        const tempe = await add(home, { ingredientId: "fx_kit_tempe" });
        const first = await sync(home, { cursor: null, changes: [] });
        expect(first.full).toBe(true);
        expect(first.items.map((i) => i.id)).toEqual([tempe.id]);
        expect(first.removedItemIds).toEqual([]);
        const quiet = await sync(home, { cursor: first.cursor, changes: [] });
        expect(quiet).toMatchObject({ full: false, items: [], removedItemIds: [], results: [] });

        await patch(home, tempe.id, { state: "out" });
        const next = await sync(home, { cursor: quiet.cursor, changes: [] });
        expect(next.full).toBe(false);
        expect(next.items.map((i) => [i.id, i.state])).toEqual([[tempe.id, "out"]]);
      });

      it("KIT-16 queued changes add and change items, dated on the server's clock minus their age", async () => {
        const home = await signInWithHousehold(api);
        const changes = [
          change({ ingredient: { ingredientId: "fx_kit_tempe" }, state: "out", ageMs: 120_000 }),
          change({
            ingredient: { customName: "Sambal botol fiktif" },
            category: "sauces_condiments",
            quantity: "a_little",
            brand: { customName: "Merek fiktif" },
            ageMs: 60_000,
          }),
          change({
            ingredient: { ingredientId: "fx_kit_kecap_manis" },
            brand: { brandId: "fx_kit_merek_a" },
          }),
        ];
        const result = await sync(home, { cursor: null, changes });
        expect(result.results.map((r) => [r.changeId, r.outcome, r.errorCode])).toEqual(
          changes.map((c) => [c.changeId, "applied", null]),
        );
        const byIngredient: Record<string, ItemBody> = Object.fromEntries(
          result.items.map((i): [string, ItemBody] => [i.ingredientId ?? i.customName ?? "", i]),
        );
        expect(byIngredient["fx_kit_tempe"]).toMatchObject({ state: "out", category: "protein" });
        expect(byIngredient["Sambal botol fiktif"]).toMatchObject({
          quantity: "a_little",
          brand: { brandId: null, name: "Merek fiktif" },
        });
        expect(byIngredient["fx_kit_kecap_manis"]?.brand).toEqual({
          brandId: "fx_kit_merek_a",
          name: "Merek A fiksi",
        });
        const tempeId = result.results[0]?.itemId as string;
        expect((await editedAtOf(tempeId))?.toISOString()).toBe(
          new Date(api.clock.now().getTime() - 120_000).toISOString(),
        );
      });

      it("KIT-16 latest change wins per ingredient: an older queued change is superseded", async () => {
        const home = await signInWithHousehold(api);
        const item = await add(home, { ingredientId: "fx_kit_garam" });
        // Phone A went offline and marked it out 10 minutes ago.
        api.clock.advance(5 * 60);
        // Phone B marked it available just now (online).
        await patch(home, item.id, { state: "out" });
        api.clock.advance(5 * 60);
        await patch(home, item.id, { state: "available" });
        const stale = change({
          ingredient: { ingredientId: "fx_kit_garam" },
          state: "out",
          ageMs: 9 * 60_000,
        });
        const result = await sync(home, { cursor: null, changes: [stale] });
        expect(result.results[0]).toMatchObject({
          outcome: "superseded",
          itemId: item.id,
          errorCode: null,
        });
        expect(result.items.find((i) => i.id === item.id)?.state).toBe("available");
        // A change made after phone B's goes through.
        const fresh = change({
          ingredient: { ingredientId: "fx_kit_garam" },
          state: "out",
          ageMs: 0,
        });
        api.clock.advance(1);
        const applied = await sync(home, { cursor: null, changes: [fresh] });
        expect(applied.results[0]?.outcome).toBe("applied");
        expect(applied.items.find((i) => i.id === item.id)?.state).toBe("out");
      });

      it("KIT-16 a removal is reported to other phones, and an older queued change cannot bring the item back", async () => {
        const home = await signInWithHousehold(api);
        const item = await add(home, { ingredientId: "fx_kit_kemangi" });
        const before = await sync(home, { cursor: null, changes: [] });
        api.clock.advance(60);
        const removed = await sync(home, {
          cursor: null,
          changes: [
            change({ ingredient: { ingredientId: "fx_kit_kemangi" }, operation: "remove" }),
          ],
        });
        expect(removed.results[0]).toMatchObject({ outcome: "applied", itemId: null });
        const other = await sync(home, { cursor: before.cursor, changes: [] });
        expect(other.removedItemIds).toEqual([item.id]);
        expect(other.items).toEqual([]);

        const older = change({
          ingredient: { ingredientId: "fx_kit_kemangi" },
          state: "available",
          ageMs: 30_000,
        });
        const stale = await sync(home, { cursor: null, changes: [older] });
        expect(stale.results[0]).toMatchObject({ outcome: "superseded", itemId: null });
        expect((await list(home)).map((i) => i.ingredientId)).toEqual([]);
        // The DELETE route records removals too.
        const again = await add(home, { ingredientId: "fx_kit_kemangi" });
        expect(again.id).not.toBe(item.id);
        const cursor = (await sync(home, { cursor: null, changes: [] })).cursor;
        await api.request("DELETE", `${ITEMS}/${again.id}`, { token: home.token });
        expect((await sync(home, { cursor, changes: [] })).removedItemIds).toEqual([again.id]);
        // Removing what is not there is applied and protects against older adds.
        api.clock.advance(1);
        const none = await sync(home, {
          cursor: null,
          changes: [
            change({ ingredient: { customName: "Tidak ada fiktif" }, operation: "remove" }),
          ],
        });
        expect(none.results[0]).toMatchObject({ outcome: "applied", itemId: null });
        const olderAdd = change({
          ingredient: { customName: "tidak ada FIKTIF" },
          category: "staples",
          ageMs: 5_000,
        });
        expect((await sync(home, { cursor: null, changes: [olderAdd] })).results[0]?.outcome).toBe(
          "superseded",
        );
      });

      it("KIT-16 a replayed change returns its first result and is not applied twice; a reused ID is rejected", async () => {
        const home = await signInWithHousehold(api);
        const item = await add(home, { ingredientId: "fx_kit_beras" });
        const queued = change({ ingredient: { ingredientId: "fx_kit_beras" }, state: "out" });
        const first = await sync(home, { cursor: null, changes: [queued] });
        expect(first.results[0]).toMatchObject({ outcome: "applied", itemId: item.id });
        api.clock.advance(60);
        await patch(home, item.id, { state: "available" });
        // The same queued change again, later (its age has grown): the first result, nothing applied.
        api.clock.advance(60);
        const replay = await sync(home, {
          cursor: null,
          changes: [{ ...queued, ageMs: 120_000 }, queued],
        });
        expect(replay.results.map((r) => r.outcome)).toEqual(["applied", "applied"]);
        expect(replay.items.find((i) => i.id === item.id)?.state).toBe("available");
        const reused = await sync(home, {
          cursor: null,
          changes: [{ ...queued, state: "available" }],
        });
        expect(reused.results[0]).toMatchObject({
          outcome: "rejected",
          errorCode: "idempotency_key_reused",
          itemId: null,
        });
        // Change IDs are per household: another household's same ID is a new change.
        const other = await signInWithHousehold(api);
        const elsewhere = await sync(other, {
          cursor: null,
          changes: [{ ...queued, ingredient: { ingredientId: "fx_kit_beras" } }],
        });
        expect(elsewhere.results[0]?.outcome).toBe("applied");
        expect(elsewhere.items.map((i) => i.id)).not.toContain(item.id);
      });

      it("L2 a temporary rejection is not remembered: the same change ID applies when sent again", async () => {
        const home = await signInWithHousehold(api);
        const down = await another({ reference: unavailableReference });
        const queued = change({ ingredient: { ingredientId: "fx_kit_kemangi" } });
        const outage = await sync(home, { cursor: null, changes: [queued] }, down);
        expect(outage.results[0]).toMatchObject({
          outcome: "rejected",
          errorCode: "reference_data_unavailable",
        });
        const recovered = await sync(home, { cursor: null, changes: [queued] });
        expect(recovered.results[0]?.outcome).toBe("applied");
        expect((await list(home)).map((i) => i.ingredientId)).toEqual(["fx_kit_kemangi"]);

        const limited = await another({
          kitchenConfig: resolveKitchenConfig({ maxItemsPerHousehold: 30 }),
        });
        const small = await signInWithHousehold(limited);
        const fill = Array.from({ length: 30 }, (_, i) =>
          change({ ingredient: { customName: `Isi fiktif ${i}` }, category: "staples" }),
        );
        await sync(small, { cursor: null, changes: fill }, limited);
        const extra = change({
          ingredient: { customName: "Satu lagi fiktif" },
          category: "staples",
        });
        const full = await sync(small, { cursor: null, changes: [extra] }, limited);
        expect(full.results[0]).toMatchObject({
          outcome: "rejected",
          errorCode: "kitchen_item_limit_reached",
        });
        const first = (await list(small, limited))[0] as ItemBody;
        await limited.request("DELETE", `${ITEMS}/${first.id}`, { token: small.token });
        const retried = await sync(small, { cursor: null, changes: [extra] }, limited);
        expect(retried.results[0]?.outcome).toBe("applied");
        // A permanent rejection is remembered: the same ID keeps its first result.
        const bad = change({ ingredient: { ingredientId: "fx_kit_tidak_ada" } });
        await sync(home, { cursor: null, changes: [bad] });
        const again = await sync(home, { cursor: null, changes: [bad] });
        expect(again.results[0]).toMatchObject({
          outcome: "rejected",
          errorCode: "validation_failed",
        });
        const { rows } = await db.query(
          `SELECT outcome, error_code FROM kitchen_sync_change WHERE household_id = $1 ORDER BY created_at`,
          [home.householdId],
        );
        expect(rows).toEqual([
          { outcome: "applied", error_code: null },
          { outcome: "rejected", error_code: "validation_failed" },
        ]);
      });

      it("KIT-16 a bad change is rejected on its own; the rest still apply", async () => {
        const home = await signInWithHousehold(api);
        const changes = [
          change({ ingredient: { ingredientId: "fx_kit_tidak_ada" } }),
          change({ ingredient: { customName: "Tanpa kategori fiktif" } }),
          change({ ingredient: { ingredientId: "fx_kit_lain" } }),
          // T-030 L1: a name whose folded key is too long to store.
          change({ ingredient: { customName: "ﷺ".repeat(60) }, category: "staples" }),
          change({ ingredient: { customName: "Nama​" }, category: "staples" }),
          change({
            ingredient: { ingredientId: "fx_kit_kecap_manis" },
            brand: { brandId: "fx_kit_merek_lain" },
          }),
          change({
            ingredient: { customName: "Saus fiktif" },
            category: "staples",
            brand: { brandId: "fx_kit_merek_a" },
          }),
          change({ ingredient: { ingredientId: "fx_kit_tempe" } }),
        ];
        const result = await sync(home, { cursor: null, changes });
        expect(result.results.map((r) => [r.outcome, r.errorCode])).toEqual([
          ["rejected", "validation_failed"],
          ["rejected", "validation_failed"],
          ["rejected", "validation_failed"],
          ["rejected", "validation_failed"],
          ["rejected", "validation_failed"],
          ["rejected", "validation_failed"],
          ["rejected", "validation_failed"],
          ["applied", null],
        ]);
        expect(result.items.map((i) => i.ingredientId)).toEqual(["fx_kit_tempe"]);
        const down = await another({ reference: unavailableReference });
        const unchecked = await sync(
          home,
          {
            cursor: null,
            changes: [
              change({ ingredient: { ingredientId: "fx_kit_kemangi" } }),
              change({ ingredient: { customName: "Bumbu fiktif" }, category: "staples" }),
            ],
          },
          down,
        );
        expect(unchecked.results.map((r) => [r.outcome, r.errorCode])).toEqual([
          ["rejected", "reference_data_unavailable"],
          ["applied", null],
        ]);
        const limited = await another({
          kitchenConfig: resolveKitchenConfig({ maxItemsPerHousehold: 30 }),
        });
        const small = await signInWithHousehold(limited);
        const many = Array.from({ length: 31 }, (_, i) =>
          change({ ingredient: { customName: `Bahan fiktif ${i}` }, category: "staples" }),
        );
        const capped = await sync(small, { cursor: null, changes: many }, limited);
        expect(capped.results.slice(0, 30).every((r) => r.outcome === "applied")).toBe(true);
        expect(capped.results[30]).toMatchObject({
          outcome: "rejected",
          errorCode: "kitchen_item_limit_reached",
        });
      });

      it("L3 KIT-16 a change is dated now minus its age; an age out of range rejects only that change", async () => {
        const h = await another({
          kitchenConfig: resolveKitchenConfig({
            sync: { maxChangeAgeHours: 24, recordRetentionDays: 1 },
          }),
        });
        const home = await signInWithHousehold(h);
        const good = change({
          ingredient: { ingredientId: "fx_kit_tempe" },
          ageMs: 10 * HOUR * 1000,
        });
        const result = await sync(
          home,
          {
            cursor: null,
            changes: [
              change({ ingredient: { ingredientId: "fx_kit_garam" }, ageMs: 25 * HOUR * 1000 }),
              change({ ingredient: { ingredientId: "fx_kit_beras" }, ageMs: -1 }),
              change({ ingredient: { ingredientId: "fx_kit_kemangi" }, ageMs: 2_592_000_001 }),
              good,
            ],
          },
          h,
        );
        expect(result.results.map((r) => [r.outcome, r.errorCode])).toEqual([
          ["rejected", "validation_failed"],
          ["rejected", "validation_failed"],
          ["rejected", "validation_failed"],
          ["applied", null],
        ]);
        expect(result.items.map((i) => i.ingredientId)).toEqual(["fx_kit_tempe"]);
        const id = result.results[3]?.itemId as string;
        expect((await editedAtOf(id))?.toISOString()).toBe(
          new Date(h.clock.now().getTime() - 10 * HOUR * 1000).toISOString(),
        );
        // Only a value that is not a whole number breaks the request's shape.
        for (const ageMs of [1.5, "10", null]) {
          expectProblem(
            await h.request("POST", SYNC, {
              token: home.token,
              body: {
                cursor: null,
                changes: [change({ ingredient: { ingredientId: "fx_kit_tempe" }, ageMs })],
              },
            }),
            400,
            "validation_failed",
          );
        }
      });

      it("M1 an old queued change never beats a newer online removal or edit (review T-032 probe P1)", async () => {
        const MIN = 60_000;
        // (b) Removed online at T; 80 minutes later a change made at T - 40 min arrives.
        const b = await signInWithHousehold(api);
        const beras = await add(b, { ingredientId: "fx_kit_beras" });
        await api.request("DELETE", `${ITEMS}/${beras.id}`, { token: b.token });
        api.clock.advance(80 * 60);
        const b2 = { ...b, token: await freshToken(api, b) };
        const revived = await sync(b2, {
          cursor: null,
          changes: [
            change({
              ingredient: { ingredientId: "fx_kit_beras" },
              state: "available",
              ageMs: 120 * MIN,
            }),
          ],
        });
        expect(revived.results[0]).toMatchObject({ outcome: "superseded", itemId: null });
        expect(await list(b2)).toEqual([]);
        // (c) Marked out online at T; the same kind of older change says available.
        const c = await signInWithHousehold(api);
        const garam = await add(c, { ingredientId: "fx_kit_garam" });
        await patch(c, garam.id, { state: "out" });
        api.clock.advance(80 * 60);
        const c2 = { ...c, token: await freshToken(api, c) };
        const reverted = await sync(c2, {
          cursor: null,
          changes: [
            change({
              ingredient: { ingredientId: "fx_kit_garam" },
              state: "available",
              ageMs: 120 * MIN,
            }),
          ],
        });
        expect(reverted.results[0]).toMatchObject({ outcome: "superseded", itemId: garam.id });
        expect((await list(c2)).map((i) => i.state)).toEqual(["out"]);
        // (a) Both through the sync: added 3 hours ago, removed 80 minutes ago,
        // then a change made 120 minutes ago arrives.
        const a = await signInWithHousehold(api);
        await add(a, { ingredientId: "fx_kit_tempe" });
        api.clock.advance(3 * 60 * 60);
        const a2 = { ...a, token: await freshToken(api, a) };
        const removal = await sync(a2, {
          cursor: null,
          changes: [
            change({
              ingredient: { ingredientId: "fx_kit_tempe" },
              operation: "remove",
              ageMs: 80 * MIN,
            }),
          ],
        });
        expect(removal.results[0]?.outcome).toBe("applied");
        const older = await sync(a2, {
          cursor: null,
          changes: [
            change({
              ingredient: { ingredientId: "fx_kit_tempe" },
              state: "available",
              ageMs: 120 * MIN,
            }),
          ],
        });
        expect(older.results[0]?.outcome).toBe("superseded");
        expect(await list(a2)).toEqual([]);
        // With a 1-hour limit the 2-hour-old change is not accepted at all.
        const strict = await another({
          kitchenConfig: resolveKitchenConfig({
            sync: { maxChangeAgeHours: 1, recordRetentionDays: 1 },
          }),
        });
        const d = await signInWithHousehold(strict);
        const late = await sync(
          d,
          {
            cursor: null,
            changes: [change({ ingredient: { ingredientId: "fx_kit_tempe" }, ageMs: 120 * MIN })],
          },
          strict,
        );
        expect(late.results[0]).toMatchObject({
          outcome: "rejected",
          errorCode: "validation_failed",
        });
      });

      it("M1 L1 a change older than the kept removals never adds an item, even when retention is misconfigured (probe P2)", async () => {
        // Built directly, bypassing the startup check, to show the sync does not rely on it.
        const h = await another({
          kitchenConfig: {
            ...resolveKitchenConfig({}),
            sync: { maxChangeAgeHours: 720, recordRetentionDays: 1 },
          },
        });
        const home = await signInWithHousehold(h);
        const tempe = await add(home, { ingredientId: "fx_kit_tempe" }, h);
        await h.request("DELETE", `${ITEMS}/${tempe.id}`, { token: home.token });
        h.clock.advance(2 * DAY);
        await purgeKitchenSyncRecords(db, new Date(h.clock.now().getTime() - DAY * 1000));
        const session = { ...home, token: await freshToken(h, home) };
        const old = await sync(
          session,
          {
            cursor: null,
            changes: [
              change({ ingredient: { ingredientId: "fx_kit_tempe" }, ageMs: 3 * DAY * 1000 }),
            ],
          },
          h,
        );
        expect(old.results[0]).toMatchObject({ outcome: "superseded", itemId: null });
        expect(await list(session, h)).toEqual([]);
        // A change from inside the kept window still adds the item.
        const fresh = await sync(
          session,
          {
            cursor: null,
            changes: [change({ ingredient: { ingredientId: "fx_kit_tempe" }, ageMs: HOUR * 1000 })],
          },
          h,
        );
        expect(fresh.results[0]?.outcome).toBe("applied");
      });

      it("KIT-16 a request with the wrong shape is refused whole and applies nothing", async () => {
        const home = await signInWithHousehold(api);
        const good = change({ ingredient: { ingredientId: "fx_kit_tempe" } });
        for (const body of [
          { changes: [good] },
          { cursor: null },
          { cursor: null, changes: [good, { ...good, changeId: "bukan-uuid" }] },
          {
            cursor: null,
            changes: [good, { ...good, changeId: randomUUID(), operation: "hapus" }],
          },
          { cursor: null, changes: [good, { ...good, changeId: randomUUID(), ingredient: {} }] },
          { cursor: null, changes: [{ ...good, householdId: home.householdId }] },
          { cursor: "x".repeat(513), changes: [] },
          { cursor: null, changes: Array.from({ length: 101 }, () => good) },
        ]) {
          expectProblem(
            await api.request("POST", SYNC, { token: home.token, body }),
            400,
            "validation_failed",
          );
        }
        expect(await list(home)).toEqual([]);
      });

      it("KIT-16 a cursor is bound to its household and signed: tampered, foreign or old cursors resync in full", async () => {
        const a = await signInWithHousehold(api);
        const b = await signInWithHousehold(api);
        const aItem = await add(a, { ingredientId: "fx_kit_tempe" });
        const bItem = await add(b, { ingredientId: "fx_kit_kemangi" });
        const bCursor = (await sync(b, { cursor: null, changes: [] })).cursor;
        const aCursor = (await sync(a, { cursor: null, changes: [] })).cursor;
        const [prefix, payload, mac] = aCursor.split(".") as [string, string, string];
        const forged = Buffer.from(
          JSON.stringify({ ...JSON.parse(Buffer.from(payload, "base64url").toString()), s: "0" }),
        ).toString("base64url");
        for (const cursor of [
          bCursor,
          `${prefix}.${forged}.${mac}`,
          `${prefix}.${payload}.${"A".repeat(mac.length)}`,
          "v1.e30.AAAA",
          "garbage",
        ]) {
          const result = await sync(a, { cursor, changes: [] });
          expect(result.full, cursor).toBe(true);
          expect(result.items.map((i) => i.id)).toEqual([aItem.id]);
          expect(result.items.map((i) => i.id)).not.toContain(bItem.id);
        }
        // A cursor older than the kept removals cannot be continued from.
        const h = await another({});
        h.clock.advance(31 * DAY);
        const session = { ...a, token: await freshToken(h, a) };
        expect((await sync(session, { cursor: aCursor, changes: [] }, h)).full).toBe(true);
      });

      it("KIT-16 KIT-06 sync changes of state count as uses", async () => {
        const home = await signInWithHousehold(api);
        await add(home, { ingredientId: "fx_kit_beras" });
        await add(home, { ingredientId: "fx_kit_garam" });
        const result = await sync(home, {
          cursor: null,
          changes: [
            change({ ingredient: { ingredientId: "fx_kit_garam" }, state: "out" }),
            change({ ingredient: { ingredientId: "fx_kit_garam" }, state: "available" }),
          ],
        });
        expect(result.items.map((i) => [i.ingredientId, i.usageRank])).toEqual([
          ["fx_kit_garam", 1],
          ["fx_kit_beras", null],
        ]);
      });

      it("KIT-16 a sync waits for a kitchen write in progress, so its cursor never skips it", async (context) => {
        if (opened.openSession === null) {
          context.skip("PGlite has one connection; set TEST_DATABASE_URL to run");
          return;
        }
        const home = await signInWithHousehold(api);
        const before = (await sync(home, { cursor: null, changes: [] })).cursor;
        const session = await opened.openSession();
        try {
          await lockHouseholdKitchen(session.executor, home.householdId);
          await insertItem(session.executor, {
            householdId: home.householdId,
            accountId: home.accountId,
            ref: { kind: "reference", ingredientId: "fx_kit_tempe" },
            values: {
              category: "protein",
              state: "available",
              quantity: null,
              brandId: null,
              brandCustomName: null,
              useScore: 0,
              useScoreAt: null,
              editedAt: new Date(),
            },
            isDefaultStaple: false,
            now: new Date(),
          });
        } catch (error) {
          await session.rollback();
          throw error;
        }
        const waiting = sync(home, { cursor: before, changes: [] });
        let settled = false;
        void waiting.then(() => (settled = true));
        await new Promise((resolve) => setTimeout(resolve, 300));
        expect(settled).toBe(false);
        await session.commit();
        const result = await waiting;
        expect(result.items.map((i) => i.ingredientId)).toEqual(["fx_kit_tempe"]);
      });

      it("KIT-16 old change records and removals are purged after the retention", async () => {
        const home = await signInWithHousehold(api);
        const queued = change({ ingredient: { ingredientId: "fx_kit_beras" } });
        await sync(home, { cursor: null, changes: [queued] });
        await purgeKitchenSyncRecords(db, new Date(api.clock.now().getTime() + 1000));
        const { rows } = await db.query(
          `SELECT 1 FROM kitchen_sync_change WHERE household_id = $1`,
          [home.householdId],
        );
        expect(rows).toEqual([]);
      });
    });

    // ---------------------------------------------------------------- NFR-09

    describe("NFR-09 IDOR: sets and the sync stay in the session's household", () => {
      const snapshot = async (householdId: string) => [
        (
          await db.query(
            `SELECT id, state, quantity, brand_id, brand_custom_name, change_seq::text FROM kitchen_item
              WHERE household_id = $1 ORDER BY id`,
            [householdId],
          )
        ).rows,
        (
          await db.query(
            `SELECT id, name, updated_at FROM ingredient_set WHERE household_id = $1 ORDER BY id`,
            [householdId],
          )
        ).rows,
        (
          await db.query(
            `SELECT set_id, kitchen_item_id FROM ingredient_set_item WHERE household_id = $1 ORDER BY 1, 2`,
            [householdId],
          )
        ).rows,
      ];

      it("NFR-09 every route with a set ID answers 404 for another household's sets and items, and changes nothing", async () => {
        const a = await signInWithHousehold(api);
        const b = await signInWithHousehold(api);
        const bItem = await add(b, { ingredientId: "fx_kit_tempe", state: "out" });
        const bSet = (
          await api.request("POST", SETS, {
            token: b.token,
            body: { name: "Rahasia B", itemIds: [bItem.id] },
          })
        ).body as SetBody;
        const aItem = await add(a, { ingredientId: "fx_kit_tempe" });
        const aSet = (
          await api.request("POST", SETS, {
            token: a.token,
            body: { name: "Milik A", itemIds: [aItem.id] },
          })
        ).body as SetBody;
        const before = await snapshot(b.householdId);

        const matrix: Record<string, (setId: string) => Promise<Response>> = {
          "PUT /v1/household/kitchen/sets/:setId": (id) =>
            api.request("PUT", `${SETS}/${id}`, {
              token: a.token,
              body: { name: "Diubah", itemIds: [] },
            }),
          "DELETE /v1/household/kitchen/sets/:setId": (id) =>
            api.request("DELETE", `${SETS}/${id}`, { token: a.token }),
          "POST /v1/household/kitchen/sets/:setId/mark-available": (id) =>
            api.request("POST", `${SETS}/${id}/mark-available`, { token: a.token }),
        };
        expect(Object.keys(matrix).sort()).toEqual(routesWithSetIds());
        for (const call of Object.values(matrix)) {
          for (const id of [bSet.id, bItem.id, b.householdId, randomUUID(), "not-a-uuid"]) {
            expectProblem(await call(id), 404, "not_found");
          }
        }
        // Another household's item IDs in a set body are not found.
        for (const [method, url] of [
          ["POST", SETS],
          ["PUT", `${SETS}/${aSet.id}`],
        ] as const) {
          expectProblem(
            await api.request(method, url, {
              token: a.token,
              body: { name: "X", itemIds: [bItem.id] },
            }),
            404,
            "not_found",
          );
        }
        // The sync names ingredients, not IDs: the same ingredient in A stays A's.
        const result = await sync(a, {
          cursor: null,
          changes: [
            change({ ingredient: { ingredientId: "fx_kit_tempe" }, state: "out" }),
            change({ ingredient: { ingredientId: "fx_kit_tempe" }, operation: "remove" }),
          ],
        });
        expect(result.results.map((r) => r.outcome)).toEqual(["applied", "applied"]);
        expect(await snapshot(b.householdId)).toEqual(before);
        expect((await list(b)).map((i) => [i.id, i.state])).toEqual([[bItem.id, "out"]]);
        const aSets = (await api.request("GET", SETS, { token: a.token })).body as {
          items: SetBody[];
        };
        expect(aSets.items.map((s) => s.id)).toEqual([aSet.id]);
      });
    });

    describe("privacy", () => {
      it("set names, typed brands and synced custom names never appear in logs or error responses", async () => {
        const home = await signInWithHousehold(api);
        const item = await add(home, { ingredientId: "fx_kit_kecap_manis" });
        await api.request("POST", SETS, {
          token: home.token,
          body: { name: "Set Rahasia", itemIds: [] },
        });
        const refused = await api.request("POST", SETS, {
          token: home.token,
          body: { name: "Rahasia​", itemIds: [] },
        });
        expect(refused.raw).not.toMatch(/rahasia/i);
        await patch(home, item.id, { brand: { customName: "Merek Rahasia" } });
        const bad = await patch(home, item.id, { brand: { customName: "Merek Rahasia​" } });
        expect(bad.raw).not.toMatch(/rahasia/i);
        const synced = await sync(home, {
          cursor: null,
          changes: [change({ ingredient: { customName: "Bahan Rahasia" }, category: "staples" })],
        });
        expect(JSON.stringify(synced.results)).not.toMatch(/rahasia/i);
        expect(api.logger.text).not.toMatch(/rahasia/i);
      });
    });
  });
}
