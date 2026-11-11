import type { Migration } from "./types.js";

/**
 * Security re-check T-016 N1: ciphertext lengths must not reveal what was
 * encrypted. The data layer pads before encrypting (`crypto/data-key-cipher.ts`);
 * the database holds it to that:
 *
 * - every `hard_rule.details_enc` is exactly 4125 bytes: 29 bytes of format,
 *   IV and tag around the fixed 4096-byte padded body
 *   (`HARD_RULE_PADDED_BYTES`), whatever the rule type or allergen;
 * - every `safety_log_member.details_enc` is 29 bytes plus a power-of-two
 *   bucket from 1 KiB to 512 KiB, and all members of one log that carry
 *   details use the same bucket, whatever their status or number of reasons.
 *
 * Accepted residuals, recorded for the product lead: the number of hard-rule
 * rows per member, and whether a member has a data key or a log row has
 * details, stay visible.
 */
export const migration0006: Migration = {
  version: 6,
  name: "ciphertext-padding",
  sql: String.raw`
ALTER TABLE hard_rule
  ADD CONSTRAINT hard_rule_details_fixed_length CHECK (octet_length(details_enc) = 4125);

ALTER TABLE safety_log_member
  ADD CONSTRAINT safety_log_member_details_bucket CHECK (
    details_enc IS NULL
    OR octet_length(details_enc) - 29 IN (1024, 2048, 4096, 8192, 16384, 32768, 65536, 131072, 262144, 524288)
  );

CREATE OR REPLACE FUNCTION safety_log_member_requires_consent() RETURNS trigger
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
  -- N1: every member of one log with details has the same ciphertext length.
  IF EXISTS (
    SELECT 1 FROM safety_log_member m
     WHERE m.log_id = NEW.log_id
       AND m.details_enc IS NOT NULL
       AND octet_length(m.details_enc) <> octet_length(NEW.details_enc)
  ) THEN
    RAISE EXCEPTION 'safety log details in one log must share one padded length'
      USING ERRCODE = 'KM004';
  END IF;
  RETURN NEW;
END
$$;
`,
};
