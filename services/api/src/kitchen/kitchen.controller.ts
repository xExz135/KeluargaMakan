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
  Res,
} from "@nestjs/common";
import type { FastifyReply } from "fastify";

import { Requires, Scope, type HouseholdScope } from "../authz/access.js";
import { parseIdempotencyKey } from "../http/requests.js";
import { KITCHEN_SERVICE } from "../http/tokens.js";
import type { KitchenItemView, KitchenListView, KitchenService } from "./kitchen-service.js";
import { parseKitchenItemCreate, parseKitchenItemUpdate } from "./requests.js";

/**
 * T-031 endpoints of contract 0.2.0 (Dapur Saya): list, add, change and
 * remove kitchen items (KIT-01 to KIT-05, KIT-07). Sets and the sync are
 * T-032. Every route is scoped to the session's household.
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
}
