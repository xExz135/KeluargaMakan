import type { Migration } from "./types.js";

/**
 * Dapur Saya (T-031, KIT-05, KIT-16).
 *
 * - `custom_key`: the comparison key of a custom ingredient's name (Unicode
 *   NFKC, accents removed, lower case, punctuation and spacing collapsed),
 *   computed by the API (`kitchen/text.ts`). One custom item per key and
 *   household, so "Daun Jeruk" and "daun  jeruk" are the same ingredient,
 *   and the sync (T-032) can find an item by its name. Rows written before
 *   this migration get `lower(btrim(custom_name))`; V1 has no such rows in
 *   use.
 * - An index on `household_id` for listing a household's kitchen.
 */
export const migration0008: Migration = {
  version: 8,
  name: "kitchen-custom-key",
  sql: String.raw`
ALTER TABLE kitchen_item ADD COLUMN custom_key text;

UPDATE kitchen_item SET custom_key = lower(btrim(custom_name)) WHERE custom_name IS NOT NULL;

ALTER TABLE kitchen_item ADD CONSTRAINT kitchen_item_custom_key_check CHECK (
  (custom_name IS NULL) = (custom_key IS NULL)
  AND (custom_key IS NULL OR char_length(custom_key) BETWEEN 1 AND 240)
);

CREATE UNIQUE INDEX kitchen_item_household_custom_key
  ON kitchen_item (household_id, custom_key) WHERE custom_key IS NOT NULL;

CREATE INDEX kitchen_item_household_idx ON kitchen_item (household_id);
`,
};
