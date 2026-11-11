import type { Migration } from "./types.js";

/**
 * Health data: SRS 18.1 Hard rule, stored under DAT-02 separate-key encryption.
 *
 * Key hierarchy (see `crypto/`):
 *   health-data key-encryption key (Cloud KMS `KMS_HEALTH_DATA_KEY`, or the local
 *   provider in development and tests; never the general-data key)
 *     -> one random data key per member, stored wrapped in `health_data_key`
 *       -> AES-256-GCM over each hard rule (`hard_rule.details_enc`) and over the
 *          member's safety log details (`safety_log_member.details_enc`)
 *
 * Every hard-rule field (type, allergen, free text, mapping, confirmer) is in
 * the ciphertext; the plain columns are IDs and timestamps only.
 *
 * Consent (ACC-08, SET-03, SET-10, QUESTIONS #13), enforced in the database as
 * well as in the data layer:
 * - A hard rule can be written only under the member's latest health-data
 *   consent record, and only while that record is given and not withdrawn.
 * - A child profile also needs a recorded guardian confirmation.
 * - Declining or withdrawing consent deletes the member's data key at once,
 *   which cascades to every hard rule in the live database (SET-04). Backups
 *   and point-in-time-recovery copies taken earlier still hold the wrapped key
 *   and the ciphertext, which the health-data key can read; they are purged on
 *   their normal cycle, which T-023 keeps within the 30-day target.
 *
 * Deletion and redaction (SET-04, SET-07, SET-08, QUESTIONS #40): whenever a
 * member's data key is deleted (consent declined or withdrawn, profile deleted,
 * household deleted), that member's safety log details are cleared. The
 * pseudonymous member ID left in the log then points at nothing (migration
 * 0005 also replaces it with a random ID). Migration 0005 tightens all of
 * this after the T-016 security review.
 */
export const migration0004: Migration = {
  version: 4,
  name: "health-data",
  sql: String.raw`
CREATE TABLE health_data_key (
  id uuid PRIMARY KEY,
  household_id uuid NOT NULL,
  profile_id uuid NOT NULL,
  key_ref text NOT NULL CHECK (char_length(key_ref) BETWEEN 1 AND 512),
  wrapped_key bytea NOT NULL CHECK (octet_length(wrapped_key) BETWEEN 16 AND 4096),
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT health_data_key_profile_key UNIQUE (profile_id),
  CONSTRAINT health_data_key_id_profile_key UNIQUE (id, profile_id),
  CONSTRAINT health_data_key_profile_fkey FOREIGN KEY (profile_id, household_id)
    REFERENCES profile (id, household_id) ON DELETE CASCADE
);

CREATE TABLE hard_rule (
  id uuid PRIMARY KEY,
  household_id uuid NOT NULL,
  profile_id uuid NOT NULL,
  health_key_id uuid NOT NULL,
  consent_record_id uuid NOT NULL REFERENCES consent_record (id),
  details_enc bytea NOT NULL CHECK (octet_length(details_enc) BETWEEN 29 AND 16384),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT hard_rule_profile_fkey FOREIGN KEY (profile_id, household_id)
    REFERENCES profile (id, household_id) ON DELETE CASCADE,
  CONSTRAINT hard_rule_health_key_fkey FOREIGN KEY (health_key_id, profile_id)
    REFERENCES health_data_key (id, profile_id) ON DELETE CASCADE
);

CREATE INDEX hard_rule_profile_idx ON hard_rule (profile_id);

CREATE FUNCTION hard_rule_requires_consent() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
  latest record;
BEGIN
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

CREATE TRIGGER hard_rule_requires_consent
  BEFORE INSERT OR UPDATE ON hard_rule
  FOR EACH ROW EXECUTE FUNCTION hard_rule_requires_consent();

CREATE FUNCTION consent_revokes_health_data() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.purpose = 'health_data'
     AND NEW.profile_id IS NOT NULL
     AND (NEW.decision = 'declined' OR NEW.withdrawn_at IS NOT NULL)
  THEN
    DELETE FROM health_data_key WHERE profile_id = NEW.profile_id;
  END IF;
  RETURN NULL;
END
$$;

CREATE TRIGGER consent_revokes_health_data
  AFTER INSERT OR UPDATE OF withdrawn_at ON consent_record
  FOR EACH ROW EXECUTE FUNCTION consent_revokes_health_data();

CREATE FUNCTION health_data_key_redacts_safety_log() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  UPDATE safety_log_member
     SET details_enc = NULL, redacted_at = now()
   WHERE member_key_id = OLD.id AND details_enc IS NOT NULL;
  RETURN NULL;
END
$$;

CREATE TRIGGER health_data_key_redacts_safety_log
  AFTER DELETE ON health_data_key
  FOR EACH ROW EXECUTE FUNCTION health_data_key_redacts_safety_log();
`,
};
