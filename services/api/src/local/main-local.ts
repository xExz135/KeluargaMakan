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
 * `DATABASE_URL` (this server never connects to a database server), any key
 * provider other than the local one, and a `HOST` that is not loopback
 * (security review 2026-11-15 L3): with the dev code sender and relaxed
 * sign-in limits it must never be reachable from the network.
 */
export const LOOPBACK_HOSTS: readonly string[] = ["127.0.0.1", "::1", "localhost"];

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
  const host = env["HOST"];
  if (host !== undefined && !LOOPBACK_HOSTS.includes(host)) {
    throw new Error(
      "the local test server listens on loopback only; HOST must be unset, 127.0.0.1, ::1 or localhost",
    );
  }
  const dataDir = env["LOCAL_PGLITE_DIR"] ?? "";
  if (dataDir === "" || !isAbsolute(dataDir)) {
    throw new Error("LOCAL_PGLITE_DIR must be an absolute path");
  }
  return { dataDir };
}

/** Grace period for a stop requested while the server is still starting. */
const STARTUP_STOP_TIMEOUT_MS = 10_000;

/**
 * dev-local.mjs holds stdin open and closes it to stop the server; it also
 * closes when that script ends in any way, so the server (and its hold on the
 * database folder) never outlives it. Works the same on Windows, where a
 * child process cannot be sent SIGINT. Attached before any startup work
 * (security review 2026-11-15 I1): a close during startup stops the server as
 * soon as it is up, and exits at the latest after a grace period.
 */
function stopOnStdinClose(): { serverStarted(stop: () => void): void } {
  const state: { stop: (() => void) | null; requested: boolean } = {
    stop: null,
    requested: false,
  };
  const request = () => {
    if (state.requested) return;
    state.requested = true;
    if (state.stop !== null) state.stop();
    else setTimeout(() => process.exit(0), STARTUP_STOP_TIMEOUT_MS).unref();
  };
  process.stdin.once("close", request);
  process.stdin.once("end", request);
  process.stdin.resume();
  if (process.stdin.readableEnded || process.stdin.destroyed) request();
  return {
    serverStarted(stop) {
      state.stop = stop;
      if (state.requested) stop();
    },
  };
}

async function main(): Promise<void> {
  const env = process.env;
  const settings = localServerSettings(env);
  const lifeline = env["LOCAL_STOP_ON_STDIN_CLOSE"] === "1" ? stopOnStdinClose() : null;
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
  lifeline?.serverStarted(stop);
}

if (process.argv[1] !== undefined && import.meta.url === pathToFileURL(process.argv[1]).href) {
  main().catch(exitOnStartFailure);
}
