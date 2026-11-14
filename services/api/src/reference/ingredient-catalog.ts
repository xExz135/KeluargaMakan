import type { VerifiedReference } from "@keluargamakan/reference-data";

import { isKitchenCategory, type KitchenCategory } from "../../config/kitchen.js";
import { foldName } from "./fold.js";

/**
 * The reference ingredient catalog as the kitchen and search use it (KIT-04,
 * QUESTIONS #49): names, local and regional names, the kitchen category and
 * brands, built once from a verified dataset. It holds no safety data; only
 * Cek Aman reads components, allergens and halal status. The values come
 * from the human-owned reference data and are copied, never changed.
 */

export interface LocalizedName {
  readonly id: string;
  readonly en: string;
}

export interface CatalogIngredient {
  readonly ingredientId: string;
  readonly displayName: LocalizedName;
  readonly localNames: readonly string[];
  /** The reference category when it is a KIT-03 code, else null. */
  readonly category: KitchenCategory | null;
  readonly brandVaries: boolean;
  readonly brands: readonly { readonly brandId: string; readonly name: string }[];
}

export interface SearchHit {
  readonly ingredient: CatalogIngredient;
  /** The local name that matched, or null when a display name matched. */
  readonly matchedName: string | null;
}

/** A record the catalog cannot read. The dataset is then not used at all (fail closed). */
export class CatalogFormatError extends Error {
  override readonly name = "CatalogFormatError";
}

interface IndexedName {
  readonly text: string;
  readonly folded: string;
  readonly words: readonly string[];
  readonly isLocal: boolean;
}

interface Entry {
  readonly ingredient: CatalogIngredient;
  readonly names: readonly IndexedName[];
  readonly sortKey: string;
}

const own = (record: object, key: string): unknown =>
  Object.hasOwn(record, key) ? (record as Record<string, unknown>)[key] : undefined;

const isRecord = (value: unknown): value is object =>
  typeof value === "object" && value !== null && !Array.isArray(value);

const text = (value: unknown): value is string => typeof value === "string" && /\S/.test(value);

function readIngredient(raw: unknown, index: number): CatalogIngredient {
  const bad = (what: string) =>
    new CatalogFormatError(`reference ingredient ${index} has no valid ${what}`);
  if (!isRecord(raw)) throw bad("record");
  const id = own(raw, "id");
  const displayName = own(raw, "displayName");
  const localNames = own(raw, "localNames");
  const brandVaries = own(raw, "brandVaries");
  const variants = own(raw, "brandVariants");
  if (!text(id)) throw bad("id");
  if (!isRecord(displayName)) throw bad("displayName");
  const nameId = own(displayName, "id");
  const nameEn = own(displayName, "en");
  if (!text(nameId) || !text(nameEn)) throw bad("displayName");
  if (!Array.isArray(localNames) || !localNames.every(text)) throw bad("localNames");
  if (typeof brandVaries !== "boolean") throw bad("brandVaries");
  if (!Array.isArray(variants)) throw bad("brandVariants");
  const brands = variants.map((variant: unknown) => {
    const brandId = isRecord(variant) ? own(variant, "brandId") : undefined;
    const brandName = isRecord(variant) ? own(variant, "brandName") : undefined;
    if (!text(brandId) || !text(brandName)) throw bad("brandVariants");
    return Object.freeze({ brandId, name: brandName });
  });
  const category = own(raw, "category");
  return Object.freeze({
    ingredientId: id,
    displayName: Object.freeze({ id: nameId, en: nameEn }),
    localNames: Object.freeze([...localNames]),
    category: isKitchenCategory(category) ? category : null,
    brandVaries,
    brands: Object.freeze(brands),
  });
}

function indexName(value: string, isLocal: boolean): IndexedName | null {
  const folded = foldName(value);
  if (folded === "") return null;
  return { text: value, folded, words: folded.split(" "), isLocal };
}

/** 0 exact, 1 starts with the query, 2 every query word starts a word, 3 contains it; null: no match. */
function rankOf(name: IndexedName, query: string, words: readonly string[]): number | null {
  if (name.folded === query) return 0;
  if (name.folded.startsWith(query)) return 1;
  if (words.every((word) => name.words.some((candidate) => candidate.startsWith(word)))) return 2;
  if (name.folded.includes(query)) return 3;
  return null;
}

export class IngredientCatalog {
  readonly referenceVersion: string;
  readonly #entries: readonly Entry[];
  readonly #byId: ReadonlyMap<string, CatalogIngredient>;

  /** Throws `CatalogFormatError` when any record cannot be read. */
  constructor(reference: VerifiedReference) {
    this.referenceVersion = reference.referenceVersion;
    const entries = reference.reference.ingredients.map((raw: unknown, index) => {
      const ingredient = readIngredient(raw, index);
      const names = [
        indexName(ingredient.displayName.id, false),
        indexName(ingredient.displayName.en, false),
        ...ingredient.localNames.map((name) => indexName(name, true)),
      ].filter((name): name is IndexedName => name !== null);
      return { ingredient, names, sortKey: foldName(ingredient.displayName.id) };
    });
    entries.sort(
      (a, b) =>
        compareText(a.sortKey, b.sortKey) ||
        compareText(a.ingredient.ingredientId, b.ingredient.ingredientId),
    );
    this.#entries = Object.freeze(entries);
    this.#byId = new Map(entries.map((entry) => [entry.ingredient.ingredientId, entry.ingredient]));
  }

  /** Every ingredient, sorted by Indonesian display name. */
  list(): readonly CatalogIngredient[] {
    return this.#entries.map((entry) => entry.ingredient);
  }

  get(ingredientId: string): CatalogIngredient | null {
    return this.#byId.get(ingredientId) ?? null;
  }

  /**
   * KIT-04: matches the display names (Indonesian and English) and the local
   * names, ignoring case, accents, punctuation and spacing. Best first:
   * exact, then starting, then word-starting, then containing matches; a
   * display-name match before a local-name match of the same kind; then by
   * display name. A query with nothing to compare matches nothing.
   */
  search(query: string, limit: number): SearchHit[] {
    const folded = foldName(query);
    if (folded === "") return [];
    const words = folded.split(" ");
    const scored: { entry: Entry; rank: number; name: IndexedName }[] = [];
    for (const entry of this.#entries) {
      let best: { rank: number; name: IndexedName } | null = null;
      for (const name of entry.names) {
        const rank = rankOf(name, folded, words);
        if (rank === null) continue;
        if (
          best === null ||
          rank < best.rank ||
          (rank === best.rank && best.name.isLocal && !name.isLocal)
        ) {
          best = { rank, name };
        }
      }
      if (best !== null) scored.push({ entry, ...best });
    }
    // Entries are already in display-name order, and the sort is stable.
    scored.sort((a, b) => a.rank - b.rank || Number(a.name.isLocal) - Number(b.name.isLocal));
    return scored.slice(0, limit).map(({ entry, name }) => ({
      ingredient: entry.ingredient,
      matchedName: name.isLocal ? name.text : null,
    }));
  }
}

function compareText(a: string, b: string): number {
  return a < b ? -1 : a > b ? 1 : 0;
}
