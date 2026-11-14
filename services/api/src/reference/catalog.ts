import { referenceDataUnavailable, type ReferenceSource } from "./reference-data.js";

/**
 * Reference names for IDs the household refers to: liked or disliked
 * ingredients and dishes (PRF-06) and the ingredients a free-text rule maps
 * to (PRF-08). The API returns localized names so the app renders only what
 * it receives (QUESTIONS #44). Values are human-owned reference data; this
 * module only reads them.
 *
 * - Ingredients come from the verified reference dataset, the same one the
 *   ingredient search and Cek Aman use (QUESTIONS #49; security review T-030
 *   L3). There is no other source: the `reference_dataset` table is not read,
 *   because nothing checks its content hash or pin.
 * - Dishes are library recipes (T-041). Until the library exists no dish is
 *   known, so dish likes and dislikes are refused rather than stored blind.
 *
 * Writes accept only known IDs, and answer 503 `reference_data_unavailable`
 * while no verified dataset is loaded (L4), never "unknown ingredient". A
 * stored ID that later leaves the reference data is still returned, with its
 * ID as the name (never hidden); reads keep working without a dataset.
 */

export interface LocalizedName {
  readonly id: string;
  readonly en: string;
}

export interface ReferenceCatalog {
  ingredientNames(ids: readonly string[]): Promise<Map<string, LocalizedName>>;
  dishNames(ids: readonly string[]): Promise<Map<string, LocalizedName>>;
  /** Before a write checks ingredient IDs: throws 503 `reference_data_unavailable` without a dataset. */
  requireIngredients(): void;
}

export function fallbackName(refId: string): LocalizedName {
  return { id: refId, en: refId };
}

export class VerifiedReferenceCatalog implements ReferenceCatalog {
  readonly #source: ReferenceSource;

  constructor(source: ReferenceSource) {
    this.#source = source;
  }

  ingredientNames(ids: readonly string[]): Promise<Map<string, LocalizedName>> {
    const catalog = this.#source.current()?.catalog;
    const names = new Map<string, LocalizedName>();
    if (catalog === undefined) return Promise.resolve(names);
    for (const id of new Set(ids)) {
      const found = catalog.get(id);
      if (found !== null) names.set(id, { id: found.displayName.id, en: found.displayName.en });
    }
    return Promise.resolve(names);
  }

  /** No library recipes exist before T-041. */
  dishNames(): Promise<Map<string, LocalizedName>> {
    return Promise.resolve(new Map<string, LocalizedName>());
  }

  requireIngredients(): void {
    if (this.#source.current() === null) throw referenceDataUnavailable();
  }
}
