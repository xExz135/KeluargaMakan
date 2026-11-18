// TEST FIXTURE: not real safety or nutrition data. Loads fictional library
// recipes for tests (T-041). It is the only code that writes a tester label
// and test date: real recipes are recorded and tested by the content team
// through the staff-only test-record operation, which is not served yet
// (LIB-01, QUESTIONS #80). Agents never mark a real recipe as tested.
import { createHash } from "node:crypto";

import type { Schemas } from "@keluargamakan/contracts";

import type { SqlExecutor } from "../../db/executor.js";

type LocalizedText = Schemas["LocalizedText"];

export interface FixtureLine {
  readonly lineId: string;
  readonly ingredientId: string | null;
  readonly rawName: string;
  readonly quantity: {
    readonly amount: number | null;
    readonly unitCode: string | null;
    readonly unitLabel: LocalizedText | null;
  };
  readonly isOptional: boolean;
  readonly groupLabel: LocalizedText | null;
}

export interface FixtureContent {
  readonly name: LocalizedText;
  readonly description: LocalizedText;
  readonly cuisine: Schemas["Cuisine"];
  readonly regionId: string | null;
  readonly mealTypes: readonly Schemas["MealType"][];
  readonly baseServings: number;
  readonly prepMinutes: number;
  readonly cookMinutes: number;
  readonly difficulty: Schemas["RecipeDifficulty"];
  readonly tags: Schemas["RecipeTags"];
  readonly imageIds: readonly string[];
  readonly ingredients: readonly FixtureLine[];
  readonly steps: readonly Schemas["RecipeStep"][];
  readonly variants: readonly Schemas["AdminRecipeVariant"][];
}

export interface FixtureRecipe {
  readonly recipeId: string;
  readonly baseRecipeId: string | null;
  readonly testRecord: { readonly testedBy: string; readonly testedOn: string };
  readonly content: FixtureContent;
}

export interface FixtureLibrary {
  readonly $comment: string;
  readonly regions: readonly Schemas["RecipeRegion"][];
  readonly recipes: readonly FixtureRecipe[];
}

const MARKER = "TEST FIXTURE";

/** Refuses anything that is not plainly a fixture: fx_ IDs and a fixture tester label. */
function requireFixture(recipe: FixtureRecipe): void {
  if (!recipe.recipeId.startsWith("fx_")) {
    throw new Error("fixture recipes use fx_ IDs");
  }
  if (!recipe.testRecord.testedBy.includes(MARKER)) {
    throw new Error("a fixture tester label must say TEST FIXTURE");
  }
}

/** Publishes the next version of a fixture recipe (version 1 creates the recipe). */
export async function publishFixtureRecipe(
  db: SqlExecutor,
  recipe: FixtureRecipe,
): Promise<number> {
  requireFixture(recipe);
  const c = recipe.content;
  return db.transaction(async (tx) => {
    const { rows } = await tx.query<{ current_version: number }>(
      `SELECT current_version FROM library_recipe WHERE recipe_id = $1 FOR UPDATE`,
      [recipe.recipeId],
    );
    const version = (rows[0]?.current_version ?? 0) + 1;
    if (version === 1) {
      await tx.query(
        `INSERT INTO library_recipe (recipe_id, base_recipe_id, current_version) VALUES ($1, $2, 1)`,
        [recipe.recipeId, recipe.baseRecipeId],
      );
    }
    await tx.query(
      `INSERT INTO library_recipe_version
         (recipe_id, version, name, description, cuisine, region_id, meal_types, base_servings,
          prep_minutes, cook_minutes, difficulty, tag_fried, tag_santan, tag_spice_level,
          tested_by, tested_on)
       VALUES ($1, $2, $3::jsonb, $4::jsonb, $5, $6, $7::text[], $8, $9, $10, $11, $12, $13, $14,
               $15, $16::date)`,
      [
        recipe.recipeId,
        version,
        JSON.stringify(c.name),
        JSON.stringify(c.description),
        c.cuisine,
        c.regionId,
        [...c.mealTypes],
        c.baseServings,
        c.prepMinutes,
        c.cookMinutes,
        c.difficulty,
        c.tags.fried,
        c.tags.santan,
        c.tags.spiceLevel,
        recipe.testRecord.testedBy,
        recipe.testRecord.testedOn,
      ],
    );
    for (const [position, line] of c.ingredients.entries()) {
      await tx.query(
        `INSERT INTO library_recipe_line
           (recipe_id, version, line_id, position, ingredient_id, raw_name, amount, unit_code,
            unit_label, is_optional, group_label)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9::jsonb, $10, $11::jsonb)`,
        [
          recipe.recipeId,
          version,
          line.lineId,
          position,
          line.ingredientId,
          line.rawName,
          line.quantity.amount,
          line.quantity.unitCode,
          line.quantity.unitLabel === null ? null : JSON.stringify(line.quantity.unitLabel),
          line.isOptional,
          line.groupLabel === null ? null : JSON.stringify(line.groupLabel),
        ],
      );
    }
    for (const [position, step] of c.steps.entries()) {
      await tx.query(
        `INSERT INTO library_recipe_step
           (recipe_id, version, step_id, position, text, timer_seconds, ingredient_line_ids)
         VALUES ($1, $2, $3, $4, $5::jsonb, $6, $7::text[])`,
        [
          recipe.recipeId,
          version,
          step.stepId,
          position,
          JSON.stringify(step.text),
          step.timerSeconds,
          [...step.ingredientLineIds],
        ],
      );
    }
    for (const [position, imageId] of c.imageIds.entries()) {
      await tx.query(
        `INSERT INTO library_recipe_version_image (recipe_id, version, position, image_id)
         VALUES ($1, $2, $3, $4)`,
        [recipe.recipeId, version, position, imageId],
      );
    }
    for (const [position, variant] of c.variants.entries()) {
      await tx.query(
        `INSERT INTO library_recipe_variant
           (recipe_id, version, variant_id, position, label, separate_before_step_id, omitted_line_ids)
         VALUES ($1, $2, $3, $4, $5::jsonb, $6, $7::text[])`,
        [
          recipe.recipeId,
          version,
          variant.variantId,
          position,
          JSON.stringify(variant.label),
          variant.separateBeforeStepId,
          [...variant.omittedLineIds],
        ],
      );
    }
    if (version > 1) {
      await tx.query(`UPDATE library_recipe SET current_version = $2 WHERE recipe_id = $1`, [
        recipe.recipeId,
        version,
      ]);
    }
    return version;
  });
}

export async function retireFixtureRecipe(db: SqlExecutor, recipeId: string): Promise<void> {
  await db.query(
    `UPDATE library_recipe SET status = 'retired', retired_at = now() WHERE recipe_id = $1`,
    [recipeId],
  );
}

/** A fictional picture: arbitrary bytes, never a real photo. */
export async function insertFixtureImage(
  db: SqlExecutor,
  imageId: string,
  bytes: Buffer = Buffer.from(`fixture-image:${imageId}`, "utf8"),
): Promise<string> {
  if (!imageId.startsWith("fx_")) throw new Error("fixture images use fx_ IDs");
  const sha256 = createHash("sha256").update(bytes).digest("hex");
  await db.query(
    `INSERT INTO library_image (image_id, media_type, bytes, sha256, width, height, alt)
     VALUES ($1, 'image/webp', $2, $3, 640, 480, $4::jsonb)`,
    [
      imageId,
      bytes,
      sha256,
      JSON.stringify({ id: "Gambar uji fiksi", en: "Fiction test picture" }),
    ],
  );
  return sha256;
}

export async function withdrawFixtureImage(db: SqlExecutor, imageId: string): Promise<void> {
  await db.query(`UPDATE library_image SET withdrawn_at = now() WHERE image_id = $1`, [imageId]);
}

/** Loads the regions, the pictures the recipes name, and every recipe. */
export async function loadFixtureLibrary(db: SqlExecutor, library: FixtureLibrary): Promise<void> {
  if (!library.$comment.startsWith(MARKER)) throw new Error("not a TEST FIXTURE library");
  for (const region of library.regions) {
    if (!region.regionId.startsWith("fx_")) throw new Error("fixture regions use fx_ IDs");
    await db.query(`INSERT INTO library_region (region_id, display_name) VALUES ($1, $2::jsonb)`, [
      region.regionId,
      JSON.stringify(region.displayName),
    ]);
  }
  const images = new Set(library.recipes.flatMap((recipe) => recipe.content.imageIds));
  for (const imageId of images) await insertFixtureImage(db, imageId);
  // Base dishes first, so a regional variant can link to its base (LIB-04).
  const ordered = [...library.recipes].sort(
    (a, b) => Number(a.baseRecipeId !== null) - Number(b.baseRecipeId !== null),
  );
  for (const recipe of ordered) await publishFixtureRecipe(db, recipe);
}
