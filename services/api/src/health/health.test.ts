// TEST FIXTURE: not real safety or nutrition data. Fictional reference catalog (fx_kit_ IDs).
import "reflect-metadata";

import { join } from "node:path";

import { afterAll, beforeAll, describe, expect, it } from "vitest";

import { resolveKitchenConfig } from "../../config/kitchen.js";
import type { SqlExecutor } from "../db/executor.js";
import { migrate } from "../db/migrate.js";
import { pgliteTarget, type TestDatabase } from "../db/testing/databases.js";
import { startHarness } from "../http/testing/harness.js";
import { checkStaplesInReference } from "../kitchen/staples.js";
import {
  buildFixtureReference,
  REPO_ROOT,
  type BuiltFixture,
} from "../kitchen/testing/catalog-fixture.js";
import {
  referenceSourceOf,
  requireReferenceOutsideDevelopment,
  unavailableReference,
  type ReferenceSource,
} from "../reference/reference-data.js";

let fixture: BuiltFixture;
let reference: ReferenceSource;
let opened: TestDatabase;
let db: SqlExecutor;

beforeAll(async () => {
  fixture = buildFixtureReference(join(REPO_ROOT, "data", "fixtures", "kitchen-catalog"));
  reference = referenceSourceOf(fixture.verified);
  opened = await pgliteTarget.open();
  db = opened.executor;
  await migrate(db);
});
afterAll(async () => {
  fixture.cleanup();
  await opened.close();
});

/** An executor whose every statement fails, as when the database is down. */
const downDb: SqlExecutor = {
  query: () => Promise.reject(Object.assign(new Error("connection refused"), { code: "08006" })),
  execScript: () => Promise.reject(new Error("connection refused")),
  transaction: () => Promise.reject(new Error("connection refused")),
};

describe("L2 readiness probe (security review T-030)", () => {
  it("L2 ready when the database answers and a verified reference dataset is loaded", async () => {
    const h = await startHarness(db, { reference });
    try {
      const response = await h.request("GET", "/health/ready");
      expect(response.status).toBe(200);
      expect(response.body).toEqual({ status: "ready" });
      expect(response.headers["cache-control"]).toBe("no-store");
    } finally {
      await h.close();
    }
  });

  it("L2 not ready without a verified dataset, or when the database is down; no details given", async () => {
    for (const [executor, source] of [
      [db, unavailableReference],
      [downDb, reference],
    ] as const) {
      const h = await startHarness(executor, { reference: source });
      try {
        const response = await h.request("GET", "/health/ready");
        expect(response.status).toBe(503);
        expect(response.body).toEqual({ status: "not_ready" });
        expect(h.logger.text).not.toContain("connection refused");
      } finally {
        await h.close();
      }
    }
  });
});

describe("L2 startup without a verified reference dataset", () => {
  it.each(["production", "staging", undefined, "", "Local", "prod"])(
    "L2 APP_ENV %j refuses to start without a verified dataset",
    (appEnv) => {
      expect(() => requireReferenceOutsideDevelopment(unavailableReference, appEnv)).toThrow(
        /required outside APP_ENV local and test/,
      );
      expect(() => requireReferenceOutsideDevelopment(reference, appEnv)).not.toThrow();
    },
  );

  it.each(["local", "test"])(
    "L2 APP_ENV %j starts without one (catalog routes answer 503)",
    (appEnv) => {
      expect(() => requireReferenceOutsideDevelopment(unavailableReference, appEnv)).not.toThrow();
    },
  );

  it("L2 KIT-07 configured staples that cannot be checked stop startup; no staples need no dataset", () => {
    const staples = resolveKitchenConfig({
      defaultStaples: [{ ingredientId: "fx_kit_beras", category: "staples" }],
    });
    expect(() => checkStaplesInReference(staples, unavailableReference)).toThrow(
      /cannot be checked/,
    );
    expect(() => checkStaplesInReference(staples, reference)).not.toThrow();
    expect(() =>
      checkStaplesInReference(resolveKitchenConfig({}), unavailableReference),
    ).not.toThrow();
  });
});
