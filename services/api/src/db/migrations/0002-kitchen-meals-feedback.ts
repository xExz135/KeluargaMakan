import type { Migration } from "./types.js";

/**
 * SRS 18.1 Kitchen item, Ingredient set, Meal and Feedback (V1).
 *
 * - Kitchen item (KIT-01 to KIT-09, KIT-16): a reference ingredient or a custom
 *   one (KIT-05; custom items always get "Check the label", SAF-09). No
 *   freshness date (KIT-10 is V2). `changed_at` is the server time of the last
 *   accepted change, used for last-write-wins per ingredient (KIT-16); the
 *   device time of the edit is kept for the sync logic (T-030).
 * - Meal: the cooked-meal record only (QUESTIONS #19): date, slot, recipe and
 *   who ate. No portions, fat answer, source or nutrition (V2). Retention comes
 *   from configuration (DAT-04, 2 years target).
 * - Feedback (PRF-13): overall Yes, Mixed or No, optionally per member who ate.
 */
export const migration0002: Migration = {
  version: 2,
  name: "kitchen-meals-feedback",
  sql: String.raw`
CREATE TABLE kitchen_item (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id uuid NOT NULL REFERENCES household (id) ON DELETE CASCADE,
  ingredient_id text CHECK (ingredient_id IS NULL OR ingredient_id ~ '^[a-z0-9][a-z0-9_.-]{0,99}$'),
  custom_name text CHECK (custom_name IS NULL OR char_length(btrim(custom_name)) BETWEEN 1 AND 60),
  category text NOT NULL CHECK (category IN (
    'protein', 'vegetables', 'fruit', 'spices_aromatics', 'staples',
    'sauces_condiments', 'dairy', 'frozen', 'leftovers'
  )),
  state text NOT NULL DEFAULT 'available' CHECK (state IN ('available', 'out')),
  quantity text CHECK (quantity IS NULL OR quantity IN ('a_little', 'some', 'plenty')),
  brand_id text CHECK (brand_id IS NULL OR brand_id ~ '^[a-z0-9][a-z0-9_.-]{0,99}$'),
  brand_custom_name text CHECK (
    brand_custom_name IS NULL OR char_length(btrim(brand_custom_name)) BETWEEN 1 AND 60
  ),
  is_default_staple boolean NOT NULL DEFAULT false,
  changed_by_account_id uuid REFERENCES account (id) ON DELETE SET NULL,
  changed_at timestamptz NOT NULL DEFAULT now(),
  client_changed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT kitchen_item_id_household_key UNIQUE (id, household_id),
  CONSTRAINT kitchen_item_ingredient_check CHECK ((ingredient_id IS NULL) <> (custom_name IS NULL)),
  CONSTRAINT kitchen_item_brand_check CHECK (brand_id IS NULL OR brand_custom_name IS NULL),
  CONSTRAINT kitchen_item_brand_reference_check CHECK (brand_id IS NULL OR ingredient_id IS NOT NULL),
  CONSTRAINT kitchen_item_staple_check CHECK (NOT is_default_staple OR ingredient_id IS NOT NULL)
);

CREATE UNIQUE INDEX kitchen_item_household_ingredient_key
  ON kitchen_item (household_id, ingredient_id) WHERE ingredient_id IS NOT NULL;
CREATE UNIQUE INDEX kitchen_item_household_custom_name_key
  ON kitchen_item (household_id, lower(btrim(custom_name))) WHERE custom_name IS NOT NULL;

CREATE TABLE ingredient_set (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id uuid NOT NULL REFERENCES household (id) ON DELETE CASCADE,
  name text NOT NULL CHECK (char_length(btrim(name)) BETWEEN 1 AND 40),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT ingredient_set_id_household_key UNIQUE (id, household_id)
);

CREATE TABLE ingredient_set_item (
  set_id uuid NOT NULL,
  household_id uuid NOT NULL,
  kitchen_item_id uuid NOT NULL,
  PRIMARY KEY (set_id, kitchen_item_id),
  CONSTRAINT ingredient_set_item_set_fkey FOREIGN KEY (set_id, household_id)
    REFERENCES ingredient_set (id, household_id) ON DELETE CASCADE,
  CONSTRAINT ingredient_set_item_kitchen_item_fkey FOREIGN KEY (kitchen_item_id, household_id)
    REFERENCES kitchen_item (id, household_id) ON DELETE CASCADE
);

CREATE TABLE meal (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id uuid NOT NULL REFERENCES household (id) ON DELETE CASCADE,
  eaten_on date NOT NULL,
  slot text NOT NULL CHECK (slot IN ('breakfast', 'lunch', 'dinner', 'snack', 'sahur', 'buka')),
  recipe_id text NOT NULL CHECK (recipe_id ~ '^[a-z0-9][a-z0-9_.-]{0,99}$'),
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT meal_id_household_key UNIQUE (id, household_id)
);

CREATE INDEX meal_household_eaten_on_idx ON meal (household_id, eaten_on DESC);
CREATE INDEX meal_eaten_on_idx ON meal (eaten_on);

CREATE TABLE meal_member (
  meal_id uuid NOT NULL,
  household_id uuid NOT NULL,
  profile_id uuid NOT NULL,
  PRIMARY KEY (meal_id, profile_id),
  CONSTRAINT meal_member_meal_fkey FOREIGN KEY (meal_id, household_id)
    REFERENCES meal (id, household_id) ON DELETE CASCADE,
  CONSTRAINT meal_member_profile_fkey FOREIGN KEY (profile_id, household_id)
    REFERENCES profile (id, household_id) ON DELETE CASCADE
);

CREATE INDEX meal_member_profile_idx ON meal_member (profile_id);

CREATE TABLE feedback (
  meal_id uuid PRIMARY KEY,
  household_id uuid NOT NULL,
  overall text NOT NULL CHECK (overall IN ('yes', 'mixed', 'no')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT feedback_meal_fkey FOREIGN KEY (meal_id, household_id)
    REFERENCES meal (id, household_id) ON DELETE CASCADE
);

CREATE TABLE feedback_member (
  meal_id uuid NOT NULL REFERENCES feedback (meal_id) ON DELETE CASCADE,
  profile_id uuid NOT NULL,
  rating text NOT NULL CHECK (rating IN ('yes', 'mixed', 'no')),
  PRIMARY KEY (meal_id, profile_id),
  -- Only someone who ate the meal can rate it.
  CONSTRAINT feedback_member_meal_member_fkey FOREIGN KEY (meal_id, profile_id)
    REFERENCES meal_member (meal_id, profile_id) ON DELETE CASCADE
);
`,
};
