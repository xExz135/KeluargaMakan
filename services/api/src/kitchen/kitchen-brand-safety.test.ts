// TEST FIXTURE: not real safety or nutrition data. One fictional brand-varying
// ingredient (fx_kbr_ IDs; its generic record "may contain" milk, one brand
// variant is verified without milk, one is unverified) and fictional members.
import "reflect-metadata";

import { join } from "node:path";

import { evaluate, type HardRule } from "@keluargamakan/cek-aman";
import { afterAll, beforeAll, describe, expect, it } from "vitest";

import { migrate } from "../db/migrate.js";
import { pgliteTarget, type TestDatabase } from "../db/testing/databases.js";
import {
  signInWithHousehold,
  startHarness,
  type Harness,
  type HouseholdSession,
} from "../http/testing/harness.js";
import { referenceSourceOf } from "../reference/reference-data.js";
import { kitchenIngredientInput, kitchenRecordedBrand } from "./cek-aman-input.js";
import { buildFixtureReference, REPO_ROOT, type BuiltFixture } from "./testing/catalog-fixture.js";

interface ItemBody {
  id: string;
  ingredientId: string | null;
  customName: string | null;
  brand: { brandId: string | null; name: string } | null;
}

const milkAllergy: HardRule = { ruleId: "r-milk", type: "allergy", allergen: "milk" };

let fixture: BuiltFixture;
let opened: TestDatabase;
let api: Harness;
let home: HouseholdSession;
let item: ItemBody;

beforeAll(async () => {
  fixture = buildFixtureReference(join(REPO_ROOT, "data", "fixtures", "kitchen-brands"));
  opened = await pgliteTarget.open();
  await migrate(opened.executor);
  api = await startHarness(opened.executor, { reference: referenceSourceOf(fixture.verified) });
  home = await signInWithHousehold(api);
  item = (
    await api.request("POST", "/v1/household/kitchen/items", {
      token: home.token,
      body: { ingredientId: "fx_kbr_kaldu" },
    })
  ).body as ItemBody;
});
afterAll(async () => {
  await api.close();
  await opened.close();
  fixture.cleanup();
});

/** Records the brand through the API, then evaluates the saved item with Cek Aman. */
async function resultWith(brand: object | null) {
  const saved = await api.request("PATCH", `/v1/household/kitchen/items/${item.id}`, {
    token: home.token,
    body: { brand },
  });
  expect(saved.status, saved.raw).toBe(200);
  const stored = saved.body as ItemBody;
  const recorded = kitchenRecordedBrand(stored);
  const result = evaluate({
    ingredients: [kitchenIngredientInput(stored)],
    recordedBrands: recorded === null ? [] : [recorded],
    members: [{ memberId: "m1", hardRules: [milkAllergy] }],
    reference: fixture.verified.reference,
  });
  const member = result.perMember[0];
  return { status: member?.status, codes: member?.reasons.map((reason) => reason.code) ?? [] };
}

describe("KIT-09 SAF-07 a recorded brand reaches Cek Aman only when it is a reference brand", () => {
  it("SAF-07 no brand recorded: Check the label (brand not recorded)", async () => {
    const result = await resultWith(null);
    expect(result.status).toBe("check_label");
    expect(result.codes).toContain("brand_not_recorded");
  });

  it("SAF-07 a typed brand is never a recorded brand: still Check the label", async () => {
    const result = await resultWith({ customName: "Merek terperiksa fiksi" });
    expect(result.status).toBe("check_label");
    expect(result.codes).toContain("brand_not_recorded");
    expect(result.codes).not.toContain("brand_unverified");
  });

  it("SAF-07 a reference brand without verified data: Check the label (brand unverified)", async () => {
    const result = await resultWith({ brandId: "fx_kbr_merek_belum" });
    expect(result.status).toBe("check_label");
    expect(result.codes).toContain("brand_unverified");
  });

  it("SAF-07 a reference brand with verified data is checked with that brand's data", async () => {
    // Only the engine decides; with this fictional verified variant it finds no milk.
    expect(await resultWith({ brandId: "fx_kbr_merek_terperiksa" })).toEqual({
      status: "safe",
      codes: [],
    });
  });
});
