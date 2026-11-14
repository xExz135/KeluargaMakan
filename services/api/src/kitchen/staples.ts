import type { KitchenConfig } from "../../config/kitchen.js";
import type { ReferenceSource } from "../reference/reference-data.js";

/**
 * KIT-07: every configured default staple must be an ingredient of the
 * verified reference dataset, so a configuration mistake stops startup
 * instead of giving every new household an unknown ingredient. When no
 * dataset is loaded there is nothing to check against; the catalog routes
 * then answer 503 and Cek Aman cannot run either.
 */
export function checkStaplesInReference(config: KitchenConfig, reference: ReferenceSource): void {
  const catalog = reference.current()?.catalog;
  if (catalog === undefined) return;
  const missing = config.defaultStaples
    .map((staple) => staple.ingredientId)
    .filter((id) => catalog.get(id) === null);
  if (missing.length > 0) {
    throw new Error(
      `kitchen config defaultStaples names ingredients missing from the reference data: ${missing.join(", ")}`,
    );
  }
}
