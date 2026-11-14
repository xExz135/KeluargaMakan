import { ApiError } from "../api-error.js";
import { keyedHash } from "../auth/crypto.js";
import { ConcurrentUpdateError, withDbErrors } from "../db/errors.js";
import type { SqlExecutor } from "../db/executor.js";

/**
 * Contract `Idempotency-Key` for create operations (offline queue replay).
 * Records are per account and keep only the operation, a keyed hash of the
 * request and the created resource's ID, never the request or response body.
 *
 * Callers must not put health data into the hashed request parts: the hash key
 * is a general secret, and a small value space (11 allergens) could be
 * guessed from a keyed hash by anyone holding it (DAT-02). Hard-rule creates
 * hash only the target and compare the rule itself after decrypting it.
 */

const OPERATION = /^[a-z_]{1,40}$/;

export const idempotencyKeyReused = () =>
  new ApiError("idempotency_key_reused", 409, "The Idempotency-Key was used with another request");

export interface IdempotentRequest {
  readonly accountId: string;
  readonly key: string;
  readonly operation: string;
  readonly requestHash: Buffer;
  /** Records older than this are ignored and replaced. */
  readonly keptSince: Date;
}

export function requestHash(hashKey: Buffer, operation: string, parts: readonly unknown[]): Buffer {
  return keyedHash(hashKey, "idempotent_request", JSON.stringify([operation, ...parts]));
}

/**
 * The resource created by an earlier request with this key, or null. A key
 * used for another operation or another request is refused (409).
 */
export async function findReplay(
  tx: SqlExecutor,
  request: IdempotentRequest,
): Promise<string | null> {
  if (!OPERATION.test(request.operation)) throw new Error("invalid idempotency operation name");
  const { rows } = await withDbErrors(() =>
    tx.query<{ operation: string; request_hash: Uint8Array; resource_id: string }>(
      `SELECT operation, request_hash, resource_id FROM idempotency_record
        WHERE account_id = $1 AND idempotency_key = $2 AND created_at >= $3`,
      [request.accountId, request.key, request.keptSince],
    ),
  );
  const row = rows[0];
  if (row === undefined) return null;
  if (
    row.operation !== request.operation ||
    !Buffer.from(row.request_hash).equals(request.requestHash)
  ) {
    throw idempotencyKeyReused();
  }
  return row.resource_id;
}

/**
 * Records the created resource in the same transaction as the create. A
 * concurrent request with the same key makes this throw the retryable
 * `ConcurrentUpdateError`, which rolls the create back; the retry then
 * finds the first request's record.
 */
export async function remember(
  tx: SqlExecutor,
  request: IdempotentRequest,
  resourceId: string,
  now: Date,
): Promise<void> {
  if (!OPERATION.test(request.operation)) throw new Error("invalid idempotency operation name");
  await withDbErrors(async () => {
    await tx.query(
      `DELETE FROM idempotency_record
        WHERE account_id = $1 AND idempotency_key = $2 AND created_at < $3`,
      [request.accountId, request.key, request.keptSince],
    );
    const { rowCount } = await tx.query(
      `INSERT INTO idempotency_record
         (account_id, idempotency_key, operation, request_hash, resource_id, created_at)
       VALUES ($1, $2, $3, $4, $5, $6)
       ON CONFLICT (account_id, idempotency_key) DO NOTHING`,
      [request.accountId, request.key, request.operation, request.requestHash, resourceId, now],
    );
    if (rowCount !== 1) throw new ConcurrentUpdateError();
  });
}

/**
 * Like `findReplay` for a request that is recorded under one of several
 * operation names (for example "created" and "already there"), so a replay
 * can answer like the first request. `requests` differ only in `operation`
 * and `requestHash`. Returns the operation recorded and the resource.
 */
export async function findReplayOf(
  tx: SqlExecutor,
  requests: readonly IdempotentRequest[],
): Promise<{ readonly operation: string; readonly resourceId: string } | null> {
  const first = requests[0];
  if (first === undefined) throw new Error("no idempotent request given");
  for (const request of requests) {
    if (!OPERATION.test(request.operation)) throw new Error("invalid idempotency operation name");
  }
  const { rows } = await withDbErrors(() =>
    tx.query<{ operation: string; request_hash: Uint8Array; resource_id: string }>(
      `SELECT operation, request_hash, resource_id FROM idempotency_record
        WHERE account_id = $1 AND idempotency_key = $2 AND created_at >= $3`,
      [first.accountId, first.key, first.keptSince],
    ),
  );
  const row = rows[0];
  if (row === undefined) return null;
  const match = requests.find(
    (request) =>
      request.operation === row.operation &&
      Buffer.from(row.request_hash).equals(request.requestHash),
  );
  if (match === undefined) throw idempotencyKeyReused();
  return { operation: match.operation, resourceId: row.resource_id };
}
