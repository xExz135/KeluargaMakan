import type { Schemas } from "@keluargamakan/contracts";

import type { LibraryConfig } from "../../config/library.js";
import { ApiError, validationFailed } from "../api-error.js";
import type { Clock } from "../auth/auth-service.js";
import type { HouseholdScope } from "../authz/access.js";
import type { SqlExecutor } from "../db/executor.js";
import type { HealthDataKeys } from "../db/health-data-keys.js";
import { isReferenceId } from "../db/ids.js";
import { RETRY_AFTER_SECONDS } from "../http/problem.js";
import { listItems, type KitchenItemRow } from "../kitchen/kitchen-store.js";
import { foldName } from "../reference/fold.js";
import {
  referenceDataUnavailable,
  type LoadedReference,
  type ReferenceSource,
} from "../reference/reference-data.js";
import {
  checkFood,
  serveChecked,
  type CheckContext,
  type FoodCandidate,
  type PendingCheck,
} from "../safety/checked-serving.js";
import { loadCheckEaters, type CheckEater } from "../safety/eaters.js";
import {
  LibraryChangingError,
  LibraryReader,
  readServableImage,
  readServableImageBytes,
  type LibraryRecipe,
  type LoadedLibrary,
} from "./library-store.js";
import type { LibrarySearchInput, RecipeDetailInput } from "./requests.js";
import { decodeSearchCursor, encodeSearchCursor } from "./search-cursor.js";

/**
 * The recipe library for households (T-041; LIB-01, LIB-03, LIB-04, LIB-05,
 * LIB-08), with every food item checked by Cek Aman for exactly the selected
 * eaters and logged before it is returned (SAF-02, SAF-14, PRF-11), through
 * `safety/checked-serving.ts`.
 *
 * - Only servable recipes are read (published, current version, tester and
 *   test date recorded; `library-store.ts`), and only cuisines served in this
 *   phase (`servedCuisines`, LIB-10).
 * - Search (LIB-08) matches recipe names and ingredient names, local names
 *   included, and filters by region, meal type and total time. Every
 *   matching recipe is checked, so Not safe ones can be left out and counted
 *   (`hiddenNotSafe`); only the recipes on the returned page are logged and
 *   returned. A recipe Cek Aman cannot check is left out, never returned
 *   without a result.
 * - The recipe screen returns the recipe whatever its result (SAF-12: no
 *   override), with its regional versions (LIB-04), each with its own
 *   result. No adaptation, substitution or variant is served yet (T-047,
 *   T-048; security review T-040 N1), so those IDs answer 409.
 * - Works with every AI service down (AI-08): nothing here calls one.
 *
 * Search text, recipe names and household data are never logged.
 */

export interface LibraryServiceDeps {
  readonly db: SqlExecutor;
  readonly keys: HealthDataKeys;
  readonly reference: ReferenceSource;
  readonly config: LibraryConfig;
  readonly hashKey: Buffer;
  readonly clock?: Clock;
}

type Summary = Schemas["RecipeSummary"];
type ListItem = Schemas["LibraryRecipeListItem"];

const systemClock: Clock = { now: () => new Date() };

const TIME_LIMITS: Readonly<Record<Schemas["TimeAvailable"], number>> = {
  up_to_15: 15,
  up_to_30: 30,
  up_to_60: 60,
  over_60: Number.POSITIVE_INFINITY,
};

const notFound = () => new ApiError("not_found", 404, "Not found");
const adaptationExpired = () =>
  new ApiError("adaptation_expired", 409, "The adaptation is not available");
const substitutionNotAvailable = () =>
  new ApiError("substitution_not_available", 409, "The substitution or variant is not offered");
const libraryChanging = () =>
  new ApiError("service_unavailable", 503, "The library changed while it was read", {
    retryAfterSeconds: RETRY_AFTER_SECONDS,
  });
const uncheckable = () => new ApiError("internal_error", 500, "The recipe could not be checked");

// ---------------------------------------------------------------- bodies

export function summaryBody(recipe: LibraryRecipe): Summary {
  return {
    recipeId: recipe.recipeId,
    version: recipe.version,
    name: { ...recipe.name },
    description: { ...recipe.description },
    cuisine: recipe.cuisine,
    region:
      recipe.region === null
        ? null
        : { regionId: recipe.region.regionId, displayName: { ...recipe.region.displayName } },
    mealTypes: [...recipe.mealTypes],
    prepMinutes: recipe.prepMinutes,
    cookMinutes: recipe.cookMinutes,
    totalMinutes: recipe.prepMinutes + recipe.cookMinutes,
    difficulty: recipe.difficulty,
    baseServings: recipe.baseServings,
    tags: { ...recipe.tags },
    images: recipe.images.map((image) => ({
      imageId: image.imageId,
      width: image.width,
      height: image.height,
      alt: { ...image.alt },
    })),
    // LIB-07: only a library recipe with its test record shows "Resep teruji".
    origin: "library",
    testRecord: { testedBy: recipe.testRecord.testedBy, testedOn: recipe.testRecord.testedOn },
    baseRecipeId: recipe.baseRecipeId,
  };
}

/** The Cek Aman input of a library recipe: every line, optional ones included (QUESTIONS #86). */
export function candidateOf(recipe: LibraryRecipe): FoodCandidate {
  return {
    subject: { kind: "library_recipe", id: recipe.recipeId, version: String(recipe.version) },
    lines: recipe.lines.map((line) => ({
      lineId: line.lineId,
      ingredientId: line.ingredientId,
      rawName: line.rawName,
    })),
  };
}

/**
 * SAF-07, QUESTIONS #87: the brands the household recorded, per reference
 * ingredient. Only items marked available count: a brand recorded on an
 * item that ran out may not be the brand bought next (QUESTIONS #91), and
 * leaving it out can only give Check the label, never Safe.
 */
export function recordedBrandsOf(items: readonly KitchenItemRow[]): Map<string, string[]> {
  const brands = new Map<string, string[]>();
  for (const item of items) {
    if (item.state !== "available" || item.ingredient_id === null || item.brand_id === null) {
      continue;
    }
    const list = brands.get(item.ingredient_id) ?? [];
    if (!list.includes(item.brand_id)) list.push(item.brand_id);
    brands.set(item.ingredient_id, list);
  }
  return brands;
}

function availableIngredients(items: readonly KitchenItemRow[]): Set<string> {
  return new Set(
    items.flatMap((item) =>
      item.state === "available" && item.ingredient_id !== null ? [item.ingredient_id] : [],
    ),
  );
}

/** CKM-05: quantities scale linearly; three significant digits, never zero. */
function scaled(amount: number | null, factor: number): number | null {
  if (amount === null) return null;
  const value = Number((amount * factor).toPrecision(3));
  return value > 0 ? value : amount * factor;
}

// ---------------------------------------------------------------- search

interface IndexedName {
  readonly folded: string;
  readonly words: readonly string[];
}

function indexName(value: string): IndexedName | null {
  const folded = foldName(value);
  return folded === "" ? null : { folded, words: folded.split(" ") };
}

/** Same ranks as the ingredient search: 0 exact, 1 starts, 2 word starts, 3 contains. */
function rankOf(name: IndexedName, query: string, words: readonly string[]): number | null {
  if (name.folded === query) return 0;
  if (name.folded.startsWith(query)) return 1;
  if (words.every((word) => name.words.some((candidate) => candidate.startsWith(word)))) return 2;
  if (name.folded.includes(query)) return 3;
  return null;
}

/** Ingredient match ranks come after every name match. */
const INGREDIENT_RANK_OFFSET = 10;

function ingredientNames(recipe: LibraryRecipe, reference: LoadedReference): IndexedName[] {
  const names: (IndexedName | null)[] = [];
  for (const line of recipe.lines) {
    names.push(indexName(line.rawName));
    const ingredient = line.ingredientId === null ? null : reference.catalog.get(line.ingredientId);
    if (ingredient !== null) {
      names.push(indexName(ingredient.displayName.id), indexName(ingredient.displayName.en));
      for (const local of ingredient.localNames) names.push(indexName(local));
    }
  }
  return names.filter((name): name is IndexedName => name !== null);
}

function matchRank(
  recipe: LibraryRecipe,
  reference: LoadedReference,
  query: string | null,
): number | null {
  if (query === null) return 0;
  const folded = foldName(query);
  if (folded === "") return null;
  const words = folded.split(" ");
  let best: number | null = null;
  const consider = (rank: number | null) => {
    if (rank !== null && (best === null || rank < best)) best = rank;
  };
  for (const name of [indexName(recipe.name.id), indexName(recipe.name.en)]) {
    if (name !== null) consider(rankOf(name, folded, words));
  }
  if (best === null) {
    for (const name of ingredientNames(recipe, reference)) {
      const rank = rankOf(name, folded, words);
      consider(rank === null ? null : rank + INGREDIENT_RANK_OFFSET);
    }
  }
  return best;
}

function compareText(a: string, b: string): number {
  return a < b ? -1 : a > b ? 1 : 0;
}

export class LibraryService {
  readonly #db: SqlExecutor;
  readonly #keys: HealthDataKeys;
  readonly #reference: ReferenceSource;
  readonly #config: LibraryConfig;
  readonly #hashKey: Buffer;
  readonly #clock: Clock;
  readonly #reader: LibraryReader;

  constructor(deps: LibraryServiceDeps) {
    this.#db = deps.db;
    this.#keys = deps.keys;
    this.#reference = deps.reference;
    this.#config = deps.config;
    this.#hashKey = deps.hashKey;
    this.#clock = deps.clock ?? systemClock;
    this.#reader = new LibraryReader(deps.db);
  }

  async #library(): Promise<LoadedLibrary> {
    try {
      return await this.#reader.current();
    } catch (error) {
      if (error instanceof LibraryChangingError) throw libraryChanging();
      throw error;
    }
  }

  #served(recipe: LibraryRecipe): boolean {
    return this.#config.servedCuisines.includes(recipe.cuisine);
  }

  #context(
    scope: HouseholdScope,
    reference: LoadedReference,
    eaters: readonly CheckEater[],
    kitchen: readonly KitchenItemRow[],
  ): CheckContext {
    return {
      householdId: scope.householdId,
      eaters,
      recordedBrands: recordedBrandsOf(kitchen),
      reference,
      evaluatedAt: this.#clock.now(),
    };
  }

  /** LIB-08, LIB-04: the regions servable recipes come from. No food content. */
  async regions(): Promise<Schemas["LibraryRegionList"]> {
    const library = await this.#library();
    const regions = new Map<string, Schemas["RecipeRegion"]>();
    for (const recipe of library.recipes) {
      if (!this.#served(recipe) || recipe.region === null) continue;
      regions.set(recipe.region.regionId, {
        regionId: recipe.region.regionId,
        displayName: { ...recipe.region.displayName },
      });
    }
    const items = [...regions.values()].sort(
      (a, b) =>
        compareText(foldName(a.displayName.id), foldName(b.displayName.id)) ||
        compareText(a.regionId, b.regionId),
    );
    return { libraryVersion: library.libraryVersion, items };
  }

  /**
   * LIB-03 picture bytes (T-040 L8): `private, no-cache`; 304 only when the
   * sent tag equals the current one; 404 for an unknown, withdrawn or
   * unused picture.
   */
  async image(
    imageId: string,
    ifNoneMatch: unknown,
  ): Promise<
    | { readonly status: 304; readonly etag: string }
    | {
        readonly status: 200;
        readonly etag: string;
        readonly mediaType: string;
        readonly bytes: Buffer;
      }
  > {
    if (!isReferenceId(imageId)) throw notFound();
    const image = await readServableImage(this.#db, imageId);
    if (image === null) throw notFound();
    const etag = `"${image.sha256}"`;
    if (sentTagMatches(ifNoneMatch, etag)) return { status: 304, etag };
    const bytes = await readServableImageBytes(this.#db, imageId, image.sha256);
    if (bytes === null) throw notFound();
    return { status: 200, etag, mediaType: image.mediaType, bytes };
  }

  async search(
    scope: HouseholdScope,
    input: LibrarySearchInput,
  ): Promise<Schemas["LibrarySearchResult"]> {
    let offset = 0;
    if (input.cursor !== null) {
      const decoded = decodeSearchCursor(this.#hashKey, scope.householdId, input, input.cursor);
      if (decoded === null) throw validationFailed([{ pointer: "/cursor", code: "invalid_value" }]);
      offset = decoded;
    }
    const reference = this.#reference.current();
    if (reference === null) throw referenceDataUnavailable();
    const eaters = await loadCheckEaters(this.#db, this.#keys, scope.householdId, input.eaters);
    const kitchen = await listItems(this.#db, scope.householdId);
    const library = await this.#library();

    const regions = new Set(input.regionIds);
    const mealTypes = new Set(input.mealTypes);
    const maxMinutes =
      input.timeAvailable === null ? Number.POSITIVE_INFINITY : TIME_LIMITS[input.timeAvailable];
    const matches: { recipe: LibraryRecipe; rank: number; sortKey: string }[] = [];
    for (const recipe of library.recipes) {
      if (!this.#served(recipe)) continue;
      if (regions.size > 0 && (recipe.region === null || !regions.has(recipe.region.regionId))) {
        continue;
      }
      if (mealTypes.size > 0 && !recipe.mealTypes.some((type) => mealTypes.has(type))) continue;
      if (recipe.prepMinutes + recipe.cookMinutes > maxMinutes) continue;
      const rank = matchRank(recipe, reference, input.query);
      if (rank === null) continue;
      matches.push({ recipe, rank, sortKey: foldName(recipe.name.id) });
    }
    matches.sort(
      (a, b) =>
        a.rank - b.rank ||
        compareText(a.sortKey, b.sortKey) ||
        compareText(a.recipe.recipeId, b.recipe.recipeId),
    );

    const context = this.#context(scope, reference, eaters, kitchen);
    const visible: { recipe: LibraryRecipe; check: PendingCheck }[] = [];
    const hiddenFor = new Set<string>();
    let hiddenCount = 0;
    for (const { recipe } of matches) {
      const check = checkFood(context, candidateOf(recipe));
      // SAF-02: an item Cek Aman could not check is left out.
      if (check === null) continue;
      if (!input.includeNotSafe && check.notSafeFor.length > 0) {
        hiddenCount += 1;
        for (const memberId of check.notSafeFor) hiddenFor.add(memberId);
        continue;
      }
      visible.push({ recipe, check });
    }

    const page = visible.slice(offset, offset + input.limit);
    const served = await serveChecked(
      this.#db,
      this.#keys,
      page.map((entry) => entry.check),
    );
    const items: ListItem[] = page.map((entry, index) => {
      const safety = served[index];
      if (safety === undefined || safety.subjectId !== entry.recipe.recipeId) {
        throw new Error("served checks out of order");
      }
      return { recipe: summaryBody(entry.recipe), safety: safety.safety };
    });
    const next = offset + input.limit;
    return {
      items,
      nextCursor:
        next < visible.length
          ? encodeSearchCursor(this.#hashKey, scope.householdId, input, next)
          : null,
      totalCount: visible.length,
      hiddenNotSafe: {
        count: hiddenCount,
        memberIds: eaters.map((eater) => eater.memberId).filter((id) => hiddenFor.has(id)),
      },
      libraryVersion: library.libraryVersion,
    };
  }

  async detail(
    scope: HouseholdScope,
    recipeId: string,
    input: RecipeDetailInput,
  ): Promise<Schemas["RecipeDetail"]> {
    const reference = this.#reference.current();
    if (reference === null) throw referenceDataUnavailable();
    const library = await this.#library();
    const recipe = isReferenceId(recipeId) ? library.byId.get(recipeId) : undefined;
    // LIB-01: an unpublished, retired, untested or unknown recipe is 404.
    if (recipe === undefined || !this.#served(recipe)) throw notFound();
    const eaters = await loadCheckEaters(this.#db, this.#keys, scope.householdId, input.eaters);
    // Household-bound IDs (NFR-09): none is issued yet, so every one answers
    // the same, without a lookup (T-047 adaptations, T-048 substitutions and
    // variants; security review T-040 N1 keeps variants unserved).
    if (input.adaptationId !== null) throw adaptationExpired();
    if (input.substitutionIds.length > 0 || input.variantId !== null) {
      throw substitutionNotAvailable();
    }
    const kitchen = await listItems(this.#db, scope.householdId);
    const context = this.#context(scope, reference, eaters, kitchen);

    const base = recipe.baseRecipeId ?? recipe.recipeId;
    const family = library.recipes
      .filter(
        (other) =>
          other.recipeId !== recipe.recipeId &&
          this.#served(other) &&
          (other.recipeId === base || other.baseRecipeId === base),
      )
      .sort(
        (a, b) =>
          compareText(foldName(a.name.id), foldName(b.name.id)) ||
          compareText(a.recipeId, b.recipeId),
      )
      .slice(0, this.#config.maxRegionalVariants);

    const main = checkFood(context, candidateOf(recipe));
    // SAF-02: the recipe is never returned without a result.
    if (main === null) throw uncheckable();
    const variants = family.flatMap((other) => {
      const check = checkFood(context, candidateOf(other));
      return check === null ? [] : [{ recipe: other, check }];
    });
    const served = await serveChecked(this.#db, this.#keys, [
      main,
      ...variants.map((entry) => entry.check),
    ]);
    const [mainServed, ...variantServed] = served;
    if (mainServed === undefined || mainServed.subjectId !== recipe.recipeId) {
      throw new Error("served checks out of order");
    }

    // SUG-16: servings for the eaters (one each; portion sizes follow in
    // T-045, QUESTIONS #92), quantities scaled to them.
    const servings = Math.max(1, eaters.length);
    const factor = servings / recipe.baseServings;
    const available = availableIngredients(kitchen);
    const nameOf = (ingredientId: string | null) => {
      const item = ingredientId === null ? null : reference.catalog.get(ingredientId);
      return item === null ? null : { id: item.displayName.id, en: item.displayName.en };
    };
    const ingredients = recipe.lines.map((line): Schemas["RecipeIngredientLine"] => ({
      lineId: line.lineId,
      ingredientId: line.ingredientId,
      displayName: nameOf(line.ingredientId),
      rawName: line.rawName,
      quantity: {
        amount: scaled(line.amount, factor),
        unitCode: line.unitCode,
        unitLabel: line.unitLabel === null ? null : { ...line.unitLabel },
      },
      isOptional: line.isOptional,
      groupLabel: line.groupLabel === null ? null : { ...line.groupLabel },
      inKitchen:
        line.ingredientId !== null && available.has(line.ingredientId) ? "available" : "missing",
    }));
    // SUG-10: optional lines are not counted; the missing list has no quantity or shop.
    const required = ingredients.filter((line) => !line.isOptional);
    const missing = required.filter((line) => line.inKitchen === "missing");

    return {
      recipe: summaryBody(recipe),
      ingredients,
      steps: recipe.steps.map((step) => ({
        stepId: step.stepId,
        text: { ...step.text },
        timerSeconds: step.timerSeconds,
        ingredientLineIds: [...step.ingredientLineIds],
      })),
      servings,
      kitchenMatch: {
        availableCount: required.length - missing.length,
        missingCount: missing.length,
        missing: missing.map((line) => ({
          lineId: line.lineId,
          ingredientId: line.ingredientId,
          displayName: line.displayName,
          rawName: line.rawName,
        })),
      },
      safety: mainServed.safety,
      adaptation: null,
      variant: null,
      appliedSubstitutionIds: [],
      regionalVariants: variants.map((entry, index) => {
        const safety = variantServed[index];
        if (safety === undefined || safety.subjectId !== entry.recipe.recipeId) {
          throw new Error("served checks out of order");
        }
        return { recipe: summaryBody(entry.recipe), safety: safety.safety };
      }),
      // QUESTIONS #15: V1 shows no nutrition; T-042 serves reviewed ranges later.
      nutritionPerServing: { status: "unavailable", ranges: [] },
      // PRF-12 trade-offs come with ranking (T-045).
      tradeOff: null,
      // SET-09: AI features stay off until the household opts in; no opt-in
      // exists yet, and the library recipe needs no AI (AI-08).
      aiAvailability: "off",
    };
  }
}

/** T-040 L8: the sent `If-None-Match` names exactly the current strong tag. */
export function sentTagMatches(header: unknown, etag: string): boolean {
  if (typeof header !== "string" || header.length > 200) return false;
  return header
    .split(",")
    .map((tag) => tag.trim())
    .some((tag) => tag === etag);
}
