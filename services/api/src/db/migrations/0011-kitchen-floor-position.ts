import type { Migration } from "./types.js";

/**
 * Kitchen sync floor by position (security review T-032 re-check N3).
 *
 * `evicted_seq` is the highest sync position among the removals evicted at
 * the household's cap. A cursor below it may have missed one of them, so it
 * resyncs in full; new cursors never start below it. Comparing positions,
 * not times, closes the case of a cursor issued in the same millisecond as
 * an eviction.
 */
export const migration0011: Migration = {
  version: 11,
  name: "kitchen-floor-position",
  sql: String.raw`
ALTER TABLE kitchen_sync_floor ADD COLUMN evicted_seq bigint NOT NULL DEFAULT 0
  CHECK (evicted_seq >= 0);
`,
};
