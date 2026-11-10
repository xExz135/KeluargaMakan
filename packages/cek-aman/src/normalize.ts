import { DIET_SUITABILITY, HALAL_VALUES } from "./vocabulary.js";
import type { DietSuitability, HalalValue } from "./vocabulary.js";

/**
 * Reference data reaches the engine from storage, so the engine never trusts
 * its shape. Every reader below turns anything missing or malformed into
 * "unverified", which can only ever produce "Check the label" (fail closed).
 */

export interface NormalizedComponents {
  readonly verified: boolean;
  readonly ids: readonly string[];
}

export interface NormalizedAllergens {
  readonly verified: boolean;
  /** Raw tags; unrecognized ones are reported by the evaluator. */
  readonly contains: readonly string[];
  readonly mayContain: readonly string[];
}

export interface NormalizedHalal {
  readonly verified: boolean;
  readonly value: HalalValue;
  readonly sources: readonly string[];
}

export interface NormalizedDiet {
  readonly verified: boolean;
  readonly vegetarian: DietSuitability;
  readonly vegan: DietSuitability;
}

export interface NormalizedSafetyData {
  readonly components: NormalizedComponents;
  readonly allergens: NormalizedAllergens;
  readonly halal: NormalizedHalal;
  readonly diet: NormalizedDiet;
}

type Obj = Readonly<Record<string, unknown>>;

export function isObject(value: unknown): value is Obj {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

/** Returns the list when it is an array of strings, otherwise null. */
function stringList(value: unknown): readonly string[] | null {
  if (!Array.isArray(value)) return null;
  const list: unknown[] = value;
  return list.every((item) => typeof item === "string") ? list : null;
}

function oneOf<T extends string>(allowed: readonly T[], value: unknown, fallback: T): T {
  return (allowed as readonly unknown[]).includes(value) ? (value as T) : fallback;
}

function readComponents(raw: unknown): NormalizedComponents {
  const data = isObject(raw) ? raw : {};
  const ids = stringList(data["ingredientIds"]);
  return { verified: ids !== null && data["verification"] === "verified", ids: ids ?? [] };
}

function readAllergens(raw: unknown): NormalizedAllergens {
  const data = isObject(raw) ? raw : {};
  const contains = stringList(data["contains"]);
  const mayContain = stringList(data["mayContain"]);
  return {
    verified: contains !== null && mayContain !== null && data["verification"] === "verified",
    contains: contains ?? [],
    mayContain: mayContain ?? [],
  };
}

function readHalal(raw: unknown): NormalizedHalal {
  const data = isObject(raw) ? raw : {};
  return {
    verified: data["verification"] === "verified",
    value: oneOf(HALAL_VALUES, data["value"], "unknown"),
    sources: stringList(data["nonHalalSources"]) ?? [],
  };
}

function readDiet(raw: unknown): NormalizedDiet {
  const data = isObject(raw) ? raw : {};
  return {
    verified: data["verification"] === "verified",
    vegetarian: oneOf(DIET_SUITABILITY, data["vegetarian"], "unknown"),
    vegan: oneOf(DIET_SUITABILITY, data["vegan"], "unknown"),
  };
}

/** Reads the four safety dimensions of an ingredient or brand variant. */
export function readSafetyData(raw: Obj): NormalizedSafetyData {
  return {
    components: readComponents(raw["components"]),
    allergens: readAllergens(raw["allergens"]),
    halal: readHalal(raw["halal"]),
    diet: readDiet(raw["diet"]),
  };
}
