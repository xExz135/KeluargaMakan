/**
 * SRS 18 acceptance: "A data audit can trace every stored field to an entity
 * in this table." Every table and column in the database is listed here with
 * the SRS 18.1 entity and attribute it stores. A database test compares this
 * map with `information_schema`, both ways, so a column cannot be added
 * without a trace.
 *
 * Sensitivity follows SRS 18.1. `health` columns are encrypted with the
 * health-data key (DAT-02) or hold only IDs that point at such data.
 */

export const SRS_18_1_ENTITIES = [
  "Household",
  "Account",
  "Profile",
  "Hard rule",
  "Soft preference",
  "Health profile",
  "Consent record",
  "Kitchen item",
  "Ingredient set",
  "Leftover",
  "Meal",
  "Nutrition estimate",
  "Feedback",
  "Plan",
  "Family recipe",
  "Shared link",
  "Safety result log",
  "Library recipe",
  "Ingredient",
  "Nutrition reference",
] as const;
export type Srs181Entity = (typeof SRS_18_1_ENTITIES)[number];

/** V2 and V3 entities (SRS 21): never stored in V1. */
export const LATER_PHASE_ENTITIES: readonly Srs181Entity[] = [
  "Health profile",
  "Leftover",
  "Nutrition estimate",
  "Plan",
  "Family recipe",
  "Shared link",
  "Nutrition reference",
];

export type Sensitivity = "public" | "personal" | "health" | "infrastructure";

export interface TableTrace {
  /** `infrastructure` only for the migration bookkeeping table. */
  readonly entity: Srs181Entity | "infrastructure";
  readonly sensitivity: Sensitivity;
  /** Column name -> the SRS 18.1 attribute (or requirement) it stores. */
  readonly columns: Readonly<Record<string, string>>;
}

const id = "identifier (opaque UUID)";
const household = "Belongs to: Household (scoping, NFR-09)";
const created = "record time";
const updated = "record time of last change";

export const SCHEMA_TRACE: Readonly<Record<string, TableTrace>> = {
  schema_migration: {
    entity: "infrastructure",
    sensitivity: "infrastructure",
    columns: {
      version: "applied migration version",
      name: "applied migration name",
      checksum: "applied migration checksum",
      applied_at: "applied time",
    },
  },
  household: {
    entity: "Household",
    sensitivity: "personal",
    columns: {
      id,
      name: "Name",
      city: "City",
      time_zone: "Time zone",
      language: "Language (ACC-09)",
      manager_account_id: "Manager account (ACC-03)",
      manager_profile_id: "Manager account's own profile (ACC-04)",
      created_at: created,
      updated_at: updated,
    },
  },
  account: {
    entity: "Account",
    sensitivity: "personal",
    columns: {
      id,
      household_id: "Belongs to: Household",
      role: "Role (manager; co-cook is V2)",
      phone: "Phone (ACC-01)",
      email: "Email (ACC-01)",
      sign_in_methods: "Sign-in method (ACC-01, ACC-02)",
      created_at: created,
      updated_at: updated,
    },
  },
  profile: {
    entity: "Profile",
    sensitivity: "personal",
    columns: {
      id,
      household_id: household,
      name: "Name",
      avatar_style: "Avatar (PRF-01; no photos, QUESTIONS #27)",
      avatar_color_token: "Avatar",
      avatar_illustration_id: "Avatar",
      age_group: "Age group (PRF-01)",
      is_child: "Children flagged (PRF-18), derived from age group",
      portion_size: "Portion sizes (PRF-07); null = age-group default",
      rice_portion: "Portion sizes: rice portion (PRF-07); null = age-group default",
      likes_dislikes_updated_at: "Likes, dislikes: time of last change",
      created_at: created,
      updated_at: updated,
    },
  },
  profile_like_dislike: {
    entity: "Profile",
    sensitivity: "personal",
    columns: {
      profile_id: "Profile",
      kind: "Likes, dislikes: ingredient or dish (PRF-06)",
      ref_id: "Likes, dislikes: reference ingredient or dish (PRF-06)",
      sentiment: "Likes, dislikes (PRF-06)",
      created_at: created,
    },
  },
  soft_preference: {
    entity: "Soft preference",
    sensitivity: "personal",
    columns: {
      profile_id: "Belongs to: Profile",
      spice_level: "Type: spice level, strength (PRF-05)",
      less_of: "Type: less fried, sugar, salt, santan (PRF-05)",
      textures: "Type: textures (PRF-05)",
      updated_at: updated,
    },
  },
  consent_record: {
    entity: "Consent record",
    sensitivity: "personal",
    columns: {
      id,
      seq: "order of decisions (latest decision wins, SET-03)",
      household_id: household,
      profile_id: "Member",
      purpose: "Purpose (health data, guardian confirmation SET-10)",
      decision: "Date given / declined (QUESTIONS #47)",
      text_version: "Text version (SET-03)",
      language: "Text version: language shown",
      decided_at: "Date given",
      recorded_by_account_id: "recorded by the manager account (ACC-08)",
      withdrawn_at: "Date withdrawn (SET-03)",
      deletion_due_by: "Date withdrawn: deletion deadline (SET-04)",
    },
  },
  health_data_key: {
    entity: "Hard rule",
    sensitivity: "health",
    columns: {
      id: "member data key ID; pseudonymous member ID in the safety log (QUESTIONS #40)",
      household_id: household,
      profile_id: "Belongs to: Profile",
      key_ref: "health-data key that wrapped the data key (DAT-02)",
      wrapped_key: "member data key, wrapped by the health-data key (DAT-02)",
      created_at: created,
    },
  },
  hard_rule: {
    entity: "Hard rule",
    sensitivity: "health",
    columns: {
      id,
      household_id: household,
      profile_id: "Belongs to: Profile",
      health_key_id: "data key used (DAT-02)",
      consent_record_id: "consent the rule was stored under (ACC-08, QUESTIONS #13)",
      details_enc: "Type, mapped ingredients, free text, mapping status (encrypted, DAT-02)",
      created_at: created,
      updated_at: updated,
    },
  },
  kitchen_item: {
    entity: "Kitchen item",
    sensitivity: "personal",
    columns: {
      id,
      household_id: household,
      ingredient_id: "Ingredient: reference ingredient (KIT-04)",
      custom_name: "Ingredient: custom ingredient (KIT-05)",
      category: "Ingredient: category (KIT-03)",
      state: "State (KIT-02)",
      quantity: "Quantity (KIT-09)",
      brand_id: "Brand (KIT-09, SAF-07)",
      brand_custom_name: "Brand (KIT-09), not in the reference data",
      is_default_staple: "State: default staple (KIT-07, ACC-05)",
      changed_by_account_id: "Last changed by",
      changed_at: "Last changed when: server time (KIT-16)",
      client_changed_at: "Last changed when: device time (KIT-16)",
      created_at: created,
    },
  },
  ingredient_set: {
    entity: "Ingredient set",
    sensitivity: "personal",
    columns: {
      id,
      household_id: household,
      name: "Name (KIT-08)",
      created_at: created,
      updated_at: updated,
    },
  },
  ingredient_set_item: {
    entity: "Ingredient set",
    sensitivity: "personal",
    columns: {
      set_id: "Ingredient set",
      household_id: household,
      kitchen_item_id: "List of ingredients (KIT-08)",
    },
  },
  meal: {
    entity: "Meal",
    sensitivity: "personal",
    columns: {
      id,
      household_id: household,
      eaten_on: "Date",
      slot: "Slot (SUG-02 meal types)",
      recipe_id: "Recipe (SUG-07 repetition window)",
      created_at: created,
    },
  },
  meal_member: {
    entity: "Meal",
    sensitivity: "personal",
    columns: {
      meal_id: "Meal",
      household_id: household,
      profile_id: "Members who ate (PRF-14)",
    },
  },
  feedback: {
    entity: "Feedback",
    sensitivity: "personal",
    columns: {
      meal_id: "Meal",
      household_id: household,
      overall: "Rating overall (PRF-13)",
      created_at: created,
      updated_at: updated,
    },
  },
  feedback_member: {
    entity: "Feedback",
    sensitivity: "personal",
    columns: {
      meal_id: "Meal",
      profile_id: "Rating per member: member",
      rating: "Rating per member (PRF-13)",
    },
  },
  reference_dataset: {
    entity: "Ingredient",
    sensitivity: "public",
    columns: {
      version: "reference data version (DAT-06)",
      schema: "dataset schema identifier",
      content_sha256: "content hash of the dataset (DAT-06, PR #5 M3)",
      payload:
        "Names and local names, category, components, allergens, halal status, brand variants, TKPI link",
      imported_at: created,
      is_active: "version in use (SAF-13)",
    },
  },
  safety_log: {
    entity: "Safety result log",
    sensitivity: "health",
    columns: {
      id,
      household_id: "Belongs to: Household; cleared when the household is deleted",
      log_format: "log record format version",
      subject_kind: "Recipe: kind of food item (SAF-02)",
      subject_id: "Recipe",
      subject_version: "Recipe: version",
      evaluated_at: "evaluation time (SAF-14)",
      rule_set_version: "Rule set version",
      reference_version: "Data version",
      ingredient_ids: "Recipe: reference ingredient IDs evaluated",
      recorded_brands: "Recipe: household brands evaluated (SAF-07)",
      created_at: created,
    },
  },
  safety_log_member: {
    entity: "Safety result log",
    sensitivity: "health",
    columns: {
      log_id: "Safety result log",
      member_index: "Members: order",
      member_key_id: "Members: pseudonymous ID (QUESTIONS #40)",
      status: "Result",
      reason_codes: "Result: reason codes",
      details_enc: "Result: rules and reasons (encrypted, DAT-02)",
      redacted_at: "Result: time the details were removed (SET-04, SET-07, SET-08)",
    },
  },
};
