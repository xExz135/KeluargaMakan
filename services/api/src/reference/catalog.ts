import { withDbErrors } from "../db/errors.js";
import type { SqlExecutor } from "../db/executor.js";
import { isReferenceId } from "../db/ids.js";

/**
 * Reference names for IDs the household refers to: liked or disliked
 * ingredients and dishes (PRF-06) and the ingredients a free-text rule maps
 * to (PRF-08). The API returns localized names so the app renders only what
 * it receives (QUESTIONS #44). Values are human-owned reference data; this
 * module only reads them.
 *
 * - Ingredients come from the active reference dataset (`reference_dataset`,
 *   T-013 build). With no active dataset no ingredient is known.
 * - Dishes are library recipes (T-041). Until the library exists no dish is
 *   known, so dish likes and dislikes are refused rather than stored blind.
 *
 * Writes accept only known IDs. A stored ID that later leaves the reference
 * data is still returned, with its ID as the name (never hidden).
 */

export interface LocalizedName {
  readonly id: string;
  readonly en: string;
}

export interface ReferenceCatalog {
  ingredientNames(ids: readonly string[]): Promise<Map<string, LocalizedName>>;
  dishNames(ids: readonly string[]): Promise<Map<string, LocalizedName>>;
}

export function fallbackName(refId: string): LocalizedName {
  return { id: refId, en: refId };
}

export class DbReferenceCatalog implements ReferenceCatalog {
  readonly #db: SqlExecutor;

  constructor(db: SqlExecutor) {
    this.#db = db;
  }

  async ingredientNames(ids: readonly string[]): Promise<Map<string, LocalizedName>> {
    const wanted = [...new Set(ids)].filter(isReferenceId);
    if (wanted.length === 0) return new Map();
    const { rows } = await withDbErrors(() =>
      this.#db.query<{ ref_id: string; name_id: string | null; name_en: string | null }>(
        `SELECT e->>'id' AS ref_id,
                e->'displayName'->>'id' AS name_id,
                e->'displayName'->>'en' AS name_en
           FROM reference_dataset d
           CROSS JOIN LATERAL jsonb_array_elements(
             CASE WHEN jsonb_typeof(d.payload->'ingredients') = 'array'
                  THEN d.payload->'ingredients' ELSE '[]'::jsonb END
           ) e
          WHERE d.is_active AND e->>'id' = ANY($1::text[])`,
        [wanted],
      ),
    );
    const names = new Map<string, LocalizedName>();
    for (const row of rows) {
      if (typeof row.name_id === "string" && typeof row.name_en === "string") {
        names.set(row.ref_id, { id: row.name_id, en: row.name_en });
      }
    }
    return names;
  }

  /** No library recipes exist before T-041. */
  dishNames(): Promise<Map<string, LocalizedName>> {
    return Promise.resolve(new Map<string, LocalizedName>());
  }
}
