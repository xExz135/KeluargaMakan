import type { RecipeIngredientInput, RecordedBrand } from "@keluargamakan/cek-aman";

/**
 * How a kitchen item enters a Cek Aman evaluation (T-043 uses this for
 * recipes adapted to what is in the kitchen, Taste & Tweak fixes and
 * leftover remakes). A custom ingredient (KIT-05) has no reference ID, so it
 * goes in unresolved (`ingredientId: null`) and the engine gives "Check the
 * label" to every member with a hard rule (SAF-09). Nothing here decides
 * safety: only the engine does (SAF-01).
 */
export interface KitchenIngredient {
  readonly ingredientId: string | null;
  readonly customName: string | null;
  readonly brand: { readonly brandId: string | null } | null;
}

export function kitchenIngredientInput(item: KitchenIngredient): RecipeIngredientInput {
  return {
    ingredientId: item.ingredientId,
    rawName: item.ingredientId ?? item.customName ?? "",
  };
}

/** SAF-07: only a reference brand on a reference ingredient is a recorded brand; typed text is not. */
export function kitchenRecordedBrand(item: KitchenIngredient): RecordedBrand | null {
  const brandId = item.brand?.brandId ?? null;
  return item.ingredientId === null || brandId === null
    ? null
    : { ingredientId: item.ingredientId, brandId };
}
