import type { RateLimitRule } from "../../config/api.js";
import { withDbErrors } from "../db/errors.js";
import type { SqlExecutor } from "../db/executor.js";
import { keyedHash } from "./crypto.js";

/**
 * ACC-01 rate limits: fixed-window counters in PostgreSQL, so limits hold
 * across restarts and instances without another paid service. The key is a
 * keyed hash of the destination or client address; the value itself is never
 * stored.
 */
export type RateLimitScope =
  "code_request_destination" | "code_request_client" | "code_verify_client" | "refresh_client";

export interface RateLimitDecision {
  readonly allowed: boolean;
  /** Seconds until the window ends (at least 1 when not allowed). */
  readonly retryAfterSeconds: number;
}

export class RateLimiter {
  constructor(
    private readonly db: SqlExecutor,
    private readonly hashKey: Buffer,
  ) {}

  /** Counts one request and says whether it is within the limit. */
  async hit(
    scope: RateLimitScope,
    key: string,
    rule: RateLimitRule,
    now: Date,
  ): Promise<RateLimitDecision> {
    const windowMs = rule.windowSeconds * 1000;
    const windowStart = new Date(Math.floor(now.getTime() / windowMs) * windowMs);
    const retryAfterSeconds = Math.max(
      1,
      Math.ceil((windowStart.getTime() + windowMs - now.getTime()) / 1000),
    );
    const { rows } = await withDbErrors(() =>
      this.db.query<{ hits: number }>(
        `INSERT INTO auth_rate_limit (scope, key_hash, window_start, hits)
         VALUES ($1, $2, $3, 1)
         ON CONFLICT (scope, key_hash, window_start)
         DO UPDATE SET hits = auth_rate_limit.hits + 1
         RETURNING hits`,
        [scope, keyedHash(this.hashKey, "rate_limit", scope, key), windowStart],
      ),
    );
    const hits = Number(rows[0]?.hits ?? Number.POSITIVE_INFINITY);
    return { allowed: hits <= rule.limit, retryAfterSeconds };
  }
}
