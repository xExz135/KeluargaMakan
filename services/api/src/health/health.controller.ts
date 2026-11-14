import { Controller, Get, Inject, Res } from "@nestjs/common";
import type { FastifyReply } from "fastify";

import { Public } from "../authz/access.js";
import type { SqlExecutor } from "../db/executor.js";
import { HEALTH_CHECKS } from "../http/tokens.js";
import type { ReferenceSource } from "../reference/reference-data.js";

/**
 * Readiness probe for the load balancer and alerting (security review T-030
 * L2, T-076): 200 `{"status":"ready"}` when the database answers and a
 * verified reference dataset is loaded, else 503 `{"status":"not_ready"}`.
 * It says nothing about which check failed, holds no household data and
 * needs no token, so it is public. Operations only: it is not part of the
 * client contract (packages/contracts) and clients never call it.
 */

export interface HealthChecks {
  readonly db: SqlExecutor;
  readonly reference: ReferenceSource;
}

export type Readiness = { readonly status: "ready" } | { readonly status: "not_ready" };

async function databaseAnswers(db: SqlExecutor): Promise<boolean> {
  try {
    await db.query("SELECT 1");
    return true;
  } catch {
    return false;
  }
}

@Controller("health")
export class HealthController {
  constructor(@Inject(HEALTH_CHECKS) private readonly checks: HealthChecks) {}

  @Get("ready")
  @Public()
  async ready(@Res({ passthrough: true }) reply: FastifyReply): Promise<Readiness> {
    const ready =
      this.checks.reference.current() !== null && (await databaseAnswers(this.checks.db));
    void reply.header("Cache-Control", "no-store").status(ready ? 200 : 503);
    return ready ? { status: "ready" } : { status: "not_ready" };
  }
}
