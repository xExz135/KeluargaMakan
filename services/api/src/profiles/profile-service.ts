import { randomUUID } from "node:crypto";

import type { HardRuleType, StandardAllergen } from "@keluargamakan/cek-aman";

import type { ApiConfig } from "../../config/api.js";
import type { PortionSize, ProfileConfig } from "../../config/profiles.js";
import type { Targets } from "../../config/targets.js";
import { ApiError } from "../api-error.js";
import type { Clock } from "../auth/auth-service.js";
import { systemClock } from "../auth/auth-service.js";
import type { HouseholdScope } from "../authz/access.js";
import { dataHandlingFor, isChildAgeGroup, type AgeGroup } from "../consent/child-data-policy.js";
import {
  assertHealthDataWritable,
  isChildProfile,
  recordGuardian,
  renewalRequired,
} from "../consent/consent-service.js";
import type { RulesConsentState } from "../db/consent.js";
import { deleteProfile } from "../db/deletion.js";
import { ConcurrentUpdateError, NotFoundError, withDbErrors } from "../db/errors.js";
import type { SqlExecutor } from "../db/executor.js";
import {
  deleteHardRule,
  insertHardRule,
  listMembersRules,
  listProfileRules,
  type HardRuleRecord,
  type NewHardRule,
  type ProfileRules,
} from "../db/hard-rules.js";
import type { HealthDataKeys } from "../db/health-data-keys.js";
import { isUuid } from "../db/ids.js";
import { lockMembers } from "../db/locks.js";
import type { AvatarInput } from "../households/household-service.js";
import {
  findReplay,
  idempotencyKeyReused,
  remember,
  requestHash,
  type IdempotentRequest,
} from "../idempotency/idempotency.js";
import { fallbackName, type LocalizedName, type ReferenceCatalog } from "../reference/catalog.js";
import type {
  FoodRefInput,
  FoodRefKind,
  LessOf,
  LikesDislikesInput,
  ProfileCreateInput,
  ProfileUpdateInput,
  SoftPreferencesInput,
  SpiceLevel,
  Texture,
} from "./requests.js";

/**
 * Keluarga Saya profiles API (T-020): PRF-01 to PRF-07, PRF-18.
 *
 * - Every query is scoped by the household from the caller's session
 *   (NFR-09). A profile or rule ID from another household is not found.
 * - PRF-02: the profile limit is `targets.household.maxProfiles` (target,
 *   floor 12).
 * - PRF-03: hard rules are stored encrypted with the member's data key under
 *   the separate health-data key (T-016), only under an active consent and,
 *   for a child, a recorded guardian confirmation (ACC-08, SET-10). The
 *   consent gate runs first so the client gets a clear 409 before any key
 *   service work. Rules are never overridden: there is no update, only add
 *   and remove (SAF-12).
 * - Reads fail closed (QUESTIONS #39): a member whose rules cannot be read
 *   makes the whole request fail (503); a member is never returned with an
 *   empty or shorter rule list.
 * - PRF-05 to PRF-07: soft preferences, likes and dislikes, and portions with
 *   age-group defaults from configuration. None of these is health data.
 * - Names are personal data: they are never logged and never put into an
 *   error message (T-016 L2 pattern).
 */

export const profileLimitReached = () =>
  new ApiError("profile_limit_reached", 409, "The household has reached its profile limit");
export const managerProfileMustBeAdult = () =>
  new ApiError(
    "manager_profile_must_be_adult",
    409,
    "The manager's own profile cannot take a child age group",
  );
export const hardRuleDuplicate = () =>
  new ApiError("hard_rule_duplicate", 409, "The member already has this hard rule");

export interface FoodRefView {
  readonly kind: FoodRefKind;
  readonly refId: string;
  readonly displayName: LocalizedName;
}

export interface MappingView {
  readonly status: "mapped" | "proposed" | "unmapped";
  readonly ingredients: readonly {
    readonly ingredientId: string;
    readonly displayName: LocalizedName;
  }[];
  readonly confirmedBy: "content_team" | "manager" | null;
  readonly updatedAt: string;
}

export interface HardRuleView {
  readonly id: string;
  readonly type: HardRuleType;
  readonly allergen: StandardAllergen | null;
  readonly freeText: string | null;
  readonly mapping: MappingView | null;
  readonly createdAt: Date;
}

export interface ProfileRulesView {
  readonly consent: RulesConsentState & { readonly renewalRequired: boolean };
  readonly items: readonly HardRuleView[];
}

export interface ProfileView {
  readonly id: string;
  readonly name: string;
  readonly avatar: AvatarInput;
  readonly ageGroup: AgeGroup;
  readonly isChild: boolean;
  readonly isManager: boolean;
  readonly guardianConfirmation: {
    readonly consentRecordId: string;
    readonly confirmedAt: Date;
    readonly textVersion: string;
  } | null;
  readonly portions: {
    readonly portionSize: PortionSize;
    readonly portionSizeIsDefault: boolean;
    readonly ricePortion: PortionSize;
    readonly ricePortionIsDefault: boolean;
  };
  readonly rules: ProfileRulesView;
  readonly preferences: {
    readonly spiceLevel: SpiceLevel | null;
    readonly lessOf: readonly LessOf[];
    readonly textures: readonly Texture[];
    readonly updatedAt: Date | null;
  };
  readonly likesDislikes: {
    readonly likes: readonly FoodRefView[];
    readonly dislikes: readonly FoodRefView[];
    readonly updatedAt: Date | null;
  };
  readonly createdAt: Date;
  readonly updatedAt: Date;
}

interface ProfileRow {
  id: string;
  name: string;
  avatar_style: "initials" | "illustration";
  avatar_color_token: string | null;
  avatar_illustration_id: string | null;
  age_group: AgeGroup;
  is_child: boolean;
  portion_size: PortionSize | null;
  rice_portion: PortionSize | null;
  likes_dislikes_updated_at: Date | null;
  created_at: Date;
  updated_at: Date;
  is_manager: boolean;
  spice_level: SpiceLevel | null;
  less_of: LessOf[] | null;
  textures: Texture[] | null;
  pref_updated_at: Date | null;
}

const PROFILE_SELECT = `
SELECT p.id, p.name, p.avatar_style, p.avatar_color_token, p.avatar_illustration_id,
       p.age_group, p.is_child, p.portion_size, p.rice_portion, p.likes_dislikes_updated_at,
       p.created_at, p.updated_at,
       (p.id = h.manager_profile_id) AS is_manager,
       sp.spice_level, sp.less_of, sp.textures, sp.updated_at AS pref_updated_at
  FROM profile p
  JOIN household h ON h.id = p.household_id
  LEFT JOIN soft_preference sp ON sp.profile_id = p.id
 WHERE p.household_id = $1`;

const CREATE_PROFILE = "create_profile";
const CREATE_HARD_RULE = "create_hard_rule";

export interface ProfileServiceDeps {
  readonly db: SqlExecutor;
  readonly keys: HealthDataKeys;
  readonly catalog: ReferenceCatalog;
  readonly config: ApiConfig;
  readonly targets: Targets;
  readonly profileConfig: ProfileConfig;
  readonly hashKey: Buffer;
  readonly clock?: Clock;
}

/** What makes two hard rules the same rule (for duplicates and idempotent replays). */
function ruleIdentity(rule: {
  readonly type: HardRuleType;
  readonly allergen: StandardAllergen | null;
  readonly freeText: string | null;
  readonly mappedIds: readonly string[];
}): string {
  // L5: compatibility forms (full-width letters and the like) and case fold
  // together, so a look-alike text is the same rule.
  const text =
    rule.freeText === null
      ? null
      : rule.freeText.normalize("NFKC").trim().replace(/\s+/g, " ").toLowerCase();
  return JSON.stringify([rule.type, rule.allergen, text, [...rule.mappedIds].sort()]);
}

function identityOfInput(rule: NewHardRule): string {
  switch (rule.type) {
    case "allergy":
      return ruleIdentity({
        type: rule.type,
        allergen: rule.allergen,
        freeText: null,
        mappedIds: [],
      });
    case "halal":
    case "vegetarian":
    case "vegan":
      return ruleIdentity({ type: rule.type, allergen: null, freeText: null, mappedIds: [] });
    case "free_text":
    case "medical_exclusion":
      return ruleIdentity({
        type: rule.type,
        allergen: null,
        freeText: rule.freeText ?? null,
        mappedIds: rule.mappedIngredientIds ?? [],
      });
  }
}

function identityOfStored(rule: HardRuleRecord): string {
  return ruleIdentity({
    type: rule.type,
    allergen: rule.allergen,
    freeText: rule.freeText,
    mappedIds: rule.mapping?.status === "mapped" ? rule.mapping.ingredientIds : [],
  });
}

export class ProfileService {
  readonly #db: SqlExecutor;
  readonly #keys: HealthDataKeys;
  readonly #catalog: ReferenceCatalog;
  readonly #config: ApiConfig;
  readonly #targets: Targets;
  readonly #profileConfig: ProfileConfig;
  readonly #hashKey: Buffer;
  readonly #clock: Clock;

  constructor(deps: ProfileServiceDeps) {
    this.#db = deps.db;
    this.#keys = deps.keys;
    this.#catalog = deps.catalog;
    this.#config = deps.config;
    this.#targets = deps.targets;
    this.#profileConfig = deps.profileConfig;
    this.#hashKey = deps.hashKey;
    this.#clock = deps.clock ?? systemClock;
  }

  /** PRF-02: the configured profile limit (target, at least 12). */
  get maxProfiles(): number {
    return this.#targets.household.maxProfiles.value;
  }

  #idempotent(
    scope: HouseholdScope,
    key: string | null,
    operation: string,
    parts: readonly unknown[],
    now: Date,
  ): IdempotentRequest | null {
    if (key === null) return null;
    return {
      accountId: scope.accountId,
      key,
      operation,
      requestHash: requestHash(this.#hashKey, operation, parts),
      keptSince: new Date(now.getTime() - this.#config.retention.idempotencyKeyHours * 3600_000),
    };
  }

  // ------------------------------------------------------------ profiles

  /** All profiles, manager first. Fails as a whole if any member's rules cannot be read. */
  async list(scope: HouseholdScope): Promise<ProfileView[]> {
    const { rows } = await withDbErrors(() =>
      this.#db.query<ProfileRow>(`${PROFILE_SELECT} ORDER BY is_manager DESC, p.created_at, p.id`, [
        scope.householdId,
      ]),
    );
    return this.#views(scope, rows);
  }

  async get(scope: HouseholdScope, profileId: string): Promise<ProfileView> {
    if (!isUuid(profileId)) throw new NotFoundError("profile");
    const { rows } = await withDbErrors(() =>
      this.#db.query<ProfileRow>(`${PROFILE_SELECT} AND p.id = $2`, [scope.householdId, profileId]),
    );
    const [view] = await this.#views(scope, rows);
    if (view === undefined) throw new NotFoundError("profile");
    return view;
  }

  async #views(scope: HouseholdScope, rows: readonly ProfileRow[]): Promise<ProfileView[]> {
    if (rows.length === 0) return [];
    const ids = rows.map((row) => row.id);
    let rules: Map<string, ProfileRules>;
    try {
      rules = await listMembersRules(this.#db, this.#keys, scope.householdId, ids);
    } catch (error) {
      // A profile deleted between the two reads: retry rather than answer
      // with a profile whose rules were not read.
      if (error instanceof NotFoundError) throw new ConcurrentUpdateError();
      throw error;
    }
    const [guardians, likes] = await Promise.all([
      this.#guardians(scope.householdId, ids),
      this.#likes(ids),
    ]);
    const mapped = [...rules.values()].flatMap((r) =>
      r.items.flatMap((rule) => rule.mapping?.ingredientIds ?? []),
    );
    const ingredientIds = [
      ...mapped,
      ...[...likes.values()]
        .flat()
        .filter((ref) => ref.kind === "ingredient")
        .map((ref) => ref.refId),
    ];
    const dishIds = [...likes.values()]
      .flat()
      .filter((ref) => ref.kind === "dish")
      .map((ref) => ref.refId);
    const [ingredientNames, dishNames] = await Promise.all([
      this.#catalog.ingredientNames(ingredientIds),
      this.#catalog.dishNames(dishIds),
    ]);
    const nameOf = (kind: FoodRefKind, refId: string) =>
      (kind === "ingredient" ? ingredientNames : dishNames).get(refId) ?? fallbackName(refId);

    return rows.map((row): ProfileView => {
      const memberRules = rules.get(row.id);
      // Fail closed: every listed profile must have had its rules read.
      if (memberRules === undefined) throw new ConcurrentUpdateError();
      const defaults = this.#profileConfig.portionDefaults[row.age_group];
      const handling = dataHandlingFor(row.age_group);
      const refs = likes.get(row.id) ?? [];
      const guardian = guardians.get(row.id) ?? null;
      return {
        id: row.id,
        name: row.name,
        avatar: {
          style: row.avatar_style,
          colorToken: row.avatar_color_token,
          illustrationId: row.avatar_illustration_id,
        },
        ageGroup: row.age_group,
        // L6: if the policy and the stored flag ever disagree, the stricter one wins.
        isChild: handling.isChild || row.is_child,
        isManager: row.is_manager,
        guardianConfirmation: handling.isChild || row.is_child ? guardian : null,
        portions: {
          portionSize: row.portion_size ?? defaults.portionSize,
          portionSizeIsDefault: row.portion_size === null,
          ricePortion: row.rice_portion ?? defaults.ricePortion,
          ricePortionIsDefault: row.rice_portion === null,
        },
        rules: this.#rulesView(memberRules, handling.isChild || row.is_child, (id) =>
          nameOf("ingredient", id),
        ),
        preferences: {
          spiceLevel: row.spice_level,
          lessOf: row.less_of ?? [],
          textures: row.textures ?? [],
          updatedAt: row.pref_updated_at,
        },
        likesDislikes: {
          likes: refs
            .filter((ref) => ref.sentiment === "like")
            .map((ref) => ({
              kind: ref.kind,
              refId: ref.refId,
              displayName: nameOf(ref.kind, ref.refId),
            })),
          dislikes: refs
            .filter((ref) => ref.sentiment === "dislike")
            .map((ref) => ({
              kind: ref.kind,
              refId: ref.refId,
              displayName: nameOf(ref.kind, ref.refId),
            })),
          updatedAt: row.likes_dislikes_updated_at,
        },
        createdAt: row.created_at,
        updatedAt: row.updated_at,
      };
    });
  }

  #rulesView(
    rules: ProfileRules,
    isChild: boolean,
    nameOf: (id: string) => LocalizedName,
  ): ProfileRulesView {
    return {
      // QUESTIONS #62: the stored rules are still returned (and still used by
      // Cek Aman) while a renewal is needed; only new health data waits.
      consent: { ...rules.consent, renewalRequired: renewalRequired(rules.consent, isChild) },
      // Contract: `items` is empty unless consent is given (the data layer guarantees it too).
      items:
        rules.consent.status === "given" ? rules.items.map((rule) => ruleView(rule, nameOf)) : [],
    };
  }

  async #guardians(
    householdId: string,
    profileIds: readonly string[],
  ): Promise<Map<string, NonNullable<ProfileView["guardianConfirmation"]>>> {
    const { rows } = await withDbErrors(() =>
      this.#db.query<{ id: string; profile_id: string; decided_at: Date; text_version: string }>(
        `SELECT DISTINCT ON (profile_id) id, profile_id, decided_at, text_version
           FROM consent_record
          WHERE household_id = $1 AND profile_id = ANY($2::uuid[])
            AND purpose = 'guardian_confirmation' AND decision = 'given'
          ORDER BY profile_id, seq DESC`,
        [householdId, profileIds],
      ),
    );
    return new Map(
      rows.map((row) => [
        row.profile_id,
        { consentRecordId: row.id, confirmedAt: row.decided_at, textVersion: row.text_version },
      ]),
    );
  }

  async #likes(
    profileIds: readonly string[],
  ): Promise<Map<string, { kind: FoodRefKind; refId: string; sentiment: "like" | "dislike" }[]>> {
    const { rows } = await withDbErrors(() =>
      this.#db.query<{
        profile_id: string;
        kind: FoodRefKind;
        ref_id: string;
        sentiment: "like" | "dislike";
      }>(
        `SELECT profile_id, kind, ref_id, sentiment FROM profile_like_dislike
          WHERE profile_id = ANY($1::uuid[])
          ORDER BY created_at, kind, ref_id`,
        [profileIds],
      ),
    );
    const out = new Map<
      string,
      { kind: FoodRefKind; refId: string; sentiment: "like" | "dislike" }[]
    >();
    for (const row of rows) {
      const list = out.get(row.profile_id) ?? [];
      list.push({ kind: row.kind, refId: row.ref_id, sentiment: row.sentiment });
      out.set(row.profile_id, list);
    }
    return out;
  }

  /**
   * PRF-01, PRF-02, SET-10: adds a member. A child needs the guardian
   * confirmation in the same request; health data stays off (no consent).
   */
  async create(
    scope: HouseholdScope,
    input: ProfileCreateInput,
    idempotencyKey: string | null,
  ): Promise<ProfileView> {
    const now = this.#clock.now();
    const avatar = input.avatar;
    const request = this.#idempotent(
      scope,
      idempotencyKey,
      CREATE_PROFILE,
      [
        input.name,
        input.ageGroup,
        avatar === null ? null : [avatar.style, avatar.colorToken, avatar.illustrationId],
        input.guardianConfirmation === null
          ? null
          : [
              input.guardianConfirmation.confirmed,
              input.guardianConfirmation.textVersion,
              input.guardianConfirmation.language,
            ],
      ],
      now,
    );
    const profileId = await withDbErrors(() =>
      this.#db.transaction(async (tx) => {
        // Serializes profile creation per household, so the limit holds
        // under concurrent requests. `NO KEY UPDATE` does not block writers
        // that only reference the household.
        await tx.query(`SELECT set_config('lock_timeout', $1, true)`, [
          `${this.#config.sessions.lockTimeoutMs}ms`,
        ]);
        await tx.query(`SELECT id FROM household WHERE id = $1 FOR NO KEY UPDATE`, [
          scope.householdId,
        ]);
        if (request !== null) {
          const previous = await findReplay(tx, request);
          if (previous !== null) return previous;
        }
        const { rows } = await tx.query<{ n: string }>(
          `SELECT count(*) AS n FROM profile WHERE household_id = $1`,
          [scope.householdId],
        );
        if (Number(rows[0]?.n ?? 0) >= this.maxProfiles) throw profileLimitReached();

        const id = randomUUID();
        await tx.query(
          `INSERT INTO profile
             (id, household_id, name, avatar_style, avatar_color_token, avatar_illustration_id,
              age_group, created_at, updated_at)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $8)`,
          [
            id,
            scope.householdId,
            input.name,
            avatar?.style ?? "initials",
            avatar?.colorToken ?? null,
            avatar?.illustrationId ?? null,
            input.ageGroup,
            now,
          ],
        );
        if (dataHandlingFor(input.ageGroup).guardianConfirmationRequired) {
          await recordGuardian(tx, scope, id, input.guardianConfirmation, now);
        }
        if (request !== null) await remember(tx, request, id, now);
        // SET-10: check the guardian constraint now, inside this call.
        await tx.query(`SET CONSTRAINTS ALL IMMEDIATE`);
        return id;
      }),
    );
    try {
      return await this.get(scope, profileId);
    } catch (error) {
      // A replayed key whose profile was deleted since.
      if (error instanceof NotFoundError && request !== null) throw idempotencyKeyReused();
      throw error;
    }
  }

  /** PRF-01, PRF-07, PRF-18, SET-10: edits a profile; a change into a child age group needs the guardian confirmation. */
  async update(
    scope: HouseholdScope,
    profileId: string,
    input: ProfileUpdateInput,
  ): Promise<ProfileView> {
    if (!isUuid(profileId)) throw new NotFoundError("profile");
    const now = this.#clock.now();
    await withDbErrors(() =>
      this.#db.transaction(async (tx) => {
        await lockMembers(tx, scope.householdId, [profileId]);
        const { rows } = await tx.query<{ age_group: AgeGroup; is_manager: boolean }>(
          `SELECT p.age_group, (p.id = h.manager_profile_id) AS is_manager
             FROM profile p JOIN household h ON h.id = p.household_id
            WHERE p.id = $1 AND p.household_id = $2`,
          [profileId, scope.householdId],
        );
        const current = rows[0];
        if (current === undefined) throw new NotFoundError("profile");
        const nextAge = input.ageGroup ?? current.age_group;
        // QUESTIONS #46 (owner, 2026-11-12): the manager gives every consent and
        // guardian confirmation, so the manager's own profile stays an adult.
        if (current.is_manager && isChildAgeGroup(nextAge)) throw managerProfileMustBeAdult();
        const becomesChild = isChildAgeGroup(nextAge) && !isChildAgeGroup(current.age_group);
        if (becomesChild) {
          await recordGuardian(tx, scope, profileId, input.guardianConfirmation ?? null, now);
        } else if (input.guardianConfirmation !== undefined) {
          if (!isChildAgeGroup(nextAge)) {
            throw new ApiError("validation_failed", 400, "Request validation failed", {
              fieldErrors: [{ pointer: "/guardianConfirmation", code: "not_allowed" }],
            });
          }
          // A child's guardian confirmation renewed, for example for a new text version.
          await recordGuardian(tx, scope, profileId, input.guardianConfirmation, now);
        }

        const sets: string[] = [];
        const params: unknown[] = [profileId, scope.householdId];
        const set = (column: string, value: unknown) => {
          params.push(value);
          sets.push(`${column} = $${params.length}`);
        };
        if (input.name !== undefined) set("name", input.name);
        if (input.avatar !== undefined) {
          set("avatar_style", input.avatar.style);
          set("avatar_color_token", input.avatar.colorToken);
          set("avatar_illustration_id", input.avatar.illustrationId);
        }
        if (input.ageGroup !== undefined) set("age_group", input.ageGroup);
        if (input.portionSize !== undefined) set("portion_size", input.portionSize);
        if (input.ricePortion !== undefined) set("rice_portion", input.ricePortion);
        set("updated_at", now);
        await tx.query(
          `UPDATE profile SET ${sets.join(", ")} WHERE id = $1 AND household_id = $2`,
          params,
        );
        await tx.query(`SET CONSTRAINTS ALL IMMEDIATE`);
      }),
    );
    return this.get(scope, profileId);
  }

  /** PRF-01, SET-07: deletes the profile and all of its data. */
  async remove(scope: HouseholdScope, profileId: string): Promise<void> {
    if (!(await deleteProfile(this.#db, scope.householdId, profileId))) {
      throw new NotFoundError("profile");
    }
  }

  // ------------------------------------------------------------ preferences

  /** PRF-05: replaces the soft preferences. Not health data. */
  async replacePreferences(
    scope: HouseholdScope,
    profileId: string,
    input: SoftPreferencesInput,
  ): Promise<ProfileView["preferences"]> {
    if (!isUuid(profileId)) throw new NotFoundError("profile");
    const now = this.#clock.now();
    const { rows } = await withDbErrors(() =>
      this.#db.query<{
        spice_level: SpiceLevel | null;
        less_of: LessOf[];
        textures: Texture[];
        updated_at: Date;
      }>(
        `INSERT INTO soft_preference (profile_id, spice_level, less_of, textures, updated_at)
         SELECT p.id, $3, $4::text[], $5::text[], $6
           FROM profile p WHERE p.id = $1 AND p.household_id = $2
         ON CONFLICT (profile_id) DO UPDATE
           SET spice_level = EXCLUDED.spice_level, less_of = EXCLUDED.less_of,
               textures = EXCLUDED.textures, updated_at = EXCLUDED.updated_at
         RETURNING spice_level, less_of, textures, updated_at`,
        [
          profileId,
          scope.householdId,
          input.spiceLevel,
          [...input.lessOf],
          [...input.textures],
          now,
        ],
      ),
    );
    const row = rows[0];
    if (row === undefined) throw new NotFoundError("profile");
    return {
      spiceLevel: row.spice_level,
      lessOf: row.less_of,
      textures: row.textures,
      updatedAt: row.updated_at,
    };
  }

  /** PRF-06: replaces likes and dislikes; only known ingredients or dishes are accepted. */
  async replaceLikesDislikes(
    scope: HouseholdScope,
    profileId: string,
    input: LikesDislikesInput,
  ): Promise<ProfileView["likesDislikes"]> {
    if (!isUuid(profileId)) throw new NotFoundError("profile");
    const all = [
      ...input.likes.map((ref, index) => ({
        ref,
        pointer: `/likes/${index}/refId`,
        sentiment: "like" as const,
      })),
      ...input.dislikes.map((ref, index) => ({
        ref,
        pointer: `/dislikes/${index}/refId`,
        sentiment: "dislike" as const,
      })),
    ];
    const names = await this.#namesFor(all.map((item) => item.ref));
    const unknown = all.filter((item) => !names.has(`${item.ref.kind}:${item.ref.refId}`));
    if (unknown.length > 0) {
      throw new ApiError("validation_failed", 400, "Request validation failed", {
        fieldErrors: unknown.map((item) => ({
          pointer: item.pointer,
          code: "invalid_value" as const,
        })),
      });
    }
    const now = this.#clock.now();
    await withDbErrors(() =>
      this.#db.transaction(async (tx) => {
        await lockMembers(tx, scope.householdId, [profileId]);
        await tx.query(`DELETE FROM profile_like_dislike WHERE profile_id = $1`, [profileId]);
        for (const [index, item] of all.entries()) {
          await tx.query(
            `INSERT INTO profile_like_dislike (profile_id, kind, ref_id, sentiment, created_at)
             VALUES ($1, $2, $3, $4, $5)`,
            [
              profileId,
              item.ref.kind,
              item.ref.refId,
              item.sentiment,
              new Date(now.getTime() + index),
            ],
          );
        }
        await tx.query(
          `UPDATE profile SET likes_dislikes_updated_at = $3 WHERE id = $1 AND household_id = $2`,
          [profileId, scope.householdId, now],
        );
      }),
    );
    const view = (item: FoodRefInput): FoodRefView => ({
      kind: item.kind,
      refId: item.refId,
      displayName: names.get(`${item.kind}:${item.refId}`) ?? fallbackName(item.refId),
    });
    return { likes: input.likes.map(view), dislikes: input.dislikes.map(view), updatedAt: now };
  }

  async #namesFor(refs: readonly FoodRefInput[]): Promise<Map<string, LocalizedName>> {
    const [ingredients, dishes] = await Promise.all([
      this.#catalog.ingredientNames(
        refs.filter((r) => r.kind === "ingredient").map((r) => r.refId),
      ),
      this.#catalog.dishNames(refs.filter((r) => r.kind === "dish").map((r) => r.refId)),
    ]);
    const out = new Map<string, LocalizedName>();
    for (const [id, name] of ingredients) out.set(`ingredient:${id}`, name);
    for (const [id, name] of dishes) out.set(`dish:${id}`, name);
    return out;
  }

  // ------------------------------------------------------------ hard rules

  /** PRF-03, ACC-08: the member's rules and consent state; 503 instead of a partial list. */
  async listRules(scope: HouseholdScope, profileId: string): Promise<ProfileRulesView> {
    if (!isUuid(profileId)) throw new NotFoundError("profile");
    const rules = await listProfileRules(this.#db, this.#keys, scope.householdId, profileId);
    const child = await isChildProfile(this.#db, scope.householdId, profileId);
    return this.#rulesView(rules, child, await this.#names(rules.items));
  }

  async #names(items: readonly HardRuleRecord[]): Promise<(id: string) => LocalizedName> {
    const ids = items.flatMap((rule) => rule.mapping?.ingredientIds ?? []);
    const names = await this.#catalog.ingredientNames(ids);
    return (id) => names.get(id) ?? fallbackName(id);
  }

  /**
   * PRF-03, PRF-04, PRF-08, ACC-08, SET-10: adds one hard rule. Order of
   * checks: idempotent replay, consent and guardian gate (409), known mapped
   * ingredients (400), duplicate (409), then the encrypted write.
   */
  async createRule(
    scope: HouseholdScope,
    profileId: string,
    rule: NewHardRule,
    idempotencyKey: string | null,
  ): Promise<HardRuleView> {
    if (!isUuid(profileId)) throw new NotFoundError("profile");
    const now = this.#clock.now();
    // DAT-02: the hashed request names only the member, never the rule; a
    // replay is compared with the decrypted rule instead.
    const request = this.#idempotent(scope, idempotencyKey, CREATE_HARD_RULE, [profileId], now);
    if (request !== null) {
      const previous = await withDbErrors(() => findReplay(this.#db, request));
      if (previous !== null) {
        const current = await listProfileRules(this.#db, this.#keys, scope.householdId, profileId);
        const stored = current.items.find((item) => item.id === previous);
        if (stored === undefined || identityOfStored(stored) !== identityOfInput(rule)) {
          throw idempotencyKeyReused();
        }
        return ruleView(stored, await this.#names([stored]));
      }
    }

    // ACC-08, SET-10: a clear 409 before any key service work.
    await assertHealthDataWritable(this.#db, scope.householdId, profileId);

    const mappedIds =
      rule.type === "free_text" || rule.type === "medical_exclusion"
        ? (rule.mappedIngredientIds ?? [])
        : [];
    if (mappedIds.length > 0) {
      const known = await this.#catalog.ingredientNames(mappedIds);
      const unknown = mappedIds
        .map((id, index) => ({ id, index }))
        .filter((item) => !known.has(item.id));
      if (unknown.length > 0) {
        throw new ApiError("validation_failed", 400, "Request validation failed", {
          fieldErrors: unknown.map((item) => ({
            pointer: `/mappedIngredientIds/${item.index}`,
            code: "invalid_value" as const,
          })),
        });
      }
    }

    const stored = await insertHardRule(this.#db, this.#keys, {
      householdId: scope.householdId,
      profileId,
      rule,
      // PRF-08: a mapping picked at entry is the manager's confirmation; set
      // from the authenticated role, never from the request (PR #5 L6).
      mappingConfirmedBy: mappedIds.length > 0 ? "manager" : null,
      now,
      // L5: under the member lock, so concurrent identical creates cannot both
      // pass; the consent gate runs again there too.
      beforeInsert: async (tx: SqlExecutor, existing: readonly HardRuleRecord[]) => {
        await assertHealthDataWritable(tx, scope.householdId, profileId);
        const identity = identityOfInput(rule);
        if (existing.some((item) => identityOfStored(item) === identity)) {
          throw hardRuleDuplicate();
        }
      },
      ...(request === null
        ? {}
        : { onInserted: (tx: SqlExecutor, ruleId: string) => remember(tx, request, ruleId, now) }),
    });
    return ruleView(stored, await this.#names([stored]));
  }

  /** PRF-03: the manager removes a rule (an edit of the profile, never a safety override). */
  async removeRule(scope: HouseholdScope, profileId: string, ruleId: string): Promise<void> {
    if (!(await deleteHardRule(this.#db, scope.householdId, profileId, ruleId))) {
      throw new NotFoundError("hard rule");
    }
  }
}

function ruleView(rule: HardRuleRecord, nameOf: (id: string) => LocalizedName): HardRuleView {
  return {
    id: rule.id,
    type: rule.type,
    allergen: rule.allergen,
    freeText: rule.freeText,
    mapping:
      rule.mapping === null
        ? null
        : {
            status: rule.mapping.status,
            ingredients: rule.mapping.ingredientIds.map((ingredientId) => ({
              ingredientId,
              displayName: nameOf(ingredientId),
            })),
            confirmedBy: rule.mapping.status === "mapped" ? rule.mapping.confirmedBy : null,
            updatedAt: rule.mapping.updatedAt,
          },
    createdAt: rule.createdAt,
  };
}
