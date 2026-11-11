// TEST FIXTURE: not real safety or nutrition data. Test-only database targets.
import { randomBytes } from "node:crypto";

import { PGlite, type Transaction } from "@electric-sql/pglite";
import pg from "pg";

import { pgExecutor, type SqlExecutor } from "../executor.js";

/**
 * The database suite runs against every available target:
 *
 * - `pglite`: PostgreSQL 18 compiled to WebAssembly, in-process. Always
 *   available, so the suite runs on any machine and in CI without Docker.
 * - `postgres`: a real PostgreSQL server (the docker compose service, version
 *   17). Runs when `TEST_DATABASE_URL` is set; each run uses its own schema,
 *   dropped afterwards. Without it the target is skipped with a message.
 */

export interface TestDatabase {
  readonly executor: SqlExecutor;
  close(): Promise<void>;
}

export interface DatabaseTarget {
  readonly name: string;
  /** Null when available; otherwise why the target is skipped. */
  readonly skipReason: string | null;
  open(): Promise<TestDatabase>;
}

type PgliteQueryable = Pick<PGlite, "query" | "exec"> | Transaction;

function pgliteExecutor(db: PgliteQueryable, inTransaction: boolean, root: PGlite): SqlExecutor {
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

export const pgliteTarget: DatabaseTarget = {
  name: "pglite",
  skipReason: null,
  async open() {
    const db = await PGlite.create();
    return {
      executor: pgliteExecutor(db, false, db),
      close: () => db.close(),
    };
  },
};

const postgresUrl = process.env["TEST_DATABASE_URL"];

export const postgresTarget: DatabaseTarget = {
  name: "postgres",
  skipReason:
    postgresUrl === undefined || postgresUrl === ""
      ? "TEST_DATABASE_URL is not set (start `docker compose up postgres` and set it to run against PostgreSQL 17)"
      : null,
  async open() {
    if (postgresUrl === undefined) throw new Error("TEST_DATABASE_URL is not set");
    const schema = `t_${randomBytes(6).toString("hex")}`;
    const admin = new pg.Client({ connectionString: postgresUrl });
    await admin.connect();
    await admin.query(`CREATE SCHEMA ${schema}`);
    await admin.end();
    const pool = new pg.Pool({
      connectionString: postgresUrl,
      max: 4,
      options: `-c search_path=${schema}`,
    });
    return {
      executor: pgExecutor(pool),
      async close() {
        await pool.query(`DROP SCHEMA ${schema} CASCADE`);
        await pool.end();
      },
    };
  },
};

export const DATABASE_TARGETS: readonly DatabaseTarget[] = [pgliteTarget, postgresTarget];
