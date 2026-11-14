/**
 * Dapur Saya settings (T-031).
 *
 * - `defaultStaples` (KIT-07, ACC-05): the reference ingredients every new
 *   household starts with as available. Which ingredients they are (the SRS
 *   names rice, shallots, garlic, chili, salt and kecap) is content: the IDs
 *   come from the human-owned reference data, so agents never fill them in.
 *   Until the content team sets them the list is empty and
 *   `pendingContentReview` is true. Each entry names its KIT-03 category, so
 *   the list does not depend on how the reference data spells categories.
 * - Limits and search sizes are operational values, not SRS (target) figures.
 *
 * Overrides come from `KITCHEN_CONFIG_JSON` without a code change; unknown
 * keys and out-of-range values stop startup.
 */

import { ID_PATTERN } from "@keluargamakan/cek-aman";

export const KITCHEN_CATEGORIES = [
  "protein",
  "vegetables",
  "fruit",
  "spices_aromatics",
  "staples",
  "sauces_condiments",
  "dairy",
  "frozen",
  "leftovers",
] as const;
export type KitchenCategory = (typeof KITCHEN_CATEGORIES)[number];

export function isKitchenCategory(value: unknown): value is KitchenCategory {
  return typeof value === "string" && (KITCHEN_CATEGORIES as readonly string[]).includes(value);
}

export interface DefaultStaple {
  readonly ingredientId: string;
  readonly category: KitchenCategory;
}

export interface KitchenConfig {
  readonly defaultStaples: readonly DefaultStaple[];
  /** True while `defaultStaples` is not set by the content team. */
  readonly pendingContentReview: boolean;
  readonly maxItemsPerHousehold: number;
  readonly search: {
    readonly defaultResults: number;
    readonly maxResults: number;
  };
}

const MAX_STAPLES = 30;
const SEARCH_LIMIT_CEILING = 50; // contract IngredientSearchRequest.limit maximum

export const defaultKitchenConfig: KitchenConfig = Object.freeze({
  defaultStaples: Object.freeze([]),
  pendingContentReview: true,
  maxItemsPerHousehold: 500,
  search: Object.freeze({ defaultResults: 20, maxResults: 50 }),
});

const REFERENCE_ID = new RegExp(ID_PATTERN);

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function onlyKeys(record: Record<string, unknown>, allowed: readonly string[], path: string): void {
  for (const key of Object.keys(record)) {
    if (!allowed.includes(key)) throw new Error(`Unknown kitchen config: ${path}${key}`);
  }
}

function wholeNumber(value: unknown, min: number, max: number, name: string): number {
  if (typeof value !== "number" || !Number.isInteger(value) || value < min || value > max) {
    throw new Error(`kitchen config ${name} must be a whole number from ${min} to ${max}`);
  }
  return value;
}

function staples(value: unknown): readonly DefaultStaple[] {
  if (!Array.isArray(value)) throw new Error("kitchen config defaultStaples must be a list");
  if (value.length > MAX_STAPLES) {
    throw new Error(`kitchen config defaultStaples has more than ${MAX_STAPLES} entries`);
  }
  const seen = new Set<string>();
  return Object.freeze(
    value.map((entry: unknown, index) => {
      const at = `defaultStaples[${index}]`;
      if (!isRecord(entry)) throw new Error(`kitchen config ${at} must be an object`);
      onlyKeys(entry, ["ingredientId", "category"], `${at}.`);
      const { ingredientId, category } = entry;
      if (typeof ingredientId !== "string" || !REFERENCE_ID.test(ingredientId)) {
        throw new Error(`kitchen config ${at}.ingredientId must be a reference ingredient ID`);
      }
      if (!isKitchenCategory(category)) {
        throw new Error(`kitchen config ${at}.category must be a KIT-03 category code`);
      }
      if (seen.has(ingredientId)) throw new Error(`kitchen config ${at} repeats an ingredient`);
      seen.add(ingredientId);
      return Object.freeze({ ingredientId, category });
    }),
  );
}

/** Defaults with the given values replaced. */
export function resolveKitchenConfig(overrides: unknown = {}): KitchenConfig {
  if (!isRecord(overrides)) throw new Error("kitchen config must be an object");
  onlyKeys(overrides, ["defaultStaples", "maxItemsPerHousehold", "search"], "");
  const search = overrides["search"] ?? {};
  if (!isRecord(search)) throw new Error("kitchen config search must be an object");
  onlyKeys(search, ["defaultResults", "maxResults"], "search.");
  const maxResults = wholeNumber(
    search["maxResults"] ?? defaultKitchenConfig.search.maxResults,
    1,
    SEARCH_LIMIT_CEILING,
    "search.maxResults",
  );
  const defaultResults = wholeNumber(
    search["defaultResults"] ?? Math.min(defaultKitchenConfig.search.defaultResults, maxResults),
    1,
    maxResults,
    "search.defaultResults",
  );
  const given = Object.hasOwn(overrides, "defaultStaples");
  return Object.freeze({
    defaultStaples: given
      ? staples(overrides["defaultStaples"])
      : defaultKitchenConfig.defaultStaples,
    pendingContentReview: !given,
    maxItemsPerHousehold: wholeNumber(
      overrides["maxItemsPerHousehold"] ?? defaultKitchenConfig.maxItemsPerHousehold,
      MAX_STAPLES,
      5000,
      "maxItemsPerHousehold",
    ),
    search: Object.freeze({ defaultResults, maxResults }),
  });
}

export function kitchenConfigFromEnv(
  env: Readonly<Record<string, string | undefined>>,
): KitchenConfig {
  const raw = env["KITCHEN_CONFIG_JSON"]?.trim();
  if (raw === undefined || raw === "") return defaultKitchenConfig;
  let parsed: unknown;
  try {
    parsed = JSON.parse(raw);
  } catch {
    throw new Error("KITCHEN_CONFIG_JSON is not valid JSON");
  }
  return resolveKitchenConfig(parsed);
}
