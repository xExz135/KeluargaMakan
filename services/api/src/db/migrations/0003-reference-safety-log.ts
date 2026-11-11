import type { Migration } from "./types.js";

/**
 * Reference data and the Cek Aman safety result log.
 *
 * Reference dataset (SRS 18.1 Ingredient, DAT-06, SAF-13): ARCHITECTURE keeps
 * versioned reference tables in PostgreSQL. A dataset is stored exactly as the
 * T-013 build produced it (validated, versioned, content-hashed, PR #5 M3) and
 * is immutable; only the active flag moves. Agents never write its values.
 *
 * Safety result log (SAF-14, DAT-05, DAT-06; DECISIONS 2026-11-11, QUESTIONS #40):
 * - Plain columns hold only versions, reference IDs, statuses and reason codes.
 *   No free text, raw ingredient names or member names (PR #5 M2).
 * - Members are identified by a pseudonymous ID: the ID of their health-data
 *   key (`health_data_key.id`, migration 0004), never the profile ID. There is
 *   deliberately no foreign key, so the row survives the member's deletion as
 *   an ID nothing links to.
 * - Rule details and full reasons are in `details_enc`, encrypted with the
 *   member's data key under the health-data key (DAT-02). Deleting that key
 *   (withdrawal, profile or household deletion) redacts them (0004 trigger).
 * - Rows are append-only, apart from redaction and unlinking the household on
 *   deletion. Retention (2 years target) comes from configuration.
 */
export const migration0003: Migration = {
  version: 3,
  name: "reference-safety-log",
  sql: String.raw`
CREATE TABLE reference_dataset (
  version text PRIMARY KEY CHECK (char_length(version) BETWEEN 1 AND 100),
  schema text NOT NULL CHECK (schema = 'keluargamakan.reference.ingredients/1'),
  content_sha256 text NOT NULL CHECK (content_sha256 ~ '^[0-9a-f]{64}$'),
  payload jsonb NOT NULL CHECK (jsonb_typeof(payload) = 'object'),
  imported_at timestamptz NOT NULL DEFAULT now(),
  is_active boolean NOT NULL DEFAULT false,
  CONSTRAINT reference_dataset_content_sha256_key UNIQUE (content_sha256)
);

CREATE UNIQUE INDEX reference_dataset_one_active ON reference_dataset (is_active) WHERE is_active;

CREATE FUNCTION reference_dataset_guard() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF ROW(NEW.version, NEW.schema, NEW.content_sha256, NEW.payload, NEW.imported_at)
       IS DISTINCT FROM ROW(OLD.version, OLD.schema, OLD.content_sha256, OLD.payload, OLD.imported_at)
  THEN
    RAISE EXCEPTION 'reference datasets are immutable; import a new version' USING ERRCODE = 'KM003';
  END IF;
  RETURN NEW;
END
$$;

CREATE TRIGGER reference_dataset_guard
  BEFORE UPDATE ON reference_dataset
  FOR EACH ROW EXECUTE FUNCTION reference_dataset_guard();

CREATE TABLE safety_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id uuid REFERENCES household (id) ON DELETE SET NULL,
  log_format text NOT NULL CHECK (char_length(log_format) BETWEEN 1 AND 64),
  subject_kind text NOT NULL CHECK (subject_kind IN (
    'library_recipe', 'suggestion', 'substitution', 'taste_tweak_fix',
    'planned_meal', 'family_recipe', 'leftover_remake'
  )),
  subject_id text NOT NULL CHECK (subject_id ~ '^[a-z0-9][a-z0-9_.-]{0,99}$'),
  subject_version text CHECK (subject_version IS NULL OR char_length(subject_version) BETWEEN 1 AND 100),
  evaluated_at timestamptz NOT NULL,
  rule_set_version text NOT NULL CHECK (char_length(rule_set_version) BETWEEN 1 AND 100),
  reference_version text NOT NULL CHECK (char_length(reference_version) BETWEEN 1 AND 100),
  -- Reference ingredient IDs in recipe order; NULL marks an unresolved
  -- (custom or AI-named) ingredient. Raw names are never stored.
  ingredient_ids text[] NOT NULL CHECK (
    array_to_string(ingredient_ids, ',') ~ '^([a-z0-9][a-z0-9_.-]{0,99}(,|$))*$'
  ),
  recorded_brands jsonb NOT NULL DEFAULT '[]' CHECK (jsonb_typeof(recorded_brands) = 'array'),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX safety_log_evaluated_at_idx ON safety_log (evaluated_at);
CREATE INDEX safety_log_household_idx ON safety_log (household_id, evaluated_at);

CREATE TABLE safety_log_member (
  log_id uuid NOT NULL REFERENCES safety_log (id) ON DELETE CASCADE,
  member_index smallint NOT NULL CHECK (member_index >= 0),
  member_key_id uuid NOT NULL,
  status text NOT NULL CHECK (status IN ('safe', 'not_safe', 'check_label')),
  reason_codes text[] NOT NULL CHECK (
    array_position(reason_codes, NULL) IS NULL
    AND array_to_string(reason_codes, ',') ~ '^([a-z_]{1,64}(,|$))*$'
  ),
  details_enc bytea CHECK (details_enc IS NULL OR octet_length(details_enc) BETWEEN 29 AND 1048576),
  redacted_at timestamptz,
  PRIMARY KEY (log_id, member_index),
  CONSTRAINT safety_log_member_once UNIQUE (log_id, member_key_id),
  CONSTRAINT safety_log_member_redaction_check CHECK ((details_enc IS NULL) = (redacted_at IS NOT NULL))
);

CREATE INDEX safety_log_member_key_idx ON safety_log_member (member_key_id);

CREATE FUNCTION safety_log_guard() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF ROW(NEW.id, NEW.log_format, NEW.subject_kind, NEW.subject_id, NEW.subject_version,
         NEW.evaluated_at, NEW.rule_set_version, NEW.reference_version, NEW.ingredient_ids,
         NEW.recorded_brands, NEW.created_at)
       IS DISTINCT FROM
     ROW(OLD.id, OLD.log_format, OLD.subject_kind, OLD.subject_id, OLD.subject_version,
         OLD.evaluated_at, OLD.rule_set_version, OLD.reference_version, OLD.ingredient_ids,
         OLD.recorded_brands, OLD.created_at)
     OR (NEW.household_id IS NOT NULL AND NEW.household_id IS DISTINCT FROM OLD.household_id)
  THEN
    RAISE EXCEPTION 'safety logs are append-only (SAF-14)' USING ERRCODE = 'KM003';
  END IF;
  RETURN NEW;
END
$$;

CREATE TRIGGER safety_log_guard
  BEFORE UPDATE ON safety_log
  FOR EACH ROW EXECUTE FUNCTION safety_log_guard();

CREATE FUNCTION safety_log_member_guard() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF ROW(NEW.log_id, NEW.member_index, NEW.member_key_id, NEW.status, NEW.reason_codes)
       IS DISTINCT FROM ROW(OLD.log_id, OLD.member_index, OLD.member_key_id, OLD.status, OLD.reason_codes)
     OR (NEW.details_enc IS NOT NULL AND NEW.details_enc IS DISTINCT FROM OLD.details_enc)
     OR (OLD.redacted_at IS NOT NULL AND NEW.redacted_at IS DISTINCT FROM OLD.redacted_at)
  THEN
    RAISE EXCEPTION 'safety log members can only be redacted (SAF-14)' USING ERRCODE = 'KM003';
  END IF;
  RETURN NEW;
END
$$;

CREATE TRIGGER safety_log_member_guard
  BEFORE UPDATE ON safety_log_member
  FOR EACH ROW EXECUTE FUNCTION safety_log_member_guard();
`,
};
