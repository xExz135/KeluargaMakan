import { KITCHEN_CATEGORIES } from "../../config/kitchen.js";
import type { KitchenItemRow, KitchenItemState } from "./kitchen-store.js";

/**
 * KIT-06: the most used ingredients come first in their category.
 *
 * "Used" in V1 means the item's state changed: it ran out (it was used up)
 * or it came back after being out (it was bought again). Each such change
 * adds 1 to the item's score, and the score halves every
 * `usageHalfLifeDays` (configuration), so what the household uses now
 * outranks what it used months ago. Writing the same state again is not a
 * use. Adding an item is not a use. The score belongs to the household's
 * own item; nothing about people or other households is used. Recording
 * used-up ingredients after cooking (KIT-11) is V2 and will add uses here.
 */

const DAY_MS = 86_400_000;
/** Scores below this count as no use (avoids ranking long-forgotten items). */
const NEGLIGIBLE = 0.01;

/** The score as of `at`, after halving every `halfLifeDays` since it was last updated. */
export function currentScore(
  score: number,
  scoreAt: Date | null,
  at: Date,
  halfLifeDays: number,
): number {
  if (scoreAt === null || score <= 0) return 0;
  const elapsed = Math.max(0, at.getTime() - scoreAt.getTime());
  return score * 0.5 ** (elapsed / (halfLifeDays * DAY_MS));
}

/** The score after a change to `next` made at `editedAt` (a use when the state changes). */
export function scoreAfter(
  row: Pick<KitchenItemRow, "state" | "use_score" | "use_score_at"> | null,
  next: KitchenItemState,
  editedAt: Date,
  halfLifeDays: number,
): { readonly useScore: number; readonly useScoreAt: Date | null } {
  if (row === null) return { useScore: 0, useScoreAt: null };
  if (row.state === next) return { useScore: row.use_score, useScoreAt: row.use_score_at };
  // An older change (offline sync) never moves the score's date backwards.
  const at =
    row.use_score_at !== null && row.use_score_at.getTime() > editedAt.getTime()
      ? row.use_score_at
      : editedAt;
  const decayed = currentScore(row.use_score, row.use_score_at, at, halfLifeDays);
  return { useScore: Math.min(decayed + 1, 1e8), useScoreAt: at };
}

/**
 * `usageRank` per item: 1 is the most used item in its category; items with
 * no recent use get null. Ties go by item ID so the order is stable.
 */
export function usageRanks(
  rows: readonly KitchenItemRow[],
  now: Date,
  halfLifeDays: number,
): Map<string, number | null> {
  const ranks = new Map<string, number | null>();
  for (const category of KITCHEN_CATEGORIES) {
    const scored = rows
      .filter((row) => row.category === category)
      .map((row) => ({
        id: row.id,
        score: currentScore(row.use_score, row.use_score_at, now, halfLifeDays),
      }));
    const used = scored
      .filter((item) => item.score >= NEGLIGIBLE)
      .sort((a, b) => b.score - a.score || (a.id < b.id ? -1 : a.id > b.id ? 1 : 0));
    used.forEach((item, index) => ranks.set(item.id, index + 1));
    for (const item of scored) if (!ranks.has(item.id)) ranks.set(item.id, null);
  }
  return ranks;
}
