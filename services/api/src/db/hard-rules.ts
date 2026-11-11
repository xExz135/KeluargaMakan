import { randomUUID } from "node:crypto";

import type {
  HardRule as CekAmanHardRule,
  HardRuleType,
  MappingConfirmer,
  StandardAllergen,
} from "@keluargamakan/cek-aman";

import { consentStateOf, latestHealthConsents, type RulesConsentState } from "./consent.js";
import { decryptField, encryptField } from "./crypto/data-key-cipher.js";
import { DecryptionError, KeyServiceError } from "./crypto/key-provider.js";
import {
  ConsentRequiredError,
  InvalidDataError,
  MappingNotApplicableError,
  NotFoundError,
  RulesUnavailableError,
  withDbErrors,
} from "./errors.js";
import type { SqlExecutor } from "./executor.js";
import {
  RuleBodyError,
  decodeRuleBody,
  encodeRuleBody,
  toCekAmanRule,
  type HardRuleBody,
  type RuleMappingBody,
} from "./hard-rule-codec.js";
import type { HealthDataKeys, MemberDataKey } from "./health-data-keys.js";
import { isUuid } from "./ids.js";

/**
 * SRS 18.1 Hard rule storage (PRF-03, PRF-08, DAT-02).
 *
 * Reading never degrades: when any requested member's rules cannot be read,
 * unwrapped, decrypted or validated, the whole read throws
 * `RulesUnavailableError`. It never returns a shorter or empty rule list
 * (QUESTIONS #39, security review PR #5 H2), because Cek Aman would turn
 * missing rules into "Safe".
 */

export interface HardRuleRecord {
  readonly id: string;
  readonly profileId: string;
  readonly type: HardRuleType;
  readonly allergen: StandardAllergen | null;
  readonly freeText: string | null;
  readonly mapping: RuleMappingBody | null;
  readonly createdAt: Date;
  readonly updatedAt: Date;
}

/** Contract `ProfileRules`: `items` is empty unless `consent.status` is `given`. */
export interface ProfileRules {
  readonly consent: RulesConsentState;
  readonly items: readonly HardRuleRecord[];
}

/**
 * One selected member, ready for Cek Aman (PRF-09, PRF-11). A member without
 * a given consent has `hardRules: null`, not `[]`: clients show "rules not
 * saved", never "Safe" (QUESTIONS #36).
 */
export type MemberRulesForEvaluation =
  | {
      readonly profileId: string;
      readonly consent: "given";
      readonly hardRules: readonly CekAmanHardRule[];
    }
  | {
      readonly profileId: string;
      readonly consent: "none" | "declined" | "withdrawn";
      readonly hardRules: null;
    };

interface RuleRow {
  id: string;
  profile_id: string;
  household_id: string;
  health_key_id: string;
  details_enc: Uint8Array;
  created_at: Date;
  updated_at: Date;
}

function ruleContext(ruleId: string, profileId: string, householdId: string): string {
  return `hard_rule:${ruleId}:${profileId}:${householdId}`;
}

function toUnavailable(error: unknown): RulesUnavailableError {
  if (error instanceof RulesUnavailableError) return error;
  if (error instanceof KeyServiceError) {
    return new RulesUnavailableError("key_unavailable", { cause: error });
  }
  if (error instanceof DecryptionError) {
    return new RulesUnavailableError("decrypt_failed", { cause: error });
  }
  if (error instanceof RuleBodyError)
    return new RulesUnavailableError("malformed", { cause: error });
  // Anything else from the crypto path (for example a bad key length) also fails closed.
  return new RulesUnavailableError("decrypt_failed", { cause: error });
}

async function requireProfiles(
  db: SqlExecutor,
  householdId: string,
  profileIds: readonly string[],
): Promise<void> {
  const ids = [...new Set(profileIds)];
  if (!isUuid(householdId) || ids.length === 0 || !ids.every(isUuid)) {
    throw new NotFoundError("profile");
  }
  const { rows } = await db.query<{ id: string }>(
    `SELECT id FROM profile WHERE household_id = $1 AND id = ANY($2::uuid[])`,
    [householdId, ids],
  );
  if (rows.length !== ids.length) throw new NotFoundError("profile");
}

interface DecryptedMember {
  readonly consent: RulesConsentState;
  readonly rules: readonly HardRuleRecord[];
}

/** Reads and decrypts every rule of the given members, or throws. */
async function readMembers(
  db: SqlExecutor,
  keys: HealthDataKeys,
  householdId: string,
  profileIds: readonly string[],
): Promise<Map<string, DecryptedMember>> {
  await requireProfiles(db, householdId, profileIds);
  const consents = await latestHealthConsents(db, householdId, profileIds);
  const { rows } = await db.query<RuleRow>(
    `SELECT id, profile_id, household_id, health_key_id, details_enc, created_at, updated_at
       FROM hard_rule
      WHERE household_id = $1 AND profile_id = ANY($2::uuid[])
      ORDER BY created_at, id`,
    [householdId, [...new Set(profileIds)]],
  );

  let memberKeys: Map<string, MemberDataKey>;
  try {
    const withRules = [...new Set(rows.map((row) => row.profile_id))];
    memberKeys = await keys.loadForProfiles(db, householdId, withRules);
  } catch (error) {
    throw toUnavailable(error);
  }

  const result = new Map<string, DecryptedMember>();
  for (const profileId of profileIds) {
    const consent = consentStateOf(consents.get(profileId));
    const own = rows.filter((row) => row.profile_id === profileId);
    if (consent.status !== "given" && own.length > 0) {
      // Rules without consent cannot exist (database trigger); if they do,
      // something is wrong, and the check must not go ahead.
      throw new RulesUnavailableError("inconsistent");
    }
    const rules = own.map((row): HardRuleRecord => {
      const key = memberKeys.get(profileId);
      if (key === undefined || key.keyId !== row.health_key_id) {
        throw new RulesUnavailableError("inconsistent");
      }
      try {
        const body = decodeRuleBody(
          decryptField(key.dataKey, row.details_enc, ruleContext(row.id, profileId, householdId)),
        );
        return {
          id: row.id,
          profileId,
          type: body.type,
          allergen: body.allergen,
          freeText: body.freeText,
          mapping: body.mapping,
          createdAt: row.created_at,
          updatedAt: row.updated_at,
        };
      } catch (error) {
        throw toUnavailable(error);
      }
    });
    result.set(profileId, { consent, rules });
  }
  return result;
}

/** Contract `ProfileRules` for one member. Throws `RulesUnavailableError` instead of returning partial rules. */
export async function listProfileRules(
  db: SqlExecutor,
  keys: HealthDataKeys,
  householdId: string,
  profileId: string,
): Promise<ProfileRules> {
  const member = (await readMembers(db, keys, householdId, [profileId])).get(profileId);
  if (member === undefined) throw new NotFoundError("profile");
  return { consent: member.consent, items: member.rules };
}

/**
 * PRF-11: the hard rules of exactly the selected members, in the given order,
 * in the Cek Aman input shape. Throws `RulesUnavailableError` if any member's
 * rules cannot be read; the caller must abort the whole safety check.
 */
export async function loadRulesForEvaluation(
  db: SqlExecutor,
  keys: HealthDataKeys,
  householdId: string,
  profileIds: readonly string[],
): Promise<MemberRulesForEvaluation[]> {
  const members = await readMembers(db, keys, householdId, profileIds);
  return profileIds.map((profileId): MemberRulesForEvaluation => {
    const member = members.get(profileId);
    if (member === undefined) throw new NotFoundError("profile");
    if (member.consent.status !== "given") {
      return { profileId, consent: member.consent.status, hardRules: null };
    }
    let hardRules: CekAmanHardRule[];
    try {
      hardRules = member.rules.map((rule) =>
        toCekAmanRule(rule.id, {
          v: 1,
          type: rule.type,
          allergen: rule.allergen,
          freeText: rule.freeText,
          mapping: rule.mapping,
        }),
      );
    } catch (error) {
      throw toUnavailable(error);
    }
    return { profileId, consent: "given", hardRules };
  });
}

/** PRF-03 input. `mappedIngredientIds` records the manager's confirmed match at entry (PRF-08). */
export type NewHardRule =
  | { readonly type: "allergy"; readonly allergen: StandardAllergen }
  | { readonly type: "halal" | "vegetarian" | "vegan" }
  | {
      readonly type: "free_text";
      readonly freeText: string;
      readonly mappedIngredientIds?: readonly string[];
    }
  | {
      readonly type: "medical_exclusion";
      readonly freeText?: string | null;
      readonly mappedIngredientIds?: readonly string[];
    };

function buildBody(
  rule: NewHardRule,
  mappingConfirmedBy: MappingConfirmer | null,
  now: Date,
): HardRuleBody {
  switch (rule.type) {
    case "allergy":
      return { v: 1, type: "allergy", allergen: rule.allergen, freeText: null, mapping: null };
    case "halal":
    case "vegetarian":
    case "vegan":
      return { v: 1, type: rule.type, allergen: null, freeText: null, mapping: null };
    case "free_text":
    case "medical_exclusion": {
      const ids = rule.mappedIngredientIds ?? [];
      if (ids.length > 0 && mappingConfirmedBy === null) {
        throw new InvalidDataError("a mapping at entry needs a server-side confirmer");
      }
      const mapping: RuleMappingBody =
        ids.length > 0 && mappingConfirmedBy !== null
          ? {
              status: "mapped",
              ingredientIds: [...ids],
              confirmedBy: mappingConfirmedBy,
              updatedAt: now.toISOString(),
            }
          : {
              status: "unmapped",
              ingredientIds: [],
              confirmedBy: null,
              updatedAt: now.toISOString(),
            };
      return {
        v: 1,
        type: rule.type,
        allergen: null,
        freeText: rule.type === "free_text" ? rule.freeText : (rule.freeText ?? null),
        mapping,
      };
    }
  }
}

function encode(body: HardRuleBody): string {
  try {
    return encodeRuleBody(body);
  } catch (error) {
    throw new InvalidDataError(error instanceof Error ? error.message : "invalid hard rule");
  }
}

async function activeConsentId(
  db: SqlExecutor,
  householdId: string,
  profileId: string,
): Promise<string> {
  const latest = (await latestHealthConsents(db, householdId, [profileId])).get(profileId);
  const state = consentStateOf(latest);
  if (state.status !== "given" || state.consentRecordId === null) throw new ConsentRequiredError();
  return state.consentRecordId;
}

/**
 * Stores one hard rule, encrypted with the member's data key (DAT-02), only
 * under an active health-data consent (ACC-08) and, for a child, a guardian
 * confirmation (SET-10). The database enforces both again.
 *
 * `mappingConfirmedBy` comes from the authenticated role (manager or content
 * team), never from the request body (PR #5 L6).
 */
export async function insertHardRule(
  db: SqlExecutor,
  keys: HealthDataKeys,
  input: {
    readonly householdId: string;
    readonly profileId: string;
    readonly rule: NewHardRule;
    readonly mappingConfirmedBy: MappingConfirmer | null;
    readonly now?: Date;
  },
): Promise<HardRuleRecord> {
  const now = input.now ?? new Date();
  const body = buildBody(input.rule, input.mappingConfirmedBy, now);
  const json = encode(body);
  return withDbErrors(() =>
    db.transaction(async (tx) => {
      await requireProfiles(tx, input.householdId, [input.profileId]);
      const consentRecordId = await activeConsentId(tx, input.householdId, input.profileId);
      const key = await keys.getOrCreate(tx, input.householdId, input.profileId);
      const id = randomUUID();
      const details = encryptField(
        key.dataKey,
        json,
        ruleContext(id, input.profileId, input.householdId),
      );
      const { rows } = await tx.query<{ created_at: Date; updated_at: Date }>(
        `INSERT INTO hard_rule
           (id, household_id, profile_id, health_key_id, consent_record_id, details_enc, created_at, updated_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $7)
         RETURNING created_at, updated_at`,
        [id, input.householdId, input.profileId, key.keyId, consentRecordId, details, now],
      );
      const row = rows[0];
      if (row === undefined) throw new Error("hard rule insert returned no row");
      return {
        id,
        profileId: input.profileId,
        type: body.type,
        allergen: body.allergen,
        freeText: body.freeText,
        mapping: body.mapping,
        createdAt: row.created_at,
        updatedAt: row.updated_at,
      };
    }),
  );
}

/**
 * PRF-08: confirms the mapping of a free-text or medical-exclusion rule.
 * `confirmedBy` is set by the server from the authenticated role.
 */
export async function confirmRuleMapping(
  db: SqlExecutor,
  keys: HealthDataKeys,
  input: {
    readonly householdId: string;
    readonly profileId: string;
    readonly ruleId: string;
    readonly ingredientIds: readonly string[];
    readonly confirmedBy: MappingConfirmer;
    readonly now?: Date;
  },
): Promise<HardRuleRecord> {
  const now = input.now ?? new Date();
  return withDbErrors(() =>
    db.transaction(async (tx) => {
      const current = (await listProfileRules(tx, keys, input.householdId, input.profileId)).items;
      const rule = current.find((item) => item.id === input.ruleId);
      if (rule === undefined) throw new NotFoundError("hard rule");
      if (rule.type !== "free_text" && rule.type !== "medical_exclusion") {
        throw new MappingNotApplicableError();
      }
      const body: HardRuleBody = {
        v: 1,
        type: rule.type,
        allergen: null,
        freeText: rule.freeText,
        mapping: {
          status: "mapped",
          ingredientIds: [...input.ingredientIds],
          confirmedBy: input.confirmedBy,
          updatedAt: now.toISOString(),
        },
      };
      const json = encode(body);
      const consentRecordId = await activeConsentId(tx, input.householdId, input.profileId);
      const key = await keys.getOrCreate(tx, input.householdId, input.profileId);
      const details = encryptField(
        key.dataKey,
        json,
        ruleContext(rule.id, input.profileId, input.householdId),
      );
      const { rows } = await tx.query<{ updated_at: Date }>(
        `UPDATE hard_rule
            SET details_enc = $4, consent_record_id = $5, health_key_id = $6, updated_at = $7
          WHERE id = $1 AND profile_id = $2 AND household_id = $3
          RETURNING updated_at`,
        [rule.id, input.profileId, input.householdId, details, consentRecordId, key.keyId, now],
      );
      if (rows[0] === undefined) throw new NotFoundError("hard rule");
      return { ...rule, mapping: body.mapping, updatedAt: rows[0].updated_at };
    }),
  );
}

export async function deleteHardRule(
  db: SqlExecutor,
  householdId: string,
  profileId: string,
  ruleId: string,
): Promise<boolean> {
  if (!isUuid(householdId) || !isUuid(profileId) || !isUuid(ruleId)) return false;
  const { rowCount } = await db.query(
    `DELETE FROM hard_rule WHERE id = $1 AND profile_id = $2 AND household_id = $3`,
    [ruleId, profileId, householdId],
  );
  return rowCount === 1;
}
