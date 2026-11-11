import type { Pool, PoolClient } from "pg";

/**
 * The narrow database interface the data layer is written against. Production
 * uses node-postgres (`pgExecutor`); tests also run the same code on PGlite
 * (PostgreSQL compiled to WebAssembly) so the database suite runs even where
 * Docker is not available. See `testing/databases.ts`.
 */
export interface SqlResult<R> {
  readonly rows: R[];
  readonly rowCount: number;
}

export interface SqlExecutor {
  /** One statement with `$1`-style parameters. */
  query<R extends object = Record<string, unknown>>(
    text: string,
    params?: readonly unknown[],
  ): Promise<SqlResult<R>>;
  /** A multi-statement script without parameters (migrations only). */
  execScript(sql: string): Promise<void>;
  /**
   * Runs `fn` in a transaction: commit on success, rollback on any error.
   * Called on an executor that is already inside a transaction, it joins that
   * transaction instead of nesting.
   */
  transaction<T>(fn: (tx: SqlExecutor) => Promise<T>): Promise<T>;
}

function clientExecutor(client: PoolClient): SqlExecutor {
  const self: SqlExecutor = {
    async query<R extends object>(text: string, params: readonly unknown[] = []) {
      const result = await client.query<R & Record<string, unknown>>(text, [...params]);
      return { rows: result.rows as R[], rowCount: result.rowCount ?? 0 };
    },
    async execScript(sql: string) {
      await client.query(sql);
    },
    transaction: (fn) => fn(self),
  };
  return self;
}

/** node-postgres adapter. The pool's lifecycle stays with the caller. */
export function pgExecutor(pool: Pool): SqlExecutor {
  return {
    async query<R extends object>(text: string, params: readonly unknown[] = []) {
      const result = await pool.query<R & Record<string, unknown>>(text, [...params]);
      return { rows: result.rows as R[], rowCount: result.rowCount ?? 0 };
    },
    async execScript(sql: string) {
      await pool.query(sql);
    },
    async transaction<T>(fn: (tx: SqlExecutor) => Promise<T>): Promise<T> {
      const client = await pool.connect();
      try {
        await client.query("BEGIN");
        const result = await fn(clientExecutor(client));
        await client.query("COMMIT");
        return result;
      } catch (error) {
        await client.query("ROLLBACK").catch(() => undefined);
        throw error;
      } finally {
        client.release();
      }
    },
  };
}
