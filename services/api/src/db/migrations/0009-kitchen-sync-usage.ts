import type { Migration } from "./types.js";

/**
 * Dapur Saya sync and frequency order (T-032; KIT-06, KIT-16).
 *
 * - `kitchen_change_seq`: one ordering for every kitchen write. Each item
 *   write and each removal takes the next value, under the household's
 *   kitchen lock, so a household's values commit in order and a sync cursor
 *   ("everything after N") never skips a write.
 * - `kitchen_item.use_score`, `use_score_at`: KIT-06 frequency. A use (the
 *   item runs out, or comes back after being out) adds 1; the API halves the
 *   score every configured number of days when it reads it.
 * - `kitchen_item.client_changed_at` (0002) now holds the time of the edit on
 *   the server's clock (server time minus the phone's `ageMs`), which is what
 *   the latest-change-wins rule compares; `changed_at` stays the time the
 *   server stored it.
 * - `kitchen_item_tombstone`: a removed ingredient, so a sync can report the
 *   removal and an older queued change cannot bring the item back. Keyed by
 *   the reference ID or the custom name key, never the name itself.
 * - `kitchen_sync_change`: each sync change ID per household, with a keyed
 *   hash of the change and its outcome, so a replayed change returns its
 *   first result and is never applied twice.
 *
 * Tombstones and change records are purged after the configured retention.
 */
export const migration0009: Migration = {
  version: 9,
  name: "kitchen-sync-usage",
  sql: String.raw`
CREATE SEQUENCE kitchen_change_seq AS bigint;

ALTER TABLE kitchen_item
  ADD COLUMN change_seq bigint NOT NULL DEFAULT nextval('kitchen_change_seq'),
  ADD COLUMN use_score double precision NOT NULL DEFAULT 0,
  ADD COLUMN use_score_at timestamptz;

ALTER TABLE kitchen_item ADD CONSTRAINT kitchen_item_use_score_check CHECK (
  use_score >= 0 AND use_score < 1e9 AND (use_score = 0 OR use_score_at IS NOT NULL)
);

CREATE INDEX kitchen_item_household_seq_idx ON kitchen_item (household_id, change_seq);

CREATE TABLE kitchen_item_tombstone (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id uuid NOT NULL REFERENCES household (id) ON DELETE CASCADE,
  item_id uuid,
  ingredient_id text CHECK (ingredient_id IS NULL OR ingredient_id ~ '^[a-z0-9][a-z0-9_.-]{0,99}$'),
  custom_key text CHECK (custom_key IS NULL OR char_length(custom_key) BETWEEN 1 AND 240),
  removed_at timestamptz NOT NULL,
  recorded_at timestamptz NOT NULL,
  change_seq bigint NOT NULL DEFAULT nextval('kitchen_change_seq'),
  CONSTRAINT kitchen_item_tombstone_key_check CHECK ((ingredient_id IS NULL) <> (custom_key IS NULL))
);

CREATE INDEX kitchen_item_tombstone_seq_idx ON kitchen_item_tombstone (household_id, change_seq);
CREATE INDEX kitchen_item_tombstone_ingredient_idx
  ON kitchen_item_tombstone (household_id, ingredient_id) WHERE ingredient_id IS NOT NULL;
CREATE INDEX kitchen_item_tombstone_custom_idx
  ON kitchen_item_tombstone (household_id, custom_key) WHERE custom_key IS NOT NULL;
CREATE INDEX kitchen_item_tombstone_recorded_idx ON kitchen_item_tombstone (recorded_at);

CREATE TABLE kitchen_sync_change (
  household_id uuid NOT NULL REFERENCES household (id) ON DELETE CASCADE,
  change_id uuid NOT NULL,
  request_hash bytea NOT NULL CHECK (octet_length(request_hash) = 32),
  outcome text NOT NULL CHECK (outcome IN ('applied', 'superseded', 'rejected')),
  item_id uuid,
  error_code text CHECK (error_code IS NULL OR error_code ~ '^[a-z_]{1,64}$'),
  created_at timestamptz NOT NULL,
  PRIMARY KEY (household_id, change_id),
  CONSTRAINT kitchen_sync_change_error_check CHECK ((outcome = 'rejected') = (error_code IS NOT NULL))
);

CREATE INDEX kitchen_sync_change_created_idx ON kitchen_sync_change (created_at);
`,
};
