import type { Migration } from "./types.js";

/**
 * Kitchen removals, tightened (security review T-032 L4).
 *
 * - One removal per ingredient and household: later removals update it
 *   (unique indexes below), so the table cannot grow from repeated add and
 *   remove cycles. The removal keeps the item ID, and the API reuses that ID
 *   when the ingredient is added again, so a phone that missed the cycle
 *   still matches the item.
 * - A custom ingredient's removal is keyed by an HMAC of its name key under
 *   the server's hash key (`custom_key_hash`), never the folded name: only
 *   equality is needed, and a removed custom name such as a medicine is not
 *   readable from the table. The plain `custom_key` column is dropped; its
 *   rows are deleted here (they cannot be hashed in SQL, and 0009 was never
 *   released).
 * - `kitchen_sync_floor`: when a household reaches the configured removal
 *   cap, its oldest removals are evicted and the floor records the newest
 *   evicted removal time and when it happened. Older changes then never add
 *   an item, and older cursors resync in full.
 */
export const migration0010: Migration = {
  version: 10,
  name: "kitchen-removals",
  sql: String.raw`
DELETE FROM kitchen_item_tombstone WHERE custom_key IS NOT NULL;

DELETE FROM kitchen_item_tombstone t
 USING kitchen_item_tombstone newer
 WHERE t.household_id = newer.household_id
   AND t.ingredient_id = newer.ingredient_id
   AND (t.removed_at, t.id) < (newer.removed_at, newer.id);

ALTER TABLE kitchen_item_tombstone DROP CONSTRAINT kitchen_item_tombstone_key_check;
DROP INDEX kitchen_item_tombstone_ingredient_idx;
ALTER TABLE kitchen_item_tombstone DROP COLUMN custom_key;

ALTER TABLE kitchen_item_tombstone ADD COLUMN custom_key_hash bytea
  CHECK (custom_key_hash IS NULL OR octet_length(custom_key_hash) = 32);
ALTER TABLE kitchen_item_tombstone ADD CONSTRAINT kitchen_item_tombstone_key_check
  CHECK ((ingredient_id IS NULL) <> (custom_key_hash IS NULL));

CREATE UNIQUE INDEX kitchen_item_tombstone_ingredient_key
  ON kitchen_item_tombstone (household_id, ingredient_id) WHERE ingredient_id IS NOT NULL;
CREATE UNIQUE INDEX kitchen_item_tombstone_custom_key
  ON kitchen_item_tombstone (household_id, custom_key_hash) WHERE custom_key_hash IS NOT NULL;
CREATE INDEX kitchen_item_tombstone_household_removed_idx
  ON kitchen_item_tombstone (household_id, removed_at);

CREATE TABLE kitchen_sync_floor (
  household_id uuid PRIMARY KEY REFERENCES household (id) ON DELETE CASCADE,
  removed_before timestamptz NOT NULL,
  evicted_at timestamptz NOT NULL
);
`,
};
