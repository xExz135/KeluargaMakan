import pg from "pg";

import { pgExecutor } from "../executor.js";
import { migrate } from "../migrate.js";

/**
 * `pnpm --filter @keluargamakan/api db:migrate` (after `build`). Reads
 * `DATABASE_URL` from the environment (Secret Manager in staging and
 * production, `.env` locally). Prints versions only, never the URL.
 */
async function main(): Promise<void> {
  const connectionString = process.env["DATABASE_URL"];
  if (connectionString === undefined || connectionString === "") {
    process.stderr.write("DATABASE_URL is not set\n");
    process.exitCode = 1;
    return;
  }
  const pool = new pg.Pool({ connectionString, max: 1 });
  try {
    const result = await migrate(pgExecutor(pool));
    process.stdout.write(
      `schema at version ${result.current}; applied: ${result.applied.join(", ") || "none"}\n`,
    );
  } finally {
    await pool.end();
  }
}

main().catch((error: unknown) => {
  process.stderr.write(`${error instanceof Error ? error.message : "migration failed"}\n`);
  process.exitCode = 1;
});
