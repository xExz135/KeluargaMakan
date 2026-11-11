import "reflect-metadata";

import { randomUUID } from "node:crypto";

import { Catch, Module, type ArgumentsHost, type ExceptionFilter } from "@nestjs/common";
import { NestFactory } from "@nestjs/core";
import { FastifyAdapter, type NestFastifyApplication } from "@nestjs/platform-fastify";
import type { FastifyReply, FastifyRequest } from "fastify";

import type { ApiConfig } from "../../config/api.js";
import { readAccount } from "../auth/accounts.js";
import { AuthService, type Clock } from "../auth/auth-service.js";
import type { SignInCodeSender } from "../auth/code-sender.js";
import type { AuthSecrets } from "../auth/secrets.js";
import type { SqlExecutor } from "../db/executor.js";
import { HouseholdService } from "../households/household-service.js";
import type { ApiLogger } from "../logger.js";
import { AuthGuard } from "./auth.guard.js";
import { AccountController, AuthController, HouseholdController } from "./controllers.js";
import { toProblem } from "./problem.js";
import { ACCOUNT_READER, AUTH_SERVICE, HOUSEHOLD_SERVICE } from "./tokens.js";

export interface AppDeps {
  readonly db: SqlExecutor;
  readonly config: ApiConfig;
  readonly secrets: AuthSecrets;
  readonly codeSender: SignInCodeSender;
  readonly logger: ApiLogger;
  readonly clock?: Clock;
  /**
   * Proxy hops whose `X-Forwarded-For` entry is skipped when finding the
   * client address (security review H1): CIDR ranges from
   * `parseTrustedProxies`. Empty (the default) trusts no proxy. `true`
   * (trust every hop) is accepted only from `parseTrustedProxies` in local
   * and test.
   */
  readonly trustedProxies?: readonly string[] | true;
}

function trustProxyOption(trusted: readonly string[] | true | undefined): boolean | string[] {
  if (trusted === true) return true;
  if (trusted === undefined || trusted.length === 0) return false;
  // Fastify (proxy-addr) walks X-Forwarded-For from the right and stops at
  // the first address outside these ranges, so client-written entries on the
  // left are never used.
  return [...trusted];
}

/** Request bodies in this API are small JSON documents. */
const BODY_LIMIT_BYTES = 64 * 1024;

function sendProblem(
  error: unknown,
  request: FastifyRequest,
  reply: FastifyReply,
  logger: ApiLogger,
): void {
  const problem = toProblem(error, request.id);
  if (problem.status >= 500) {
    // Class or code only: never the message, which may come from a driver or vendor.
    logger.error("request_failed", {
      requestId: request.id,
      route: request.routeOptions.url ?? null,
      status: problem.status,
      error: problem.logName,
    });
  }
  if (problem.retryAfterSeconds !== null) {
    void reply.header("Retry-After", String(problem.retryAfterSeconds));
  }
  void reply
    .status(problem.status)
    .header("Content-Type", "application/problem+json")
    .send(JSON.stringify(problem.body));
}

/** Builds the API. The caller owns the database connection and closes the app. */
export async function createApp(deps: AppDeps): Promise<NestFastifyApplication> {
  const authService = new AuthService({
    db: deps.db,
    config: deps.config,
    secrets: deps.secrets,
    codeSender: deps.codeSender,
    ...(deps.clock === undefined ? {} : { clock: deps.clock }),
  });
  const householdService = new HouseholdService({
    db: deps.db,
    config: deps.config,
    hashKey: deps.secrets.hashKey,
    ...(deps.clock === undefined ? {} : { clock: deps.clock }),
  });

  @Catch()
  class ProblemFilter implements ExceptionFilter {
    catch(error: unknown, host: ArgumentsHost): void {
      const http = host.switchToHttp();
      sendProblem(
        error,
        http.getRequest<FastifyRequest>(),
        http.getResponse<FastifyReply>(),
        deps.logger,
      );
    }
  }

  @Module({
    controllers: [AuthController, AccountController, HouseholdController],
    providers: [
      AuthGuard,
      { provide: AUTH_SERVICE, useValue: authService },
      { provide: HOUSEHOLD_SERVICE, useValue: householdService },
      { provide: ACCOUNT_READER, useValue: { read: (id: string) => readAccount(deps.db, id) } },
    ],
  })
  class ApiModule {}

  const adapter = new FastifyAdapter({
    bodyLimit: BODY_LIMIT_BYTES,
    trustProxy: trustProxyOption(deps.trustedProxies),
    // Request IDs are always generated here; a client-supplied ID is ignored.
    requestIdHeader: false,
    genReqId: () => randomUUID(),
    logger: false,
  });
  const app = await NestFactory.create<NestFastifyApplication>(ApiModule, adapter, {
    logger: false,
    abortOnError: false,
  });
  app.useGlobalFilters(new ProblemFilter());

  const fastify = app.getHttpAdapter().getInstance();
  fastify.addHook("onResponse", (request, reply, done) => {
    deps.logger.info("request", {
      requestId: request.id,
      method: request.method,
      route: request.routeOptions.url ?? null,
      status: reply.statusCode,
    });
    done();
  });

  await app.init();
  await fastify.ready();
  return app;
}
