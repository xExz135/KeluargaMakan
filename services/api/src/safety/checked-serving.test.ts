// TEST FIXTURE: not real safety or nutrition data. Fictional ingredients and members.
import { readdirSync, readFileSync, statSync } from "node:fs";
import { join, relative, sep } from "node:path";
import { fileURLToPath } from "node:url";

import type { ReferenceDataset } from "@keluargamakan/cek-aman";
import type { VerifiedReference } from "@keluargamakan/reference-data";
import { afterAll, beforeAll, describe, expect, it } from "vitest";

import type { SqlExecutor } from "../db/executor.js";
import { HealthDataKeys } from "../db/health-data-keys.js";
import { migrate } from "../db/migrate.js";
import { readRecipeHalalLog } from "../db/recipe-halal-log.js";
import { recordHealthConsent, withdrawHealthConsent } from "../db/consent.js";
import { RulesChangedError } from "../db/errors.js";
import { insertHardRule } from "../db/hard-rules.js";
import { readSafetyLog } from "../db/safety-log.js";
import { pgliteTarget, type TestDatabase } from "../db/testing/databases.js";
import { randomLocalKeys, seedHousehold, type SeededHousehold } from "../db/testing/seed.js";
import { referenceSourceOf, type LoadedReference } from "../reference/reference-data.js";
import {
  checkFood,
  serveChecked,
  type CheckContext,
  type FoodCandidate,
} from "./checked-serving.js";
import { loadCheckEaters } from "./eaters.js";

const SRC = fileURLToPath(new URL("..", import.meta.url));
const SEAM = join("safety", "checked-serving.ts");

/** Every non-test TypeScript file of services/api/src, relative to it. */
function sourceFiles(dir: string = SRC): string[] {
  return readdirSync(dir).flatMap((name) => {
    const full = join(dir, name);
    if (statSync(full).isDirectory()) return sourceFiles(full);
    return name.endsWith(".ts") && !name.endsWith(".test.ts") ? [relative(SRC, full)] : [];
  });
}

const isTestingSupport = (path: string) => path.split(sep).includes("testing");

describe("T-025 N4 SAF-02 one module serves safety results", () => {
  it("T-025 N4 evaluate, evaluateWithLog, deriveRecipeHalal and deriveRecipeHalalWithLog are called only from the serving module", () => {
    const calls = /\b(evaluate|evaluateWithLog|deriveRecipeHalal|deriveRecipeHalalWithLog)\s*\(/;
    const offenders = sourceFiles()
      .filter((path) => path !== SEAM)
      .filter((path) => calls.test(readFileSync(join(SRC, path), "utf8")));
    expect(offenders).toEqual([]);
    expect(calls.test(readFileSync(join(SRC, SEAM), "utf8"))).toBe(true);
  });

  it("T-025 N4 no other module imports those engine functions, so none can call them by another name", () => {
    const names = ["evaluate", "evaluateWithLog", "deriveRecipeHalal", "deriveRecipeHalalWithLog"];
    const importBlock = /import\s*(type\s*)?\{([^}]*)\}\s*from\s*["']@keluargamakan\/cek-aman["']/g;
    const offenders: string[] = [];
    for (const path of sourceFiles()) {
      if (path === SEAM) continue;
      for (const match of readFileSync(join(SRC, path), "utf8").matchAll(importBlock)) {
        if (match[1] !== undefined) continue; // type-only import
        const imported = (match[2] ?? "")
          .split(",")
          .map(
            (part) =>
              part
                .trim()
                .replace(/^type\s+/, "")
                .split(/\s+as\s+/)[0],
          )
          .filter((part) => part !== undefined && part !== "");
        if (imported.some((name) => names.includes(name ?? ""))) offenders.push(path);
      }
      if (
        /import\s*\*\s*as\s+\w+\s+from\s*["']@keluargamakan\/cek-aman["']/.test(
          readFileSync(join(SRC, path), "utf8"),
        )
      ) {
        offenders.push(path);
      }
    }
    expect(offenders).toEqual([]);
  });

  it("LIB-01 household code reads library content only through the servable view", () => {
    // SQL that names the recipe or version table itself (the subject kind
    // "library_recipe" is not a table reference).
    const direct = /\b(FROM|JOIN|INTO|UPDATE)\s+library_recipe(_version)?\b(?!_)/i;
    const offenders = sourceFiles()
      .filter((path) => !path.startsWith(join("db", "migrations")) && !isTestingSupport(path))
      .filter((path) => direct.test(readFileSync(join(SRC, path), "utf8")));
    expect(offenders).toEqual([]);
  });

  it("LIB-01 the fixture loader, the only writer of a tester label, is never imported by served code", () => {
    const offenders = sourceFiles()
      .filter((path) => !isTestingSupport(path))
      .filter((path) => /testing\/fixture-library/.test(readFileSync(join(SRC, path), "utf8")));
    expect(offenders).toEqual([]);
  });
});

// ---------------------------------------------------------------- the two steps

const verified = (data: ReferenceDataset): VerifiedReference => ({
  version: data.version,
  contentHash: "0".repeat(64),
  fixture: true,
  ingredientCount: data.ingredients.length,
  referenceVersion: data.version,
  reference: data,
});

const ingredient = (id: string, contains: string[]) => ({
  id,
  displayName: { id: `${id} fiksi`, en: `${id} fiction` },
  localNames: [],
  category: "protein",
  components: { verification: "verified", ingredientIds: [] },
  allergens: { verification: "verified", contains, mayContain: [] },
  halal: { verification: "verified", value: "halal", nonHalalSources: [] },
  diet: { verification: "verified", vegetarian: "suitable", vegan: "suitable" },
  brandVaries: false,
  brandVariants: [],
  tkpiCode: null,
});

let opened: TestDatabase;
let db: SqlExecutor;
let keys: HealthDataKeys;
let home: SeededHousehold;
let reference: LoadedReference;
let managerStamp: string;

const stampOf = async (profileId: string) =>
  (await db.query<{ s: string }>(`SELECT health_rules_stamp($1) AS s`, [profileId])).rows[0]?.s ??
  "";

beforeAll(async () => {
  opened = await pgliteTarget.open();
  db = opened.executor;
  await migrate(db);
  keys = new HealthDataKeys(randomLocalKeys());
  home = await seedHousehold(db);
  const source = referenceSourceOf(
    verified({
      schema: "keluargamakan.reference.ingredients/1",
      version: "TEST-FIXTURE-seam-1@sha256:00",
      ingredients: [ingredient("fx_s_udang", ["shrimp"]), ingredient("fx_s_nasi", [])],
    } as unknown as ReferenceDataset),
  );
  const loaded = source.current();
  if (loaded === null) throw new Error("no reference");
  reference = loaded;
  managerStamp = await stampOf(home.managerProfileId);
});
afterAll(async () => {
  await opened.close();
});

const candidate: FoodCandidate = {
  subject: { kind: "library_recipe", id: "fx_s_resep", version: "1" },
  lines: [
    { lineId: "l1", ingredientId: "fx_s_nasi", rawName: "Nasi fiksi" },
    { lineId: "l2", ingredientId: "fx_s_udang", rawName: "Udang fiksi" },
  ],
};

function context(): CheckContext {
  return {
    householdId: home.householdId,
    eaters: [
      {
        memberId: home.managerProfileId,
        rulesConsent: "given",
        hardRules: [{ ruleId: "fx-rule-1", type: "allergy", allergen: "shrimp" }],
        rulesStamp: managerStamp,
      },
    ],
    recordedBrands: new Map(),
    reference,
    evaluatedAt: new Date("2026-11-16T03:00:00.000Z"),
  };
}

describe("SAF-02 SAF-14 checkFood and serveChecked", () => {
  it("SAF-02 checkFood writes nothing; serveChecked logs both records under one checkId, then serves", async () => {
    const pending = checkFood(context(), candidate);
    expect(pending?.notSafeFor).toEqual([home.managerProfileId]);
    expect(
      (await db.query(`SELECT 1 FROM safety_log WHERE household_id = $1`, [home.householdId])).rows,
    ).toEqual([]);
    const [served] = await serveChecked(db, keys, [pending!]);
    expect(served?.safety.members[0]?.status).toBe("not_safe");
    const checkId = served?.safety.checkId ?? "";
    expect((await readSafetyLog(db, keys, home.householdId, checkId)).subject.id).toBe(
      "fx_s_resep",
    );
    expect((await readRecipeHalalLog(db, home.householdId, checkId)).status).toBe("halal");
  });

  it("SAF-02 a check is served once only", async () => {
    const pending = checkFood(context(), candidate)!;
    await serveChecked(db, keys, [pending]);
    await expect(serveChecked(db, keys, [pending])).rejects.toThrow(/served once/);
    await expect(
      serveChecked(db, keys, [{ subjectId: "x", statuses: [], notSafeFor: [] }]),
    ).rejects.toThrow(/served once/);
  });

  it("SAF-09 SAF-02 an item Cek Aman refuses to check gives no check at all", () => {
    const duplicateLines: FoodCandidate = {
      ...candidate,
      lines: [candidate.lines[0]!, candidate.lines[0]!],
    };
    expect(checkFood(context(), duplicateLines)).toBeNull();
    // A reason that cannot be shown in full (no such line name) is left out too.
    expect(
      checkFood(context(), {
        ...candidate,
        lines: [{ lineId: "l1", ingredientId: "fx_s_udang", rawName: " " }],
      }),
    ).toBeNull();
  });

  it("T-025 N4 when the log write fails nothing is stored and nothing is returned", async () => {
    const pending = checkFood(context(), candidate)!;
    const failing: SqlExecutor = {
      query: (text, params) =>
        text.includes("INSERT INTO recipe_halal_log")
          ? Promise.reject(new Error("injected"))
          : db.query(text, params),
      execScript: (sql) => db.execScript(sql),
      transaction: (fn) =>
        db.transaction((tx) =>
          fn({
            query: (text, params) =>
              text.includes("INSERT INTO recipe_halal_log")
                ? Promise.reject(new Error("injected"))
                : tx.query(text, params),
            execScript: (sql) => tx.execScript(sql),
            transaction: (inner) => inner(tx),
          }),
        ),
    };
    const before = (
      await db.query<{ n: number }>(
        `SELECT count(*)::int AS n FROM safety_log WHERE household_id = $1`,
        [home.householdId],
      )
    ).rows[0]?.n;
    await expect(serveChecked(failing, keys, [pending])).rejects.toThrow();
    const after = (
      await db.query<{ n: number }>(
        `SELECT count(*)::int AS n FROM safety_log WHERE household_id = $1`,
        [home.householdId],
      )
    ).rows[0]?.n;
    expect(after).toBe(before);
  });
});

describe("L1 SAF-12 PRF-11 SET-04 a check made with rules or consent that changed is never served", () => {
  const logsOf = async (householdId: string) =>
    (
      await db.query<{ n: number }>(
        `SELECT count(*)::int AS n FROM safety_log WHERE household_id = $1`,
        [householdId],
      )
    ).rows[0]?.n;

  async function consentedHousehold(): Promise<SeededHousehold> {
    const household = await seedHousehold(db);
    await recordHealthConsent(db, {
      householdId: household.householdId,
      profileId: household.managerProfileId,
      decision: "given",
      textVersion: "health-data-draft-1",
      language: "id",
      recordedByAccountId: household.accountId,
    });
    return household;
  }

  async function checkNow(household: SeededHousehold) {
    const eaters = await loadCheckEaters(db, keys, household.householdId, {
      mode: "only_me",
      memberIds: [],
    });
    const pending = checkFood(
      {
        householdId: household.householdId,
        eaters,
        recordedBrands: new Map(),
        reference,
        evaluatedAt: new Date(),
      },
      candidate,
    );
    if (pending === null) throw new Error("not checked");
    return pending;
  }

  it("L1 P2 a rule added after the check: nothing is served (no stale Safe) and nothing is logged", async () => {
    const household = await consentedHousehold();
    const pending = await checkNow(household);
    expect(pending.statuses[0]?.status).toBe("safe");
    await insertHardRule(db, keys, {
      householdId: household.householdId,
      profileId: household.managerProfileId,
      rule: { type: "allergy", allergen: "shrimp" },
      mappingConfirmedBy: null,
    });
    await expect(serveChecked(db, keys, [pending])).rejects.toBeInstanceOf(RulesChangedError);
    expect(await logsOf(household.householdId)).toBe(0);
    // Checked again with the current rules, the dish is Not safe.
    const [served] = await serveChecked(db, keys, [await checkNow(household)]);
    expect(served?.safety.members[0]?.status).toBe("not_safe");
  });

  it("L1 P3 consent withdrawn after the check: no body with the withdrawn rule text is returned", async () => {
    const household = await consentedHousehold();
    await insertHardRule(db, keys, {
      householdId: household.householdId,
      profileId: household.managerProfileId,
      rule: { type: "free_text", freeText: "alergi udang fiksi", mappedIngredientIds: [] },
      mappingConfirmedBy: null,
    });
    const pending = await checkNow(household);
    await withdrawHealthConsent(db, {
      householdId: household.householdId,
      profileId: household.managerProfileId,
      withdrawnAt: new Date(),
      deletionWindowDays: 30,
    });
    let served: unknown = null;
    await expect(
      serveChecked(db, keys, [pending]).then((result) => {
        served = result;
      }),
    ).rejects.toBeInstanceOf(RulesChangedError);
    expect(served).toBeNull();
    expect(await logsOf(household.householdId)).toBe(0);
    const [again] = await serveChecked(db, keys, [await checkNow(household)]);
    expect(again?.safety.members[0]).toMatchObject({ rulesConsent: "withdrawn", reasons: [] });
    expect(JSON.stringify(again)).not.toContain("alergi udang fiksi");
  });
});
