import { createHash } from "node:crypto";

import type { SqlExecutor } from "./executor.js";
import { MIGRATIONS, type Migration } from "./migrations/index.js";

/**
 * Forward-only SQL migrations. ARCHITECTURE names no migration tool; this is a
 * deliberately small runner (in the style of node-pg-migrate or Flyway) so the
 * same migrations run on node-postgres and on PGlite in tests, without an ORM
 * or install scripts (pnpm `onlyBuiltDependencies: []`).
 *
 * - All pending migrations apply in one transaction, so a failure leaves the
 *   schema unchanged.
 * - A transaction-scoped advisory lock stops two instances from migrating at
 *   once.
 * - The checksum of every applied migration is checked, so an edited migration
 *   fails loudly instead of leaving environments out of step.
 * - A database with migrations this code does not know is refused.
 */

const MIGRATION_TABLE = "schema_migration";
/** Arbitrary constant shared by every API instance. */
const ADVISORY_LOCK_KEY = "7316002016";

export function migrationChecksum(migration: Migration): string {
  return createHash("sha256").update(migration.sql, "utf8").digest("hex");
}

export class MigrationError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "MigrationError";
  }
}

export function validateMigrationList(migrations: readonly Migration[]): void {
  migrations.forEach((migration, index) => {
    if (migration.version !== index + 1) {
      throw new MigrationError(
        `migration versions must be 1..n without gaps (found ${migration.version} at ${index})`,
      );
    }
    if (!/^[a-z0-9]+(-[a-z0-9]+)*$/.test(migration.name)) {
      throw new MigrationError(`migration ${migration.version} has an invalid name`);
    }
    if (migration.sql.trim() === "") {
      throw new MigrationError(`migration ${migration.version} is empty`);
    }
  });
}

interface AppliedRow {
  version: number;
  name: string;
  checksum: string;
}

export interface MigrateResult {
  readonly applied: readonly number[];
  readonly current: number;
}

export async function migrate(
  db: SqlExecutor,
  migrations: readonly Migration[] = MIGRATIONS,
): Promise<MigrateResult> {
  validateMigrationList(migrations);
  return db.transaction(async (tx) => {
    await tx.query(`SELECT pg_advisory_xact_lock(${ADVISORY_LOCK_KEY})`);
    await tx.execScript(`
      CREATE TABLE IF NOT EXISTS ${MIGRATION_TABLE} (
        version integer PRIMARY KEY,
        name text NOT NULL,
        checksum text NOT NULL,
        applied_at timestamptz NOT NULL DEFAULT now()
      );
    `);
    const { rows } = await tx.query<AppliedRow>(
      `SELECT version, name, checksum FROM ${MIGRATION_TABLE} ORDER BY version`,
    );
    for (const [index, row] of rows.entries()) {
      if (row.version !== index + 1) {
        throw new MigrationError(`applied migrations have a gap before ${row.version}`);
      }
      const known = migrations[row.version - 1];
      if (known === undefined) {
        throw new MigrationError(
          `database has migration ${row.version} (${row.name}) that this code does not know`,
        );
      }
      if (known.name !== row.name || migrationChecksum(known) !== row.checksum) {
        throw new MigrationError(
          `migration ${row.version} (${row.name}) was changed after it was applied`,
        );
      }
    }
    const applied: number[] = [];
    for (const migration of migrations.slice(rows.length)) {
      await tx.execScript(migration.sql);
      await tx.query(
        `INSERT INTO ${MIGRATION_TABLE} (version, name, checksum) VALUES ($1, $2, $3)`,
        [migration.version, migration.name, migrationChecksum(migration)],
      );
      applied.push(migration.version);
    }
    return { applied, current: migrations.length };
  });
}
