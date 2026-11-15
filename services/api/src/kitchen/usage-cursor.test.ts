// TEST FIXTURE: not real safety or nutrition data. Fictional IDs only.
import { randomBytes, randomUUID } from "node:crypto";

import { describe, expect, it } from "vitest";

import type { KitchenItemRow } from "./kitchen-store.js";
import { decodeCursor, encodeCursor } from "./sync-cursor.js";
import { currentScore, scoreAfter, usageRanks } from "./usage.js";

const DAY = 86_400_000;
const at = (days: number) => new Date(Date.UTC(2026, 10, 1) + days * DAY);

function row(fields: Partial<KitchenItemRow>): KitchenItemRow {
  return {
    id: randomUUID(),
    ingredient_id: null,
    custom_name: "x",
    custom_key: "x",
    category: "staples",
    state: "available",
    quantity: null,
    brand_id: null,
    brand_custom_name: null,
    is_default_staple: false,
    changed_at: at(0),
    client_changed_at: at(0),
    use_score: 0,
    use_score_at: null,
    change_seq: "1",
    created_at: at(0),
    ...fields,
  };
}

describe("KIT-06 usage score", () => {
  it("KIT-06 halves every half-life", () => {
    expect(currentScore(4, at(0), at(30), 30)).toBeCloseTo(2);
    expect(currentScore(4, at(0), at(60), 30)).toBeCloseTo(1);
    expect(currentScore(0, null, at(60), 30)).toBe(0);
  });

  it("KIT-06 a change of state is a use; the same state again is not; a new item has none", () => {
    const item = row({ state: "available", use_score: 2, use_score_at: at(0) });
    expect(scoreAfter(item, "available", at(30), 30)).toEqual({ useScore: 2, useScoreAt: at(0) });
    const used = scoreAfter(item, "out", at(30), 30);
    expect(used.useScore).toBeCloseTo(2);
    expect(used.useScoreAt).toEqual(at(30));
    expect(scoreAfter(null, "available", at(30), 30)).toEqual({ useScore: 0, useScoreAt: null });
  });

  it("KIT-16 an older synced change never moves the score's date backwards", () => {
    const item = row({ state: "available", use_score: 1, use_score_at: at(10) });
    const used = scoreAfter(item, "out", at(5), 30);
    expect(used.useScoreAt).toEqual(at(10));
    expect(used.useScore).toBeCloseTo(2);
  });

  it("KIT-06 ranks per category, most used first, unused items unranked", () => {
    const a = row({ category: "staples", use_score: 3, use_score_at: at(0) });
    const b = row({ category: "staples", use_score: 1, use_score_at: at(0) });
    const c = row({ category: "staples" });
    const d = row({ category: "dairy", use_score: 0.5, use_score_at: at(0) });
    const ranks = usageRanks([a, b, c, d], at(0), 30);
    expect([ranks.get(a.id), ranks.get(b.id), ranks.get(c.id), ranks.get(d.id)]).toEqual([
      1,
      2,
      null,
      1,
    ]);
  });
});

describe("KIT-16 sync cursor", () => {
  const key = randomBytes(32);
  const household = randomUUID();

  it("KIT-16 round-trips for its household within the retention", () => {
    const cursor = encodeCursor(key, household, 42n, at(10));
    expect(cursor.length).toBeLessThanOrEqual(512);
    expect(decodeCursor(key, cursor, household, at(0))).toBe(42n);
  });

  it("KIT-16 is not used when tampered, foreign, signed with another key, old or malformed", () => {
    const cursor = encodeCursor(key, household, 42n, at(10));
    const [prefix, payload, mac] = cursor.split(".") as [string, string, string];
    const tampered = Buffer.from(
      JSON.stringify({ h: household, s: "0", t: at(10).getTime() }),
    ).toString("base64url");
    for (const [why, candidate, owner, notBefore] of [
      ["another household", cursor, randomUUID(), at(0)],
      ["another key", encodeCursor(randomBytes(32), household, 42n, at(10)), household, at(0)],
      ["changed position", `${prefix}.${tampered}.${mac}`, household, at(0)],
      ["older than the retention", cursor, household, at(11)],
      ["no signature", `${prefix}.${payload}.`, household, at(0)],
      ["wrong version", `v2.${payload}.${mac}`, household, at(0)],
      ["not a cursor", "garbage", household, at(0)],
      ["null", null, household, at(0)],
    ] as const) {
      expect(decodeCursor(key, candidate, owner, notBefore), why).toBeNull();
    }
  });
});
