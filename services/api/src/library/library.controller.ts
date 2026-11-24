import type { Schemas } from "@keluargamakan/contracts";
import { Body, Controller, Get, Headers, HttpCode, Inject, Param, Post, Res } from "@nestjs/common";
import type { FastifyReply } from "fastify";

import type { LibraryConfig } from "../../config/library.js";
import { Requires, Scope, type HouseholdScope } from "../authz/access.js";
import { LIBRARY_CONFIG, LIBRARY_SERVICE } from "../http/tokens.js";
import type { LibraryService } from "./library-service.js";
import { parseLibrarySearch, parseRecipeDetail } from "./requests.js";

/**
 * Library endpoints of contract 0.3 served by T-041: search (LIB-08), the
 * region list (LIB-04, LIB-08), recipe images (LIB-03) and the recipe screen
 * (CKM-01). Every route needs `library:read`, a household permission scoped
 * from the session (security review T-040 L7): the access guard refuses a
 * caller without a household (409) on every route, including the two that
 * read no household data. Every food item returned
 * carries its logged Cek Aman result (SAF-02, SAF-14).
 *
 * Not served here: substitutions (T-048) and every admin recipe and draft
 * route (QUESTIONS #80); they answer 404.
 */

/** Only the phone may keep a copy, and it checks again before each use (T-040 L8). */
export const IMAGE_CACHE_CONTROL = "private, no-cache";

@Controller("v1/library")
export class LibraryController {
  constructor(
    @Inject(LIBRARY_SERVICE) private readonly library: LibraryService,
    @Inject(LIBRARY_CONFIG) private readonly config: LibraryConfig,
  ) {}

  @Post("recipes/search")
  @HttpCode(200)
  @Requires("library:read")
  async search(
    @Scope() scope: HouseholdScope,
    @Body() body: unknown,
  ): Promise<Schemas["LibrarySearchResult"]> {
    return this.library.search(scope, parseLibrarySearch(body, this.config));
  }

  @Get("regions")
  @Requires("library:read")
  async regions(@Scope() scope: HouseholdScope): Promise<Schemas["LibraryRegionList"]> {
    return this.library.regions(scope);
  }

  @Get("images/:imageId")
  @Requires("library:read")
  async image(
    @Scope() scope: HouseholdScope,
    @Param("imageId") imageId: string,
    @Headers("if-none-match") ifNoneMatch: unknown,
    @Res({ passthrough: true }) reply: FastifyReply,
  ): Promise<Buffer | undefined> {
    const image = await this.library.image(scope, imageId, ifNoneMatch);
    void reply
      .header("ETag", image.etag)
      .header("Cache-Control", IMAGE_CACHE_CONTROL)
      .header("X-Content-Type-Options", "nosniff");
    if (image.status === 304) {
      void reply.status(304);
      return undefined;
    }
    void reply.header("Content-Type", image.mediaType);
    return image.bytes;
  }

  @Post("recipes/:recipeId/detail")
  @HttpCode(200)
  @Requires("library:read")
  async detail(
    @Scope() scope: HouseholdScope,
    @Param("recipeId") recipeId: string,
    @Body() body: unknown,
  ): Promise<Schemas["RecipeDetail"]> {
    return this.library.detail(scope, recipeId, parseRecipeDetail(body));
  }
}
