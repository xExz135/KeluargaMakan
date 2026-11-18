import type { Migration } from "./types.js";

/**
 * Security review T-041 fixes (migration 0012 is left unchanged; this one
 * adds to it).
 *
 * - M2 (LIB-01, NFR-23, QUESTIONS #94): a published version needs the staff
 *   member who recorded the cook's test, the author and the approver, and
 *   the approver is never the one who recorded the test or wrote the
 *   version. A tester label alone no longer passes the gate. There is no
 *   staff table yet (QUESTIONS #80), so these are not foreign keys; they
 *   become foreign keys when staff accounts exist.
 * - L5 (LIB-11, DAT-05, DAT-06, SAF-14): TRUNCATE is refused on the library
 *   tables and on both safety logs, which the row-level no-delete triggers
 *   do not cover.
 * - L1 (SAF-02, SAF-12, PRF-11, SET-04): `health_rules_stamp` summarizes a
 *   member's consent state and current hard rules (IDs, last change, key).
 *   The API reads it before a check and compares it under the member lock
 *   when it logs the check; any difference means the check used rules or
 *   consent that are no longer current, and nothing is served.
 */
export const migration0013: Migration = {
  version: 13,
  name: "library-staff-truncate-rules-stamp",
  sql: String.raw`
ALTER TABLE library_recipe_version
  ALTER COLUMN test_recorded_by_staff_id SET NOT NULL,
  ALTER COLUMN author_staff_id SET NOT NULL,
  ALTER COLUMN approved_by_staff_id SET NOT NULL,
  ADD CONSTRAINT library_recipe_version_tester_not_approver
    CHECK (approved_by_staff_id <> test_recorded_by_staff_id);

CREATE FUNCTION km_refuse_truncate() RETURNS trigger
LANGUAGE plpgsql SET search_path FROM CURRENT AS $$
BEGIN
  RAISE EXCEPTION 'TRUNCATE is refused on %: library content and safety logs are kept (LIB-11, DAT-05)',
    TG_TABLE_NAME USING ERRCODE = 'KM003';
END
$$;

CREATE TRIGGER library_region_no_truncate BEFORE TRUNCATE ON library_region
  FOR EACH STATEMENT EXECUTE FUNCTION km_refuse_truncate();
CREATE TRIGGER library_image_no_truncate BEFORE TRUNCATE ON library_image
  FOR EACH STATEMENT EXECUTE FUNCTION km_refuse_truncate();
CREATE TRIGGER library_recipe_no_truncate BEFORE TRUNCATE ON library_recipe
  FOR EACH STATEMENT EXECUTE FUNCTION km_refuse_truncate();
CREATE TRIGGER library_recipe_version_no_truncate BEFORE TRUNCATE ON library_recipe_version
  FOR EACH STATEMENT EXECUTE FUNCTION km_refuse_truncate();
CREATE TRIGGER library_recipe_line_no_truncate BEFORE TRUNCATE ON library_recipe_line
  FOR EACH STATEMENT EXECUTE FUNCTION km_refuse_truncate();
CREATE TRIGGER library_recipe_step_no_truncate BEFORE TRUNCATE ON library_recipe_step
  FOR EACH STATEMENT EXECUTE FUNCTION km_refuse_truncate();
CREATE TRIGGER library_recipe_version_image_no_truncate BEFORE TRUNCATE ON library_recipe_version_image
  FOR EACH STATEMENT EXECUTE FUNCTION km_refuse_truncate();
CREATE TRIGGER library_recipe_variant_no_truncate BEFORE TRUNCATE ON library_recipe_variant
  FOR EACH STATEMENT EXECUTE FUNCTION km_refuse_truncate();
CREATE TRIGGER library_release_no_truncate BEFORE TRUNCATE ON library_release
  FOR EACH STATEMENT EXECUTE FUNCTION km_refuse_truncate();
CREATE TRIGGER recipe_halal_log_no_truncate BEFORE TRUNCATE ON recipe_halal_log
  FOR EACH STATEMENT EXECUTE FUNCTION km_refuse_truncate();
CREATE TRIGGER safety_log_no_truncate BEFORE TRUNCATE ON safety_log
  FOR EACH STATEMENT EXECUTE FUNCTION km_refuse_truncate();
CREATE TRIGGER safety_log_member_no_truncate BEFORE TRUNCATE ON safety_log_member
  FOR EACH STATEMENT EXECUTE FUNCTION km_refuse_truncate();

-- An opaque summary of a member's consent and hard rules; it holds no rule
-- content. Independent of the session time zone.
CREATE FUNCTION health_rules_stamp(member uuid) RETURNS text
LANGUAGE sql STABLE SET search_path FROM CURRENT AS $$
  SELECT md5(
    health_consent_active(member)::text
    || '|' || COALESCE((
      SELECT max(c.seq)::text FROM consent_record c
       WHERE c.profile_id = member AND c.purpose = 'health_data'
    ), '-')
    || '|' || COALESCE((
      SELECT string_agg(
               h.id::text || '@' || extract(epoch FROM h.updated_at)::text || '@' || h.health_key_id::text,
               ',' ORDER BY h.id)
        FROM hard_rule h WHERE h.profile_id = member
    ), '')
  )
$$;
`,
};
