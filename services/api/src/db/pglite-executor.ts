import type { PGlite, Transaction } from "@electric-sql/pglite";

import type { SqlExecutor } from "./executor.js";

/**
 * PGlite (PostgreSQL compiled to WebAssembly) adapter for the same
 * `SqlExecutor` interface node-postgres uses. Two callers only:
 *
 * - the database tests (`testing/databases.ts`), in memory;
 * - the local development server (`local/local-database.ts`), refused unless
 *   `APP_ENV` is exactly `local`.
 *
 * Type-only import: this module never loads PGlite itself, so production code
 * that imports it cannot start an embedded database by accident. PGlite runs
 * one query at a time and its `transaction()` holds the same lock as every
 * root query, so a transaction never interleaves with other requests.
 */
type PgliteQueryable = Pick<PGlite, "query" | "exec"> | Transaction;

export function pgliteExecutor(
  db: PgliteQueryable,
  inTransaction: boolean,
  root: PGlite,
): SqlExecutor {
  const self: SqlExecutor = {
    async query<R extends object>(text: string, params: readonly unknown[] = []) {
      const result = await db.query<R>(text, [...params]);
      return { rows: result.rows, rowCount: result.affectedRows ?? result.rows.length };
    },
    async execScript(sql: string) {
      await db.exec(sql);
    },
    transaction<T>(fn: (tx: SqlExecutor) => Promise<T>): Promise<T> {
      if (inTransaction) return fn(self);
      return root.transaction((tx) => fn(pgliteExecutor(tx, true, root)));
    },
  };
  return self;
}
