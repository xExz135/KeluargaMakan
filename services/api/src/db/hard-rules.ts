import { randomUUID } from "node:crypto";

import type {
  HardRule as CekAmanHardRule,
  HardRuleType,
  MappingConfirmer,
  StandardAllergen,
} from "@keluargamakan/cek-aman";

import {
  consentStateOf,
  latestHealthConsents,
  type ConsentRecordRow,
  type RulesConsentState,
} from "./consent.js";
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
import { lockMembers } from "./locks.js";

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

interface StoredRule {
  id: string;
  health_key_id: string;
  details_enc: string;
  created_at: string;
  updated_at: string;
}

/** One selected member with consent, key and rules, all from one statement. */
interface MemberSnapshotRow {
  profile_id: string;
  c_id: string | null;
  c_household_id: string | null;
  c_profile_id: string | null;
  c_purpose: "health_data" | null;
  c_decision: "given" | "declined" | null;
  c_text_version: string | null;
  c_language: "id" | "en" | null;
  c_decided_at: Date | null;
  c_recorded_by_account_id: string | null;
  c_withdrawn_at: Date | null;
  c_deletion_due_by: Date | null;
  k_id: string | null;
  k_household_id: string | null;
  k_key_ref: string | null;
  k_wrapped_key: Uint8Array | null;
  rules: StoredRule[] | null;
}

/**
 * H1 (security review T-016): consent, key and rules come from ONE statement,
 * so they share one snapshot under any isolation level, also inside a caller's
 * READ COMMITTED transaction. A withdrawal that commits during the read is
 * either fully visible (consent withdrawn, no rules) or not visible at all
 * (consent given, every rule). It can never produce "given" with rules missing.
 */
const MEMBER_SNAPSHOT_SQL = `
SELECT p.id AS profile_id,
       c.id AS c_id, c.household_id AS c_household_id, c.profile_id AS c_profile_id,
       c.purpose AS c_purpose, c.decision AS c_decision, c.text_version AS c_text_version,
       c.language AS c_language, c.decided_at AS c_decided_at,
       c.recorded_by_account_id AS c_recorded_by_account_id,
       c.withdrawn_at AS c_withdrawn_at, c.deletion_due_by AS c_deletion_due_by,
       k.id AS k_id, k.household_id AS k_household_id, k.key_ref AS k_key_ref,
       k.wrapped_key AS k_wrapped_key,
       r.rules
  FROM profile p
  LEFT JOIN LATERAL (
    SELECT * FROM consent_record cr
     WHERE cr.profile_id = p.id AND cr.household_id = p.household_id
       AND cr.purpose = 'health_data'
     ORDER BY cr.seq DESC
     LIMIT 1
  ) c ON true
  LEFT JOIN health_data_key k ON k.profile_id = p.id AND k.household_id = p.household_id
  LEFT JOIN LATERAL (
    SELECT json_agg(json_build_object(
             'id', h.id,
             'health_key_id', h.health_key_id,
             'details_enc', encode(h.details_enc, 'base64'),
             'created_at', to_char(h.created_at AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'),
             'updated_at', to_char(h.updated_at AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"')
           ) ORDER BY h.created_at, h.id) AS rules
      FROM hard_rule h
     WHERE h.profile_id = p.id AND h.household_id = p.household_id
  ) r ON true
 WHERE p.household_id = $1 AND p.id = ANY($2::uuid[])`;

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
  // Anything else from the crypto path (for example a bad key length) also
  // fails closed. Its message is not kept: it could carry decrypted text (L1).
  return new RulesUnavailableError("decrypt_failed");
}

function consentOf(row: MemberSnapshotRow): ConsentRecordRow | undefined {
  if (
    row.c_id === null ||
    row.c_purpose === null ||
    row.c_decision === null ||
    row.c_text_version === null ||
    row.c_language === null ||
    row.c_decided_at === null
  ) {
    return undefined;
  }
  return {
    id: row.c_id,
    householdId: row.c_household_id,
    profileId: row.c_profile_id,
    purpose: row.c_purpose,
    decision: row.c_decision,
    textVersion: row.c_text_version,
    language: row.c_language,
    decidedAt: new Date(row.c_decided_at),
    recordedByAccountId: row.c_recorded_by_account_id,
    withdrawnAt: row.c_withdrawn_at === null ? null : new Date(row.c_withdrawn_at),
    deletionDueBy: row.c_deletion_due_by === null ? null : new Date(row.c_deletion_due_by),
  };
}

interface DecryptedMember {
  readonly consent: RulesConsentState;
  readonly rules: readonly HardRuleRecord[];
}

/** Reads and decrypts every rule of the given members from one snapshot, or throws. */
async function readMembers(
  db: SqlExecutor,
  keys: HealthDataKeys,
  householdId: string,
  profileIds: readonly string[],
): Promise<Map<string, DecryptedMember>> {
  const ids = [...new Set(profileIds)];
  if (!isUuid(householdId) || ids.length === 0 || !ids.every(isUuid)) {
    throw new NotFoundError("profile");
  }
  const { rows } = await withDbErrors(() =>
    db.query<MemberSnapshotRow>(MEMBER_SNAPSHOT_SQL, [householdId, ids]),
  );
  if (rows.length !== ids.length) throw new NotFoundError("profile");

  const result = new Map<string, DecryptedMember>();
  for (const row of rows) {
    const profileId = row.profile_id;
    const consent = consentStateOf(consentOf(row));
    const stored = row.rules ?? [];
    if (consent.status !== "given" && stored.length > 0) {
      // Rules without consent cannot exist (database trigger); if they do,
      // something is wrong, and the check must not go ahead.
      throw new RulesUnavailableError("inconsistent");
    }
    let key: MemberDataKey | null = null;
    if (stored.length > 0) {
      if (row.k_id === null || row.k_key_ref === null || row.k_wrapped_key === null) {
        throw new RulesUnavailableError("inconsistent");
      }
      try {
        key = await keys.unwrap({
          id: row.k_id,
          profile_id: profileId,
          household_id: row.k_household_id ?? householdId,
          key_ref: row.k_key_ref,
          wrapped_key: row.k_wrapped_key,
        });
      } catch (error) {
        throw toUnavailable(error);
      }
    }
    const memberKey = key;
    const rules = stored.map((rule): HardRuleRecord => {
      if (memberKey === null || memberKey.keyId !== rule.health_key_id) {
        throw new RulesUnavailableError("inconsistent");
      }
      try {
        const body = decodeRuleBody(
          decryptField(
            memberKey.dataKey,
            Buffer.from(rule.details_enc, "base64"),
            ruleContext(rule.id, profileId, householdId),
          ),
        );
        return {
          id: rule.id,
          profileId,
          type: body.type,
          allergen: body.allergen,
          freeText: body.freeText,
          mapping: body.mapping,
          createdAt: new Date(rule.created_at),
          updatedAt: new Date(rule.updated_at),
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
      await lockMembers(tx, input.householdId, [input.profileId]);
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
      await lockMembers(tx, input.householdId, [input.profileId]);
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
