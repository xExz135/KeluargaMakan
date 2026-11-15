import { isAbsolute } from "node:path";

import type { SqlExecutor } from "../db/executor.js";
import { pgliteExecutor } from "../db/pglite-executor.js";

/**
 * Embedded PostgreSQL (PGlite) for the owner's local test server
 * (`pnpm dev:local`). Private use on one machine, nothing deployed.
 *
 * Refused unless `APP_ENV` is exactly `local`: not `test`, not a value with
 * spaces or capitals, and never staging, production or a missing value. The
 * check runs before PGlite is loaded, and PGlite is a development dependency
 * of the API, so a production install does not even contain it. Production
 * and staging use node-postgres against Cloud SQL (`main.ts`).
 */
export class LocalOnlyError extends Error {
  constructor(what: string) {
    super(`${what} runs only with APP_ENV=local`);
    this.name = "LocalOnlyError";
  }
}

/** Throws unless `appEnv` is exactly "local". */
export function requireExactlyLocal(appEnv: string | undefined, what: string): void {
  if (appEnv !== "local") throw new LocalOnlyError(what);
}

export interface LocalDatabase {
  readonly executor: SqlExecutor;
  close(): Promise<void>;
}

export interface LocalDatabaseOptions {
  /** `APP_ENV`; must be exactly `local`. */
  readonly appEnv: string | undefined;
  /** Absolute folder for the database files (git-ignored `.local-dev/pgdata`). */
  readonly dataDir: string;
}

export async function openLocalDatabase(options: LocalDatabaseOptions): Promise<LocalDatabase> {
  requireExactlyLocal(options.appEnv, "the embedded local database");
  if (options.dataDir.trim() === "" || !isAbsolute(options.dataDir)) {
    throw new Error("the local database folder must be an absolute path");
  }
  // Loaded only after the check above.
  const { PGlite } = await import("@electric-sql/pglite");
  const db = await PGlite.create({ dataDir: options.dataDir });
  return { executor: pgliteExecutor(db, false, db), close: () => db.close() };
}
