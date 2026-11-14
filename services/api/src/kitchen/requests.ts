import { KITCHEN_CATEGORIES, type KitchenCategory } from "../../config/kitchen.js";
import { isReferenceId } from "../db/ids.js";
import { cleanUserText, codePointLength } from "../http/text.js";
import { BodyReader } from "../http/validation.js";
import { foldName } from "../reference/fold.js";
import type { IngredientRef, KitchenItemState } from "./kitchen-store.js";

/** Request body parsers for the kitchen schemas of contract 0.2.0 (T-031). */

const STATES: readonly KitchenItemState[] = ["available", "out"];
export const CUSTOM_NAME_MAX = 60;

export interface KitchenItemCreateInput {
  readonly ref: IngredientRef;
  readonly category: KitchenCategory | null;
  readonly state: KitchenItemState;
}

export interface KitchenItemUpdateInput {
  readonly state?: KitchenItemState;
  readonly category?: KitchenCategory;
}

/** Longest comparison key the database stores (migration 0008 `kitchen_item_custom_key_check`). */
export const CUSTOM_KEY_MAX = 240;

/**
 * KIT-05: a custom name in NFC, trimmed, without hidden or control
 * characters, and its comparison key; null when the name cannot be stored.
 * The key is NFKC-folded, which can make it much longer than the name (one
 * compatibility character can expand to 18), so it is bounded too (security
 * review T-030 L1). The sync (T-032) uses the same check for its
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

export function parseKitchenItemUpdate(body: unknown): KitchenItemUpdateInput {
  const reader = new BodyReader();
  // `quantity` and `brand` (KIT-09) are served from T-032.
  const record = reader.object(body, "", ["state", "category"]);
  const out: { state?: KitchenItemState; category?: KitchenCategory } = {};
  if (record !== null) {
    if (Object.keys(record).length === 0) reader.fail("", "required");
    const state = reader.enumValue(record, "state", "", STATES, false);
    const category = reader.enumValue(record, "category", "", KITCHEN_CATEGORIES, false);
    if (state !== undefined) out.state = state;
    if (category !== undefined) out.category = category;
  }
  reader.done();
  return out;
}
