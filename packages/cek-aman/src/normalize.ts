import { DIET_SUITABILITY, HALAL_VALUES } from "./vocabulary.js";
import type { DietSuitability, HalalValue } from "./vocabulary.js";

/**
 * Reference data reaches the engine from storage, so the engine never trusts
 * its shape. Every reader below turns anything missing or malformed into
 * "unverified", which can only ever produce "Check the label" (fail closed).
 *
 * Every field of every input object is read with `own` and every list with
 * `ownItems`, so a value inherited from a polluted `Object.prototype` (or
 * `Array.prototype`) can never stand in for missing data (SAF-01).
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
  /** Every listed source, even from a malformed list: any source fails a halal rule (SAF-08). */
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

/** Reads an own property only; an inherited value reads as missing (SAF-01, fail closed). */
export function own(obj: Obj, key: string): unknown {
  return Object.hasOwn(obj, key) ? obj[key] : undefined;
}

/** Own elements of an array, with holes read as undefined, or null when it is not an array. */
export function ownItems(value: unknown): readonly unknown[] | null {
  if (!Array.isArray(value)) return null;
  const list: readonly unknown[] = value;
  return Array.from({ length: list.length }, (_, index) =>
    Object.hasOwn(list, index) ? list[index] : undefined,
  );
}

/** Own elements of the list at `obj[key]`; empty when either is missing or malformed. */
export function ownList(obj: unknown, key: string): readonly unknown[] {
  return (isObject(obj) ? ownItems(own(obj, key)) : null) ?? [];
}

/** Returns the list when it is an array of strings, otherwise null. */
function stringList(value: unknown): readonly string[] | null {
  const list = ownItems(value);
  if (list === null) return null;
  return list.every((item) => typeof item === "string") ? list : null;
}

function oneOf<T extends string>(allowed: readonly T[], value: unknown, fallback: T): T {
  return (allowed as readonly unknown[]).includes(value) ? (value as T) : fallback;
}

function readComponents(raw: unknown): NormalizedComponents {
  const data = isObject(raw) ? raw : {};
  const ids = stringList(own(data, "ingredientIds"));
  return { verified: ids !== null && own(data, "verification") === "verified", ids: ids ?? [] };
}

function readAllergens(raw: unknown): NormalizedAllergens {
  const data = isObject(raw) ? raw : {};
  const contains = stringList(own(data, "contains"));
  const mayContain = stringList(own(data, "mayContain"));
  return {
    verified: contains !== null && mayContain !== null && own(data, "verification") === "verified",
    contains: contains ?? [],
    mayContain: mayContain ?? [],
  };
}

function readHalal(raw: unknown): NormalizedHalal {
  const data = isObject(raw) ? raw : {};
  const listed = own(data, "nonHalalSources");
  const items = ownItems(listed);
  return {
    // A missing or malformed source list means the halal data are not usable.
    verified: stringList(listed) !== null && own(data, "verification") === "verified",
    value: oneOf(HALAL_VALUES, own(data, "value"), "unknown"),
    sources: (items ?? []).filter((item): item is string => typeof item === "string"),
  };
}

function readDiet(raw: unknown): NormalizedDiet {
  const data = isObject(raw) ? raw : {};
  return {
    verified: own(data, "verification") === "verified",
    vegetarian: oneOf(DIET_SUITABILITY, own(data, "vegetarian"), "unknown"),
    vegan: oneOf(DIET_SUITABILITY, own(data, "vegan"), "unknown"),
  };
}

/** Reads the four safety dimensions of an ingredient or brand variant. */
export function readSafetyData(raw: Obj): NormalizedSafetyData {
  return {
    components: readComponents(own(raw, "components")),
    allergens: readAllergens(own(raw, "allergens")),
    halal: readHalal(own(raw, "halal")),
    diet: readDiet(own(raw, "diet")),
  };
}
