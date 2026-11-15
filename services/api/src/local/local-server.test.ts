// TEST FIXTURE: not real safety or nutrition data. Local test server guards.
import { randomBytes } from "node:crypto";
import { mkdtempSync, mkdirSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

import { createBuiltDataset, loadReferenceDataFromEnv } from "@keluargamakan/reference-data";
import { afterAll, describe, expect, it } from "vitest";

import { apiConfigFromEnv } from "../../config/api.js";
import { createCodeSender, DevCodeSender } from "../auth/code-sender.js";
import { createKeyProvider } from "../db/crypto/config.js";
import { migrate } from "../db/migrate.js";
import { MIGRATIONS } from "../db/migrations/index.js";
import { LocalOnlyError, openLocalDatabase, requireExactlyLocal } from "./local-database.js";
import { localServerSettings } from "./main-local.js";

/**
 * The local test server (`pnpm dev:local`) adds an embedded database and runs
 * with the dev code sender, the local key provider and the TEST FIXTURE
 * catalog. None of these may work outside APP_ENV=local (dev sender, key
 * provider and fixtures also in test, where the suites need them).
 */
const NOT_LOCAL: readonly (string | undefined)[] = [
  "production",
  "staging",
  undefined,
  "",
  "prod",
  "test",
  " local",
  "local ",
  "LOCAL",
  "test\n",
];
const NOT_DEVELOPMENT: readonly (string | undefined)[] = [
  "production",
  "staging",
  undefined,
  "",
  "prod",
  // Security review 2026-11-15 I2: exact match, never trimmed or case-folded.
  " local",
  "local ",
  "LOCAL",
  "test\n",
  " test",
];

const work = mkdtempSync(join(tmpdir(), "km-local-server-"));
afterAll(() => rmSync(work, { recursive: true, force: true }));

describe("NFR-10 embedded local database", () => {
  it.each(NOT_LOCAL)("is refused with APP_ENV=%j", async (appEnv) => {
    await expect(openLocalDatabase({ appEnv, dataDir: join(work, "refused") })).rejects.toThrow(
      LocalOnlyError,
    );
    expect(() => requireExactlyLocal(appEnv, "x")).toThrow(LocalOnlyError);
  });

  it("refuses a relative folder", async () => {
    await expect(openLocalDatabase({ appEnv: "local", dataDir: "pgdata" })).rejects.toThrow(
      /absolute/,
    );
  });

  it("opens with APP_ENV=local, migrates, and keeps data across restarts", async () => {
    const dataDir = join(work, "pgdata");
    const first = await openLocalDatabase({ appEnv: "local", dataDir });
    const applied = await migrate(first.executor);
    expect(applied.current).toBe(MIGRATIONS.length);
    await first.executor.execScript("CREATE TABLE local_probe (value text)");
    await first.executor.query("INSERT INTO local_probe VALUES ($1)", ["kept"]);
    await first.close();

    const second = await openLocalDatabase({ appEnv: "local", dataDir });
    const again = await migrate(second.executor);
    expect(again.applied).toEqual([]);
    const { rows } = await second.executor.query<{ value: string }>(
      "SELECT value FROM local_probe",
    );
    expect(rows).toEqual([{ value: "kept" }]);
    await second.close();
  });
});

describe("NFR-10 local test server settings", () => {
  const dataDir = join(work, "settings");
  const localEnv = { APP_ENV: "local", KEY_PROVIDER: "local", LOCAL_PGLITE_DIR: dataDir };

  it("accepts the settings dev-local.mjs passes", () => {
    expect(localServerSettings(localEnv)).toEqual({ dataDir });
  });

  it.each(NOT_LOCAL)("is refused with APP_ENV=%j", (appEnv) => {
    expect(() => localServerSettings({ ...localEnv, APP_ENV: appEnv })).toThrow(LocalOnlyError);
  });

  it("refuses a DATABASE_URL, another key provider or a relative folder", () => {
    expect(() =>
      localServerSettings({ ...localEnv, DATABASE_URL: "postgres://127.0.0.1/x" }),
    ).toThrow(/DATABASE_URL/);
    expect(() => localServerSettings({ ...localEnv, KEY_PROVIDER: "cloud_kms" })).toThrow(
      /KEY_PROVIDER/,
    );
    expect(() => localServerSettings({ ...localEnv, LOCAL_PGLITE_DIR: "pgdata" })).toThrow(
      /absolute/,
    );
  });
});

describe("NFR-10 the other local shortcuts stay refused outside development", () => {
  const localKeys = {
    KEY_PROVIDER: "local",
    LOCAL_GENERAL_DATA_KEK: randomBytes(32).toString("base64"),
    LOCAL_HEALTH_DATA_KEK: randomBytes(32).toString("base64"),
  };

  // TEST FIXTURE dataset, written outside data/ like dev-local.mjs does.
  const dataset = createBuiltDataset({
    version: "TEST-FIXTURE-local-server-1",
    fixture: true,
    ingredients: [],
  });
  const referenceDir = join(work, "reference");
  mkdirSync(referenceDir, { recursive: true });
  const referencePath = join(referenceDir, "fixture-reference-dataset.json");
  writeFileSync(referencePath, JSON.stringify(dataset), "utf8");
  const referenceEnv = {
    REFERENCE_DATA_PATH: referencePath,
    REFERENCE_DATA_SHA256: dataset.contentHash.value,
  };

  it("works in local, as the local server needs", () => {
    expect(createCodeSender({ APP_ENV: "local", CODE_SENDER: "dev" })).toBeInstanceOf(
      DevCodeSender,
    );
    expect(() => createKeyProvider({ APP_ENV: "local", ...localKeys })).not.toThrow();
    expect(loadReferenceDataFromEnv({ APP_ENV: "local", ...referenceEnv }).fixture).toBe(true);
  });

  // The relaxed sign-in limits dev-local.mjs passes (LOCAL_API_CONFIG).
  const DAY = 24 * 60 * 60;
  const relaxedLimits = JSON.stringify({
    rateLimits: {
      codeRequestPerDestination: { limit: 30, windowSeconds: 60 * 60 },
      codeRequestPerDestinationDaily: { limit: 200, windowSeconds: DAY },
      codeVerifyFailuresPerDestination: { limit: 100, windowSeconds: DAY },
      codeRequestPerClient: { limit: 200, windowSeconds: 60 * 60 },
      codeVerifyPerClient: { limit: 200, windowSeconds: 15 * 60 },
    },
  });

  it("accepts the relaxed local sign-in limits in local", () => {
    expect(
      apiConfigFromEnv({ APP_ENV: "local", API_CONFIG_JSON: relaxedLimits }).rateLimits
        .codeRequestPerDestinationDaily.limit,
    ).toBe(200);
  });

  it.each(NOT_DEVELOPMENT)("relaxed local sign-in limits refused with APP_ENV=%j", (appEnv) => {
    expect(() => apiConfigFromEnv({ APP_ENV: appEnv, API_CONFIG_JSON: relaxedLimits })).toThrow(
      /outside local and test/,
    );
  });

  it.each(NOT_DEVELOPMENT)("dev code sender refused with APP_ENV=%j", (appEnv) => {
    expect(() => createCodeSender({ APP_ENV: appEnv, CODE_SENDER: "dev" })).toThrow();
  });

  it.each(NOT_DEVELOPMENT)("local key provider refused with APP_ENV=%j", (appEnv) => {
    expect(() => createKeyProvider({ APP_ENV: appEnv, ...localKeys })).toThrow();
  });

  it.each(NOT_DEVELOPMENT)("fixture catalog refused with APP_ENV=%j", (appEnv) => {
    expect(() => loadReferenceDataFromEnv({ APP_ENV: appEnv, ...referenceEnv })).toThrow();
  });
});
