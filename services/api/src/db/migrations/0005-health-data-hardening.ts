import type { Migration } from "./types.js";

/**
 * Security review T-016 (2026-11-11) fixes in the database.
 *
 * H3: the safety log keeps no rule-revealing data in plain columns. The
 * per-member status, reason codes, ingredient IDs and recorded brands move
 * into the member's encrypted details. A plain row now says only that a
 * member was among the people eating for a subject at a time; who is eating is
 * not health data.
 *
 * H4: health-data writes are serialized per member on a row lock of the
 * profile (`FOR NO KEY UPDATE`, which excludes other health-data writers but
 * not unrelated inserts that only reference the profile). The triggers take
 * the lock as well, so writes that bypass the data layer are covered:
 * - a member data key can be created only under an active health consent;
 * - a safety log member row can carry details only under the member's live
 *   key and an active health consent;
 * - a consent decision waits for any in-flight rule write of that member, and
 *   the in-flight write's key and rules are then deleted with the rest.
 *
 * M3 (technical part): redaction also replaces the pseudonymous member ID with
 * a fresh random one per row, so redacted rows no longer link to each other.
 *
 * L4: account and profile references in consent records and kitchen items stay
 * inside one household (composite keys; only the member column is cleared on
 * deletion). L5: every trigger function pins its search_path. L6: consent
 * records cannot be deleted. L7: version columns follow a version pattern.
 */
export const migration0005: Migration = {
  version: 5,
  name: "health-data-hardening",
  sql: String.raw`
CREATE FUNCTION health_consent_active(member uuid) RETURNS boolean
LANGUAGE sql STABLE SET search_path FROM CURRENT AS $$
  SELECT COALESCE((
    SELECT c.decision = 'given' AND c.withdrawn_at IS NULL
      FROM consent_record c
     WHERE c.profile_id = member AND c.purpose = 'health_data'
     ORDER BY c.seq DESC
     LIMIT 1
  ), false)
$$;

CREATE FUNCTION lock_member_for_health_data(member uuid) RETURNS void
LANGUAGE plpgsql SET search_path FROM CURRENT AS $$
BEGIN
  PERFORM 1 FROM profile WHERE id = member FOR NO KEY UPDATE;
END
$$;

-- H4: rule writes lock the member before the consent check.
CREATE OR REPLACE FUNCTION hard_rule_requires_consent() RETURNS trigger
LANGUAGE plpgsql SET search_path FROM CURRENT AS $$
DECLARE
  latest record;
BEGIN
  PERFORM lock_member_for_health_data(NEW.profile_id);
  SELECT c.id, c.decision, c.withdrawn_at INTO latest
    FROM consent_record c
   WHERE c.profile_id = NEW.profile_id AND c.purpose = 'health_data'
   ORDER BY c.seq DESC
   LIMIT 1;
  IF NOT FOUND
     OR latest.id <> NEW.consent_record_id
     OR latest.decision <> 'given'
     OR latest.withdrawn_at IS NOT NULL
  THEN
    RAISE EXCEPTION 'an active health-data consent is required' USING ERRCODE = 'KM001';
  END IF;
  IF EXISTS (SELECT 1 FROM profile p WHERE p.id = NEW.profile_id AND p.is_child)
     AND NOT EXISTS (
       SELECT 1 FROM consent_record g
        WHERE g.profile_id = NEW.profile_id
          AND g.purpose = 'guardian_confirmation'
          AND g.decision = 'given'
     )
  THEN
    RAISE EXCEPTION 'guardian confirmation required for a child profile' USING ERRCODE = 'KM002';
  END IF;
  RETURN NEW;
END
$$;

-- H4: a data key exists only under an active health consent.
CREATE FUNCTION health_data_key_requires_consent() RETURNS trigger
LANGUAGE plpgsql SET search_path FROM CURRENT AS $$
BEGIN
  PERFORM lock_member_for_health_data(NEW.profile_id);
  IF NOT health_consent_active(NEW.profile_id) THEN
    RAISE EXCEPTION 'an active health-data consent is required' USING ERRCODE = 'KM001';
  END IF;
  RETURN NEW;
END
$$;

CREATE TRIGGER health_data_key_requires_consent
  BEFORE INSERT ON health_data_key
  FOR EACH ROW EXECUTE FUNCTION health_data_key_requires_consent();

-- H4: a consent decision waits for in-flight health-data writes of the member.
CREATE FUNCTION consent_record_lock_member() RETURNS trigger
LANGUAGE plpgsql SET search_path FROM CURRENT AS $$
BEGIN
  IF NEW.purpose = 'health_data' AND NEW.profile_id IS NOT NULL THEN
    PERFORM lock_member_for_health_data(NEW.profile_id);
  END IF;
  RETURN NEW;
END
$$;

CREATE TRIGGER consent_record_lock_member
  BEFORE INSERT OR UPDATE OF withdrawn_at ON consent_record
  FOR EACH ROW EXECUTE FUNCTION consent_record_lock_member();

-- L6: consent records are never deleted.
CREATE FUNCTION consent_record_no_delete() RETURNS trigger
LANGUAGE plpgsql SET search_path FROM CURRENT AS $$
BEGIN
  RAISE EXCEPTION 'consent records cannot be deleted' USING ERRCODE = 'KM003';
END
$$;

CREATE TRIGGER consent_record_no_delete
  BEFORE DELETE ON consent_record
  FOR EACH ROW EXECUTE FUNCTION consent_record_no_delete();

-- H3: no rule-revealing plain columns in the safety log.
CREATE OR REPLACE FUNCTION safety_log_guard() RETURNS trigger
LANGUAGE plpgsql SET search_path FROM CURRENT AS $$
BEGIN
  IF ROW(NEW.id, NEW.log_format, NEW.subject_kind, NEW.subject_id, NEW.subject_version,
         NEW.evaluated_at, NEW.rule_set_version, NEW.reference_version, NEW.created_at)
       IS DISTINCT FROM
     ROW(OLD.id, OLD.log_format, OLD.subject_kind, OLD.subject_id, OLD.subject_version,
         OLD.evaluated_at, OLD.rule_set_version, OLD.reference_version, OLD.created_at)
     OR (NEW.household_id IS NOT NULL AND NEW.household_id IS DISTINCT FROM OLD.household_id)
  THEN
    RAISE EXCEPTION 'safety logs are append-only (SAF-14)' USING ERRCODE = 'KM003';
  END IF;
  RETURN NEW;
END
$$;

ALTER TABLE safety_log
  DROP COLUMN ingredient_ids,
  DROP COLUMN recorded_brands,
  ADD CONSTRAINT safety_log_rule_set_version_pattern
    CHECK (rule_set_version ~ '^[A-Za-z0-9][A-Za-z0-9._+/-]{0,99}$'),
  ADD CONSTRAINT safety_log_reference_version_pattern
    CHECK (reference_version ~ '^[A-Za-z0-9][A-Za-z0-9._+/-]{0,99}$'),
  ADD CONSTRAINT safety_log_subject_version_pattern
    CHECK (subject_version IS NULL OR subject_version ~ '^[A-Za-z0-9][A-Za-z0-9._+/-]{0,99}$');

-- Redaction clears the details once and replaces the pseudonym (M3).
CREATE OR REPLACE FUNCTION safety_log_member_guard() RETURNS trigger
LANGUAGE plpgsql SET search_path FROM CURRENT AS $$
BEGIN
  IF ROW(NEW.log_id, NEW.member_index) IS DISTINCT FROM ROW(OLD.log_id, OLD.member_index)
     OR OLD.redacted_at IS NOT NULL
     OR NEW.details_enc IS NOT NULL
  THEN
    RAISE EXCEPTION 'safety log members can only be redacted, once (SAF-14)' USING ERRCODE = 'KM003';
  END IF;
  RETURN NEW;
END
$$;

ALTER TABLE safety_log_member
  DROP COLUMN status,
  DROP COLUMN reason_codes;

-- H4: details only under the member's live key and an active consent.
CREATE FUNCTION safety_log_member_requires_consent() RETURNS trigger
LANGUAGE plpgsql SET search_path FROM CURRENT AS $$
DECLARE
  member uuid;
BEGIN
  IF NEW.details_enc IS NULL THEN
    RETURN NEW;
  END IF;
  SELECT k.profile_id INTO member FROM health_data_key k WHERE k.id = NEW.member_key_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'safety log details need the member''s data key' USING ERRCODE = 'KM001';
  END IF;
  PERFORM lock_member_for_health_data(member);
  IF NOT EXISTS (SELECT 1 FROM health_data_key k WHERE k.id = NEW.member_key_id)
     OR NOT health_consent_active(member)
  THEN
    RAISE EXCEPTION 'an active health-data consent is required' USING ERRCODE = 'KM001';
  END IF;
  RETURN NEW;
END
$$;

CREATE TRIGGER safety_log_member_requires_consent
  BEFORE INSERT ON safety_log_member
  FOR EACH ROW EXECUTE FUNCTION safety_log_member_requires_consent();

CREATE OR REPLACE FUNCTION health_data_key_redacts_safety_log() RETURNS trigger
LANGUAGE plpgsql SET search_path FROM CURRENT AS $$
BEGIN
  UPDATE safety_log_member
     SET details_enc = NULL, redacted_at = now(), member_key_id = gen_random_uuid()
   WHERE member_key_id = OLD.id AND redacted_at IS NULL;
  RETURN NULL;
END
$$;

-- L4: references stay inside the household. The single-column foreign keys
-- keep clearing the reference on deletion; these composite keys only check
-- (NO ACTION, after the cascades) that a reference points into the same
-- household.
ALTER TABLE consent_record
  ADD CONSTRAINT consent_record_profile_household_fkey FOREIGN KEY (profile_id, household_id)
    REFERENCES profile (id, household_id),
  ADD CONSTRAINT consent_record_account_household_fkey FOREIGN KEY (recorded_by_account_id, household_id)
    REFERENCES account (id, household_id);

ALTER TABLE kitchen_item
  ADD CONSTRAINT kitchen_item_changed_by_household_fkey FOREIGN KEY (changed_by_account_id, household_id)
    REFERENCES account (id, household_id);

-- L5: pin search_path on the functions from earlier migrations.
ALTER FUNCTION consent_record_guard() SET search_path FROM CURRENT;
ALTER FUNCTION profile_requires_guardian_confirmation() SET search_path FROM CURRENT;
ALTER FUNCTION reference_dataset_guard() SET search_path FROM CURRENT;
ALTER FUNCTION consent_revokes_health_data() SET search_path FROM CURRENT;
`,
};
