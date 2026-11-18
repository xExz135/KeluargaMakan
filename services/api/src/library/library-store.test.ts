// TEST FIXTURE: not real safety or nutrition data. Fictional recipes and IDs only.
import { readFileSync } from "node:fs";
import { join } from "node:path";

import { afterAll, beforeAll, describe, expect, it } from "vitest";

import type { SqlExecutor } from "../db/executor.js";
import { migrate } from "../db/migrate.js";
import { DATABASE_TARGETS, type TestDatabase } from "../db/testing/databases.js";
import { seedHousehold } from "../db/testing/seed.js";
import { REPO_ROOT } from "../kitchen/testing/catalog-fixture.js";
import { LibraryReader } from "./library-store.js";
import {
  loadFixtureLibrary,
  publishFixtureRecipe,
  retireFixtureRecipe,
  type FixtureLibrary,
  type FixtureRecipe,
} from "./testing/fixture-library.js";

const FIXTURE: FixtureLibrary = JSON.parse(
  readFileSync(join(REPO_ROOT, "data", "fixtures", "library", "recipes.json"), "utf8"),
) as FixtureLibrary;
const base = FIXTURE.recipes.find((recipe) => recipe.recipeId === "fx_rcp_nasi_goreng");
if (base === undefined) throw new Error("fixture recipe missing");

function variantOf(id: string, change: Partial<FixtureRecipe["content"]>): FixtureRecipe {
  return { ...base!, recipeId: id, baseRecipeId: null, content: { ...base!.content, ...change } };
}

async function rejects(promise: Promise<unknown>): Promise<string> {
  try {
    await promise;
  } catch (error) {
    return error instanceof Error ? error.message : String(error);
  }
  throw new Error("expected the database to refuse");
}

for (const target of DATABASE_TARGETS) {
  if (target.skipReason !== null) {
    describe(`library storage: ${target.name}`, () => {
      it.skip(`skipped: ${target.skipReason}`, () => undefined);
    });
    continue;
  }

  describe(`library storage: ${target.name}`, () => {
    let opened: TestDatabase;
    let db: SqlExecutor;

    beforeAll(async () => {
      opened = await target.open();
      db = opened.executor;
      await migrate(db);
      await loadFixtureLibrary(db, FIXTURE);
    });
    afterAll(async () => {
      await opened.close();
    });

    it("LIB-03 LIB-04 every LIB-03 field is stored and read back from the servable view", async () => {
      const library = await new LibraryReader(db).current();
      const recipe = library.byId.get("fx_rcp_nasi_goreng");
      expect(recipe).toMatchObject({
        version: 1,
        cuisine: "indonesian",
        region: { regionId: "fx_reg_jawa" },
        mealTypes: ["lunch", "dinner"],
        baseServings: 4,
        prepMinutes: 10,
        cookMinutes: 15,
        difficulty: "easy",
        tags: { fried: true, santan: false, spiceLevel: "medium" },
        nutritionPerServing: { status: "unavailable", ranges: [] },
        testRecord: { testedBy: "Tim Uji Fiksi (TEST FIXTURE)", testedOn: "2026-10-01" },
        images: [{ imageId: "fx_img_nasi_goreng", width: 640, height: 480 }],
      });
      expect(recipe?.lines.map((line) => [line.lineId, line.ingredientId, line.amount])).toEqual([
        ["l1", "fx_lib_nasi", 600],
        ["l2", "fx_lib_bawang", 5],
        ["l3", "fx_lib_cabai", 3],
        ["l4", "fx_lib_terasi", 1],
        ["l5", "fx_lib_kecap", 2],
      ]);
      expect(recipe?.lines[2]?.isOptional).toBe(true);
      expect(recipe?.steps.map((step) => step.timerSeconds)).toEqual([120, null, 60]);
      expect(library.byId.get("fx_rcp_nasi_goreng_padang")?.baseRecipeId).toBe(
        "fx_rcp_nasi_goreng",
      );
      expect(library.byId.get("fx_rcp_gado_gado")?.lines[2]?.ingredientId).toBeNull();
      const variants = await db.query<{ omitted_line_ids: string[] }>(
        `SELECT omitted_line_ids FROM library_recipe_variant WHERE recipe_id = 'fx_rcp_nasi_goreng'`,
      );
      expect(variants.rows.map((row) => row.omitted_line_ids)).toEqual([["l4"]]);
    });

    it("LIB-01 NFR-23 a version cannot be stored without a tester and a test date", async () => {
      for (const column of ["tested_by", "tested_on"]) {
        const message = await rejects(
          db.transaction(async (tx) => {
            await tx.query(
              `INSERT INTO library_recipe (recipe_id, current_version) VALUES ('fx_rcp_tanpa_uji', 1)`,
            );
            await tx.query(
              `INSERT INTO library_recipe_version
                 (recipe_id, version, name, description, cuisine, meal_types, base_servings,
                  prep_minutes, cook_minutes, difficulty, tag_fried, tag_santan, tag_spice_level,
                  tested_by, tested_on)
               VALUES ('fx_rcp_tanpa_uji', 1, '{"id":"a","en":"a"}', '{"id":"a","en":"a"}',
                       'indonesian', ARRAY['lunch'], 2, 1, 1, 'easy', false, false, 'not_spicy',
                       ${column === "tested_by" ? "NULL" : "'Tim'"},
                       ${column === "tested_on" ? "NULL" : "'2026-10-01'"})`,
            );
          }),
        );
        expect(message, column).toMatch(/null value|not-null/i);
      }
      const message = await rejects(
        publishFixtureRecipe(db, {
          ...variantOf("fx_rcp_masa_depan", {}),
          testRecord: { testedBy: "Tim Uji Fiksi (TEST FIXTURE)", testedOn: "2999-01-01" },
        }),
      );
      expect(message).toMatch(/tested_before_publication/);
    });

    it("LIB-01 LIB-11 only the current version of a published recipe is servable; retirement is final", async () => {
      await publishFixtureRecipe(db, variantOf("fx_rcp_pensiun", {}));
      await publishFixtureRecipe(db, variantOf("fx_rcp_pensiun", {}));
      const servable = await db.query<{ version: number }>(
        `SELECT version FROM library_servable_version WHERE recipe_id = 'fx_rcp_pensiun'`,
      );
      expect(servable.rows.map((row) => Number(row.version))).toEqual([2]);
      await retireFixtureRecipe(db, "fx_rcp_pensiun");
      expect(
        (
          await db.query(
            `SELECT 1 FROM library_servable_version WHERE recipe_id = 'fx_rcp_pensiun'`,
          )
        ).rows,
      ).toEqual([]);
      expect(
        await rejects(
          db.query(`UPDATE library_recipe SET status = 'published', retired_at = NULL
                     WHERE recipe_id = 'fx_rcp_pensiun'`),
        ),
      ).toMatch(/LIB-11/);
      // An older version never becomes current again.
      await publishFixtureRecipe(db, variantOf("fx_rcp_mundur", {}));
      await publishFixtureRecipe(db, variantOf("fx_rcp_mundur", {}));
      expect(
        await rejects(
          db.query(
            `UPDATE library_recipe SET current_version = 1 WHERE recipe_id = 'fx_rcp_mundur'`,
          ),
        ),
      ).toMatch(/LIB-11/);
    });

    it("LIB-11 DAT-06 published content never changes and is never deleted", async () => {
      const refused = [
        `UPDATE library_recipe_version SET tested_by = 'lain' WHERE recipe_id = 'fx_rcp_sayur_lodeh'`,
        `UPDATE library_recipe_line SET ingredient_id = NULL WHERE recipe_id = 'fx_rcp_sayur_lodeh'`,
        `UPDATE library_recipe_step SET timer_seconds = 1 WHERE recipe_id = 'fx_rcp_sayur_lodeh'`,
        `DELETE FROM library_recipe_line WHERE recipe_id = 'fx_rcp_sayur_lodeh'`,
        `DELETE FROM library_recipe_version WHERE recipe_id = 'fx_rcp_sayur_lodeh'`,
        `DELETE FROM library_recipe WHERE recipe_id = 'fx_rcp_sayur_lodeh'`,
        `UPDATE library_image SET bytes = '\\x00' WHERE image_id = 'fx_img_nasi_goreng'`,
        `INSERT INTO library_recipe_line (recipe_id, version, line_id, position, ingredient_id,
           raw_name, is_optional)
         VALUES ('fx_rcp_sayur_lodeh', 1, 'l9', 9, 'fx_lib_udang', 'Udang fiksi', false)`,
      ];
      for (const sql of refused) {
        expect(await rejects(db.query(sql)), sql).toMatch(/LIB-11|never|cannot/);
      }
    });

    it("SAF-11 T-040 M2 a portion variant may leave out only lines added at or after the separation", async () => {
      const early = await rejects(
        publishFixtureRecipe(
          db,
          variantOf("fx_rcp_m2_awal", {
            variants: [
              {
                variantId: "v1",
                label: { id: "a", en: "a" },
                separateBeforeStepId: "s3",
                omittedLineIds: ["l2"],
              },
            ],
          }),
        ),
      );
      expect(early).toMatch(/T-040 M2/);
      const unused = await rejects(
        publishFixtureRecipe(
          db,
          variantOf("fx_rcp_m2_tak_dipakai", {
            steps: base.content.steps.map((step) =>
              step.stepId === "s3" ? { ...step, ingredientLineIds: [] } : step,
            ),
            variants: [
              {
                variantId: "v1",
                label: { id: "a", en: "a" },
                separateBeforeStepId: "s3",
                omittedLineIds: ["l4"],
              },
            ],
          }),
        ),
      );
      expect(unused).toMatch(/T-040 M2/);
      const unknownStep = await rejects(
        publishFixtureRecipe(
          db,
          variantOf("fx_rcp_m2_langkah", {
            variants: [
              {
                variantId: "v1",
                label: { id: "a", en: "a" },
                separateBeforeStepId: "s9",
                omittedLineIds: ["l4"],
              },
            ],
          }),
        ),
      );
      expect(unknownStep).toMatch(/foreign key/i);
      // Nothing of a refused version was stored.
      expect(
        (await db.query(`SELECT 1 FROM library_recipe WHERE recipe_id LIKE 'fx_rcp_m2_%'`)).rows,
      ).toEqual([]);
    });

    it("CKM-06 LIB-03 a step may only use lines of its own version", async () => {
      const message = await rejects(
        publishFixtureRecipe(
          db,
          variantOf("fx_rcp_langkah_salah", {
            steps: [
              {
                stepId: "s1",
                text: { id: "a", en: "a" },
                timerSeconds: null,
                ingredientLineIds: ["l99"],
              },
            ],
            variants: [],
          }),
        ),
      );
      expect(message).toMatch(/CKM-06/);
    });

    it("LIB-04 a regional variant links to a base dish, never to another variant", async () => {
      const message = await rejects(
        publishFixtureRecipe(db, {
          ...variantOf("fx_rcp_varian_varian", { variants: [] }),
          baseRecipeId: "fx_rcp_nasi_goreng_padang",
        }),
      );
      expect(message).toMatch(/LIB-04/);
    });

    it("NUT-05 stored nutrition is unavailable or a range with high above low, never one number", async () => {
      for (const [value, ok] of [
        [`{"status":"unavailable","ranges":[]}`, true],
        [
          `{"status":"estimate","ranges":[{"nutrient":"energy","low":1,"high":2,"unit":"kcal"}]}`,
          true,
        ],
        [
          `{"status":"estimate","ranges":[{"nutrient":"energy","low":2,"high":2,"unit":"kcal"}]}`,
          false,
        ],
        [
          `{"status":"estimate","ranges":[{"nutrient":"energy","low":3,"high":2,"unit":"kcal"}]}`,
          false,
        ],
        [`{"status":"estimate","ranges":[]}`, false],
        [
          `{"status":"unavailable","ranges":[{"nutrient":"energy","low":1,"high":2,"unit":"kcal"}]}`,
          false,
        ],
        [`{"status":"exact","ranges":[]}`, false],
      ] as const) {
        const { rows } = await db.query<{ ok: boolean }>(
          `SELECT library_nutrition_ok($1::jsonb) AS ok`,
          [value],
        );
        expect(rows[0]?.ok, value).toBe(ok);
      }
    });

    it("SAF-14 T-025 N2 a recipe halal record needs the safety log of the same check, with the same versions", async () => {
      const home = await seedHousehold(db);
      const checkId = "6f1d2c3b-4a59-4e6f-8a7b-9c0d1e2f3a4b";
      const insert = (reference: string) =>
        db.query(
          `INSERT INTO recipe_halal_log (check_id, household_id, log_format, subject_kind, subject_id,
             subject_version, evaluated_at, rule_set_version, reference_version, status, lines, findings)
           VALUES ($1, $2, 'keluargamakan.recipe-halal-log/1', 'library_recipe', 'fx_rcp_sayur_lodeh',
             '1', '2026-11-16T03:00:00.000Z', '1.1.0', $3, 'halal', '[]', '[]')`,
          [checkId, home.householdId, reference],
        );
      expect(await rejects(insert("TEST-FIXTURE-1@sha256:ab"))).toMatch(/SAF-14/);
      await db.query(
        `INSERT INTO safety_log (id, household_id, log_format, subject_kind, subject_id,
           subject_version, evaluated_at, rule_set_version, reference_version)
         VALUES ($1, $2, 'keluargamakan.safety-log/1', 'library_recipe', 'fx_rcp_sayur_lodeh', '1',
           '2026-11-16T03:00:00.000Z', '1.1.0', 'TEST-FIXTURE-1@sha256:ab')`,
        [checkId, home.householdId],
      );
      expect(await rejects(insert("TEST-FIXTURE-2@sha256:cd"))).toMatch(/SAF-14/);
      await insert("TEST-FIXTURE-1@sha256:ab");
      expect(
        await rejects(
          db.query(`UPDATE recipe_halal_log SET status = 'not_halal' WHERE check_id = $1`, [
            checkId,
          ]),
        ),
      ).toMatch(/append-only/);
      // DAT-05: it goes with its safety log.
      await db.query(`DELETE FROM safety_log WHERE id = $1`, [checkId]);
      expect(
        (await db.query(`SELECT 1 FROM recipe_halal_log WHERE check_id = $1`, [checkId])).rows,
      ).toEqual([]);
    });
  });
}
