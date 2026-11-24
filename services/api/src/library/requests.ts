import type { Schemas } from "@keluargamakan/contracts";

import type { LibraryConfig } from "../../config/library.js";
import { cleanUserText, codePointLength } from "../http/text.js";
import { BodyReader } from "../http/validation.js";
import type { EaterSelection } from "../safety/eaters.js";

/**
 * Request bodies of the library routes (contract 0.3 `LibrarySearchRequest`,
 * `RecipeDetailRequest`, `EaterSelection`). Field errors name the pointer
 * and a code, never the value: the search text is never echoed, stored or
 * logged.
 */

const ID = /^[a-z0-9][a-z0-9_.-]{0,99}$/;
const PAGE_CURSOR = /^[A-Za-z0-9_-]{1,512}$/;
const QUERY_MAX = 60;
const MEMBER_IDS_MAX = 50;
const REGION_IDS_MAX = 20;
const SUBSTITUTION_IDS_MAX = 20;

const EATER_MODES: readonly Schemas["EaterMode"][] = ["only_me", "whole_family", "selected"];
const MEAL_TYPES: readonly Schemas["MealType"][] = [
  "breakfast",
  "lunch",
  "dinner",
  "snack",
  "sahur",
  "buka",
];
const TIMES: readonly Schemas["TimeAvailable"][] = ["up_to_15", "up_to_30", "up_to_60", "over_60"];

/** A list of unique strings; each item must match `pattern` or be one of `values`. */
function stringList(
  reader: BodyReader,
  record: Readonly<Record<string, unknown>>,
  key: string,
  pointer: string,
  options: {
    readonly max: number;
    readonly pattern?: RegExp;
    readonly values?: readonly string[];
    readonly required?: boolean;
  },
): string[] | undefined {
  const at = `${pointer}/${key}`;
  if (!Object.hasOwn(record, key)) {
    if (options.required === true) reader.fail(at, "required");
    return undefined;
  }
  const value = record[key];
  if (!Array.isArray(value)) {
    reader.fail(at, "invalid_type");
    return undefined;
  }
  if (value.length > options.max) {
    reader.fail(at, "too_many_items");
    return undefined;
  }
  const seen = new Set<string>();
  let ok = true;
  value.forEach((item: unknown, index) => {
    if (typeof item !== "string") {
      reader.fail(`${at}/${index}`, "invalid_type");
      ok = false;
    } else if (options.pattern !== undefined && !options.pattern.test(item)) {
      reader.fail(`${at}/${index}`, "invalid_format");
      ok = false;
    } else if (options.values !== undefined && !options.values.includes(item)) {
      reader.fail(`${at}/${index}`, "invalid_value");
      ok = false;
    } else if (seen.has(item)) {
      reader.fail(`${at}/${index}`, "duplicate");
      ok = false;
    } else {
      seen.add(item);
    }
  });
  return ok ? (value as string[]) : undefined;
}

function parseEaters(
  reader: BodyReader,
  record: Readonly<Record<string, unknown>>,
): EaterSelection | null {
  if (!Object.hasOwn(record, "eaters")) {
    reader.fail("/eaters", "required");
    return null;
  }
  const eaters = reader.object(record["eaters"], "/eaters", ["mode", "memberIds"]);
  if (eaters === null) return null;
  const mode = reader.enumValue(eaters, "mode", "/eaters", EATER_MODES, true);
  const memberIds = stringList(reader, eaters, "memberIds", "/eaters", {
    max: MEMBER_IDS_MAX,
    pattern: ID,
    required: true,
  });
  if (mode === undefined || memberIds === undefined) return null;
  // PRF-09: `selected` names at least one member; the other modes name none.
  if ((mode === "selected") !== memberIds.length > 0) {
    reader.fail("/eaters/memberIds", "invalid_value");
    return null;
  }
  return { mode, memberIds };
}

function optionalId(
  reader: BodyReader,
  record: Readonly<Record<string, unknown>>,
  key: string,
): string | undefined {
  const value = reader.string(record, key, "", { pattern: ID });
  return typeof value === "string" ? value : undefined;
}

export interface LibrarySearchInput {
  readonly eaters: EaterSelection;
  /** Cleaned (NFC, trimmed); never stored or logged. */
  readonly query: string | null;
  readonly regionIds: readonly string[];
  readonly mealTypes: readonly Schemas["MealType"][];
  readonly timeAvailable: Schemas["TimeAvailable"] | null;
  readonly includeNotSafe: boolean;
  readonly cursor: string | null;
  readonly limit: number;
}

export function parseLibrarySearch(body: unknown, config: LibraryConfig): LibrarySearchInput {
  const reader = new BodyReader();
  const record = reader.object(body, "", [
    "eaters",
    "query",
    "regionIds",
    "mealTypes",
    "timeAvailable",
    "includeNotSafe",
    "cursor",
    "limit",
  ]);
  if (record === null) {
    reader.done();
    throw new Error("unreachable");
  }
  const eaters = parseEaters(reader, record);

  let query: string | null = null;
  const raw = reader.string(record, "query", "", { minLength: 1, maxLength: QUERY_MAX });
  if (typeof raw === "string") {
    // Hidden or control characters are refused (contract LibrarySearchRequest).
    const clean = cleanUserText(raw);
    if (clean === null || codePointLength(clean) > QUERY_MAX)
      reader.fail("/query", "invalid_format");
    else query = clean;
  }

  const regionIds =
    stringList(reader, record, "regionIds", "", { max: REGION_IDS_MAX, pattern: ID }) ?? [];
  const mealTypes = (stringList(reader, record, "mealTypes", "", {
    max: MEAL_TYPES.length,
    values: MEAL_TYPES,
  }) ?? []) as Schemas["MealType"][];
  const timeAvailable = reader.enumValue(record, "timeAvailable", "", TIMES, false) ?? null;

  let includeNotSafe = false;
  if (Object.hasOwn(record, "includeNotSafe")) {
    const value = record["includeNotSafe"];
    if (typeof value !== "boolean") reader.fail("/includeNotSafe", "invalid_type");
    else includeNotSafe = value;
  }

  let cursor: string | null = null;
  if (Object.hasOwn(record, "cursor") && record["cursor"] !== null) {
    const value = reader.string(record, "cursor", "", { pattern: PAGE_CURSOR });
    if (typeof value === "string") cursor = value;
  }

  let limit = config.search.defaultLimit;
  if (Object.hasOwn(record, "limit")) {
    const value = record["limit"];
    if (typeof value !== "number" || !Number.isInteger(value)) {
      reader.fail("/limit", "invalid_type");
    } else if (value < 1 || value > config.search.maxLimit) {
      reader.fail("/limit", "invalid_value");
    } else {
      limit = value;
    }
  }
  reader.done();
  if (eaters === null) throw new Error("unreachable: eaters failed without an error");
  return { eaters, query, regionIds, mealTypes, timeAvailable, includeNotSafe, cursor, limit };
}

export interface RecipeDetailInput {
  readonly eaters: EaterSelection;
  readonly adaptationId: string | null;
  readonly substitutionIds: readonly string[];
  readonly variantId: string | null;
}

export function parseRecipeDetail(body: unknown): RecipeDetailInput {
  const reader = new BodyReader();
  const record = reader.object(body, "", [
    "eaters",
    "adaptationId",
    "substitutionIds",
    "variantId",
  ]);
  if (record === null) {
    reader.done();
    throw new Error("unreachable");
  }
  const eaters = parseEaters(reader, record);
  const adaptationId = optionalId(reader, record, "adaptationId") ?? null;
  const substitutionIds =
    stringList(reader, record, "substitutionIds", "", {
      max: SUBSTITUTION_IDS_MAX,
      pattern: ID,
    }) ?? [];
  const variantId = optionalId(reader, record, "variantId") ?? null;
  reader.done();
  if (eaters === null) throw new Error("unreachable: eaters failed without an error");
  return { eaters, adaptationId, substitutionIds, variantId };
}
