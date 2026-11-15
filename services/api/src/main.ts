import pg from "pg";

import { pgExecutor } from "./db/executor.js";
import { exitOnStartFailure, startApi } from "./server.js";

/**
 * Starts the API on PostgreSQL. Configuration comes from the environment (see
 * `.env.example`); secrets come from Secret Manager outside local
 * development. Migrations run separately (`pnpm db:migrate`).
 */
async function main(): Promise<void> {
  const env = process.env;
  const databaseUrl = env["DATABASE_URL"];
  if (databaseUrl === undefined || databaseUrl === "") throw new Error("DATABASE_URL is required");

  await startApi(env, () => {
    const pool = new pg.Pool({ connectionString: databaseUrl });
    return Promise.resolve({ executor: pgExecutor(pool), close: () => pool.end() });
  });
}

main().catch(exitOnStartFailure);
