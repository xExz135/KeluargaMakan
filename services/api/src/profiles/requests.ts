import { STANDARD_ALLERGENS, type StandardAllergen } from "@keluargamakan/cek-aman";

import type { PortionSize } from "../../config/profiles.js";
import { AGE_GROUPS, isChildAgeGroup, type AgeGroup } from "../consent/child-data-policy.js";
import type { GuardianConfirmationInput } from "../consent/consent-service.js";
import { parseGuardianConfirmation } from "../consent/consent.controller.js";
import { FREE_TEXT_MAX, MAPPED_INGREDIENTS_MAX } from "../db/hard-rule-codec.js";
import type { NewHardRule } from "../db/hard-rules.js";
import { isReferenceId } from "../db/ids.js";
import type { AvatarInput } from "../households/household-service.js";
import { parseAvatar } from "../http/requests.js";
import { cleanUserText, codePointLength } from "../http/text.js";
import { BodyReader } from "../http/validation.js";

/** Request body parsers for the profile, preference and hard-rule schemas of contract 0.1.2. */

const PORTIONS: readonly PortionSize[] = ["small", "normal", "large"];
const SPICE = ["not_spicy", "medium", "spicy"] as const;
const LESS_OF = ["fried", "sugar", "salt", "santan"] as const;
const TEXTURES = ["soft", "crunchy", "soupy"] as const;
const RULE_TYPES = [
  "allergy",
  "halal",
  "vegetarian",
  "vegan",
  "medical_exclusion",
  "free_text",
] as const;
const FOOD_REF_KINDS = ["ingredient", "dish"] as const;
const MAX_FOOD_REFS = 100;
const PROFILE_NAME = { minLength: 1, maxLength: 30 } as const;

export type SpiceLevel = (typeof SPICE)[number];
export type LessOf = (typeof LESS_OF)[number];
export type Texture = (typeof TEXTURES)[number];
export type FoodRefKind = (typeof FOOD_REF_KINDS)[number];

export interface ProfileCreateInput {
  readonly name: string;
  readonly ageGroup: AgeGroup;
  readonly avatar: AvatarInput | null;
  readonly guardianConfirmation: GuardianConfirmationInput | null;
}

export interface ProfileUpdateInput {
  readonly name?: string;
  readonly avatar?: AvatarInput;
  readonly ageGroup?: AgeGroup;
  readonly portionSize?: PortionSize | null;
  readonly ricePortion?: PortionSize | null;
  readonly guardianConfirmation?: GuardianConfirmationInput;
}

export interface SoftPreferencesInput {
  readonly spiceLevel: SpiceLevel | null;
  readonly lessOf: readonly LessOf[];
  readonly textures: readonly Texture[];
}

export interface FoodRefInput {
  readonly kind: FoodRefKind;
  readonly refId: string;
}

export interface LikesDislikesInput {
  readonly likes: readonly FoodRefInput[];
  readonly dislikes: readonly FoodRefInput[];
}

function profileName(
  reader: BodyReader,
  record: Readonly<Record<string, unknown>>,
  required: boolean,
): string | undefined {
  const name = reader.string(record, "name", "", { required, ...PROFILE_NAME });
  if (typeof name !== "string") return undefined;
  const clean = cleanUserText(name);
  if (clean === null || codePointLength(clean) > PROFILE_NAME.maxLength) {
    reader.fail("/name", "invalid_format");
    return undefined;
  }
  return clean;
}

function enumList<T extends string>(
  reader: BodyReader,
  record: Readonly<Record<string, unknown>>,
  key: string,
  values: readonly T[],
): T[] | undefined {
  if (!Object.hasOwn(record, key)) {
    reader.fail(`/${key}`, "required");
    return undefined;
  }
  const raw = record[key];
  if (!Array.isArray(raw)) {
    reader.fail(`/${key}`, "invalid_type");
    return undefined;
  }
  const out: T[] = [];
  raw.forEach((item: unknown, index) => {
    if (typeof item !== "string") reader.fail(`/${key}/${index}`, "invalid_type");
    else if (!(values as readonly string[]).includes(item)) {
      reader.fail(`/${key}/${index}`, "invalid_value");
    } else if (out.includes(item as T)) reader.fail(`/${key}/${index}`, "duplicate");
    else out.push(item as T);
  });
  return out;
}

export function parseProfileCreate(body: unknown): ProfileCreateInput {
  const reader = new BodyReader();
  const record = reader.object(body, "", ["name", "ageGroup", "avatar", "guardianConfirmation"]);
  if (record === null) return reader.done() as never;
  const name = profileName(reader, record, true);
  const ageGroup = reader.enumValue(record, "ageGroup", "", AGE_GROUPS, true);
  const avatar = Object.hasOwn(record, "avatar")
    ? parseAvatar(reader, record["avatar"], "/avatar")
    : null;
  let guardian: GuardianConfirmationInput | null = null;
  if (Object.hasOwn(record, "guardianConfirmation")) {
    if (ageGroup !== undefined && !isChildAgeGroup(ageGroup)) {
      // SET-10 applies to children only; an adult profile records no guardian.
      reader.fail("/guardianConfirmation", "not_allowed");
    } else {
      guardian = parseGuardianConfirmation(
        reader,
        record["guardianConfirmation"],
        "/guardianConfirmation",
      );
    }
  }
  reader.done();
  return { name: name!, ageGroup: ageGroup!, avatar, guardianConfirmation: guardian };
}

export function parseProfileUpdate(body: unknown): ProfileUpdateInput {
  const reader = new BodyReader();
  const record = reader.object(body, "", [
    "name",
    "avatar",
    "ageGroup",
    "portionSize",
    "ricePortion",
    "guardianConfirmation",
  ]);
  if (record === null) return reader.done() as never;
  if (Object.keys(record).length === 0) reader.fail("", "required");
  const name = profileName(reader, record, false);
  const avatar = Object.hasOwn(record, "avatar")
    ? parseAvatar(reader, record["avatar"], "/avatar")
    : undefined;
  const ageGroup = reader.enumValue(record, "ageGroup", "", AGE_GROUPS, false);
  const portion = (key: "portionSize" | "ricePortion"): PortionSize | null | undefined => {
    if (!Object.hasOwn(record, key)) return undefined;
    if (record[key] === null) return null;
    return reader.enumValue(record, key, "", PORTIONS, true);
  };
  const portionSize = portion("portionSize");
  const ricePortion = portion("ricePortion");
  const guardian = Object.hasOwn(record, "guardianConfirmation")
    ? parseGuardianConfirmation(reader, record["guardianConfirmation"], "/guardianConfirmation")
    : undefined;
  reader.done();
  return {
    ...(name === undefined ? {} : { name }),
    ...(avatar === undefined || avatar === null ? {} : { avatar }),
    ...(ageGroup === undefined ? {} : { ageGroup }),
    ...(portionSize === undefined ? {} : { portionSize }),
    ...(ricePortion === undefined ? {} : { ricePortion }),
    ...(guardian === undefined || guardian === null ? {} : { guardianConfirmation: guardian }),
  };
}

export function parseSoftPreferences(body: unknown): SoftPreferencesInput {
  const reader = new BodyReader();
  const record = reader.object(body, "", ["spiceLevel", "lessOf", "textures"]);
  if (record === null) return reader.done() as never;
  let spiceLevel: SpiceLevel | null | undefined = null;
  if (!Object.hasOwn(record, "spiceLevel")) reader.fail("/spiceLevel", "required");
  else if (record["spiceLevel"] !== null) {
    spiceLevel = reader.enumValue(record, "spiceLevel", "", SPICE, true);
  }
  const lessOf = enumList(reader, record, "lessOf", LESS_OF);
  const textures = enumList(reader, record, "textures", TEXTURES);
  reader.done();
  return { spiceLevel: spiceLevel ?? null, lessOf: lessOf!, textures: textures! };
}

function foodRefs(
  reader: BodyReader,
  record: Readonly<Record<string, unknown>>,
  key: "likes" | "dislikes",
  seen: Set<string>,
): FoodRefInput[] {
  if (!Object.hasOwn(record, key)) {
    reader.fail(`/${key}`, "required");
    return [];
  }
  const raw = record[key];
  if (!Array.isArray(raw)) {
    reader.fail(`/${key}`, "invalid_type");
    return [];
  }
  if (raw.length > MAX_FOOD_REFS) {
    reader.fail(`/${key}`, "too_many_items");
    return [];
  }
  const out: FoodRefInput[] = [];
  raw.forEach((item: unknown, index) => {
    const pointer = `/${key}/${index}`;
    const ref = reader.object(item, pointer, ["kind", "refId"]);
    if (ref === null) return;
    const kind = reader.enumValue(ref, "kind", pointer, FOOD_REF_KINDS, true);
    const refId = reader.string(ref, "refId", pointer, { required: true });
    if (typeof refId === "string" && !isReferenceId(refId)) {
      reader.fail(`${pointer}/refId`, "invalid_format");
      return;
    }
    if (kind === undefined || typeof refId !== "string") return;
    // An item may not be both liked and disliked, nor listed twice.
    const identity = `${kind}:${refId}`;
    if (seen.has(identity)) {
      reader.fail(pointer, "duplicate");
      return;
    }
    seen.add(identity);
    out.push({ kind, refId });
  });
  return out;
}

export function parseLikesDislikes(body: unknown): LikesDislikesInput {
  const reader = new BodyReader();
  const record = reader.object(body, "", ["likes", "dislikes"]);
  if (record === null) return reader.done() as never;
  const seen = new Set<string>();
  const likes = foodRefs(reader, record, "likes", seen);
  const dislikes = foodRefs(reader, record, "dislikes", seen);
  reader.done();
  return { likes, dislikes };
}

function ruleText(
  reader: BodyReader,
  record: Readonly<Record<string, unknown>>,
  required: boolean,
): string | undefined {
  const text = reader.string(record, "freeText", "", {
    required,
    minLength: 1,
    maxLength: FREE_TEXT_MAX,
  });
  if (typeof text !== "string") return undefined;
  const clean = cleanUserText(text);
  // The stored body limits UTF-16 length too (hard-rule codec).
  if (clean === null || clean.length > FREE_TEXT_MAX) {
    reader.fail("/freeText", "invalid_format");
    return undefined;
  }
  return clean;
}

/**
 * Contract `MappedIngredientIds`: absent or null is an unmapped rule (PRF-08,
 * fail closed); a present list needs at least one ID. An empty list is
 * refused, never read as "mapped to nothing" (security review T-017 F2).
 */
function mappedIds(
  reader: BodyReader,
  record: Readonly<Record<string, unknown>>,
): string[] | null | undefined {
  if (!Object.hasOwn(record, "mappedIngredientIds")) return null;
  const raw = record["mappedIngredientIds"];
  if (raw === null) return null;
  if (!Array.isArray(raw)) {
    reader.fail("/mappedIngredientIds", "invalid_type");
    return undefined;
  }
  if (raw.length === 0) {
    reader.fail("/mappedIngredientIds", "too_short");
    return undefined;
  }
  if (raw.length > MAPPED_INGREDIENTS_MAX) {
    reader.fail("/mappedIngredientIds", "too_many_items");
    return undefined;
  }
  const out: string[] = [];
  let ok = true;
  raw.forEach((item: unknown, index) => {
    if (typeof item !== "string") {
      reader.fail(`/mappedIngredientIds/${index}`, "invalid_type");
      ok = false;
    } else if (!isReferenceId(item)) {
      reader.fail(`/mappedIngredientIds/${index}`, "invalid_format");
      ok = false;
    } else if (out.includes(item)) {
      reader.fail(`/mappedIngredientIds/${index}`, "duplicate");
      ok = false;
    } else out.push(item);
  });
  return ok ? out : undefined;
}

/** Contract `HardRuleCreate` (PRF-03, PRF-04, PRF-08). */
export function parseHardRuleCreate(body: unknown): NewHardRule {
  const reader = new BodyReader();
  const record = reader.object(body, "", ["type", "allergen", "freeText", "mappedIngredientIds"]);
  if (record === null) return reader.done() as never;
  const type = reader.enumValue(record, "type", "", RULE_TYPES, true);
  const notAllowed = (key: string) => {
    if (Object.hasOwn(record, key)) reader.fail(`/${key}`, "not_allowed");
  };
  let rule: NewHardRule | null = null;
  switch (type) {
    case "allergy": {
      notAllowed("freeText");
      notAllowed("mappedIngredientIds");
      const allergen = reader.enumValue<StandardAllergen>(
        record,
        "allergen",
        "",
        STANDARD_ALLERGENS,
        true,
      );
      if (allergen !== undefined) rule = { type, allergen };
      break;
    }
    case "halal":
    case "vegetarian":
    case "vegan":
      notAllowed("allergen");
      notAllowed("freeText");
      notAllowed("mappedIngredientIds");
      rule = { type };
      break;
    case "free_text": {
      notAllowed("allergen");
      const freeText = ruleText(reader, record, true);
      const ids = mappedIds(reader, record);
      if (freeText !== undefined && ids !== undefined) {
        rule = ids === null ? { type, freeText } : { type, freeText, mappedIngredientIds: ids };
      }
      break;
    }
    case "medical_exclusion": {
      notAllowed("allergen");
      const freeText = Object.hasOwn(record, "freeText") ? ruleText(reader, record, true) : null;
      const ids = mappedIds(reader, record);
      if (freeText !== undefined && ids !== undefined) {
        rule = ids === null ? { type, freeText } : { type, freeText, mappedIngredientIds: ids };
      }
      break;
    }
    case undefined:
      break;
  }
  reader.done();
  return rule!;
}
