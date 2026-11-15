import type { Schemas } from "@keluargamakan/contracts";
import {
  Body,
  Controller,
  Delete,
  Get,
  Headers,
  HttpCode,
  Inject,
  Param,
  Patch,
  Post,
  Put,
  Res,
} from "@nestjs/common";
import type { FastifyReply } from "fastify";

import { Requires, Scope, type HouseholdScope } from "../authz/access.js";
import { parseIdempotencyKey } from "../http/requests.js";
import { KITCHEN_SERVICE } from "../http/tokens.js";
import type {
  IngredientSetView,
  KitchenItemView,
  KitchenListView,
  KitchenService,
  SyncView,
} from "./kitchen-service.js";
import {
  parseIngredientSetInput,
  parseKitchenItemCreate,
  parseKitchenItemUpdate,
  parseKitchenSync,
} from "./requests.js";

/**
 * Dapur Saya endpoints of contract 0.2: kitchen items (T-031; KIT-01 to
 * KIT-07, KIT-09), ingredient sets (KIT-08) and the sync (KIT-16) (T-032).
 * Every route is scoped to the session's household.
 */

const iso = (date: Date) => date.toISOString();

export function kitchenItemBody(item: KitchenItemView): Schemas["KitchenItem"] {
  return {
    id: item.id,
    ingredientId: item.ingredientId,
    isCustom: item.isCustom,
    displayName:
      item.displayName === null ? null : { id: item.displayName.id, en: item.displayName.en },
    customName: item.customName,
    category: item.category,
    state: item.state,
    quantity: item.quantity,
    brand: item.brand === null ? null : { brandId: item.brand.brandId, name: item.brand.name },
    isDefaultStaple: item.isDefaultStaple,
    usageRank: item.usageRank,
    changedAt: iso(item.changedAt),
    createdAt: iso(item.createdAt),
  };
}

export function kitchenListBody(list: KitchenListView): Schemas["KitchenItemList"] {
  return {
    items: list.items.map(kitchenItemBody),
    maxItems: list.maxItems,
    referenceVersion: list.referenceVersion,
  };
}

@Controller("v1/household/kitchen")
export class KitchenController {
  constructor(@Inject(KITCHEN_SERVICE) private readonly kitchen: KitchenService) {}

  @Get("items")
  @Requires("kitchen:read")
  async list(@Scope() scope: HouseholdScope): Promise<Schemas["KitchenItemList"]> {
    return kitchenListBody(await this.kitchen.list(scope));
  }

  @Post("items")
  @Requires("kitchen:write")
  async add(
    @Scope() scope: HouseholdScope,
    @Body() body: unknown,
    @Headers("idempotency-key") idempotencyKey: unknown,
    @Res({ passthrough: true }) reply: FastifyReply,
  ): Promise<Schemas["KitchenItem"]> {
    const key = parseIdempotencyKey(idempotencyKey);
    const { item, created } = await this.kitchen.add(scope, parseKitchenItemCreate(body), key);
    void reply.status(created ? 201 : 200);
    return kitchenItemBody(item);
  }

  @Patch("items/:itemId")
  @Requires("kitchen:write")
  async update(
    @Scope() scope: HouseholdScope,
    @Param("itemId") itemId: string,
    @Body() body: unknown,
  ): Promise<Schemas["KitchenItem"]> {
    return kitchenItemBody(await this.kitchen.update(scope, itemId, parseKitchenItemUpdate(body)));
  }

  @Delete("items/:itemId")
  @HttpCode(204)
  @Requires("kitchen:write")
  async remove(@Scope() scope: HouseholdScope, @Param("itemId") itemId: string): Promise<void> {
    await this.kitchen.remove(scope, itemId);
  }

  // ------------------------------------------------------------ sets (KIT-08)

  @Get("sets")
  @Requires("kitchen:read")
  async listSets(@Scope() scope: HouseholdScope): Promise<Schemas["IngredientSetList"]> {
    const sets = await this.kitchen.listSets(scope);
    return { items: sets.items.map(setBody), maxSets: sets.maxSets };
  }

  @Post("sets")
  @Requires("kitchen:write")
  async createSet(
    @Scope() scope: HouseholdScope,
    @Body() body: unknown,
    @Headers("idempotency-key") idempotencyKey: unknown,
    @Res({ passthrough: true }) reply: FastifyReply,
  ): Promise<Schemas["IngredientSet"]> {
    const key = parseIdempotencyKey(idempotencyKey);
    const set = await this.kitchen.createSet(scope, parseIngredientSetInput(body), key);
    void reply.status(201);
    return setBody(set);
  }

  @Put("sets/:setId")
  @Requires("kitchen:write")
  async replaceSet(
    @Scope() scope: HouseholdScope,
    @Param("setId") setId: string,
    @Body() body: unknown,
  ): Promise<Schemas["IngredientSet"]> {
    return setBody(await this.kitchen.replaceSet(scope, setId, parseIngredientSetInput(body)));
  }

  @Delete("sets/:setId")
  @HttpCode(204)
  @Requires("kitchen:write")
  async deleteSet(@Scope() scope: HouseholdScope, @Param("setId") setId: string): Promise<void> {
    await this.kitchen.deleteSet(scope, setId);
  }

  @Post("sets/:setId/mark-available")
  @HttpCode(200)
  @Requires("kitchen:write")
  async markSetAvailable(
    @Scope() scope: HouseholdScope,
    @Param("setId") setId: string,
  ): Promise<Schemas["KitchenItemList"]> {
    return kitchenListBody(await this.kitchen.markSetAvailable(scope, setId));
  }

  // ------------------------------------------------------------ sync (KIT-16)

  @Post("sync")
  @HttpCode(200)
  @Requires("kitchen:write")
  async sync(
    @Scope() scope: HouseholdScope,
    @Body() body: unknown,
  ): Promise<Schemas["KitchenSyncResponse"]> {
    return syncBody(await this.kitchen.sync(scope, parseKitchenSync(body)));
  }
}

function setBody(set: IngredientSetView): Schemas["IngredientSet"] {
  return {
    id: set.id,
    name: set.name,
    itemIds: [...set.itemIds],
    createdAt: iso(set.createdAt),
    updatedAt: iso(set.updatedAt),
  };
}

function syncBody(view: SyncView): Schemas["KitchenSyncResponse"] {
  return {
    cursor: view.cursor,
    full: view.full,
    items: view.items.map(kitchenItemBody),
    removedItemIds: [...view.removedItemIds],
    results: view.results.map((result) => ({
      changeId: result.changeId,
      outcome: result.outcome,
      itemId: result.itemId,
      errorCode: result.errorCode as Schemas["ErrorCode"] | null,
    })),
    maxItems: view.maxItems,
    referenceVersion: view.referenceVersion,
  };
}
