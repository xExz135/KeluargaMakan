import { isAbsolute } from "node:path";
import { pathToFileURL } from "node:url";

import { migrate } from "../db/migrate.js";
import { jsonLogger } from "../logger.js";
import { exitOnStartFailure, startApi } from "../server.js";
import { openLocalDatabase, requireExactlyLocal } from "./local-database.js";

/**
 * Local test server entry, started by `pnpm dev:local` (scripts/dev-local.mjs)
 * for the owner to click through the app on an Android emulator. It runs the
 * same API as `main.ts` on an embedded PGlite database in a git-ignored
 * folder, applies the migrations, then listens.
 *
 * Refused unless `APP_ENV` is exactly `local`. It also refuses a
 * `DATABASE_URL` (this server never connects to a database server) and any
 * key provider other than the local one.
 */
export interface LocalServerSettings {
  readonly dataDir: string;
}

export function localServerSettings(
  env: Readonly<Record<string, string | undefined>>,
): LocalServerSettings {
  requireExactlyLocal(env["APP_ENV"], "the local test server");
  if ((env["DATABASE_URL"] ?? "") !== "") {
    throw new Error("the local test server uses its embedded database; unset DATABASE_URL");
  }
  if (env["KEY_PROVIDER"] !== "local") {
    throw new Error("the local test server needs KEY_PROVIDER=local");
  }
  const dataDir = env["LOCAL_PGLITE_DIR"] ?? "";
  if (dataDir === "" || !isAbsolute(dataDir)) {
    throw new Error("LOCAL_PGLITE_DIR must be an absolute path");
  }
  return { dataDir };
}

async function main(): Promise<void> {
  const env = process.env;
  const settings = localServerSettings(env);
  const { stop } = await startApi(env, async () => {
    const database = await openLocalDatabase({ appEnv: env["APP_ENV"], dataDir: settings.dataDir });
    try {
      const result = await migrate(database.executor);
      jsonLogger.info("local_database_ready", {
        schemaVersion: result.current,
        appliedMigrations: result.applied.length,
      });
    } catch (error) {
      await database.close();
      throw error;
    }
    return database;
  });
  // dev-local.mjs holds this pipe open and closes it to stop the server; it
  // also closes when that script ends in any way, so the server (and its
  // lock on the database folder) never outlives it. Works the same on
  // Windows, where a child process cannot be sent SIGINT.
  if (env["LOCAL_STOP_ON_STDIN_CLOSE"] === "1") {
    process.stdin.once("close", stop);
    process.stdin.once("end", stop);
    process.stdin.resume();
    if (process.stdin.readableEnded || process.stdin.destroyed) stop();
  }
}

if (process.argv[1] !== undefined && import.meta.url === pathToFileURL(process.argv[1]).href) {
  main().catch(exitOnStartFailure);
}
