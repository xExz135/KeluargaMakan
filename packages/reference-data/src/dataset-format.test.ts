// TEST FIXTURE: not real safety or nutrition data
//
// Tests for the built dataset format. Every ingredient is fictional.

import { describe, expect, it } from "vitest";

import { INGREDIENT_DATASET_SCHEMA, type ReferenceIngredient } from "@keluargamakan/cek-aman";

import {
  BUILT_DATASET_FORMAT,
  FIXTURE_COMMENT,
  ReferenceDataError,
  SOURCE_DATASET_SCHEMA,
  canonicalJson,
  computeContentHash,
  createBuiltDataset,
  isFixturePath,
  looksLikeFixtureVersion,
  sha256Hex,
  verifyBuiltDataset,
  type BuiltReferenceDataset,
} from "./dataset-format.js";

function record(id: string, overrides: Record<string, unknown> = {}): ReferenceIngredient {
  return {
    id,
    displayName: { id: `Fiksi ${id}`, en: `Fiction ${id}` },
    localNames: [],
    category: "fixture",
    components: { verification: "unverified", ingredientIds: [] },
    allergens: { verification: "verified", contains: [], mayContain: [] },
    halal: { verification: "verified", value: "halal", nonHalalSources: [] },
    diet: { verification: "verified", vegetarian: "suitable", vegan: "suitable" },
    brandVaries: false,
    brandVariants: [],
    tkpiCode: null,
    ...overrides,
  };
}

const real = (): BuiltReferenceDataset =>
  createBuiltDataset({
    version: "2026.11.0",
    fixture: false,
    ingredients: [record("fx_b"), record("fx_a")],
  });
const fixture = (): BuiltReferenceDataset =>
  createBuiltDataset({ version: "TEST-FIXTURE-1", fixture: true, ingredients: [record("fx_a")] });

const prod = { allowFixture: false, expectedSha256: null } as const;
const dev = { allowFixture: true, expectedSha256: null } as const;

/** A copy with fields changed and the hash recomputed, so only the change is under test. */
function rehashed(base: BuiltReferenceDataset, change: (data: Record<string, unknown>) => void) {
  const data = structuredClone(base) as unknown as Record<string, unknown>;
  change(data);
  data.contentHash = { algorithm: "sha256", value: computeContentHash(data) };
  return data;
}

describe("DAT-06 canonical JSON and content hash (security review M3)", () => {
  it("DAT-06 sorts keys, drops whitespace and keeps array order", () => {
    expect(canonicalJson({ b: [3, 1, { d: null, c: true }], a: "xé" })).toBe(
      '{"a":"xé","b":[3,1,{"c":true,"d":null}]}',
    );
    expect(canonicalJson(Object.assign(Object.create(null) as object, { z: 1, y: -0.5 }))).toBe(
      '{"y":-0.5,"z":1}',
    );
  });

  it("DAT-06 refuses values plain JSON cannot hold", () => {
    const holey: unknown[] = [];
    holey[1] = 1;
    for (const value of [Number.NaN, Infinity, undefined, () => 1, new Date(0), 1n, holey]) {
      expect(() => canonicalJson(value), String(value)).toThrow(TypeError);
    }
    expect(() => canonicalJson({ a: undefined })).toThrow(/undefined/);
  });

  it("DAT-06 the hash covers every field except itself", () => {
    const data = real();
    expect(data.contentHash.value).toBe(computeContentHash(data as never));
    const { contentHash, ...body } = data;
    expect(contentHash.value).toBe(sha256Hex(canonicalJson(body)));
    expect(sha256Hex("")).toBe("e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855");
  });

  it("DAT-06 the source schema id equals the engine's", () => {
    expect(SOURCE_DATASET_SCHEMA).toBe(INGREDIENT_DATASET_SCHEMA);
  });
});

describe("DAT-06 SAF-13 createBuiltDataset", () => {
  it("DAT-06 sorts records by id, records the version and copies records unchanged", () => {
    const input = [record("fx_b"), record("fx_a")];
    const data = createBuiltDataset({ version: "2026.11.0", fixture: false, ingredients: input });
    expect(data.ingredients.map((r) => r.id)).toEqual(["fx_a", "fx_b"]);
    expect(data.ingredients[0]).toEqual(input[1]);
    expect(data.ingredients[0]).not.toBe(input[1]);
    expect(data.ingredients[0]?.components.verification).toBe("unverified");
    expect(data).toMatchObject({
      format: BUILT_DATASET_FORMAT,
      schema: SOURCE_DATASET_SCHEMA,
      version: "2026.11.0",
      fixture: false,
      ingredientCount: 2,
    });
    expect(Object.hasOwn(data, "$comment")).toBe(false);
    expect(fixture().$comment).toBe(FIXTURE_COMMENT);
  });

  it("DAT-06 the hash does not depend on source order", () => {
    const a = createBuiltDataset({
      version: "1",
      fixture: false,
      ingredients: [record("fx_a"), record("fx_b"), record("fx_a")],
    });
    const b = createBuiltDataset({
      version: "1",
      fixture: false,
      ingredients: [record("fx_b"), record("fx_a"), record("fx_a")],
    });
    expect(a.contentHash).toEqual(b.contentHash);
  });

  it("DAT-06 refuses a fixture flag that does not match the version", () => {
    expect(() =>
      createBuiltDataset({ version: "2026.11.0", fixture: true, ingredients: [] }),
    ).toThrow(/must start with TEST-FIXTURE/);
    expect(() =>
      createBuiltDataset({ version: "TEST-FIXTURE-1", fixture: false, ingredients: [] }),
    ).toThrow(ReferenceDataError);
  });

  it("DAT-06 fixture versions and paths are recognised like the CI fixture guard", () => {
    expect(looksLikeFixtureVersion("TEST-FIXTURE-2026.11.0")).toBe(true);
    expect(looksLikeFixtureVersion("test_fixture")).toBe(true);
    expect(looksLikeFixtureVersion("2026.11.0")).toBe(false);
    expect(isFixturePath(["data", "fixtures", "x.json"].join("/"))).toBe(true);
    expect(isFixturePath(["C:", "repo", "DATA", "Fixtures", "x.json"].join("\\"))).toBe(true);
    expect(isFixturePath("/srv/reference/reference-dataset.json")).toBe(false);
  });
});

describe("DAT-06 SAF-13 verifyBuiltDataset", () => {
  it("DAT-06 returns frozen engine input whose version names the content hash", () => {
    const data = real();
    const verified = verifyBuiltDataset(data, { ...prod, expectedSha256: data.contentHash.value });
    expect(verified.version).toBe("2026.11.0");
    expect(verified.contentHash).toBe(data.contentHash.value);
    expect(verified.referenceVersion).toBe(`2026.11.0@sha256:${data.contentHash.value}`);
    expect(verified.reference.version).toBe(verified.referenceVersion);
    expect(verified.reference.schema).toBe(SOURCE_DATASET_SCHEMA);
    expect(verified.reference.ingredients).toEqual(data.ingredients);
    expect(verified.ingredientCount).toBe(2);
    expect(verified.fixture).toBe(false);
    expect(Object.isFrozen(verified.reference.ingredients[0]?.components)).toBe(true);
  });

  it("DAT-06 verifies a private copy: changing the input afterwards changes nothing", () => {
    const data = real();
    const verified = verifyBuiltDataset(data, prod);
    (data.ingredients[0] as { id: string }).id = "fx_changed";
    expect(verified.reference.ingredients[0]?.id).toBe("fx_a");
  });

  it("DAT-06 refuses content changed after the build", () => {
    const data = structuredClone(real()) as unknown as {
      ingredients: { halal: { verification: string } }[];
    };
    data.ingredients[0]!.halal.verification = "unverified";
    expect(() => verifyBuiltDataset(data, prod)).toThrow(/content hash does not match/);
  });

  it("DAT-06 refuses a hash other than the configured one", () => {
    expect(() => verifyBuiltDataset(real(), { ...prod, expectedSha256: "0".repeat(64) })).toThrow(
      /is not the configured hash/,
    );
  });

  it("SAF-13 refuses a test fixture dataset as production data", () => {
    expect(() => verifyBuiltDataset(fixture(), prod)).toThrow(
      /refusing a test fixture dataset outside local development/,
    );
    expect(verifyBuiltDataset(fixture(), dev).fixture).toBe(true);
  });

  it("SAF-13 refuses data that claims to be real but carries fixture markers", () => {
    const cases = [
      rehashed(real(), (d) => (d.version = "TEST-FIXTURE-9")),
      rehashed(real(), (d) => (d.$comment = "note")),
      rehashed(real(), (d) => {
        (d.ingredients as { category: string }[])[0]!.category = "TEST FIXTURE category";
      }),
    ];
    for (const data of cases) {
      expect(() => verifyBuiltDataset(data, dev)).toThrow(/carries test fixture markers/);
    }
    const unmarkedFixture = rehashed(fixture(), (d) => (d.version = "2026.11.0"));
    expect(() => verifyBuiltDataset(unmarkedFixture, dev)).toThrow(/must start with TEST-FIXTURE/);
  });

  const structural: [string, (d: Record<string, unknown>) => void, RegExp][] = [
    ["an unknown field", (d) => (d.safe = true), /unknown field "safe"/],
    ["an unknown format", (d) => (d.format = "other/1"), /unknown reference dataset format/],
    ["an unknown schema", (d) => (d.schema = "other/1"), /unknown reference data schema/],
    ["a missing version", (d) => delete d.version, /version is required/],
    ["a blank version", (d) => (d.version = " "), /version is required/],
    ["a missing fixture flag", (d) => (d.fixture = "no"), /whether it is a fixture/],
    ["ingredients not a list", (d) => (d.ingredients = {}), /must be a list/],
    ["a wrong count", (d) => (d.ingredientCount = 3), /does not match 2 ingredients/],
    ["a record without id", (d) => (d.ingredients = [{}, {}]), /ingredients\[0\] has no id/],
    ["a record that is not an object", (d) => (d.ingredients = ["a", "b"]), /has no id/],
    ["an empty id", (d) => (d.ingredients = [{ id: "" }, { id: "x" }]), /has no id/],
    [
      "a duplicate id",
      (d) => (d.ingredients = [record("fx_a"), record("fx_a")]),
      /duplicate ingredient id fx_a/,
    ],
  ];
  for (const [name, change, message] of structural) {
    it(`DAT-06 refuses ${name}`, () => {
      expect(() => verifyBuiltDataset(rehashed(real(), change), dev)).toThrow(message);
    });
  }

  it("DAT-06 refuses a malformed contentHash", () => {
    const hashes = [
      undefined,
      "abc",
      { algorithm: "md5", value: "0".repeat(64) },
      { algorithm: "sha256", value: 5 },
      { algorithm: "sha256", value: "A".repeat(64) },
      { algorithm: "sha256", value: "0".repeat(64), extra: 1 },
    ];
    for (const contentHash of hashes) {
      const data = { ...real(), contentHash };
      expect(() => verifyBuiltDataset(data, dev), JSON.stringify(contentHash)).toThrow(
        /contentHash must be/,
      );
    }
  });

  it("DAT-06 refuses anything that is not a plain JSON object", () => {
    for (const value of [null, "x", [], [real()]]) {
      expect(() => verifyBuiltDataset(value, dev)).toThrow(/must be a JSON object/);
    }
    expect(() => verifyBuiltDataset({ format: () => 1 }, dev)).toThrow(/not plain JSON data/);
  });
});
