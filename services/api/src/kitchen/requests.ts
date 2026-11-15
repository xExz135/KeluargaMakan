import { KITCHEN_CATEGORIES, type KitchenCategory } from "../../config/kitchen.js";
import { isReferenceId } from "../db/ids.js";
import { cleanUserText, codePointLength } from "../http/text.js";
import { BodyReader, UUID_PATTERN } from "../http/validation.js";
import { foldName } from "../reference/fold.js";
import type { IngredientRef, KitchenItemState, KitchenQuantity } from "./kitchen-store.js";

/**
 * Request body parsers for the kitchen schemas of contract 0.2 (T-031,
 * T-032). They check the shape the contract gives; what the text means (a
 * storable name, a known ingredient or brand) is checked where it is used,
 * so one bad queued sync change is rejected on its own instead of failing
 * the whole sync. Field errors report a pointer and a code, never the text.
 */

const STATES: readonly KitchenItemState[] = ["available", "out"];
const QUANTITIES: readonly KitchenQuantity[] = ["a_little", "some", "plenty"];
const OPERATIONS = ["upsert", "remove"] as const;
export const CUSTOM_NAME_MAX = 60;
export const BRAND_NAME_MAX = 60;
export const SET_NAME_MAX = 40;
/** Contract `IngredientSetInput.itemIds` and `KitchenSyncRequest.changes`. */
export const SET_ITEMS_MAX = 200;
export const SYNC_CHANGES_MAX = 100;
/** Contract `KitchenChange.ageMs` maximum (30 days). */
export const AGE_MS_MAX = 2_592_000_000;
const CURSOR_MAX = 512;

export interface KitchenItemCreateInput {
  readonly ref: IngredientRef;
  readonly category: KitchenCategory | null;
  readonly state: KitchenItemState;
}

/** A brand as sent: a reference brand ID, or text still to be checked. */
export type BrandInput =
  | { readonly kind: "reference"; readonly brandId: string }
  | { readonly kind: "custom"; readonly text: string };

/** Fields a change sets; absent ones stay as they are. `null` clears quantity or brand. */
export interface ItemPatch {
  readonly state?: KitchenItemState;
  readonly category?: KitchenCategory;
  readonly quantity?: KitchenQuantity | null;
  readonly brand?: BrandInput | null;
}

/** Longest comparison key the database stores (migration 0008 `kitchen_item_custom_key_check`). */
export const CUSTOM_KEY_MAX = 240;

/**
 * KIT-05: a custom name in NFC, trimmed, without hidden or control
 * characters, and its comparison key; null when the name cannot be stored.
 * The key is NFKC-folded, which can make it much longer than the name (one
 * compatibility character can expand to 18), so it is bounded too (security
 * review T-030 L1). The sync uses the same check for
 * `KitchenIngredientKey.customName`.
 */
export function customIngredientRef(
  value: string,
): Extract<IngredientRef, { kind: "custom" }> | null {
  const clean = cleanUserText(value);
  if (clean === null || codePointLength(clean) > CUSTOM_NAME_MAX) return null;
  const key = foldName(clean);
  if (key === "" || codePointLength(key) > CUSTOM_KEY_MAX) return null;
  return { kind: "custom", name: clean, key };
}

/** KIT-09: a typed brand in NFC, or null when it cannot be stored. */
export function cleanBrandName(value: string): string | null {
  const clean = cleanUserText(value);
  return clean === null || codePointLength(clean) > BRAND_NAME_MAX ? null : clean;
}

/** Reports only the pointer, never the text. */
function customRef(reader: BodyReader, value: string, pointer: string): IngredientRef | null {
  const ref = customIngredientRef(value);
  if (ref === null) reader.fail(pointer, "invalid_format");
  return ref;
}

export function parseKitchenItemCreate(body: unknown): KitchenItemCreateInput {
  const reader = new BodyReader();
  const record = reader.object(body, "", ["ingredientId", "customName", "category", "state"]);
  let ref: IngredientRef | null = null;
  let category: KitchenCategory | null = null;
  let state: KitchenItemState = "available";
  if (record !== null) {
    const hasReference = Object.hasOwn(record, "ingredientId");
    const hasCustom = Object.hasOwn(record, "customName");
    if (hasReference === hasCustom) {
      // Exactly one of the two.
      reader.fail(
        hasReference ? "/customName" : "/ingredientId",
        hasReference ? "not_allowed" : "required",
      );
    } else if (hasReference) {
      const id = record["ingredientId"];
      if (typeof id !== "string") reader.fail("/ingredientId", "invalid_type");
      else if (!isReferenceId(id)) reader.fail("/ingredientId", "invalid_format");
      else ref = { kind: "reference", ingredientId: id };
    } else {
      const name = reader.string(record, "customName", "", {
        required: true,
        minLength: 1,
        maxLength: CUSTOM_NAME_MAX,
      });
      if (typeof name === "string") ref = customRef(reader, name, "/customName");
    }
    category = reader.enumValue(record, "category", "", KITCHEN_CATEGORIES, false) ?? null;
    state = reader.enumValue(record, "state", "", STATES, false) ?? "available";
    if (hasCustom && !hasReference && !Object.hasOwn(record, "category")) {
      reader.fail("/category", "required");
    }
  }
  reader.done();
  return { ref: ref as IngredientRef, category, state };
}

/** `KitchenBrandInput` or null; undefined when absent or invalid (an error is recorded). */
function readBrand(
  reader: BodyReader,
  record: Readonly<Record<string, unknown>>,
  pointer: string,
): BrandInput | null | undefined {
  if (!Object.hasOwn(record, "brand")) return undefined;
  const value = record["brand"];
  if (value === null) return null;
  const at = `${pointer}/brand`;
  const brand = reader.object(value, at, ["brandId", "customName"]);
  if (brand === null) return undefined;
  const hasId = Object.hasOwn(brand, "brandId");
  const hasText = Object.hasOwn(brand, "customName");
  if (hasId === hasText) {
    reader.fail(hasId ? `${at}/customName` : `${at}/brandId`, hasId ? "not_allowed" : "required");
    return undefined;
  }
  if (hasId) {
    const id = brand["brandId"];
    if (typeof id !== "string") reader.fail(`${at}/brandId`, "invalid_type");
    else if (!isReferenceId(id)) reader.fail(`${at}/brandId`, "invalid_format");
    else return { kind: "reference", brandId: id };
    return undefined;
  }
  const text = reader.string(brand, "customName", at, {
    required: true,
    minLength: 1,
    maxLength: BRAND_NAME_MAX,
  });
  return typeof text === "string" ? { kind: "custom", text } : undefined;
}

/** The optional patch fields of `KitchenItemUpdate` and `KitchenChange`. */
function readPatch(
  reader: BodyReader,
  record: Readonly<Record<string, unknown>>,
  pointer: string,
): ItemPatch {
  const out: {
    state?: KitchenItemState;
    category?: KitchenCategory;
    quantity?: KitchenQuantity | null;
    brand?: BrandInput | null;
  } = {};
  const state = reader.enumValue(record, "state", pointer, STATES, false);
  const category = reader.enumValue(record, "category", pointer, KITCHEN_CATEGORIES, false);
  if (state !== undefined) out.state = state;
  if (category !== undefined) out.category = category;
  if (Object.hasOwn(record, "quantity")) {
    if (record["quantity"] === null) out.quantity = null;
    else {
      const quantity = reader.enumValue(record, "quantity", pointer, QUANTITIES, false);
      if (quantity !== undefined) out.quantity = quantity;
    }
  }
  const brand = readBrand(reader, record, pointer);
  if (brand !== undefined) out.brand = brand;
  return out;
}

/** KIT-02, KIT-03, KIT-09: `KitchenItemUpdate`, at least one field. */
export function parseKitchenItemUpdate(body: unknown): ItemPatch {
  const reader = new BodyReader();
  const record = reader.object(body, "", ["state", "category", "quantity", "brand"]);
  let patch: ItemPatch = {};
  if (record !== null) {
    if (Object.keys(record).length === 0) reader.fail("", "required");
    patch = readPatch(reader, record, "");
  }
  reader.done();
  return patch;
}

export interface IngredientSetInput {
  readonly name: string;
  /** Unique, lower case. */
  readonly itemIds: readonly string[];
}

/** KIT-08: `IngredientSetInput`. */
export function parseIngredientSetInput(body: unknown): IngredientSetInput {
  const reader = new BodyReader();
  const record = reader.object(body, "", ["name", "itemIds"]);
  let name = "";
  const itemIds: string[] = [];
  if (record !== null) {
    const raw = reader.string(record, "name", "", {
      required: true,
      minLength: 1,
      maxLength: SET_NAME_MAX,
    });
    if (typeof raw === "string") {
      const clean = cleanUserText(raw);
      if (clean === null || codePointLength(clean) > SET_NAME_MAX) {
        reader.fail("/name", "invalid_format");
      } else {
        name = clean;
      }
    }
    if (!Object.hasOwn(record, "itemIds")) reader.fail("/itemIds", "required");
    else if (!Array.isArray(record["itemIds"])) reader.fail("/itemIds", "invalid_type");
    else {
      const list = record["itemIds"] as unknown[];
      if (list.length > SET_ITEMS_MAX) reader.fail("/itemIds", "too_many_items");
      list.forEach((id, index) => {
        if (typeof id !== "string" || !UUID_PATTERN.test(id)) {
          reader.fail(`/itemIds/${index}`, "invalid_format");
        } else if (itemIds.includes(id.toLowerCase())) {
          reader.fail(`/itemIds/${index}`, "duplicate");
        } else {
          itemIds.push(id.toLowerCase());
        }
      });
    }
  }
  reader.done();
  return { name, itemIds };
}

/** The ingredient a sync change names, before its text is checked. */
export type IngredientKeyInput =
  | { readonly kind: "reference"; readonly ingredientId: string }
  | { readonly kind: "custom"; readonly text: string };

export interface SyncChangeInput {
  readonly changeId: string;
  readonly ingredient: IngredientKeyInput;
  readonly operation: (typeof OPERATIONS)[number];
  readonly ageMs: number;
  readonly patch: ItemPatch;
}

export interface SyncInput {
  readonly cursor: string | null;
  readonly changes: readonly SyncChangeInput[];
}

/**
 * KIT-16: `KitchenSyncRequest`. A request that does not have the contract's
 * shape is refused whole (400); the meaning of each change is checked when
 * it is applied, and a bad one is rejected on its own.
 */
export function parseKitchenSync(body: unknown): SyncInput {
  const reader = new BodyReader();
  const record = reader.object(body, "", ["cursor", "changes"]);
  let cursor: string | null = null;
  const changes: SyncChangeInput[] = [];
  if (record !== null) {
    if (!Object.hasOwn(record, "cursor")) reader.fail("/cursor", "required");
    else {
      const value = reader.string(record, "cursor", "", {
        nullable: true,
        minLength: 1,
        maxLength: CURSOR_MAX,
      });
      if (typeof value === "string") cursor = value;
    }
    if (!Object.hasOwn(record, "changes")) reader.fail("/changes", "required");
    else if (!Array.isArray(record["changes"])) reader.fail("/changes", "invalid_type");
    else {
      const list = record["changes"] as unknown[];
      if (list.length > SYNC_CHANGES_MAX) reader.fail("/changes", "too_many_items");
      else {
        list.forEach((raw, index) => {
          const change = readChange(reader, raw, `/changes/${index}`);
          if (change !== null) changes.push(change);
        });
      }
    }
  }
  reader.done();
  return { cursor, changes };
}

function readChange(reader: BodyReader, raw: unknown, at: string): SyncChangeInput | null {
  const record = reader.object(raw, at, [
    "changeId",
    "ingredient",
    "operation",
    "ageMs",
    "category",
    "state",
    "quantity",
    "brand",
  ]);
  if (record === null) return null;
  const before = reader.errors.length;
  const changeId = reader.string(record, "changeId", at, { required: true, pattern: UUID_PATTERN });
  const operation = reader.enumValue(record, "operation", at, OPERATIONS, true);
  // Only the type is checked here: an age out of range rejects just this
  // change when it is applied (security review T-032 L3).
  let ageMs = 0;
  if (!Object.hasOwn(record, "ageMs")) reader.fail(`${at}/ageMs`, "required");
  else {
    const value = record["ageMs"];
    if (typeof value !== "number" || !Number.isSafeInteger(value)) {
      reader.fail(`${at}/ageMs`, "invalid_type");
    } else {
      ageMs = value;
    }
  }
  let ingredient: IngredientKeyInput | null = null;
  if (!Object.hasOwn(record, "ingredient")) reader.fail(`${at}/ingredient`, "required");
  else {
    const key = reader.object(record["ingredient"], `${at}/ingredient`, [
      "ingredientId",
      "customName",
    ]);
    if (key !== null) {
      const hasId = Object.hasOwn(key, "ingredientId");
      const hasText = Object.hasOwn(key, "customName");
      if (hasId === hasText) {
        reader.fail(
          `${at}/ingredient/${hasId ? "customName" : "ingredientId"}`,
          hasId ? "not_allowed" : "required",
        );
      } else if (hasId) {
        const id = key["ingredientId"];
        if (typeof id !== "string") reader.fail(`${at}/ingredient/ingredientId`, "invalid_type");
        else if (!isReferenceId(id)) reader.fail(`${at}/ingredient/ingredientId`, "invalid_format");
        else ingredient = { kind: "reference", ingredientId: id };
      } else {
        const text = reader.string(key, "customName", `${at}/ingredient`, {
          required: true,
          minLength: 1,
          maxLength: CUSTOM_NAME_MAX,
        });
        if (typeof text === "string") ingredient = { kind: "custom", text };
      }
    }
  }
  const patch = readPatch(reader, record, at);
  if (reader.errors.length > before || ingredient === null || operation === undefined) return null;
  return {
    changeId: (changeId as string).toLowerCase(),
    ingredient,
    operation,
    ageMs,
    patch,
  };
}
