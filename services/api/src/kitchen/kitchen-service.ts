import type { ApiConfig } from "../../config/api.js";
import { KITCHEN_CATEGORIES, type KitchenConfig } from "../../config/kitchen.js";
import { ApiError, validationFailed } from "../api-error.js";
import { systemClock, type Clock } from "../auth/auth-service.js";
import type { HouseholdScope } from "../authz/access.js";
import { NotFoundError, withDbErrors } from "../db/errors.js";
import type { SqlExecutor } from "../db/executor.js";
import { isUuid } from "../db/ids.js";
import {
  findReplayOf,
  idempotencyKeyReused,
  remember,
  requestHash,
  type IdempotentRequest,
} from "../idempotency/idempotency.js";
import type { LocalizedName } from "../reference/ingredient-catalog.js";
import { referenceDataUnavailable, type ReferenceSource } from "../reference/reference-data.js";
import { foldName } from "../reference/fold.js";
import {
  changeItem,
  countItems,
  deleteItem,
  findItemFor,
  insertItem,
  listItems,
  lockHouseholdKitchen,
  readItem,
  type KitchenItemRow,
} from "./kitchen-store.js";
import type { KitchenItemCreateInput, KitchenItemUpdateInput } from "./requests.js";

/**
 * Dapur Saya core (T-031): the saved kitchen per household (KIT-01), its
 * nine categories (KIT-03), adding reference ingredients found by search
 * (KIT-04) and custom ingredients (KIT-05), and the default staples (KIT-07,
 * created with the household in `HouseholdService`).
 *
 * Every call works on the session's household only. Reference ingredients
 * are checked against the verified reference dataset; without one, adding a
 * reference ingredient fails with 503 and nothing is stored (fail closed),
 * while reading the list and custom items keep working.
 */

export interface KitchenItemView {
  readonly id: string;
  readonly ingredientId: string | null;
  readonly isCustom: boolean;
  readonly displayName: LocalizedName | null;
  readonly customName: string | null;
  readonly category: KitchenItemRow["category"];
  readonly state: KitchenItemRow["state"];
  readonly quantity: KitchenItemRow["quantity"];
  readonly brand: { readonly brandId: string | null; readonly name: string } | null;
  readonly isDefaultStaple: boolean;
  readonly usageRank: number | null;
  readonly changedAt: Date;
  readonly createdAt: Date;
}

export interface KitchenListView {
  readonly items: readonly KitchenItemView[];
  readonly maxItems: number;
  readonly referenceVersion: string | null;
}

const ADD_CREATED = "add_kitchen_item";
const ADD_FOUND = "add_kitchen_item_found";

const CATEGORY_ORDER = new Map(KITCHEN_CATEGORIES.map((code, index) => [code, index]));

export const kitchenItemLimitReached = () =>
  new ApiError("kitchen_item_limit_reached", 409, "The household's kitchen item limit is reached");

export interface KitchenServiceDeps {
  readonly db: SqlExecutor;
  readonly config: ApiConfig;
  readonly kitchen: KitchenConfig;
  readonly reference: ReferenceSource;
  readonly hashKey: Buffer;
  readonly clock?: Clock;
}

export class KitchenService {
  readonly #db: SqlExecutor;
  readonly #config: ApiConfig;
  readonly #kitchen: KitchenConfig;
  readonly #reference: ReferenceSource;
  readonly #hashKey: Buffer;
  readonly #clock: Clock;

  constructor(deps: KitchenServiceDeps) {
    this.#db = deps.db;
    this.#config = deps.config;
    this.#kitchen = deps.kitchen;
    this.#reference = deps.reference;
    this.#hashKey = deps.hashKey;
    this.#clock = deps.clock ?? systemClock;
  }

  #transaction<T>(fn: (tx: SqlExecutor) => Promise<T>): Promise<T> {
    return withDbErrors(() =>
      this.#db.transaction(async (tx) => {
        await tx.query(`SELECT set_config('lock_timeout', $1, true)`, [
          `${this.#config.sessions.lockTimeoutMs}ms`,
        ]);
        return fn(tx);
      }),
    );
  }

  /** KIT-01, KIT-03: the household's saved ingredients in category order. */
  async list(scope: HouseholdScope): Promise<KitchenListView> {
    const rows = await listItems(this.#db, scope.householdId);
    const loaded = this.#reference.current();
    const views = rows.map((row) => this.#view(row));
    views.sort(
      (a, b) =>
        (CATEGORY_ORDER.get(a.category) ?? 99) - (CATEGORY_ORDER.get(b.category) ?? 99) ||
        compare(sortName(a), sortName(b)) ||
        compare(a.id, b.id),
    );
    return {
      items: views,
      maxItems: this.#kitchen.maxItemsPerHousehold,
      referenceVersion: loaded?.verified.referenceVersion ?? null,
    };
  }

  /**
   * KIT-04, KIT-05: adds an ingredient, or, when the household already has
   * it, sets the requested state on the existing item (`created: false`).
   * With an `Idempotency-Key`, a repeat returns the first result.
   */
  async add(
    scope: HouseholdScope,
    input: KitchenItemCreateInput,
    idempotencyKey: string | null,
  ): Promise<{ item: KitchenItemView; created: boolean }> {
    const now = this.#clock.now();
    let category = input.category;
    if (input.ref.kind === "reference") {
      const loaded = this.#reference.current();
      if (loaded === null) throw referenceDataUnavailable();
      const known = loaded.catalog.get(input.ref.ingredientId);
      if (known === null)
        throw validationFailed([{ pointer: "/ingredientId", code: "invalid_value" }]);
      category ??= known.category;
      if (category === null) throw validationFailed([{ pointer: "/category", code: "required" }]);
    }
    if (category === null) throw validationFailed([{ pointer: "/category", code: "required" }]);
    const resolvedCategory = category;

    const parts = [
      input.ref.kind === "reference" ? input.ref.ingredientId : null,
      input.ref.kind === "custom" ? input.ref.key : null,
      input.category,
      input.state,
    ];
    const keptSince = new Date(
      now.getTime() - this.#config.retention.idempotencyKeyHours * 3600_000,
    );
    const requests: IdempotentRequest[] | null =
      idempotencyKey === null
        ? null
        : [ADD_CREATED, ADD_FOUND].map((operation) => ({
            accountId: scope.accountId,
            key: idempotencyKey,
            operation,
            requestHash: requestHash(this.#hashKey, operation, parts),
            keptSince,
          }));

    return this.#transaction(async (tx) => {
      if (!(await lockHouseholdKitchen(tx, scope.householdId))) {
        throw new NotFoundError("household");
      }
      if (requests !== null) {
        const replay = await findReplayOf(tx, requests);
        if (replay !== null) {
          const stored = await readItem(tx, scope.householdId, replay.resourceId);
          if (stored === null) throw idempotencyKeyReused();
          return { item: this.#view(stored), created: replay.operation === ADD_CREATED };
        }
      }
      const existing = await findItemFor(tx, scope.householdId, input.ref);
      let row: KitchenItemRow | null;
      let created: boolean;
      if (existing !== null) {
        row = await changeItem(
          tx,
          scope.householdId,
          existing.id,
          {
            state: input.state,
            ...(input.category === null ? {} : { category: input.category }),
          },
          scope.accountId,
          now,
        );
        created = false;
      } else {
        if ((await countItems(tx, scope.householdId)) >= this.#kitchen.maxItemsPerHousehold) {
          throw kitchenItemLimitReached();
        }
        row = await insertItem(tx, {
          householdId: scope.householdId,
          accountId: scope.accountId,
          ref: input.ref,
          category: resolvedCategory,
          state: input.state,
          isDefaultStaple: false,
          now,
        });
        created = true;
      }
      if (row === null) throw new NotFoundError("kitchen item");
      const request = requests?.[created ? 0 : 1];
      if (request !== undefined) await remember(tx, request, row.id, now);
      return { item: this.#view(row), created };
    });
  }

  /** KIT-02, KIT-03, KIT-07: changes the state or category, stamped with the server time (KIT-16). */
  async update(
    scope: HouseholdScope,
    itemId: string,
    input: KitchenItemUpdateInput,
  ): Promise<KitchenItemView> {
    if (!isUuid(itemId)) throw new NotFoundError("kitchen item");
    const now = this.#clock.now();
    return this.#transaction(async (tx) => {
      const row = await changeItem(tx, scope.householdId, itemId, input, scope.accountId, now);
      if (row === null) throw new NotFoundError("kitchen item");
      return this.#view(row);
    });
  }

  async remove(scope: HouseholdScope, itemId: string): Promise<void> {
    if (!isUuid(itemId)) throw new NotFoundError("kitchen item");
    if (!(await deleteItem(this.#db, scope.householdId, itemId))) {
      throw new NotFoundError("kitchen item");
    }
  }

  #view(row: KitchenItemRow): KitchenItemView {
    const catalog = this.#reference.current()?.catalog;
    const known = row.ingredient_id === null ? null : (catalog?.get(row.ingredient_id) ?? null);
    const brandName =
      row.brand_id === null
        ? row.brand_custom_name
        : (known?.brands.find((brand) => brand.brandId === row.brand_id)?.name ?? row.brand_id);
    return {
      id: row.id,
      ingredientId: row.ingredient_id,
      isCustom: row.ingredient_id === null,
      displayName: known === null ? null : known.displayName,
      customName: row.custom_name,
      category: row.category,
      state: row.state,
      quantity: row.quantity,
      brand: brandName === null ? null : { brandId: row.brand_id, name: brandName },
      isDefaultStaple: row.is_default_staple,
      // KIT-06 frequency order is T-032.
      usageRank: null,
      changedAt: row.changed_at,
      createdAt: row.created_at,
    };
  }
}

function sortName(view: KitchenItemView): string {
  return foldName(view.displayName?.id ?? view.customName ?? view.ingredientId ?? "");
}

function compare(a: string, b: string): number {
  return a < b ? -1 : a > b ? 1 : 0;
}
