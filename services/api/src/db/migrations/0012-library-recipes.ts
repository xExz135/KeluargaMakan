import { REFERENCE_VERSION_PATTERN } from "../ids.js";
import type { Migration } from "./types.js";

/**
 * Library recipes (T-041; SRS 18.1 Library recipe: LIB-03 fields, tester,
 * test date, version) and the recipe halal log (SAF-14, LIB-05, T-025 N2 to
 * N4).
 *
 * Library recipe:
 * - `library_recipe` is the dish: its stable ID, the base dish of a regional
 *   variant (LIB-04, one level only), the current published version and
 *   retirement (LIB-11). Rows are never deleted.
 * - `library_recipe_version` is one published version with every LIB-03
 *   field, the cook's test record (LIB-01, NFR-23, QUESTIONS #79: `tested_by`
 *   is a display label, never a full name or contact detail) and nutrition
 *   per serving in the contract shape (V1 stores and serves "unavailable",
 *   QUESTIONS #15). A version row exists only when published, so it cannot
 *   exist without a tester and a test date (NOT NULL). There is no halal
 *   column anywhere: the halal status is always derived by Cek Aman from the
 *   ingredient lines (LIB-05). There is no "tested" flag, no safety field and
 *   no AI field. Drafts are not stored here (staff admin, QUESTIONS #80).
 * - Lines, steps, picture links and content-team portion variants belong to
 *   one version and are written in the same transaction as it. A published
 *   version and its parts never change and are never deleted; a change is a
 *   new version (LIB-11, DAT-06: a logged recipe version stays traceable).
 * - Portion variants (SAF-11) follow the T-040 M2 rule, checked at commit:
 *   the separation step is a step of the version, every left-out line is
 *   used by at least one step, and no step before the separation uses it.
 * - `library_servable_version` (LIB-01 gate): the current version of every
 *   published, not retired recipe that has a tester and a test date.
 *   Household code reads library content only through this view.
 * - `library_release` counts every published or retired recipe, region
 *   change and withdrawn picture, so phones see a new `libraryVersion`.
 *
 * Recipe halal log (`keluargamakan.recipe-halal-log/1`, QUESTIONS #88): one
 * row per served halal status, keyed by the API's `checkId`, which is also
 * the ID of the check's `safety_log` row (N2). The database checks that both
 * name the same household, subject, time and versions (one reference
 * snapshot, QUESTIONS #88). It holds IDs, codes and versions only (no names
 * or free text); the brand IDs are the household's own records. It goes
 * with its safety log: deleted after the DAT-05 retention period, and
 * unlinked from the household when the household is deleted.
 *
 * Also: the verified reference version is `<data version>@sha256:<hash>`
 * (packages/reference-data), so the safety log's reference version pattern
 * now allows `@` and `:` and up to 200 characters. It still refuses spaces,
 * so a name can never be stored as a version.
 */
export const migration0012: Migration = {
  version: 12,
  name: "library-recipes",
  sql: String.raw`
ALTER TABLE safety_log
  DROP CONSTRAINT safety_log_reference_version_check,
  DROP CONSTRAINT safety_log_reference_version_pattern,
  ADD CONSTRAINT safety_log_reference_version_pattern
    CHECK (reference_version ~ '${REFERENCE_VERSION_PATTERN}');

-- Text in both languages (contract LocalizedText), each 1 to max_length characters.
CREATE FUNCTION library_text_ok(value jsonb, max_length integer) RETURNS boolean
LANGUAGE sql IMMUTABLE AS $$
  SELECT CASE
    WHEN value IS NULL OR jsonb_typeof(value) <> 'object' THEN false
    ELSE (SELECT count(*) FROM jsonb_object_keys(value)) = 2
      AND jsonb_typeof(value -> 'id') = 'string'
      AND jsonb_typeof(value -> 'en') = 'string'
      AND char_length(btrim(value ->> 'id')) BETWEEN 1 AND max_length
      AND char_length(btrim(value ->> 'en')) BETWEEN 1 AND max_length
  END
$$;

-- NUT-05: nutrition per serving is "unavailable" with no ranges, or estimate
-- ranges where high is always above low (never one number).
CREATE FUNCTION library_nutrition_ok(value jsonb) RETURNS boolean
LANGUAGE sql IMMUTABLE AS $$
  SELECT CASE
    WHEN value IS NULL OR jsonb_typeof(value) <> 'object' THEN false
    WHEN (SELECT count(*) FROM jsonb_object_keys(value)) <> 2 THEN false
    WHEN jsonb_typeof(value -> 'ranges') <> 'array' THEN false
    WHEN value ->> 'status' = 'unavailable' THEN jsonb_array_length(value -> 'ranges') = 0
    WHEN value ->> 'status' = 'estimate' THEN
      jsonb_array_length(value -> 'ranges') > 0
      AND NOT EXISTS (
        SELECT 1 FROM jsonb_array_elements(value -> 'ranges') AS r(item)
         WHERE jsonb_typeof(r.item) <> 'object'
            OR jsonb_typeof(r.item -> 'low') <> 'number'
            OR jsonb_typeof(r.item -> 'high') <> 'number'
            OR (r.item ->> 'low')::numeric < 0
            OR (r.item ->> 'high')::numeric <= (r.item ->> 'low')::numeric
            OR NOT (r.item ->> 'nutrient') = ANY (ARRAY['energy', 'protein', 'carbohydrate', 'fat',
                 'saturated_fat', 'fiber', 'sugar', 'sodium'])
            OR NOT (r.item ->> 'unit') = ANY (ARRAY['kcal', 'g', 'mg'])
      )
    ELSE false
  END
$$;

CREATE TABLE library_release (
  singleton boolean PRIMARY KEY DEFAULT true CHECK (singleton),
  release bigint NOT NULL DEFAULT 1 CHECK (release >= 1),
  changed_at timestamptz NOT NULL DEFAULT now()
);
INSERT INTO library_release DEFAULT VALUES;

CREATE FUNCTION library_release_bump() RETURNS trigger
LANGUAGE plpgsql SET search_path FROM CURRENT AS $$
BEGIN
  UPDATE library_release SET release = release + 1, changed_at = now() WHERE singleton;
  RETURN NULL;
END
$$;

CREATE FUNCTION library_no_delete() RETURNS trigger
LANGUAGE plpgsql SET search_path FROM CURRENT AS $$
BEGIN
  RAISE EXCEPTION 'library content is never deleted; retire or withdraw it (LIB-11)'
    USING ERRCODE = 'KM003';
END
$$;

CREATE FUNCTION library_immutable() RETURNS trigger
LANGUAGE plpgsql SET search_path FROM CURRENT AS $$
BEGIN
  RAISE EXCEPTION 'published library content never changes; publish a new version (LIB-11, DAT-06)'
    USING ERRCODE = 'KM003';
END
$$;

CREATE TABLE library_region (
  region_id text PRIMARY KEY CHECK (region_id ~ '^[a-z0-9][a-z0-9_.-]{0,99}$'),
  display_name jsonb NOT NULL CHECK (library_text_ok(display_name, 80)),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TRIGGER library_region_release
  AFTER INSERT OR UPDATE ON library_region
  FOR EACH STATEMENT EXECUTE FUNCTION library_release_bump();
CREATE TRIGGER library_region_no_delete
  BEFORE DELETE ON library_region
  FOR EACH ROW EXECUTE FUNCTION library_no_delete();

-- Content-team food files only, never of people. The bytes of an ID never
-- change; a row can only be withdrawn, once.
CREATE TABLE library_image (
  image_id text PRIMARY KEY CHECK (image_id ~ '^[a-z0-9][a-z0-9_.-]{0,99}$'),
  media_type text NOT NULL CHECK (media_type IN ('image/webp', 'image/jpeg')),
  bytes bytea NOT NULL CHECK (octet_length(bytes) BETWEEN 1 AND 5242880),
  sha256 text NOT NULL CHECK (sha256 ~ '^[0-9a-f]{64}$'),
  width integer NOT NULL CHECK (width BETWEEN 1 AND 10000),
  height integer NOT NULL CHECK (height BETWEEN 1 AND 10000),
  alt jsonb NOT NULL CHECK (library_text_ok(alt, 300)),
  created_at timestamptz NOT NULL DEFAULT now(),
  withdrawn_at timestamptz
);

CREATE FUNCTION library_image_guard() RETURNS trigger
LANGUAGE plpgsql SET search_path FROM CURRENT AS $$
BEGIN
  IF ROW(NEW.image_id, NEW.media_type, NEW.bytes, NEW.sha256, NEW.width, NEW.height, NEW.alt,
         NEW.created_at)
       IS DISTINCT FROM
     ROW(OLD.image_id, OLD.media_type, OLD.bytes, OLD.sha256, OLD.width, OLD.height, OLD.alt,
         OLD.created_at)
     OR OLD.withdrawn_at IS NOT NULL
     OR NEW.withdrawn_at IS NULL
  THEN
    RAISE EXCEPTION 'library_image rows never change; they can only be withdrawn, once'
      USING ERRCODE = 'KM003';
  END IF;
  RETURN NEW;
END
$$;

CREATE TRIGGER library_image_guard
  BEFORE UPDATE ON library_image
  FOR EACH ROW EXECUTE FUNCTION library_image_guard();
CREATE TRIGGER library_image_release
  AFTER UPDATE ON library_image
  FOR EACH STATEMENT EXECUTE FUNCTION library_release_bump();
CREATE TRIGGER library_image_no_delete
  BEFORE DELETE ON library_image
  FOR EACH ROW EXECUTE FUNCTION library_no_delete();

CREATE TABLE library_recipe (
  recipe_id text PRIMARY KEY CHECK (recipe_id ~ '^[a-z0-9][a-z0-9_.-]{0,99}$'),
  base_recipe_id text REFERENCES library_recipe (recipe_id),
  status text NOT NULL DEFAULT 'published' CHECK (status IN ('published', 'retired')),
  current_version integer NOT NULL CHECK (current_version >= 1),
  retired_at timestamptz,
  retired_by_staff_id uuid,
  retire_note text CHECK (retire_note IS NULL OR char_length(retire_note) <= 500),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT library_recipe_not_own_base CHECK (base_recipe_id IS DISTINCT FROM recipe_id),
  CONSTRAINT library_recipe_retired_check CHECK (
    (status = 'retired') = (retired_at IS NOT NULL)
    AND (status = 'retired' OR (retired_by_staff_id IS NULL AND retire_note IS NULL))
  )
);

CREATE TABLE library_recipe_version (
  recipe_id text NOT NULL REFERENCES library_recipe (recipe_id) DEFERRABLE INITIALLY DEFERRED,
  version integer NOT NULL CHECK (version >= 1),
  name jsonb NOT NULL CHECK (library_text_ok(name, 120)),
  description jsonb NOT NULL CHECK (library_text_ok(description, 1000)),
  cuisine text NOT NULL CHECK (cuisine IN ('indonesian', 'japanese', 'chinese', 'fusion')),
  region_id text REFERENCES library_region (region_id),
  meal_types text[] NOT NULL CHECK (
    cardinality(meal_types) BETWEEN 1 AND 6
    AND meal_types <@ ARRAY['breakfast', 'lunch', 'dinner', 'snack', 'sahur', 'buka']::text[]
    AND array_position(meal_types, NULL) IS NULL
  ),
  base_servings integer NOT NULL CHECK (base_servings BETWEEN 1 AND 50),
  prep_minutes integer NOT NULL CHECK (prep_minutes BETWEEN 0 AND 1440),
  cook_minutes integer NOT NULL CHECK (cook_minutes BETWEEN 0 AND 1440),
  difficulty text NOT NULL CHECK (difficulty IN ('easy', 'medium', 'hard')),
  tag_fried boolean NOT NULL,
  tag_santan boolean NOT NULL,
  tag_spice_level text NOT NULL CHECK (tag_spice_level IN ('not_spicy', 'medium', 'spicy')),
  nutrition_per_serving jsonb NOT NULL DEFAULT '{"status": "unavailable", "ranges": []}'
    CHECK (library_nutrition_ok(nutrition_per_serving)),
  tested_by text NOT NULL CHECK (char_length(btrim(tested_by)) BETWEEN 1 AND 80),
  tested_on date NOT NULL,
  test_notes text CHECK (test_notes IS NULL OR char_length(test_notes) <= 1000),
  test_recorded_by_staff_id uuid,
  author_staff_id uuid,
  approved_by_staff_id uuid,
  published_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (recipe_id, version),
  CONSTRAINT library_recipe_version_tested_before_publication CHECK (
    tested_on <= (published_at AT TIME ZONE 'Pacific/Kiritimati')::date
  ),
  CONSTRAINT library_recipe_version_second_person CHECK (
    approved_by_staff_id IS NULL OR approved_by_staff_id IS DISTINCT FROM author_staff_id
  )
);

ALTER TABLE library_recipe
  ADD CONSTRAINT library_recipe_current_version_fkey FOREIGN KEY (recipe_id, current_version)
    REFERENCES library_recipe_version (recipe_id, version) DEFERRABLE INITIALLY DEFERRED;

-- LIB-04: a regional variant links to a base dish that is not itself a variant.
CREATE FUNCTION library_recipe_insert_guard() RETURNS trigger
LANGUAGE plpgsql SET search_path FROM CURRENT AS $$
BEGIN
  IF NEW.status <> 'published' OR NEW.retired_at IS NOT NULL THEN
    RAISE EXCEPTION 'a library recipe starts published' USING ERRCODE = 'KM003';
  END IF;
  IF NEW.base_recipe_id IS NOT NULL AND EXISTS (
    SELECT 1 FROM library_recipe WHERE recipe_id = NEW.base_recipe_id AND base_recipe_id IS NOT NULL
  ) THEN
    RAISE EXCEPTION 'a regional variant links to a base dish, not to another variant (LIB-04)'
      USING ERRCODE = 'KM003';
  END IF;
  RETURN NEW;
END
$$;

CREATE TRIGGER library_recipe_insert_guard
  BEFORE INSERT ON library_recipe
  FOR EACH ROW EXECUTE FUNCTION library_recipe_insert_guard();

-- LIB-11: only a newer version can become current, and retirement is final.
CREATE FUNCTION library_recipe_update_guard() RETURNS trigger
LANGUAGE plpgsql SET search_path FROM CURRENT AS $$
BEGIN
  IF ROW(NEW.recipe_id, NEW.base_recipe_id, NEW.created_at)
       IS DISTINCT FROM ROW(OLD.recipe_id, OLD.base_recipe_id, OLD.created_at)
     OR OLD.status = 'retired'
     OR NEW.current_version < OLD.current_version
     OR (NEW.status = 'retired' AND NEW.current_version <> OLD.current_version)
  THEN
    RAISE EXCEPTION 'a library recipe moves only to a newer version, or to retired, once (LIB-11)'
      USING ERRCODE = 'KM003';
  END IF;
  NEW.updated_at := now();
  RETURN NEW;
END
$$;

CREATE TRIGGER library_recipe_update_guard
  BEFORE UPDATE ON library_recipe
  FOR EACH ROW EXECUTE FUNCTION library_recipe_update_guard();
CREATE TRIGGER library_recipe_release
  AFTER INSERT OR UPDATE ON library_recipe
  FOR EACH STATEMENT EXECUTE FUNCTION library_release_bump();
CREATE TRIGGER library_recipe_no_delete
  BEFORE DELETE ON library_recipe
  FOR EACH ROW EXECUTE FUNCTION library_no_delete();

-- Versions are numbered 1, 2, 3 per recipe and stamped with the time of the
-- transaction that publishes them; their parts can only be added in it.
CREATE FUNCTION library_recipe_version_insert_guard() RETURNS trigger
LANGUAGE plpgsql SET search_path FROM CURRENT AS $$
BEGIN
  IF NEW.version <> COALESCE(
       (SELECT max(version) FROM library_recipe_version WHERE recipe_id = NEW.recipe_id), 0) + 1
  THEN
    RAISE EXCEPTION 'library recipe versions are numbered in order (LIB-11)' USING ERRCODE = 'KM003';
  END IF;
  NEW.published_at := now();
  RETURN NEW;
END
$$;

CREATE TRIGGER library_recipe_version_insert_guard
  BEFORE INSERT ON library_recipe_version
  FOR EACH ROW EXECUTE FUNCTION library_recipe_version_insert_guard();
CREATE TRIGGER library_recipe_version_immutable
  BEFORE UPDATE ON library_recipe_version
  FOR EACH ROW EXECUTE FUNCTION library_immutable();
CREATE TRIGGER library_recipe_version_no_delete
  BEFORE DELETE ON library_recipe_version
  FOR EACH ROW EXECUTE FUNCTION library_no_delete();

CREATE TABLE library_recipe_line (
  recipe_id text NOT NULL,
  version integer NOT NULL,
  line_id text NOT NULL CHECK (line_id ~ '^[a-z0-9][a-z0-9_.-]{0,99}$'),
  position smallint NOT NULL CHECK (position BETWEEN 0 AND 59),
  -- NULL: the line does not resolve to a reference ingredient; Cek Aman
  -- treats it as unknown (Check the label, SAF-09).
  ingredient_id text CHECK (ingredient_id IS NULL OR ingredient_id ~ '^[a-z0-9][a-z0-9_.-]{0,99}$'),
  raw_name text NOT NULL CHECK (char_length(btrim(raw_name)) BETWEEN 1 AND 120),
  amount double precision CHECK (amount IS NULL OR (amount > 0 AND amount < 100000)),
  unit_code text CHECK (unit_code IS NULL OR unit_code ~ '^[a-z0-9_]{1,32}$'),
  unit_label jsonb CHECK (unit_label IS NULL OR library_text_ok(unit_label, 40)),
  is_optional boolean NOT NULL,
  group_label jsonb CHECK (group_label IS NULL OR library_text_ok(group_label, 80)),
  PRIMARY KEY (recipe_id, version, line_id),
  CONSTRAINT library_recipe_line_position_key UNIQUE (recipe_id, version, position),
  FOREIGN KEY (recipe_id, version) REFERENCES library_recipe_version (recipe_id, version)
);

CREATE TABLE library_recipe_step (
  recipe_id text NOT NULL,
  version integer NOT NULL,
  step_id text NOT NULL CHECK (step_id ~ '^[a-z0-9][a-z0-9_.-]{0,99}$'),
  position smallint NOT NULL CHECK (position BETWEEN 0 AND 59),
  text jsonb NOT NULL CHECK (library_text_ok(text, 2000)),
  timer_seconds integer CHECK (timer_seconds IS NULL OR timer_seconds BETWEEN 1 AND 86400),
  ingredient_line_ids text[] NOT NULL CHECK (
    cardinality(ingredient_line_ids) <= 60 AND array_position(ingredient_line_ids, NULL) IS NULL
  ),
  PRIMARY KEY (recipe_id, version, step_id),
  CONSTRAINT library_recipe_step_position_key UNIQUE (recipe_id, version, position),
  FOREIGN KEY (recipe_id, version) REFERENCES library_recipe_version (recipe_id, version)
);

CREATE TABLE library_recipe_version_image (
  recipe_id text NOT NULL,
  version integer NOT NULL,
  position smallint NOT NULL CHECK (position BETWEEN 0 AND 9),
  image_id text NOT NULL REFERENCES library_image (image_id),
  PRIMARY KEY (recipe_id, version, position),
  CONSTRAINT library_recipe_version_image_once UNIQUE (recipe_id, version, image_id),
  FOREIGN KEY (recipe_id, version) REFERENCES library_recipe_version (recipe_id, version)
);

-- SAF-11 content-team portion variants: the portion is set aside before a
-- step, and the left-out lines never go into it.
CREATE TABLE library_recipe_variant (
  recipe_id text NOT NULL,
  version integer NOT NULL,
  variant_id text NOT NULL CHECK (variant_id ~ '^[a-z0-9][a-z0-9_.-]{0,99}$'),
  position smallint NOT NULL CHECK (position BETWEEN 0 AND 19),
  label jsonb NOT NULL CHECK (library_text_ok(label, 200)),
  separate_before_step_id text NOT NULL,
  omitted_line_ids text[] NOT NULL CHECK (
    cardinality(omitted_line_ids) BETWEEN 1 AND 60 AND array_position(omitted_line_ids, NULL) IS NULL
  ),
  PRIMARY KEY (recipe_id, version, variant_id),
  CONSTRAINT library_recipe_variant_position_key UNIQUE (recipe_id, version, position),
  FOREIGN KEY (recipe_id, version) REFERENCES library_recipe_version (recipe_id, version),
  FOREIGN KEY (recipe_id, version, separate_before_step_id)
    REFERENCES library_recipe_step (recipe_id, version, step_id)
);

CREATE FUNCTION library_recipe_part_guard() RETURNS trigger
LANGUAGE plpgsql SET search_path FROM CURRENT AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM library_recipe_version
     WHERE recipe_id = NEW.recipe_id AND version = NEW.version AND published_at = now()
  ) THEN
    RAISE EXCEPTION 'published library content never changes; publish a new version (LIB-11, DAT-06)'
      USING ERRCODE = 'KM003';
  END IF;
  RETURN NEW;
END
$$;

CREATE TRIGGER library_recipe_line_guard BEFORE INSERT ON library_recipe_line
  FOR EACH ROW EXECUTE FUNCTION library_recipe_part_guard();
CREATE TRIGGER library_recipe_step_guard BEFORE INSERT ON library_recipe_step
  FOR EACH ROW EXECUTE FUNCTION library_recipe_part_guard();
CREATE TRIGGER library_recipe_version_image_guard BEFORE INSERT ON library_recipe_version_image
  FOR EACH ROW EXECUTE FUNCTION library_recipe_part_guard();
CREATE TRIGGER library_recipe_variant_guard BEFORE INSERT ON library_recipe_variant
  FOR EACH ROW EXECUTE FUNCTION library_recipe_part_guard();

CREATE TRIGGER library_recipe_line_immutable BEFORE UPDATE ON library_recipe_line
  FOR EACH ROW EXECUTE FUNCTION library_immutable();
CREATE TRIGGER library_recipe_step_immutable BEFORE UPDATE ON library_recipe_step
  FOR EACH ROW EXECUTE FUNCTION library_immutable();
CREATE TRIGGER library_recipe_version_image_immutable BEFORE UPDATE ON library_recipe_version_image
  FOR EACH ROW EXECUTE FUNCTION library_immutable();
CREATE TRIGGER library_recipe_variant_immutable BEFORE UPDATE ON library_recipe_variant
  FOR EACH ROW EXECUTE FUNCTION library_immutable();

CREATE TRIGGER library_recipe_line_no_delete BEFORE DELETE ON library_recipe_line
  FOR EACH ROW EXECUTE FUNCTION library_no_delete();
CREATE TRIGGER library_recipe_step_no_delete BEFORE DELETE ON library_recipe_step
  FOR EACH ROW EXECUTE FUNCTION library_no_delete();
CREATE TRIGGER library_recipe_version_image_no_delete BEFORE DELETE ON library_recipe_version_image
  FOR EACH ROW EXECUTE FUNCTION library_no_delete();
CREATE TRIGGER library_recipe_variant_no_delete BEFORE DELETE ON library_recipe_variant
  FOR EACH ROW EXECUTE FUNCTION library_no_delete();

-- At commit: a version has lines and steps, its steps use only its own
-- lines, and every portion variant follows the T-040 M2 rule.
CREATE FUNCTION library_recipe_version_complete() RETURNS trigger
LANGUAGE plpgsql SET search_path FROM CURRENT AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM library_recipe_line WHERE recipe_id = NEW.recipe_id AND version = NEW.version
  ) OR NOT EXISTS (
    SELECT 1 FROM library_recipe_step WHERE recipe_id = NEW.recipe_id AND version = NEW.version
  ) THEN
    RAISE EXCEPTION 'a library recipe version needs ingredient lines and steps (LIB-03)'
      USING ERRCODE = 'KM003';
  END IF;
  IF EXISTS (
    SELECT 1
      FROM library_recipe_step s
      CROSS JOIN LATERAL unnest(s.ingredient_line_ids) AS used(line_id)
     WHERE s.recipe_id = NEW.recipe_id AND s.version = NEW.version
       AND NOT EXISTS (
         SELECT 1 FROM library_recipe_line l
          WHERE l.recipe_id = s.recipe_id AND l.version = s.version AND l.line_id = used.line_id
       )
  ) THEN
    RAISE EXCEPTION 'a step uses an ingredient line the version does not have (CKM-06)'
      USING ERRCODE = 'KM003';
  END IF;
  IF EXISTS (
    SELECT 1
      FROM library_recipe_variant v
      JOIN library_recipe_step separation
        ON separation.recipe_id = v.recipe_id AND separation.version = v.version
       AND separation.step_id = v.separate_before_step_id
      CROSS JOIN LATERAL unnest(v.omitted_line_ids) AS omitted(line_id)
     WHERE v.recipe_id = NEW.recipe_id AND v.version = NEW.version
       AND (
         NOT EXISTS (
           SELECT 1 FROM library_recipe_line l
            WHERE l.recipe_id = v.recipe_id AND l.version = v.version AND l.line_id = omitted.line_id
         )
         OR NOT EXISTS (
           SELECT 1 FROM library_recipe_step s
            WHERE s.recipe_id = v.recipe_id AND s.version = v.version
              AND omitted.line_id = ANY (s.ingredient_line_ids)
         )
         OR EXISTS (
           SELECT 1 FROM library_recipe_step s
            WHERE s.recipe_id = v.recipe_id AND s.version = v.version
              AND s.position < separation.position
              AND omitted.line_id = ANY (s.ingredient_line_ids)
         )
       )
  ) OR EXISTS (
    SELECT 1 FROM library_recipe_variant v
     WHERE v.recipe_id = NEW.recipe_id AND v.version = NEW.version
       AND cardinality(v.omitted_line_ids)
           <> (SELECT count(DISTINCT x) FROM unnest(v.omitted_line_ids) AS x)
  ) THEN
    RAISE EXCEPTION 'a portion variant leaves out a line that goes in before the portion is set aside (SAF-11, T-040 M2)'
      USING ERRCODE = 'KM003';
  END IF;
  RETURN NULL;
END
$$;

CREATE CONSTRAINT TRIGGER library_recipe_version_complete
  AFTER INSERT ON library_recipe_version
  DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW EXECUTE FUNCTION library_recipe_version_complete();

-- LIB-01: the only library rows household code reads.
CREATE VIEW library_servable_version AS
SELECT v.recipe_id, v.version, r.base_recipe_id, v.name, v.description, v.cuisine, v.region_id,
       v.meal_types, v.base_servings, v.prep_minutes, v.cook_minutes, v.difficulty, v.tag_fried,
       v.tag_santan, v.tag_spice_level, v.nutrition_per_serving, v.tested_by, v.tested_on,
       v.published_at
  FROM library_recipe r
  JOIN library_recipe_version v ON v.recipe_id = r.recipe_id AND v.version = r.current_version
 WHERE r.status = 'published'
   AND r.retired_at IS NULL
   AND v.tested_by IS NOT NULL
   AND btrim(v.tested_by) <> ''
   AND v.tested_on IS NOT NULL;

CREATE TABLE recipe_halal_log (
  check_id uuid PRIMARY KEY REFERENCES safety_log (id) ON DELETE CASCADE,
  household_id uuid REFERENCES household (id) ON DELETE SET NULL,
  log_format text NOT NULL CHECK (log_format = 'keluargamakan.recipe-halal-log/1'),
  subject_kind text NOT NULL CHECK (subject_kind IN (
    'library_recipe', 'suggestion', 'substitution', 'taste_tweak_fix',
    'planned_meal', 'family_recipe', 'leftover_remake'
  )),
  subject_id text NOT NULL CHECK (subject_id ~ '^[a-z0-9][a-z0-9_.-]{0,99}$'),
  subject_version text CHECK (
    subject_version IS NULL OR subject_version ~ '^[A-Za-z0-9][A-Za-z0-9._+/-]{0,99}$'
  ),
  evaluated_at timestamptz NOT NULL,
  rule_set_version text NOT NULL CHECK (rule_set_version ~ '^[A-Za-z0-9][A-Za-z0-9._+/-]{0,99}$'),
  reference_version text NOT NULL CHECK (
    reference_version ~ '${REFERENCE_VERSION_PATTERN}'
  ),
  status text NOT NULL CHECK (status IN ('halal', 'not_halal', 'check_label')),
  -- Every line as checked: position, line ID, reference ingredient ID (or
  -- null) and the household's recorded brand IDs. No names.
  lines jsonb NOT NULL CHECK (jsonb_typeof(lines) = 'array'),
  findings jsonb NOT NULL CHECK (jsonb_typeof(findings) = 'array'),
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT recipe_halal_log_status_findings CHECK (
    (status = 'halal') = (jsonb_array_length(findings) = 0)
  )
);

CREATE INDEX recipe_halal_log_household_idx ON recipe_halal_log (household_id, evaluated_at);

-- N2 and QUESTIONS #88: the halal record and its check's safety log name the
-- same household, subject, time and versions (one reference snapshot).
CREATE FUNCTION recipe_halal_log_insert_guard() RETURNS trigger
LANGUAGE plpgsql SET search_path FROM CURRENT AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM safety_log l
     WHERE l.id = NEW.check_id
       AND l.household_id IS NOT DISTINCT FROM NEW.household_id
       AND l.subject_kind = NEW.subject_kind
       AND l.subject_id = NEW.subject_id
       AND l.subject_version IS NOT DISTINCT FROM NEW.subject_version
       AND l.evaluated_at = NEW.evaluated_at
       AND l.rule_set_version = NEW.rule_set_version
       AND l.reference_version = NEW.reference_version
  ) THEN
    RAISE EXCEPTION 'a recipe halal log needs the safety log of the same check (SAF-14)'
      USING ERRCODE = 'KM003';
  END IF;
  RETURN NEW;
END
$$;

CREATE TRIGGER recipe_halal_log_insert_guard
  BEFORE INSERT ON recipe_halal_log
  FOR EACH ROW EXECUTE FUNCTION recipe_halal_log_insert_guard();

CREATE FUNCTION recipe_halal_log_guard() RETURNS trigger
LANGUAGE plpgsql SET search_path FROM CURRENT AS $$
BEGIN
  IF ROW(NEW.check_id, NEW.log_format, NEW.subject_kind, NEW.subject_id, NEW.subject_version,
         NEW.evaluated_at, NEW.rule_set_version, NEW.reference_version, NEW.status, NEW.lines,
         NEW.findings, NEW.created_at)
       IS DISTINCT FROM
     ROW(OLD.check_id, OLD.log_format, OLD.subject_kind, OLD.subject_id, OLD.subject_version,
         OLD.evaluated_at, OLD.rule_set_version, OLD.reference_version, OLD.status, OLD.lines,
         OLD.findings, OLD.created_at)
     OR (NEW.household_id IS NOT NULL AND NEW.household_id IS DISTINCT FROM OLD.household_id)
  THEN
    RAISE EXCEPTION 'recipe halal logs are append-only (SAF-14)' USING ERRCODE = 'KM003';
  END IF;
  RETURN NEW;
END
$$;

CREATE TRIGGER recipe_halal_log_guard
  BEFORE UPDATE ON recipe_halal_log
  FOR EACH ROW EXECUTE FUNCTION recipe_halal_log_guard();
`,
};
