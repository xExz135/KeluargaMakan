import type { RateLimitRule } from "../../config/api.js";
import { withDbErrors } from "../db/errors.js";
import type { SqlExecutor } from "../db/executor.js";
import { keyedHash } from "./crypto.js";

/**
 * ACC-01 rate limits: rolling-window counters in PostgreSQL, so limits hold
 * across restarts and instances without another paid service. A window is
 * counted in 12 buckets, so a burst at a window edge cannot double the limit.
 * The key is a keyed hash of the destination's rate key or the client
 * address key; the value itself is never stored.
 */
export type RateLimitScope =
  | "code_request_destination"
  | "code_request_destination_daily"
  | "code_verify_failure_destination"
  | "code_request_client"
  | "code_verify_client"
  | "refresh_client";

export interface RateLimitDecision {
  readonly allowed: boolean;
  /** Seconds until the oldest counted bucket leaves the window (at least 1). */
  readonly retryAfterSeconds: number;
}

const BUCKETS = 12;

export class RateLimiter {
  constructor(
    private readonly db: SqlExecutor,
    private readonly hashKey: Buffer,
  ) {}

  #key(scope: RateLimitScope, key: string): Buffer {
    return keyedHash(this.hashKey, "rate_limit", scope, key);
  }

  static #bucketMs(rule: RateLimitRule): number {
    return Math.ceil((rule.windowSeconds * 1000) / BUCKETS);
  }

  /** Counts one event. */
  async record(
    scope: RateLimitScope,
    key: string,
    rule: RateLimitRule,
    now: Date,
    db: SqlExecutor = this.db,
  ): Promise<void> {
    const bucketMs = RateLimiter.#bucketMs(rule);
    const bucketStart = new Date(Math.floor(now.getTime() / bucketMs) * bucketMs);
    await withDbErrors(() =>
      db.query(
        `INSERT INTO auth_rate_limit (scope, key_hash, window_start, hits)
         VALUES ($1, $2, $3, 1)
         ON CONFLICT (scope, key_hash, window_start)
         DO UPDATE SET hits = auth_rate_limit.hits + 1`,
        [scope, this.#key(scope, key), bucketStart],
      ),
    );
  }

  /** Events in the window ending now, and when the oldest of them stops counting. */
  async count(
    scope: RateLimitScope,
    key: string,
    rule: RateLimitRule,
    now: Date,
    db: SqlExecutor = this.db,
  ): Promise<{ count: number; retryAfterSeconds: number }> {
    const bucketMs = RateLimiter.#bucketMs(rule);
    const windowMs = rule.windowSeconds * 1000;
    const { rows } = await withDbErrors(() =>
      db.query<{ hits: string | number | null; oldest: Date | null }>(
        `SELECT sum(hits) AS hits, min(window_start) AS oldest FROM auth_rate_limit
          WHERE scope = $1 AND key_hash = $2 AND window_start > $3`,
        [scope, this.#key(scope, key), new Date(now.getTime() - windowMs - bucketMs)],
      ),
    );
    const row = rows[0];
    const count = Number(row?.hits ?? 0);
    const oldest = row?.oldest ?? now;
    const leaves = oldest.getTime() + bucketMs + windowMs;
    return { count, retryAfterSeconds: Math.max(1, Math.ceil((leaves - now.getTime()) / 1000)) };
  }

  /** True while fewer than `limit` events are counted (checks without counting). */
  async check(
    scope: RateLimitScope,
    key: string,
    rule: RateLimitRule,
    now: Date,
    db: SqlExecutor = this.db,
  ): Promise<RateLimitDecision> {
    const { count, retryAfterSeconds } = await this.count(scope, key, rule, now, db);
    return { allowed: count < rule.limit, retryAfterSeconds };
  }

  /** Counts one request and says whether it is within the limit. */
  async hit(
    scope: RateLimitScope,
    key: string,
    rule: RateLimitRule,
    now: Date,
  ): Promise<RateLimitDecision> {
    await this.record(scope, key, rule, now);
    const { count, retryAfterSeconds } = await this.count(scope, key, rule, now);
    return { allowed: count <= rule.limit, retryAfterSeconds };
  }
}
