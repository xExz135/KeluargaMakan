import type { KitchenConfig } from "../../config/kitchen.js";
import type { ReferenceSource } from "../reference/reference-data.js";

/**
 * KIT-07: every configured default staple must be an ingredient of the
 * verified reference dataset, so a configuration mistake stops startup
 * instead of giving every new household an unknown ingredient. Staples that
 * cannot be checked, because no verified dataset is loaded, stop startup too
 * (security review T-030 L2): unchecked IDs are never stored for new
 * households. With no staples configured there is nothing to check.
 */
export function checkStaplesInReference(config: KitchenConfig, reference: ReferenceSource): void {
  if (config.defaultStaples.length === 0) return;
  const catalog = reference.current()?.catalog;
  if (catalog === undefined) {
    throw new Error(
      "kitchen config defaultStaples cannot be checked: no verified reference dataset is loaded",
    );
  }
  const missing = config.defaultStaples
    .map((staple) => staple.ingredientId)
    .filter((id) => catalog.get(id) === null);
  if (missing.length > 0) {
    throw new Error(
      `kitchen config defaultStaples names ingredients missing from the reference data: ${missing.join(", ")}`,
    );
  }
}
