import pg from "pg";

import { apiConfigFromEnv } from "../config/api.js";
import { resolveAppEnv } from "./app-env.js";
import { parseTrustedProxies } from "./auth/client-address.js";
import { createCodeSender } from "./auth/code-sender.js";
import { loadAuthSecrets } from "./auth/secrets.js";
import { pgExecutor } from "./db/executor.js";
import { createApp } from "./http/app.js";
import { jsonLogger } from "./logger.js";

/**
 * Starts the API. Configuration comes from the environment (see
 * `.env.example`); secrets come from Secret Manager outside local
 * development. Migrations run separately (`pnpm db:migrate`).
 */
async function main(): Promise<void> {
  const env = process.env;
  const appEnv = resolveAppEnv(env["APP_ENV"]);
  const databaseUrl = env["DATABASE_URL"];
  if (databaseUrl === undefined || databaseUrl === "") throw new Error("DATABASE_URL is required");

  if (env["TRUST_PROXY"] !== undefined) {
    // Security review T-017 H1: a boolean trusts the client-written entry.
    throw new Error(
      "TRUST_PROXY is no longer read; set TRUSTED_PROXY_CIDRS to the load balancer ranges",
    );
  }
  const pool = new pg.Pool({ connectionString: databaseUrl });
  const app = await createApp({
    db: pgExecutor(pool),
    config: apiConfigFromEnv(env),
    secrets: loadAuthSecrets(env),
    // Local development only: the dev sender prints the code and challenge ID,
    // never the destination. `createCodeSender` refuses it outside local and test.
    codeSender: createCodeSender(env, (message) =>
      jsonLogger.info("dev_sign_in_code", { challengeId: message.challengeId, code: message.code }),
    ),
    logger: jsonLogger,
    trustedProxies: parseTrustedProxies(env["TRUSTED_PROXY_CIDRS"], env["APP_ENV"]),
  });

  const port = Number(env["PORT"] ?? "3000");
  await app.listen({ port, host: env["HOST"] ?? "127.0.0.1" });
  jsonLogger.info("api_started", { appEnv, port });

  const stop = () => {
    void app
      .close()
      .then(() => pool.end())
      .finally(() => process.exit(0));
  };
  process.once("SIGTERM", stop);
  process.once("SIGINT", stop);
}

main().catch((error: unknown) => {
  // Startup errors carry fixed messages (no secrets or contact details).
  jsonLogger.error("api_start_failed", {
    error: error instanceof Error ? error.message : "unknown",
  });
  process.exit(1);
});
