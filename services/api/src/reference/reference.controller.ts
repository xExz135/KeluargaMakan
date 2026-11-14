import { RULE_SET_VERSION, STANDARD_ALLERGENS } from "@keluargamakan/cek-aman";
import type { Schemas } from "@keluargamakan/contracts";
import { Body, Controller, Get, Headers, HttpCode, Inject, Post, Res } from "@nestjs/common";
import type { FastifyReply } from "fastify";

import type { KitchenConfig } from "../../config/kitchen.js";
import { Requires } from "../authz/access.js";
import { cleanUserText, codePointLength } from "../http/text.js";
import { KITCHEN_CONFIG, REFERENCE_SOURCE } from "../http/tokens.js";
import { BodyReader } from "../http/validation.js";
import type { CatalogIngredient } from "./ingredient-catalog.js";
import {
  referenceDataUnavailable,
  type LoadedReference,
  type ReferenceSource,
} from "./reference-data.js";

/**
 * Reference vocabularies and the ingredient catalog.
 *
 * - PRF-04: the standard allergen list, straight from the Cek Aman rule-set
 *   vocabulary (T-012), in its display order; a change to the list is a
 *   rule-set change in packages/cek-aman.
 * - KIT-04 (T-031): the reference ingredient catalog and its search, from the
 *   verified dataset only. Without one the answer is 503
 *   `reference_data_unavailable`, never an empty list. The search query comes
 *   in the body and is never logged or stored.
 *
 * The API adds no values of its own.
 */

const QUERY_MAX = 60;

/**
 * Security review T-030 L7: the catalog body and its entity tag, built once
 * per loaded dataset. The tag is the dataset's content hash, which covers
 * its version and every record, so it changes exactly when the data does.
 */
interface CatalogDownload {
  readonly etag: string;
  readonly json: string;
}

const downloads = new WeakMap<LoadedReference, CatalogDownload>();

function downloadOf(loaded: LoadedReference): CatalogDownload {
  let download = downloads.get(loaded);
  if (download === undefined) {
    const body: Schemas["ReferenceIngredientCatalog"] = {
      referenceVersion: loaded.catalog.referenceVersion,
      items: loaded.catalog.list().map(catalogIngredientBody),
    };
    download = { etag: `"${loaded.verified.contentHash}"`, json: JSON.stringify(body) };
    downloads.set(loaded, download);
  }
  return download;
}

/** RFC 9110 If-None-Match: a list of tags, weak or strong, or `*`. */
export function matchesIfNoneMatch(header: unknown, etag: string): boolean {
  if (typeof header !== "string" || header.length > 1024) return false;
  return header
    .split(",")
    .map((tag) => tag.trim().replace(/^W\//, ""))
    .some((tag) => tag === "*" || tag === etag);
}

/** Only the phone may keep the copy, and it revalidates before using it. */
export const CATALOG_CACHE_CONTROL = "private, no-cache";

export function catalogIngredientBody(item: CatalogIngredient): Schemas["CatalogIngredient"] {
  return {
    ingredientId: item.ingredientId,
    displayName: { id: item.displayName.id, en: item.displayName.en },
    localNames: [...item.localNames],
    category: item.category,
    brandVaries: item.brandVaries,
    brands: item.brands.map((brand) => ({ brandId: brand.brandId, name: brand.name })),
  };
}

function parseSearch(body: unknown, config: KitchenConfig): { query: string; limit: number } {
  const reader = new BodyReader();
  const record = reader.object(body, "", ["query", "limit"]);
  let query = "";
  let limit = config.search.defaultResults;
  if (record !== null) {
    const raw = reader.string(record, "query", "", {
      required: true,
      minLength: 1,
      maxLength: QUERY_MAX,
    });
    if (typeof raw === "string") {
      const clean = cleanUserText(raw);
      if (clean === null || codePointLength(clean) > QUERY_MAX) {
        reader.fail("/query", "invalid_format");
      } else {
        query = clean;
      }
    }
    if (Object.hasOwn(record, "limit")) {
      const value = record["limit"];
      if (typeof value !== "number" || !Number.isInteger(value)) {
        reader.fail("/limit", "invalid_type");
      } else if (value < 1 || value > config.search.maxResults) {
        reader.fail("/limit", "invalid_value");
      } else {
        limit = value;
      }
    }
  }
  reader.done();
  return { query, limit };
}

@Controller("v1/reference")
export class ReferenceController {
  constructor(
    @Inject(REFERENCE_SOURCE) private readonly reference: ReferenceSource,
    @Inject(KITCHEN_CONFIG) private readonly kitchen: KitchenConfig,
  ) {}

  @Get("allergens")
  @Requires("reference:read")
  allergens(): Schemas["StandardAllergenList"] {
    return { ruleSetVersion: RULE_SET_VERSION, items: [...STANDARD_ALLERGENS] };
  }

  @Get("ingredients")
  @Requires("reference:read")
  ingredients(
    @Headers("if-none-match") ifNoneMatch: unknown,
    @Res({ passthrough: true }) reply: FastifyReply,
  ): string | undefined {
    const loaded = this.reference.current();
    if (loaded === null) throw referenceDataUnavailable();
    const download = downloadOf(loaded);
    void reply.header("ETag", download.etag).header("Cache-Control", CATALOG_CACHE_CONTROL);
    if (matchesIfNoneMatch(ifNoneMatch, download.etag)) {
      void reply.status(304);
      return undefined;
    }
    void reply.header("Content-Type", "application/json; charset=utf-8");
    return download.json;
  }

  @Post("ingredients/search")
  @HttpCode(200)
  @Requires("reference:read")
  search(@Body() body: unknown): Schemas["IngredientSearchResult"] {
    const { query, limit } = parseSearch(body, this.kitchen);
    const loaded = this.reference.current();
    if (loaded === null) throw referenceDataUnavailable();
    return {
      referenceVersion: loaded.catalog.referenceVersion,
      items: loaded.catalog.search(query, limit).map((hit) => ({
        ingredient: catalogIngredientBody(hit.ingredient),
        matchedName: hit.matchedName,
      })),
    };
  }
}
