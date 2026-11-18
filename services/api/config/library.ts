/**
 * Recipe library settings (T-041; LIB-01, LIB-03, LIB-04, LIB-08).
 *
 * The SRS marks no library figure as (target) apart from the library size
 * (LIB-02), which is content planning, not code. Page sizes and list limits
 * are operational values, kept here so they change without a code change.
 * Overrides come from `LIBRARY_CONFIG_JSON`; unknown keys and out-of-range
 * values stop startup.
 */

import type { Schemas } from "@keluargamakan/contracts";

type Cuisine = Schemas["Cuisine"];

export interface LibraryConfig {
  readonly search: {
    /** Items per page when the request gives no `limit`. */
    readonly defaultLimit: number;
    /** Largest `limit` accepted (the contract allows at most 50). */
    readonly maxLimit: number;
  };
  /** LIB-04: regional versions listed on one recipe screen. */
  readonly maxRegionalVariants: number;
  /**
   * SUG-03, LIB-10: cuisines served. V1 serves Indonesian only; a recipe of
   * another cuisine is not listed or opened until its collection ships (V3).
   */
  readonly servedCuisines: readonly Cuisine[];
}

const LIMIT_CEILING = 50; // contract LibrarySearchRequest.limit maximum
const CUISINES: readonly Cuisine[] = ["indonesian", "japanese", "chinese", "fusion"];

export const defaultLibraryConfig: LibraryConfig = Object.freeze({
  search: Object.freeze({ defaultLimit: 20, maxLimit: 50 }),
  maxRegionalVariants: 10,
  servedCuisines: Object.freeze(["indonesian"] as Cuisine[]),
});

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function onlyKeys(record: Record<string, unknown>, allowed: readonly string[], path: string): void {
  for (const key of Object.keys(record)) {
    if (!allowed.includes(key)) throw new Error(`Unknown library config: ${path}${key}`);
  }
}

function wholeNumber(value: unknown, min: number, max: number, name: string): number {
  if (typeof value !== "number" || !Number.isInteger(value) || value < min || value > max) {
    throw new Error(`library config ${name} must be a whole number from ${min} to ${max}`);
  }
  return value;
}

function cuisines(value: unknown): readonly Cuisine[] {
  if (!Array.isArray(value) || value.length === 0) {
    throw new Error("library config servedCuisines must be a non-empty list");
  }
  const out = value.map((entry: unknown) => {
    if (!(CUISINES as readonly unknown[]).includes(entry)) {
      throw new Error("library config servedCuisines must hold contract Cuisine codes");
    }
    return entry as Cuisine;
  });
  if (new Set(out).size !== out.length) {
    throw new Error("library config servedCuisines repeats a cuisine");
  }
  return Object.freeze(out);
}

/** Defaults with the given values replaced. */
export function resolveLibraryConfig(overrides: unknown = {}): LibraryConfig {
  if (!isRecord(overrides)) throw new Error("library config must be an object");
  onlyKeys(overrides, ["search", "maxRegionalVariants", "servedCuisines"], "");
  const search = overrides["search"] ?? {};
  if (!isRecord(search)) throw new Error("library config search must be an object");
  onlyKeys(search, ["defaultLimit", "maxLimit"], "search.");
  const maxLimit = wholeNumber(
    search["maxLimit"] ?? defaultLibraryConfig.search.maxLimit,
    1,
    LIMIT_CEILING,
    "search.maxLimit",
  );
  const defaultLimit = wholeNumber(
    search["defaultLimit"] ?? Math.min(defaultLibraryConfig.search.defaultLimit, maxLimit),
    1,
    maxLimit,
    "search.defaultLimit",
  );
  return Object.freeze({
    search: Object.freeze({ defaultLimit, maxLimit }),
    maxRegionalVariants: wholeNumber(
      overrides["maxRegionalVariants"] ?? defaultLibraryConfig.maxRegionalVariants,
      0,
      30,
      "maxRegionalVariants",
    ),
    servedCuisines: Object.hasOwn(overrides, "servedCuisines")
      ? cuisines(overrides["servedCuisines"])
      : defaultLibraryConfig.servedCuisines,
  });
}

export function libraryConfigFromEnv(
  env: Readonly<Record<string, string | undefined>>,
): LibraryConfig {
  const raw = env["LIBRARY_CONFIG_JSON"]?.trim();
  if (raw === undefined || raw === "") return defaultLibraryConfig;
  let parsed: unknown;
  try {
    parsed = JSON.parse(raw);
  } catch {
    throw new Error("LIBRARY_CONFIG_JSON is not valid JSON");
  }
  return resolveLibraryConfig(parsed);
}
