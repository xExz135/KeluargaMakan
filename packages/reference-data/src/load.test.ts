// TEST FIXTURE: not real safety or nutrition data
//
// Tests for the reference dataset loader the API uses. Every ingredient is
// fictional; files are written to a temporary folder.

import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

import { afterAll, describe, expect, it } from "vitest";

import type { ReferenceIngredient } from "@keluargamakan/cek-aman";

import { createBuiltDataset, type BuiltReferenceDataset } from "./dataset-format.js";
import * as api from "./index.js";
import {
  loadReferenceDataFromEnv,
  loadReferenceDataset,
  readReferenceDataConfig,
  type LoaderIo,
  type ReferenceDataConfig,
} from "./load.js";

const work = mkdtempSync(join(tmpdir(), "km-load-"));
afterAll(() => rmSync(work, { recursive: true, force: true }));

const record = (id: string) =>
  ({
    id,
    displayName: { id: `Fiksi ${id}`, en: `Fiction ${id}` },
    localNames: [],
    category: "fixture",
    components: { verification: "verified", ingredientIds: [] },
    allergens: { verification: "verified", contains: [], mayContain: [] },
    halal: { verification: "verified", value: "halal", nonHalalSources: [] },
    diet: { verification: "verified", vegetarian: "suitable", vegan: "suitable" },
    brandVaries: false,
    brandVariants: [],
    tkpiCode: null,
  }) as ReferenceIngredient;

function writeDataset(name: string, data: BuiltReferenceDataset | string): string {
  const path = join(work, name);
  writeFileSync(path, typeof data === "string" ? data : JSON.stringify(data, null, 2));
  return path;
}

const realData = createBuiltDataset({
  version: "2026.11.0",
  fixture: false,
  ingredients: [record("fx_a")],
});
const fixtureData = createBuiltDataset({
  version: "TEST-FIXTURE-1",
  fixture: true,
  ingredients: [record("fx_a")],
});
const realPath = writeDataset("real.json", realData);
const fixturePath = writeDataset("fixture.json", fixtureData);
const pin = realData.contentHash.value;
const fixtureFolder = ["", "srv", "app", "data", "fixtures", "x.json"].join("/");

describe("SAF-13 DAT-06 reference data configuration", () => {
  it("DAT-06 reads the path and pinned hash for production", () => {
    expect(
      readReferenceDataConfig({
        APP_ENV: "production",
        REFERENCE_DATA_PATH: ` ${realPath} `,
        REFERENCE_DATA_SHA256: pin.toUpperCase(),
      }),
    ).toEqual({
      environment: "production",
      path: realPath,
      expectedSha256: pin,
      allowFixture: false,
    });
  });

  it("SAF-13 a missing or unknown APP_ENV is treated as production", () => {
    for (const APP_ENV of [undefined, "", "prod", "Local"]) {
      const config = readReferenceDataConfig({
        APP_ENV,
        REFERENCE_DATA_PATH: realPath,
        REFERENCE_DATA_SHA256: pin,
      });
      expect(config.environment).toBe("production");
      expect(config.allowFixture).toBe(false);
    }
    // An inherited value is ignored, like a missing one.
    const inherited = Object.create({ APP_ENV: "local" }) as Record<string, string>;
    inherited.REFERENCE_DATA_PATH = fixtureFolder;
    expect(() => readReferenceDataConfig(inherited)).toThrow(/test fixtures folder in production/);
  });

  it("SAF-13 production and staging configuration pointing at the fixtures folder is refused", () => {
    for (const APP_ENV of ["production", "staging", undefined]) {
      expect(() =>
        readReferenceDataConfig({
          APP_ENV,
          REFERENCE_DATA_PATH: fixtureFolder,
          REFERENCE_DATA_SHA256: pin,
        }),
      ).toThrow(/refusing reference data from the test fixtures folder/);
    }
  });

  it("DAT-06 a pinned hash is required outside local development and tests", () => {
    expect(() =>
      readReferenceDataConfig({ APP_ENV: "staging", REFERENCE_DATA_PATH: realPath }),
    ).toThrow(/REFERENCE_DATA_SHA256 is required in staging/);
    expect(() =>
      readReferenceDataConfig({
        APP_ENV: "local",
        REFERENCE_DATA_PATH: realPath,
        REFERENCE_DATA_SHA256: "abc",
      }),
    ).toThrow(/64 hexadecimal characters/);
    expect(
      readReferenceDataConfig({ APP_ENV: "local", REFERENCE_DATA_PATH: fixtureFolder }),
    ).toEqual({
      environment: "local",
      path: fixtureFolder,
      expectedSha256: null,
      allowFixture: true,
    });
    expect(
      readReferenceDataConfig({
        APP_ENV: "test",
        REFERENCE_DATA_PATH: realPath,
        REFERENCE_DATA_SHA256: pin,
      }).expectedSha256,
    ).toBe(pin);
  });

  it("DAT-06 the path is required", () => {
    expect(() => readReferenceDataConfig({ APP_ENV: "local", REFERENCE_DATA_PATH: " " })).toThrow(
      /REFERENCE_DATA_PATH is required/,
    );
  });
});

describe("SAF-13 DAT-06 loading the built dataset", () => {
  const production: ReferenceDataConfig = {
    environment: "production",
    path: realPath,
    expectedSha256: pin,
    allowFixture: false,
  };

  it("DAT-06 loads a real dataset in production with its version and hash", () => {
    const loaded = loadReferenceDataFromEnv({
      APP_ENV: "production",
      REFERENCE_DATA_PATH: realPath,
      REFERENCE_DATA_SHA256: pin,
    });
    expect(loaded.version).toBe("2026.11.0");
    expect(loaded.reference.version).toBe(`2026.11.0@sha256:${pin}`);
  });

  it("SAF-13 refuses a fixture dataset in production even under a neutral path", () => {
    const copied = writeDataset("neutral-name.json", fixtureData);
    expect(() =>
      loadReferenceDataset({
        ...production,
        path: copied,
        expectedSha256: fixtureData.contentHash.value,
      }),
    ).toThrow(/refusing a test fixture dataset in production/);
  });

  it("SAF-13 local development may load a fixture dataset", () => {
    const loaded = loadReferenceDataFromEnv({ APP_ENV: "local", REFERENCE_DATA_PATH: fixturePath });
    expect(loaded.fixture).toBe(true);
  });

  it("SAF-13 refuses a symbolic link or relative path that resolves into the fixtures folder", () => {
    const io: LoaderIo = {
      realpath: () => fixtureFolder,
      readFile: () => {
        throw new Error("must not be read");
      },
    };
    expect(() => loadReferenceDataset(production, io)).toThrow(
      /refusing reference data from the test fixtures folder in production/,
    );
  });

  it("DAT-06 refuses a file that is missing, unreadable or not JSON", () => {
    expect(() => loadReferenceDataset({ ...production, path: join(work, "missing.json") })).toThrow(
      /cannot read the reference dataset/,
    );
    const unreadable: LoaderIo = {
      realpath: (path) => path,
      readFile: () => {
        throw new Error("EACCES");
      },
    };
    expect(() => loadReferenceDataset(production, unreadable)).toThrow(/EACCES/);
    const broken = writeDataset("broken.json", "{");
    expect(() => loadReferenceDataset({ ...production, path: broken })).toThrow(/not valid JSON/);
  });

  it("DAT-06 refuses a dataset whose hash differs from the pinned hash", () => {
    const other = createBuiltDataset({
      version: "2026.11.0",
      fixture: false,
      ingredients: [record("fx_b")],
    });
    const path = writeDataset("other.json", other);
    expect(() => loadReferenceDataset({ ...production, path })).toThrow(/not the configured hash/);
  });

  it("SAF-13 with no configuration at all, loading fails (fail closed)", () => {
    expect(() => loadReferenceDataFromEnv({})).toThrow(/REFERENCE_DATA_PATH is required/);
    if (process.env.REFERENCE_DATA_PATH === undefined) {
      expect(() => loadReferenceDataFromEnv()).toThrow(/REFERENCE_DATA_PATH is required/);
    }
  });

  it("DAT-06 the package entry point exposes the loader and format, with no override option", () => {
    expect(Object.keys(api).sort()).toEqual([
      "APP_ENVIRONMENTS",
      "BUILT_DATASET_FORMAT",
      "FIXTURE_COMMENT",
      "FIXTURE_MARKER",
      "FIXTURE_PATH_PATTERN",
      "FIXTURE_VERSION_PREFIX",
      "HASH_ALGORITHM",
      "ReferenceDataError",
      "SOURCE_DATASET_SCHEMA",
      "canonicalJson",
      "computeContentHash",
      "createBuiltDataset",
      "isFixturePath",
      "loadReferenceDataFromEnv",
      "loadReferenceDataset",
      "looksLikeFixtureVersion",
      "readReferenceDataConfig",
      "sha256Hex",
      "verifyBuiltDataset",
    ]);
  });
});
