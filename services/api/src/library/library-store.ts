import type { Schemas } from "@keluargamakan/contracts";

import { withDbErrors } from "../db/errors.js";
import type { SqlExecutor } from "../db/executor.js";
import { isReferenceId } from "../db/ids.js";

/**
 * Library reads for household routes (LIB-01, LIB-03, LIB-04, LIB-08).
 *
 * LIB-01 gate: every query here reads recipe content through the view
 * `library_servable_version` (migration 0012), which holds only the current
 * version of a published, not retired recipe with a recorded tester and test
 * date. No query here names the recipe or version tables directly (a source
 * test checks this), and nothing here writes. Pictures are served only while
 * not withdrawn and while a servable version uses them.
 *
 * The whole servable library is read at once and kept per `libraryVersion`
 * (the `library_release` counter, which every publish, retirement, region
 * change and withdrawal moves), so a search reads one row while nothing
 * changed.
 */

type LocalizedText = Schemas["LocalizedText"];

export interface LibraryLine {
  readonly lineId: string;
  readonly position: number;
  readonly ingredientId: string | null;
  readonly rawName: string;
  readonly amount: number | null;
  readonly unitCode: string | null;
  readonly unitLabel: LocalizedText | null;
  readonly isOptional: boolean;
  readonly groupLabel: LocalizedText | null;
}

export interface LibraryStep {
  readonly stepId: string;
  readonly position: number;
  readonly text: LocalizedText;
  readonly timerSeconds: number | null;
  readonly ingredientLineIds: readonly string[];
}

export interface LibraryImageRef {
  readonly imageId: string;
  readonly width: number;
  readonly height: number;
  readonly alt: LocalizedText;
}

export interface LibraryRegion {
  readonly regionId: string;
  readonly displayName: LocalizedText;
}

export interface LibraryRecipe {
  readonly recipeId: string;
  readonly version: number;
  readonly baseRecipeId: string | null;
  readonly name: LocalizedText;
  readonly description: LocalizedText;
  readonly cuisine: Schemas["Cuisine"];
  readonly region: LibraryRegion | null;
  readonly mealTypes: readonly Schemas["MealType"][];
  readonly baseServings: number;
  readonly prepMinutes: number;
  readonly cookMinutes: number;
  readonly difficulty: Schemas["RecipeDifficulty"];
  readonly tags: Schemas["RecipeTags"];
  readonly nutritionPerServing: Schemas["NutritionPerServing"];
  readonly testRecord: { readonly testedBy: string; readonly testedOn: string };
  readonly lines: readonly LibraryLine[];
  readonly steps: readonly LibraryStep[];
  readonly images: readonly LibraryImageRef[];
}

export interface LoadedLibrary {
  /** Contract `libraryVersion`. */
  readonly libraryVersion: string;
  /** Every servable recipe, by recipe ID order. */
  readonly recipes: readonly LibraryRecipe[];
  readonly byId: ReadonlyMap<string, LibraryRecipe>;
}

interface VersionRow {
  recipe_id: string;
  version: number;
  base_recipe_id: string | null;
  name: LocalizedText;
  description: LocalizedText;
  cuisine: Schemas["Cuisine"];
  region_id: string | null;
  region_name: LocalizedText | null;
  meal_types: Schemas["MealType"][];
  base_servings: number;
  prep_minutes: number;
  cook_minutes: number;
  difficulty: Schemas["RecipeDifficulty"];
  tag_fried: boolean;
  tag_santan: boolean;
  tag_spice_level: Schemas["RecipeSpiceLevel"];
  nutrition_per_serving: Schemas["NutritionPerServing"];
  tested_by: string;
  tested_on: string;
}

interface LineRow {
  recipe_id: string;
  line_id: string;
  position: number;
  ingredient_id: string | null;
  raw_name: string;
  amount: number | null;
  unit_code: string | null;
  unit_label: LocalizedText | null;
  is_optional: boolean;
  group_label: LocalizedText | null;
}

interface StepRow {
  recipe_id: string;
  step_id: string;
  position: number;
  text: LocalizedText;
  timer_seconds: number | null;
  ingredient_line_ids: string[];
}

interface ImageRow {
  recipe_id: string;
  image_id: string;
  width: number;
  height: number;
  alt: LocalizedText;
}

const text = (value: LocalizedText): LocalizedText => ({ id: value.id, en: value.en });
const textOrNull = (value: LocalizedText | null): LocalizedText | null =>
  value === null ? null : text(value);

function grouped<R extends { recipe_id: string }>(rows: readonly R[]): Map<string, R[]> {
  const map = new Map<string, R[]>();
  for (const row of rows) {
    const list = map.get(row.recipe_id);
    if (list === undefined) map.set(row.recipe_id, [row]);
    else list.push(row);
  }
  return map;
}

async function readRelease(db: SqlExecutor): Promise<string> {
  const { rows } = await withDbErrors(() =>
    db.query<{ release: string }>(`SELECT release::text AS release FROM library_release`),
  );
  const release = rows[0]?.release;
  if (release === undefined) throw new Error("library_release has no row");
  return `lib-${release}`;
}

async function readLibrary(db: SqlExecutor, libraryVersion: string): Promise<LoadedLibrary> {
  return withDbErrors(async () => {
    const versions = (
      await db.query<VersionRow>(
        `SELECT s.recipe_id, s.version, s.base_recipe_id, s.name, s.description, s.cuisine,
                s.region_id, g.display_name AS region_name, s.meal_types, s.base_servings,
                s.prep_minutes, s.cook_minutes, s.difficulty, s.tag_fried, s.tag_santan,
                s.tag_spice_level, s.nutrition_per_serving, s.tested_by, s.tested_on::text AS tested_on
           FROM library_servable_version s
           LEFT JOIN library_region g ON g.region_id = s.region_id
          ORDER BY s.recipe_id`,
      )
    ).rows;
    const lines = grouped(
      (
        await db.query<LineRow>(
          `SELECT l.recipe_id, l.line_id, l.position, l.ingredient_id, l.raw_name, l.amount,
                  l.unit_code, l.unit_label, l.is_optional, l.group_label
             FROM library_recipe_line l
             JOIN library_servable_version s ON s.recipe_id = l.recipe_id AND s.version = l.version
            ORDER BY l.recipe_id, l.position`,
        )
      ).rows,
    );
    const steps = grouped(
      (
        await db.query<StepRow>(
          `SELECT t.recipe_id, t.step_id, t.position, t.text, t.timer_seconds, t.ingredient_line_ids
             FROM library_recipe_step t
             JOIN library_servable_version s ON s.recipe_id = t.recipe_id AND s.version = t.version
            ORDER BY t.recipe_id, t.position`,
        )
      ).rows,
    );
    const images = grouped(
      (
        await db.query<ImageRow>(
          `SELECT v.recipe_id, i.image_id, i.width, i.height, i.alt
             FROM library_recipe_version_image v
             JOIN library_servable_version s ON s.recipe_id = v.recipe_id AND s.version = v.version
             JOIN library_image i ON i.image_id = v.image_id
            WHERE i.withdrawn_at IS NULL
            ORDER BY v.recipe_id, v.position`,
        )
      ).rows,
    );

    const recipes = versions.map((row): LibraryRecipe =>
      Object.freeze({
        recipeId: row.recipe_id,
        version: Number(row.version),
        baseRecipeId: row.base_recipe_id,
        name: text(row.name),
        description: text(row.description),
        cuisine: row.cuisine,
        region:
          row.region_id === null || row.region_name === null
            ? null
            : { regionId: row.region_id, displayName: text(row.region_name) },
        mealTypes: [...row.meal_types],
        baseServings: Number(row.base_servings),
        prepMinutes: Number(row.prep_minutes),
        cookMinutes: Number(row.cook_minutes),
        difficulty: row.difficulty,
        tags: { fried: row.tag_fried, santan: row.tag_santan, spiceLevel: row.tag_spice_level },
        nutritionPerServing: {
          status: row.nutrition_per_serving.status,
          ranges: row.nutrition_per_serving.ranges.map((range) => ({ ...range })),
        },
        testRecord: { testedBy: row.tested_by, testedOn: row.tested_on },
        lines: (lines.get(row.recipe_id) ?? []).map((line) => ({
          lineId: line.line_id,
          position: Number(line.position),
          ingredientId: line.ingredient_id,
          rawName: line.raw_name,
          amount: line.amount === null ? null : Number(line.amount),
          unitCode: line.unit_code,
          unitLabel: textOrNull(line.unit_label),
          isOptional: line.is_optional,
          groupLabel: textOrNull(line.group_label),
        })),
        steps: (steps.get(row.recipe_id) ?? []).map((step) => ({
          stepId: step.step_id,
          position: Number(step.position),
          text: text(step.text),
          timerSeconds: step.timer_seconds === null ? null : Number(step.timer_seconds),
          ingredientLineIds: [...step.ingredient_line_ids],
        })),
        images: (images.get(row.recipe_id) ?? []).map((image) => ({
          imageId: image.image_id,
          width: Number(image.width),
          height: Number(image.height),
          alt: text(image.alt),
        })),
      }),
    );
    return Object.freeze({
      libraryVersion,
      recipes: Object.freeze(recipes),
      byId: new Map(recipes.map((recipe) => [recipe.recipeId, recipe])),
    });
  });
}

/** Reads of the servable library, kept while `libraryVersion` stays the same. */
export class LibraryReader {
  readonly #db: SqlExecutor;
  #cached: LoadedLibrary | null = null;

  constructor(db: SqlExecutor) {
    this.#db = db;
  }

  /**
   * The servable library now. When the library changes while it is being
   * read, it is read again (at most twice more); it is never mixed from two
   * versions.
   */
  async current(): Promise<LoadedLibrary> {
    for (let attempt = 0; attempt < 3; attempt += 1) {
      const before = await readRelease(this.#db);
      const cached = this.#cached;
      if (cached !== null && cached.libraryVersion === before) return cached;
      const loaded = await readLibrary(this.#db, before);
      if ((await readRelease(this.#db)) === before) {
        this.#cached = loaded;
        return loaded;
      }
    }
    throw new LibraryChangingError();
  }
}

/** The library kept changing while it was read; the request may be retried. */
export class LibraryChangingError extends Error {
  constructor() {
    super("the library changed while it was read");
    this.name = "LibraryChangingError";
  }
}

export interface ServableImage {
  readonly mediaType: "image/webp" | "image/jpeg";
  readonly sha256: string;
}

/**
 * A picture that may be served: not withdrawn, and used by a servable
 * version (T-040 L8). Null otherwise, the same for an unknown ID.
 */
export async function readServableImage(
  db: SqlExecutor,
  imageId: string,
): Promise<ServableImage | null> {
  if (!isReferenceId(imageId)) return null;
  const { rows } = await withDbErrors(() =>
    db.query<{ media_type: ServableImage["mediaType"]; sha256: string }>(
      `SELECT i.media_type, i.sha256
         FROM library_image i
        WHERE i.image_id = $1
          AND i.withdrawn_at IS NULL
          AND EXISTS (
            SELECT 1 FROM library_recipe_version_image v
              JOIN library_servable_version s ON s.recipe_id = v.recipe_id AND s.version = v.version
             WHERE v.image_id = i.image_id
          )`,
      [imageId],
    ),
  );
  const row = rows[0];
  return row === undefined ? null : { mediaType: row.media_type, sha256: row.sha256 };
}

/** The bytes of a servable picture, read under the same conditions. */
export async function readServableImageBytes(
  db: SqlExecutor,
  imageId: string,
  sha256: string,
): Promise<Buffer | null> {
  if (!isReferenceId(imageId)) return null;
  const { rows } = await withDbErrors(() =>
    db.query<{ bytes: Uint8Array }>(
      `SELECT i.bytes
         FROM library_image i
        WHERE i.image_id = $1
          AND i.sha256 = $2
          AND i.withdrawn_at IS NULL
          AND EXISTS (
            SELECT 1 FROM library_recipe_version_image v
              JOIN library_servable_version s ON s.recipe_id = v.recipe_id AND s.version = v.version
             WHERE v.image_id = i.image_id
          )`,
      [imageId, sha256],
    ),
  );
  const row = rows[0];
  return row === undefined ? null : Buffer.from(row.bytes);
}
