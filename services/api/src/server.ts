import { apiConfigFromEnv } from "../config/api.js";
import { kitchenConfigFromEnv } from "../config/kitchen.js";
import { libraryConfigFromEnv } from "../config/library.js";
import { profileConfigFromEnv } from "../config/profiles.js";
import { targetsFromEnv } from "../config/targets.js";
import { resolveAppEnv } from "./app-env.js";
import { parseTrustedProxies } from "./auth/client-address.js";
import { createCodeSender } from "./auth/code-sender.js";
import { loadAuthSecrets } from "./auth/secrets.js";
import { createKeyProvider } from "./db/crypto/config.js";
import type { SqlExecutor } from "./db/executor.js";
import { HealthDataKeys } from "./db/health-data-keys.js";
import { createApp } from "./http/app.js";
import { checkStaplesInReference } from "./kitchen/staples.js";
import { jsonLogger } from "./logger.js";
import {
  referenceSourceFromEnv,
  requireReferenceOutsideDevelopment,
} from "./reference/reference-data.js";

/** The database the API runs on, opened by the entry point. */
export interface ApiDatabase {
  readonly executor: SqlExecutor;
  close(): Promise<void>;
}

/**
 * Starts the API with configuration from the environment (see
 * `services/api/.env.example`). Every setting is checked before the database
 * is opened, so a bad configuration fails before any connection is made.
 *
 * Entry points: `main.ts` (node-postgres; every environment) and
 * `local/main-local.ts` (embedded PGlite; `APP_ENV=local` only).
 * SIGTERM, SIGINT or the returned `stop` closes the server, then the
 * database, then exits.
 */
export async function startApi(
  env: Readonly<Record<string, string | undefined>>,
  openDatabase: () => Promise<ApiDatabase>,
): Promise<{ readonly stop: () => void }> {
  const appEnv = resolveAppEnv(env["APP_ENV"]);

  if (env["TRUST_PROXY"] !== undefined) {
    // Security review T-017 H1: a boolean trusts the client-written entry.
    throw new Error(
      "TRUST_PROXY is no longer read; set TRUSTED_PROXY_CIDRS to the load balancer ranges",
    );
  }
  // DAT-06, SAF-13: the verified reference dataset. Outside local and test
  // the API refuses to start without it (security review T-030 L2). In local
  // and test it starts, and the catalog routes and reference-ingredient
  // writes answer 503 (fail closed).
  const reference = referenceSourceFromEnv(env, jsonLogger);
  requireReferenceOutsideDevelopment(reference, env["APP_ENV"]);
  const kitchenConfig = kitchenConfigFromEnv(env);
  const libraryConfig = libraryConfigFromEnv(env);
  checkStaplesInReference(kitchenConfig, reference);
  const config = apiConfigFromEnv(env);
  const targets = targetsFromEnv(env);
  const profileConfig = profileConfigFromEnv(env);
  // DAT-02: no default provider; a missing or unknown KEY_PROVIDER stops startup.
  // Cloud KMS needs its client, which T-023 wires in.
  const keys = new HealthDataKeys(createKeyProvider(env));
  const secrets = loadAuthSecrets(env);
  // Local development only: the dev sender prints the code and challenge ID,
  // never the destination. `createCodeSender` refuses it outside local and test.
  const codeSender = createCodeSender(env, (message) =>
    jsonLogger.info("dev_sign_in_code", { challengeId: message.challengeId, code: message.code }),
  );
  const trustedProxies = parseTrustedProxies(env["TRUSTED_PROXY_CIDRS"], env["APP_ENV"]);

  const database = await openDatabase();
  const app = await createApp({
    db: database.executor,
    config,
    targets,
    profileConfig,
    kitchenConfig,
    libraryConfig,
    // QUESTIONS #49: the kitchen, the search, likes, dislikes and rule
    // mappings all use this one verified dataset (createApp's default catalog).
    reference,
    keys,
    secrets,
    codeSender,
    logger: jsonLogger,
    trustedProxies,
  });

  const port = Number(env["PORT"] ?? "3000");
  await app.listen({ port, host: env["HOST"] ?? "127.0.0.1" });
  jsonLogger.info("api_started", { appEnv, port });

  let stopping = false;
  const stop = () => {
    if (stopping) return;
    stopping = true;
    void app
      .close()
      .then(() => database.close())
      .finally(() => process.exit(0));
  };
  process.once("SIGTERM", stop);
  process.once("SIGINT", stop);
  return { stop };
}

/** Logs a startup error (fixed messages: no secrets or contact details) and exits. */
export function exitOnStartFailure(error: unknown): never {
  jsonLogger.error("api_start_failed", {
    error: error instanceof Error ? error.message : "unknown",
  });
  process.exit(1);
}
