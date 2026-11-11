import type { Migration } from "./types.js";

/**
 * SRS 18.1 Household, Account, Profile, Soft preference and Consent record
 * (V1). Hard rules and their keys are in 0004, after the safety log they
 * redact. Every column is listed in `schema-trace.ts`.
 *
 * Integrity choices:
 * - ACC-03: exactly one manager account per household (`household` points at
 *   it, and a partial unique index allows one manager per household).
 * - Composite foreign keys `(id, household_id)` keep every child row inside one
 *   household (NFR-09 scoping cannot be bypassed by mixing IDs).
 * - The manager's profile can only be deleted together with the household
 *   (deferred foreign key `household_manager_profile_fkey`).
 * - PRF-18: `is_child` is generated from the age group (DECISIONS 2026-11-10).
 * - SET-10: a child profile needs a recorded guardian confirmation, checked at
 *   commit by a constraint trigger.
 * - SET-03: consent records are append-only, apart from recording a withdrawal
 *   once and clearing links when a profile, household or account is deleted
 *   (QUESTIONS #33 safer default: consent records are kept).
 * - PRF-01, QUESTIONS #27: avatars only. There is no photo column.
 */
export const migration0001: Migration = {
  version: 1,
  name: "household-profiles-consent",
  sql: String.raw`
CREATE TABLE household (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text CHECK (name IS NULL OR char_length(name) BETWEEN 1 AND 60),
  city text CHECK (city IS NULL OR char_length(city) BETWEEN 1 AND 80),
  time_zone text NOT NULL CHECK (char_length(time_zone) BETWEEN 1 AND 64),
  language text NOT NULL CHECK (language IN ('id', 'en')),
  manager_account_id uuid NOT NULL,
  manager_profile_id uuid NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT household_manager_account_key UNIQUE (manager_account_id),
  CONSTRAINT household_manager_profile_key UNIQUE (manager_profile_id)
);

CREATE TABLE account (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id uuid REFERENCES household (id) ON DELETE CASCADE,
  role text NOT NULL DEFAULT 'manager' CHECK (role IN ('manager')),
  phone text CHECK (phone IS NULL OR phone ~ '^\+[1-9][0-9]{6,14}$'),
  email text CHECK (
    email IS NULL
    OR (char_length(email) BETWEEN 3 AND 254 AND email = lower(email) AND email ~ '^[^@\s]+@[^@\s]+$')
  ),
  sign_in_methods text[] NOT NULL CHECK (
    cardinality(sign_in_methods) >= 1
    AND sign_in_methods <@ ARRAY['phone', 'email', 'google']::text[]
  ),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT account_phone_key UNIQUE (phone),
  CONSTRAINT account_email_key UNIQUE (email),
  CONSTRAINT account_id_household_key UNIQUE (id, household_id)
);

CREATE UNIQUE INDEX account_one_manager_per_household
  ON account (household_id) WHERE role = 'manager';

CREATE TABLE profile (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id uuid NOT NULL REFERENCES household (id) ON DELETE CASCADE,
  name text NOT NULL CHECK (char_length(name) BETWEEN 1 AND 30),
  avatar_style text NOT NULL DEFAULT 'initials' CHECK (avatar_style IN ('initials', 'illustration')),
  avatar_color_token text CHECK (avatar_color_token IS NULL OR avatar_color_token ~ '^[a-z0-9_]{1,32}$'),
  avatar_illustration_id text CHECK (
    avatar_illustration_id IS NULL OR avatar_illustration_id ~ '^[a-z0-9_]{1,32}$'
  ),
  age_group text NOT NULL CHECK (age_group IN ('infant', 'child', 'teen', 'adult', 'elderly')),
  is_child boolean GENERATED ALWAYS AS (age_group IN ('infant', 'child', 'teen')) STORED,
  portion_size text CHECK (portion_size IS NULL OR portion_size IN ('small', 'normal', 'large')),
  rice_portion text CHECK (rice_portion IS NULL OR rice_portion IN ('small', 'normal', 'large')),
  likes_dislikes_updated_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT profile_id_household_key UNIQUE (id, household_id),
  CONSTRAINT profile_avatar_check CHECK (
    (avatar_style = 'initials' AND avatar_illustration_id IS NULL)
    OR (avatar_style = 'illustration' AND avatar_color_token IS NULL)
  )
);

CREATE INDEX profile_household_idx ON profile (household_id);

ALTER TABLE household
  ADD CONSTRAINT household_manager_account_fkey FOREIGN KEY (manager_account_id, id)
    REFERENCES account (id, household_id) DEFERRABLE INITIALLY DEFERRED,
  ADD CONSTRAINT household_manager_profile_fkey FOREIGN KEY (manager_profile_id, id)
    REFERENCES profile (id, household_id) DEFERRABLE INITIALLY DEFERRED;

CREATE TABLE soft_preference (
  profile_id uuid PRIMARY KEY REFERENCES profile (id) ON DELETE CASCADE,
  spice_level text CHECK (spice_level IS NULL OR spice_level IN ('not_spicy', 'medium', 'spicy')),
  less_of text[] NOT NULL DEFAULT '{}' CHECK (
    less_of <@ ARRAY['fried', 'sugar', 'salt', 'santan']::text[]
  ),
  textures text[] NOT NULL DEFAULT '{}' CHECK (textures <@ ARRAY['soft', 'crunchy', 'soupy']::text[]),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE profile_like_dislike (
  profile_id uuid NOT NULL REFERENCES profile (id) ON DELETE CASCADE,
  kind text NOT NULL CHECK (kind IN ('ingredient', 'dish')),
  ref_id text NOT NULL CHECK (ref_id ~ '^[a-z0-9][a-z0-9_.-]{0,99}$'),
  sentiment text NOT NULL CHECK (sentiment IN ('like', 'dislike')),
  created_at timestamptz NOT NULL DEFAULT now(),
  -- An item may not be both liked and disliked (contract LikesDislikesInput).
  PRIMARY KEY (profile_id, kind, ref_id)
);

CREATE TABLE consent_record (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  seq bigint GENERATED ALWAYS AS IDENTITY,
  household_id uuid REFERENCES household (id) ON DELETE SET NULL,
  profile_id uuid REFERENCES profile (id) ON DELETE SET NULL,
  purpose text NOT NULL CHECK (purpose IN ('health_data', 'guardian_confirmation')),
  decision text NOT NULL CHECK (decision IN ('given', 'declined')),
  text_version text NOT NULL CHECK (text_version ~ '^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$'),
  language text NOT NULL CHECK (language IN ('id', 'en')),
  decided_at timestamptz NOT NULL DEFAULT now(),
  recorded_by_account_id uuid REFERENCES account (id) ON DELETE SET NULL,
  withdrawn_at timestamptz,
  deletion_due_by timestamptz,
  CONSTRAINT consent_record_seq_key UNIQUE (seq),
  -- SET-10: a guardian confirmation is only ever a positive confirmation.
  CONSTRAINT consent_record_guardian_given CHECK (purpose <> 'guardian_confirmation' OR decision = 'given'),
  -- SET-03, SET-04: only a given health-data consent can be withdrawn, and a
  -- withdrawal always carries the deletion deadline.
  CONSTRAINT consent_record_withdrawal_check CHECK (
    withdrawn_at IS NULL OR (purpose = 'health_data' AND decision = 'given' AND withdrawn_at >= decided_at)
  ),
  CONSTRAINT consent_record_deletion_due_check CHECK (
    (withdrawn_at IS NULL AND deletion_due_by IS NULL)
    OR (withdrawn_at IS NOT NULL AND deletion_due_by IS NOT NULL AND deletion_due_by >= withdrawn_at)
  )
);

CREATE INDEX consent_record_profile_idx ON consent_record (profile_id, purpose, seq DESC);

CREATE FUNCTION consent_record_guard() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF ROW(NEW.id, NEW.seq, NEW.purpose, NEW.decision, NEW.text_version, NEW.language, NEW.decided_at)
       IS DISTINCT FROM ROW(OLD.id, OLD.seq, OLD.purpose, OLD.decision, OLD.text_version, OLD.language, OLD.decided_at)
     OR (NEW.household_id IS NOT NULL AND NEW.household_id IS DISTINCT FROM OLD.household_id)
     OR (NEW.profile_id IS NOT NULL AND NEW.profile_id IS DISTINCT FROM OLD.profile_id)
     OR (NEW.recorded_by_account_id IS NOT NULL
         AND NEW.recorded_by_account_id IS DISTINCT FROM OLD.recorded_by_account_id)
     OR (OLD.withdrawn_at IS NOT NULL AND NEW.withdrawn_at IS DISTINCT FROM OLD.withdrawn_at)
     OR (OLD.deletion_due_by IS NOT NULL AND NEW.deletion_due_by IS DISTINCT FROM OLD.deletion_due_by)
  THEN
    RAISE EXCEPTION 'consent records are append-only' USING ERRCODE = 'KM003';
  END IF;
  RETURN NEW;
END
$$;

CREATE TRIGGER consent_record_guard
  BEFORE UPDATE ON consent_record
  FOR EACH ROW EXECUTE FUNCTION consent_record_guard();

CREATE FUNCTION profile_requires_guardian_confirmation() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF EXISTS (SELECT 1 FROM profile p WHERE p.id = NEW.id AND p.is_child)
     AND NOT EXISTS (
       SELECT 1 FROM consent_record c
        WHERE c.profile_id = NEW.id AND c.purpose = 'guardian_confirmation' AND c.decision = 'given'
     )
  THEN
    RAISE EXCEPTION 'guardian confirmation required for a child profile' USING ERRCODE = 'KM002';
  END IF;
  RETURN NULL;
END
$$;

CREATE CONSTRAINT TRIGGER profile_guardian_confirmation
  AFTER INSERT OR UPDATE OF age_group ON profile
  DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW EXECUTE FUNCTION profile_requires_guardian_confirmation();
`,
};
