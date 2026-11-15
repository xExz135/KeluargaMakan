import type { ApiConfig } from "../../config/api.js";
import {
  KITCHEN_CATEGORIES,
  type KitchenCategory,
  type KitchenConfig,
} from "../../config/kitchen.js";
import { ApiError, validationFailed, type FieldError } from "../api-error.js";
import { systemClock, type Clock } from "../auth/auth-service.js";
import { keyedHash } from "../auth/crypto.js";
import type { HouseholdScope } from "../authz/access.js";
import { NotFoundError, withDbErrors } from "../db/errors.js";
import type { SqlExecutor } from "../db/executor.js";
import { isUuid } from "../db/ids.js";
import {
  findReplay,
  findReplayOf,
  idempotencyKeyReused,
  remember,
  requestHash,
  type IdempotentRequest,
} from "../idempotency/idempotency.js";
import type { CatalogIngredient, LocalizedName } from "../reference/ingredient-catalog.js";
import { referenceDataUnavailable, type ReferenceSource } from "../reference/reference-data.js";
import { foldName } from "../reference/fold.js";
import {
  changesSince,
  countItems,
  countSets,
  deleteSet,
  findItemFor,
  findSyncChange,
  insertItem,
  insertSet,
  lastRemovalOf,
  listItems,
  listSets,
  lockHouseholdKitchen,
  readItem,
  readItems,
  readSet,
  recordRemoval,
  rememberSyncChange,
  removeItem,
  replaceSet,
  writeItem,
  type IngredientRef,
  type IngredientSetRow,
  type ItemValues,
  type KitchenItemRow,
} from "./kitchen-store.js";
import {
  cleanBrandName,
  customIngredientRef,
  type BrandInput,
  type IngredientKeyInput,
  type IngredientSetInput,
  type ItemPatch,
  type KitchenItemCreateInput,
  type SyncChangeInput,
  type SyncInput,
} from "./requests.js";
import { decodeCursor, encodeCursor } from "./sync-cursor.js";
import { scoreAfter, usageRanks } from "./usage.js";

/**
 * Dapur Saya (T-031, T-032): the saved kitchen per household (KIT-01), its
 * nine categories (KIT-03), frequency order (KIT-06), reference ingredients
 * found by search (KIT-04) and custom ingredients (KIT-05), default staples
 * (KIT-07, created with the household), ingredient sets (KIT-08), quantity
 * and brand (KIT-09) and the offline sync (KIT-16).
 *
 * Every call works on the session's household only, and every write runs
 * under the household's kitchen lock. Reference ingredients and brands are
 * checked against the verified reference dataset; without one they fail
 * with 503 and nothing is stored (fail closed). A typed brand is stored as
 * text and is never a recorded brand for Cek Aman (SAF-07).
 *
 * Latest change wins per ingredient (KIT-16): every change is dated on the
 * server's clock (an online change now, a queued one now minus its age), and
 * a change older than the stored one, or than the ingredient's last
 * removal, is superseded.
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

export interface IngredientSetView {
  readonly id: string;
  readonly name: string;
  readonly itemIds: readonly string[];
  readonly createdAt: Date;
  readonly updatedAt: Date;
}

export interface SyncResultView {
  readonly changeId: string;
  readonly outcome: "applied" | "superseded" | "rejected";
  readonly itemId: string | null;
  readonly errorCode: string | null;
}

export interface SyncView extends KitchenListView {
  readonly cursor: string;
  readonly full: boolean;
  readonly removedItemIds: readonly string[];
  readonly results: readonly SyncResultView[];
}

const ADD_CREATED = "add_kitchen_item";
const ADD_FOUND = "add_kitchen_item_found";
const CREATE_SET = "create_ingredient_set";

const CATEGORY_ORDER = new Map(KITCHEN_CATEGORIES.map((code, index) => [code, index]));

export const kitchenItemLimitReached = () =>
  new ApiError("kitchen_item_limit_reached", 409, "The household's kitchen item limit is reached");
export const ingredientSetLimitReached = () =>
  new ApiError(
    "ingredient_set_limit_reached",
    409,
    "The household's ingredient set limit is reached",
  );

const fieldError = (pointer: string, code: FieldError["code"]) =>
  validationFailed([{ pointer, code }]);

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

  /** A transaction holding the household's kitchen lock. */
  #locked<T>(scope: HouseholdScope, fn: (tx: SqlExecutor) => Promise<T>): Promise<T> {
    return withDbErrors(() =>
      this.#db.transaction(async (tx) => {
        await tx.query(`SELECT set_config('lock_timeout', $1, true)`, [
          `${this.#config.sessions.lockTimeoutMs}ms`,
        ]);
        if (!(await lockHouseholdKitchen(tx, scope.householdId))) {
          throw new NotFoundError("household");
        }
        return fn(tx);
      }),
    );
  }

  // ------------------------------------------------------------ items

  /** KIT-01, KIT-03, KIT-06: the saved ingredients in category order, most used first. */
  async list(scope: HouseholdScope): Promise<KitchenListView> {
    const rows = await listItems(this.#db, scope.householdId);
    return {
      items: this.#views(rows, rows),
      maxItems: this.#kitchen.maxItemsPerHousehold,
      referenceVersion: this.#referenceVersion(),
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
    const category = this.#categoryForNew(input.ref, input.category, "");

    const parts = [
      input.ref.kind === "reference" ? input.ref.ingredientId : null,
      input.ref.kind === "custom" ? input.ref.key : null,
      input.category,
      input.state,
    ];
    const keptSince = this.#idempotencyKeptSince(now);
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

    return this.#locked(scope, async (tx) => {
      if (requests !== null) {
        const replay = await findReplayOf(tx, requests);
        if (replay !== null) {
          const stored = await readItem(tx, scope.householdId, replay.resourceId);
          if (stored === null) throw idempotencyKeyReused();
          return {
            item: await this.#viewOne(tx, scope, stored),
            created: replay.operation === ADD_CREATED,
          };
        }
      }
      const existing = await findItemFor(tx, scope.householdId, input.ref);
      const patch: ItemPatch = {
        state: input.state,
        ...(input.category === null ? {} : { category: input.category }),
      };
      const row =
        existing === null
          ? await this.#insert(tx, scope, input.ref, patch, category, now, now)
          : await this.#write(tx, scope, existing, patch, now, now);
      const created = existing === null;
      const request = requests?.[created ? 0 : 1];
      if (request !== undefined) await remember(tx, request, row.id, now);
      return { item: await this.#viewOne(tx, scope, row), created };
    });
  }

  /** KIT-02, KIT-03, KIT-09: changes state, category, quantity or brand, dated now (KIT-16). */
  async update(scope: HouseholdScope, itemId: string, patch: ItemPatch): Promise<KitchenItemView> {
    if (!isUuid(itemId)) throw new NotFoundError("kitchen item");
    const now = this.#clock.now();
    return this.#locked(scope, async (tx) => {
      const row = await readItem(tx, scope.householdId, itemId, { forUpdate: true });
      if (row === null) throw new NotFoundError("kitchen item");
      return this.#viewOne(tx, scope, await this.#write(tx, scope, row, patch, now, now));
    });
  }

  /** Removes an item; the removal is kept for the sync (KIT-16). */
  async remove(scope: HouseholdScope, itemId: string): Promise<void> {
    if (!isUuid(itemId)) throw new NotFoundError("kitchen item");
    const now = this.#clock.now();
    await this.#locked(scope, async (tx) => {
      const row = await readItem(tx, scope.householdId, itemId, { forUpdate: true });
      if (row === null) throw new NotFoundError("kitchen item");
      await removeItem(tx, scope.householdId, row, now, now);
    });
  }

  // ------------------------------------------------------------ sets (KIT-08)

  async listSets(scope: HouseholdScope): Promise<{
    readonly items: readonly IngredientSetView[];
    readonly maxSets: number;
  }> {
    const rows = await listSets(this.#db, scope.householdId);
    return { items: rows.map(setView), maxSets: this.#kitchen.maxSetsPerHousehold };
  }

  async createSet(
    scope: HouseholdScope,
    input: IngredientSetInput,
    idempotencyKey: string | null,
  ): Promise<IngredientSetView> {
    const now = this.#clock.now();
    const request: IdempotentRequest | null =
      idempotencyKey === null
        ? null
        : {
            accountId: scope.accountId,
            key: idempotencyKey,
            operation: CREATE_SET,
            requestHash: requestHash(this.#hashKey, CREATE_SET, [
              input.name,
              [...input.itemIds].sort(),
            ]),
            keptSince: this.#idempotencyKeptSince(now),
          };
    return this.#locked(scope, async (tx) => {
      if (request !== null) {
        const previous = await findReplay(tx, request);
        if (previous !== null) {
          const stored = await readSet(tx, scope.householdId, previous);
          if (stored === null) throw idempotencyKeyReused();
          return setView(stored);
        }
      }
      if ((await countSets(tx, scope.householdId)) >= this.#kitchen.maxSetsPerHousehold) {
        throw ingredientSetLimitReached();
      }
      await this.#requireItems(tx, scope, input.itemIds);
      const setId = await insertSet(tx, scope.householdId, input.name, now);
      await replaceSet(tx, scope.householdId, setId, input.name, input.itemIds, now);
      if (request !== null) await remember(tx, request, setId, now);
      const stored = await readSet(tx, scope.householdId, setId);
      if (stored === null) throw new NotFoundError("ingredient set");
      return setView(stored);
    });
  }

  async replaceSet(
    scope: HouseholdScope,
    setId: string,
    input: IngredientSetInput,
  ): Promise<IngredientSetView> {
    if (!isUuid(setId)) throw new NotFoundError("ingredient set");
    const now = this.#clock.now();
    return this.#locked(scope, async (tx) => {
      if ((await readSet(tx, scope.householdId, setId)) === null) {
        throw new NotFoundError("ingredient set");
      }
      await this.#requireItems(tx, scope, input.itemIds);
      await replaceSet(tx, scope.householdId, setId, input.name, input.itemIds, now);
      const stored = await readSet(tx, scope.householdId, setId);
      if (stored === null) throw new NotFoundError("ingredient set");
      return setView(stored);
    });
  }

  async deleteSet(scope: HouseholdScope, setId: string): Promise<void> {
    if (!isUuid(setId)) throw new NotFoundError("ingredient set");
    await this.#locked(scope, async (tx) => {
      if (!(await deleteSet(tx, scope.householdId, setId))) {
        throw new NotFoundError("ingredient set");
      }
    });
  }

  /**
   * KIT-08 "Tandai semua ada": every item in the set becomes available,
   * dated now; no other item changes and nothing becomes out. Sending it
   * again gives the same states.
   */
  async markSetAvailable(scope: HouseholdScope, setId: string): Promise<KitchenListView> {
    if (!isUuid(setId)) throw new NotFoundError("ingredient set");
    const now = this.#clock.now();
    return this.#locked(scope, async (tx) => {
      const set = await readSet(tx, scope.householdId, setId);
      if (set === null) throw new NotFoundError("ingredient set");
      const rows = await readItems(tx, scope.householdId, set.item_ids);
      const written: KitchenItemRow[] = [];
      for (const row of rows) {
        written.push(await this.#write(tx, scope, row, { state: "available" }, now, now));
      }
      const all = await listItems(tx, scope.householdId);
      return {
        items: this.#views(written, all),
        maxItems: this.#kitchen.maxItemsPerHousehold,
        referenceVersion: this.#referenceVersion(),
      };
    });
  }

  // ------------------------------------------------------------ sync (KIT-16)

  /**
   * Applies the queued changes in order, then returns everything changed
   * since the cursor (or the whole kitchen when there is no usable cursor).
   * Each change ID is remembered per household: a repeat returns its first
   * result and is never applied twice; the same ID with another change is
   * rejected (`idempotency_key_reused`). A change that cannot be applied is
   * rejected on its own and never stops the rest.
   */
  async sync(scope: HouseholdScope, input: SyncInput): Promise<SyncView> {
    const now = this.#clock.now();
    const retentionMs = this.#kitchen.sync.recordRetentionDays * 86_400_000;
    const keptSince = new Date(now.getTime() - retentionMs);
    const after = decodeCursor(this.#hashKey, input.cursor, scope.householdId, keptSince);
    return this.#locked(scope, async (tx) => {
      const results: SyncResultView[] = [];
      for (const change of input.changes) {
        results.push(await this.#syncChange(tx, scope, change, keptSince, now));
      }
      const changed = await changesSince(tx, scope.householdId, after);
      const all = after === null ? changed.items : await listItems(tx, scope.householdId);
      const present = new Set(all.map((row) => row.id));
      return {
        cursor: encodeCursor(this.#hashKey, scope.householdId, changed.latest, now),
        full: after === null,
        items: this.#views(changed.items, all),
        removedItemIds: changed.removedItemIds.filter((id) => !present.has(id)),
        results,
        maxItems: this.#kitchen.maxItemsPerHousehold,
        referenceVersion: this.#referenceVersion(),
      };
    });
  }

  async #syncChange(
    tx: SqlExecutor,
    scope: HouseholdScope,
    change: SyncChangeInput,
    keptSince: Date,
    now: Date,
  ): Promise<SyncResultView> {
    // The age is left out: a replay is sent later, so its age has grown.
    const hash = keyedHash(
      this.#hashKey,
      "kitchen_sync_change",
      JSON.stringify([change.ingredient, change.operation, canonicalPatch(change.patch)]),
    );
    const stored = await findSyncChange(tx, scope.householdId, change.changeId, keptSince);
    if (stored !== null) {
      if (!Buffer.from(stored.request_hash).equals(hash)) {
        return {
          changeId: change.changeId,
          outcome: "rejected",
          itemId: null,
          errorCode: "idempotency_key_reused",
        };
      }
      return {
        changeId: change.changeId,
        outcome: stored.outcome,
        itemId: stored.item_id,
        errorCode: stored.error_code,
      };
    }
    let result: Omit<SyncResultView, "changeId">;
    try {
      result = await this.#applySyncChange(tx, scope, change, now);
    } catch (error) {
      if (!(error instanceof ApiError)) throw error;
      result = { outcome: "rejected", itemId: null, errorCode: error.code };
    }
    await rememberSyncChange(
      tx,
      scope.householdId,
      change.changeId,
      {
        requestHash: hash,
        outcome: result.outcome,
        itemId: result.itemId,
        errorCode: result.errorCode,
      },
      now,
    );
    return { changeId: change.changeId, ...result };
  }

  async #applySyncChange(
    tx: SqlExecutor,
    scope: HouseholdScope,
    change: SyncChangeInput,
    now: Date,
  ): Promise<Omit<SyncResultView, "changeId">> {
    const ref = ingredientRefOf(change.ingredient);
    // Never in the future (ageMs >= 0), and never older than the configured limit.
    const maxAgeMs = this.#kitchen.sync.maxChangeAgeHours * 3_600_000;
    const editedAt = new Date(now.getTime() - Math.min(change.ageMs, maxAgeMs));
    const existing = await findItemFor(tx, scope.householdId, ref);
    const removedAt = await lastRemovalOf(tx, scope.householdId, ref);
    const stored = existing === null ? null : (existing.client_changed_at ?? existing.changed_at);
    const latest = [stored, removedAt]
      .filter((at): at is Date => at !== null)
      .reduce<Date | null>((max, at) => (max === null || at > max ? at : max), null);
    if (latest !== null && editedAt.getTime() < latest.getTime()) {
      return { outcome: "superseded", itemId: existing?.id ?? null, errorCode: null };
    }
    if (change.operation === "remove") {
      if (existing !== null) await removeItem(tx, scope.householdId, existing, editedAt, now);
      else await recordRemoval(tx, scope.householdId, ref, editedAt, now);
      return { outcome: "applied", itemId: null, errorCode: null };
    }
    if (existing !== null) {
      const row = await this.#write(tx, scope, existing, change.patch, editedAt, now);
      return { outcome: "applied", itemId: row.id, errorCode: null };
    }
    const category = this.#categoryForNew(ref, change.patch.category ?? null, "");
    const row = await this.#insert(tx, scope, ref, change.patch, category, editedAt, now);
    return { outcome: "applied", itemId: row.id, errorCode: null };
  }

  // ------------------------------------------------------------ shared change path

  /**
   * The category of a new item: the one given, else the catalog's. A
   * reference ingredient must be in the verified dataset (503 without one,
   * 400 when unknown); a custom one must name its category.
   */
  #categoryForNew(
    ref: IngredientRef,
    given: KitchenCategory | null,
    pointer: string,
  ): KitchenCategory {
    if (ref.kind === "reference") {
      const known = this.#known(ref.ingredientId, `${pointer}/ingredientId`);
      const category = given ?? known.category;
      if (category === null) throw fieldError(`${pointer}/category`, "required");
      return category;
    }
    if (given === null) throw fieldError(`${pointer}/category`, "required");
    return given;
  }

  #known(ingredientId: string, pointer: string): CatalogIngredient {
    const loaded = this.#reference.current();
    if (loaded === null) throw referenceDataUnavailable();
    const known = loaded.catalog.get(ingredientId);
    if (known === null) throw fieldError(pointer, "invalid_value");
    return known;
  }

  /**
   * KIT-09, SAF-07: a reference brand must be one of the ingredient's brands
   * in the verified dataset; typed text is kept as text and never becomes a
   * reference brand, so Cek Aman keeps "Check the label" for it.
   */
  #brandValues(
    ingredientId: string | null,
    brand: BrandInput | null,
  ): Pick<ItemValues, "brandId" | "brandCustomName"> {
    if (brand === null) return { brandId: null, brandCustomName: null };
    if (brand.kind === "custom") {
      const name = cleanBrandName(brand.text);
      if (name === null) throw fieldError("/brand/customName", "invalid_format");
      return { brandId: null, brandCustomName: name };
    }
    if (ingredientId === null) throw fieldError("/brand/brandId", "not_allowed");
    const known = this.#known(ingredientId, "/brand/brandId");
    if (!known.brands.some((candidate) => candidate.brandId === brand.brandId)) {
      throw fieldError("/brand/brandId", "invalid_value");
    }
    return { brandId: brand.brandId, brandCustomName: null };
  }

  #values(
    row: KitchenItemRow | null,
    ingredientId: string | null,
    patch: ItemPatch,
    category: KitchenCategory,
    editedAt: Date,
  ): ItemValues {
    const state = patch.state ?? row?.state ?? "available";
    const brand =
      patch.brand === undefined
        ? { brandId: row?.brand_id ?? null, brandCustomName: row?.brand_custom_name ?? null }
        : this.#brandValues(ingredientId, patch.brand);
    return {
      category: patch.category ?? row?.category ?? category,
      state,
      quantity: patch.quantity === undefined ? (row?.quantity ?? null) : patch.quantity,
      ...brand,
      ...scoreAfter(row, state, editedAt, this.#kitchen.usageHalfLifeDays),
      editedAt,
    };
  }

  async #write(
    tx: SqlExecutor,
    scope: HouseholdScope,
    row: KitchenItemRow,
    patch: ItemPatch,
    editedAt: Date,
    now: Date,
  ): Promise<KitchenItemRow> {
    const values = this.#values(row, row.ingredient_id, patch, row.category, editedAt);
    const written = await writeItem(tx, scope.householdId, row.id, values, scope.accountId, now);
    if (written === null) throw new NotFoundError("kitchen item");
    return written;
  }

  async #insert(
    tx: SqlExecutor,
    scope: HouseholdScope,
    ref: IngredientRef,
    patch: ItemPatch,
    category: KitchenCategory,
    editedAt: Date,
    now: Date,
  ): Promise<KitchenItemRow> {
    const ingredientId = ref.kind === "reference" ? ref.ingredientId : null;
    const values = this.#values(null, ingredientId, patch, category, editedAt);
    if ((await countItems(tx, scope.householdId)) >= this.#kitchen.maxItemsPerHousehold) {
      throw kitchenItemLimitReached();
    }
    return insertItem(tx, {
      householdId: scope.householdId,
      accountId: scope.accountId,
      ref,
      values,
      isDefaultStaple: false,
      now,
    });
  }

  async #requireItems(
    tx: SqlExecutor,
    scope: HouseholdScope,
    itemIds: readonly string[],
  ): Promise<void> {
    const found = await readItems(tx, scope.householdId, itemIds);
    if (found.length !== itemIds.length) throw new NotFoundError("kitchen item");
  }

  #idempotencyKeptSince(now: Date): Date {
    return new Date(now.getTime() - this.#config.retention.idempotencyKeyHours * 3600_000);
  }

  #referenceVersion(): string | null {
    return this.#reference.current()?.verified.referenceVersion ?? null;
  }

  async #viewOne(
    tx: SqlExecutor,
    scope: HouseholdScope,
    row: KitchenItemRow,
  ): Promise<KitchenItemView> {
    const all = await listItems(tx, scope.householdId);
    const [view] = this.#views([row], all);
    if (view === undefined) throw new NotFoundError("kitchen item");
    return view;
  }

  /** Views of `rows`, ranked within the whole kitchen `all` (KIT-06), in display order. */
  #views(rows: readonly KitchenItemRow[], all: readonly KitchenItemRow[]): KitchenItemView[] {
    const ranks = usageRanks(all, this.#clock.now(), this.#kitchen.usageHalfLifeDays);
    const views = rows.map((row) => this.#view(row, ranks.get(row.id) ?? null));
    views.sort(
      (a, b) =>
        (CATEGORY_ORDER.get(a.category) ?? 99) - (CATEGORY_ORDER.get(b.category) ?? 99) ||
        (a.usageRank ?? Number.MAX_SAFE_INTEGER) - (b.usageRank ?? Number.MAX_SAFE_INTEGER) ||
        compare(sortName(a), sortName(b)) ||
        compare(a.id, b.id),
    );
    return views;
  }

  #view(row: KitchenItemRow, usageRank: number | null): KitchenItemView {
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
      usageRank,
      changedAt: row.changed_at,
      createdAt: row.created_at,
    };
  }
}

/** A sync change's ingredient; a custom name that cannot be stored is rejected (T-030 L1). */
function ingredientRefOf(input: IngredientKeyInput): IngredientRef {
  if (input.kind === "reference") return input;
  const ref = customIngredientRef(input.text);
  if (ref === null) throw fieldError("/ingredient/customName", "invalid_format");
  return ref;
}

function canonicalPatch(patch: ItemPatch): unknown[] {
  return [
    patch.state ?? null,
    patch.category ?? null,
    patch.quantity === undefined ? "absent" : patch.quantity,
    patch.brand === undefined ? "absent" : patch.brand,
  ];
}

function setView(row: IngredientSetRow): IngredientSetView {
  return {
    id: row.id,
    name: row.name,
    itemIds: [...row.item_ids],
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

function sortName(view: KitchenItemView): string {
  return foldName(view.displayName?.id ?? view.customName ?? view.ingredientId ?? "");
}

function compare(a: string, b: string): number {
  return a < b ? -1 : a > b ? 1 : 0;
}
