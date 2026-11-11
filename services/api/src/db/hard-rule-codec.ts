import {
  HARD_RULE_TYPES,
  MAPPING_CONFIRMERS,
  MAPPING_STATUSES,
  STANDARD_ALLERGENS,
  type HardRule as CekAmanHardRule,
  type HardRuleType,
  type MappingConfirmer,
  type MappingStatus,
  type StandardAllergen,
} from "@keluargamakan/cek-aman";

import { isReferenceId } from "./ids.js";

/**
 * The encrypted body of an SRS 18.1 Hard rule: type, allergen, free text and
 * the PRF-08 mapping (status, mapped ingredients, confirmer). It is validated
 * on every write and on every read. A body that fails validation on read is
 * never skipped: the caller turns it into `RulesUnavailableError("malformed")`
 * (QUESTIONS #39).
 */

export const RULE_BODY_VERSION = 1;
export const FREE_TEXT_MAX = 200;
export const MAPPED_INGREDIENTS_MAX = 20;

/**
 * Security re-check T-016 N1: every hard-rule body is padded to this one size
 * before encryption, so the ciphertext length does not reveal the rule type or
 * allergen. The largest valid body (200 characters of free text that JSON
 * escapes to 6 bytes each, 20 mapped IDs of 100 characters, the longest type,
 * status and confirmer) is about 3.4 KiB; a test builds it and checks it fits.
 * A body that does not fit is refused, never truncated.
 */
export const HARD_RULE_PADDED_BYTES = 4096;
/** Content bytes that fit `HARD_RULE_PADDED_BYTES` after the 4-byte length prefix. */
export const HARD_RULE_BODY_MAX_BYTES = HARD_RULE_PADDED_BYTES - 4;

export interface RuleMappingBody {
  readonly status: MappingStatus;
  readonly ingredientIds: readonly string[];
  /** Set only when `mapped`, by the server from the authenticated role (PR #5 L6). */
  readonly confirmedBy: MappingConfirmer | null;
  readonly updatedAt: string;
}

export interface HardRuleBody {
  readonly v: typeof RULE_BODY_VERSION;
  readonly type: HardRuleType;
  readonly allergen: StandardAllergen | null;
  readonly freeText: string | null;
  readonly mapping: RuleMappingBody | null;
}

export class RuleBodyError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "RuleBodyError";
  }
}

const BODY_KEYS = ["v", "type", "allergen", "freeText", "mapping"] as const;
const MAPPING_KEYS = ["status", "ingredientIds", "confirmedBy", "updatedAt"] as const;

function isPlainObject(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function own(record: Record<string, unknown>, key: string): unknown {
  return Object.hasOwn(record, key) ? record[key] : undefined;
}

function exactKeys(record: Record<string, unknown>, keys: readonly string[], what: string): void {
  const actual = Object.keys(record);
  if (actual.length !== keys.length || !keys.every((key) => Object.hasOwn(record, key))) {
    throw new RuleBodyError(`${what} has unexpected fields`);
  }
}

function oneOf<T extends string>(value: unknown, allowed: readonly T[], what: string): T {
  if (typeof value !== "string" || !(allowed as readonly string[]).includes(value)) {
    throw new RuleBodyError(`${what} is not an allowed value`);
  }
  return value as T;
}

function freeTextOf(value: unknown): string {
  if (typeof value !== "string" || value.trim() === "" || value.length > FREE_TEXT_MAX) {
    throw new RuleBodyError("freeText must be 1 to 200 characters");
  }
  return value;
}

function isIsoTimestamp(value: unknown): value is string {
  return (
    typeof value === "string" &&
    /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{1,6})?Z$/.test(value) &&
    !Number.isNaN(Date.parse(value))
  );
}

function mappingOf(raw: unknown): RuleMappingBody {
  if (!isPlainObject(raw)) throw new RuleBodyError("mapping must be an object");
  exactKeys(raw, MAPPING_KEYS, "mapping");
  const status = oneOf(own(raw, "status"), MAPPING_STATUSES, "mapping.status");
  const ids = own(raw, "ingredientIds");
  if (
    !Array.isArray(ids) ||
    ids.length > MAPPED_INGREDIENTS_MAX ||
    !ids.every(isReferenceId) ||
    new Set(ids).size !== ids.length
  ) {
    throw new RuleBodyError("mapping.ingredientIds must be unique reference IDs");
  }
  const confirmedBy = own(raw, "confirmedBy");
  const updatedAt = own(raw, "updatedAt");
  if (!isIsoTimestamp(updatedAt)) throw new RuleBodyError("mapping.updatedAt must be ISO 8601 UTC");
  if (status === "mapped") {
    if (ids.length === 0) throw new RuleBodyError("a mapped rule needs ingredients");
    return {
      status,
      ingredientIds: [...ids],
      confirmedBy: oneOf(confirmedBy, MAPPING_CONFIRMERS, "mapping.confirmedBy"),
      updatedAt,
    };
  }
  if (confirmedBy !== null) throw new RuleBodyError("only a mapped rule has a confirmer");
  if (status === "proposed" && ids.length === 0) {
    throw new RuleBodyError("a proposed mapping needs ingredients");
  }
  if (status === "unmapped" && ids.length !== 0) {
    throw new RuleBodyError("an unmapped rule has no ingredients");
  }
  return { status, ingredientIds: [...ids], confirmedBy: null, updatedAt };
}

/** Validates a rule body (from storage or from the data layer's own builder). */
export function parseRuleBody(raw: unknown): HardRuleBody {
  if (!isPlainObject(raw)) throw new RuleBodyError("rule body must be an object");
  exactKeys(raw, BODY_KEYS, "rule body");
  if (own(raw, "v") !== RULE_BODY_VERSION) throw new RuleBodyError("unknown rule body version");
  const type = oneOf(own(raw, "type"), HARD_RULE_TYPES, "type");
  const allergen = own(raw, "allergen");
  const freeText = own(raw, "freeText");
  const mapping = own(raw, "mapping");
  switch (type) {
    case "allergy":
      if (freeText !== null || mapping !== null) {
        throw new RuleBodyError("an allergy rule has only an allergen");
      }
      return {
        v: RULE_BODY_VERSION,
        type,
        allergen: oneOf(allergen, STANDARD_ALLERGENS, "allergen"),
        freeText: null,
        mapping: null,
      };
    case "halal":
    case "vegetarian":
    case "vegan":
      if (allergen !== null || freeText !== null || mapping !== null) {
        throw new RuleBodyError(`a ${type} rule has no other fields`);
      }
      return { v: RULE_BODY_VERSION, type, allergen: null, freeText: null, mapping: null };
    case "free_text":
      if (allergen !== null) throw new RuleBodyError("a free-text rule has no allergen");
      return {
        v: RULE_BODY_VERSION,
        type,
        allergen: null,
        freeText: freeTextOf(freeText),
        mapping: mappingOf(mapping),
      };
    case "medical_exclusion":
      if (allergen !== null) throw new RuleBodyError("a medical exclusion has no allergen");
      return {
        v: RULE_BODY_VERSION,
        type,
        allergen: null,
        freeText: freeText === null ? null : freeTextOf(freeText),
        mapping: mappingOf(mapping),
      };
  }
}

export function decodeRuleBody(json: string): HardRuleBody {
  let raw: unknown;
  try {
    raw = JSON.parse(json);
  } catch {
    throw new RuleBodyError("rule body is not JSON");
  }
  return parseRuleBody(raw);
}

export function encodeRuleBody(body: HardRuleBody): string {
  const json = JSON.stringify(parseRuleBody(body));
  if (Buffer.byteLength(json, "utf8") > HARD_RULE_BODY_MAX_BYTES) {
    throw new RuleBodyError("rule body is too large to pad");
  }
  return json;
}

/** The Cek Aman input shape (packages/cek-aman `HardRule`) for one stored rule. */
export function toCekAmanRule(ruleId: string, body: HardRuleBody): CekAmanHardRule {
  switch (body.type) {
    case "allergy":
      if (body.allergen === null) throw new RuleBodyError("allergy without allergen");
      return { ruleId, type: "allergy", allergen: body.allergen };
    case "halal":
    case "vegetarian":
    case "vegan":
      return { ruleId, type: body.type };
    case "free_text":
    case "medical_exclusion": {
      const mapping = body.mapping;
      if (mapping === null) throw new RuleBodyError("rule without mapping");
      const cekMapping =
        mapping.status === "mapped" && mapping.confirmedBy !== null
          ? {
              status: "mapped" as const,
              ingredientIds: mapping.ingredientIds,
              confirmedBy: mapping.confirmedBy,
            }
          : mapping.status === "proposed"
            ? { status: "proposed" as const, ingredientIds: mapping.ingredientIds }
            : { status: "unmapped" as const };
      if (body.type === "free_text") {
        if (body.freeText === null) throw new RuleBodyError("free-text rule without text");
        return { ruleId, type: "free_text", freeText: body.freeText, mapping: cekMapping };
      }
      return { ruleId, type: "medical_exclusion", freeText: body.freeText, mapping: cekMapping };
    }
  }
}
