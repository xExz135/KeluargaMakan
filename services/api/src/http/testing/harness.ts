// TEST FIXTURE: not real safety or nutrition data. Test harness for the HTTP API.
import { randomBytes, randomUUID } from "node:crypto";
import { readFileSync } from "node:fs";

import type { NestFastifyApplication } from "@nestjs/platform-fastify";
import { Ajv2020 } from "ajv/dist/2020.js";
import { parse } from "yaml";

import { resolveApiConfig, type ApiConfig, type ApiConfigOverrides } from "../../../config/api.js";
import type { Clock } from "../../auth/auth-service.js";
import { DevCodeSender, type SignInCodeSender } from "../../auth/code-sender.js";
import type { AuthSecrets } from "../../auth/secrets.js";
import type { SqlExecutor } from "../../db/executor.js";
import type { ApiLogger, LogFields } from "../../logger.js";
import { createApp } from "../app.js";

/** A clock tests move by hand. */
export class TestClock implements Clock {
  #now: number;
  constructor(start = Date.parse("2026-11-12T03:00:00.000Z")) {
    this.#now = start;
  }
  now(): Date {
    return new Date(this.#now);
  }
  advance(seconds: number): void {
    this.#now += seconds * 1000;
  }
}

/** Keeps every log line, so tests can prove no contact detail, code or token is logged. */
export class CapturingLogger implements ApiLogger {
  readonly lines: string[] = [];
  info(event: string, fields: LogFields = {}): void {
    this.lines.push(JSON.stringify({ level: "info", event, ...fields }));
  }
  error(event: string, fields: LogFields = {}): void {
    this.lines.push(JSON.stringify({ level: "error", event, ...fields }));
  }
  get text(): string {
    return this.lines.join("\n");
  }
}

export function randomSecrets(): AuthSecrets {
  return { tokenKey: randomBytes(32), hashKey: randomBytes(32) };
}

let phoneCounter = 0;
/** A fictional, never-assigned phone number (no real personal data). */
export function fakePhone(): string {
  phoneCounter += 1;
  return `+6299${String(process.pid % 1000).padStart(3, "0")}${String(phoneCounter).padStart(6, "0")}`;
}

/** A fictional address on a reserved domain (RFC 2606). */
export function fakeEmail(): string {
  return `pengguna-${randomUUID().slice(0, 8)}@example.invalid`;
}

/** A random address in the 198.18.0.0/15 benchmarking range (RFC 2544). */
function randomClientAddress(): string {
  const [a = 0, b = 0, c = 0] = randomBytes(3);
  return `198.${18 + (a % 2)}.${b}.${c}`;
}

export function device(installationId: string = randomUUID()) {
  return { installationId, platform: "android", appVersion: "0.1.0" } as const;
}

export interface Response {
  readonly status: number;
  readonly headers: Readonly<Record<string, string | string[] | number | undefined>>;
  readonly body: unknown;
  readonly raw: string;
}

export interface Harness {
  readonly app: NestFastifyApplication;
  readonly clock: TestClock;
  readonly logger: CapturingLogger;
  readonly sender: DevCodeSender;
  readonly config: ApiConfig;
  readonly secrets: AuthSecrets;
  request(
    method: "GET" | "POST" | "PATCH",
    url: string,
    options?: {
      readonly body?: unknown;
      readonly rawBody?: string;
      readonly token?: string;
      readonly headers?: Readonly<Record<string, string>>;
      readonly ip?: string;
    },
  ): Promise<Response>;
  close(): Promise<void>;
}

export async function startHarness(
  db: SqlExecutor,
  options: {
    readonly config?: ApiConfigOverrides;
    readonly codeSender?: SignInCodeSender;
    /** Share another harness's secrets so its tokens are recognised. */
    readonly secrets?: AuthSecrets;
    readonly trustedProxies?: readonly string[] | true;
    /** APP_ENV the config floors are checked for (default `test`). */
    readonly appEnv?: string;
  } = {},
): Promise<Harness> {
  const clock = new TestClock();
  const logger = new CapturingLogger();
  const sender = new DevCodeSender({ appEnv: "test" });
  const config = resolveApiConfig(options.config ?? {}, { appEnv: options.appEnv ?? "test" });
  const secrets = options.secrets ?? randomSecrets();
  const app = await createApp({
    db,
    config,
    secrets,
    codeSender: options.codeSender ?? sender,
    logger,
    clock,
    ...(options.trustedProxies === undefined ? {} : { trustedProxies: options.trustedProxies }),
  });
  const fastify = app.getHttpAdapter().getInstance();
  return {
    app,
    clock,
    logger,
    sender,
    config,
    secrets,
    async request(method, url, requestOptions = {}) {
      const headers: Record<string, string> = { ...requestOptions.headers };
      if (requestOptions.token !== undefined)
        headers["authorization"] = `Bearer ${requestOptions.token}`;
      let payload: string | undefined;
      if (requestOptions.rawBody !== undefined) {
        payload = requestOptions.rawBody;
        headers["content-type"] ??= "application/json";
      } else if (requestOptions.body !== undefined) {
        payload = JSON.stringify(requestOptions.body);
        headers["content-type"] = "application/json";
      }
      const response = await fastify.inject({
        method,
        url,
        headers,
        // A fresh client address per request unless a test pins one (rate limits).
        remoteAddress: requestOptions.ip ?? randomClientAddress(),
        ...(payload === undefined ? {} : { payload }),
      });
      const raw = response.body;
      let body: unknown = null;
      if (raw !== "") {
        try {
          body = JSON.parse(raw);
        } catch {
          body = raw;
        }
      }
      return { status: response.statusCode, headers: response.headers, body, raw };
    },
    close: () => app.close(),
  };
}

// ---------------------------------------------------------------- contract schemas

const CONTRACT_ID = "https://contract.invalid/openapi.json";
const spec = parse(
  readFileSync(new URL("../../../../../packages/contracts/openapi.yaml", import.meta.url), "utf8"),
) as { components: unknown };
const ajv = new Ajv2020({ strict: false, allErrors: true, validateFormats: false });
ajv.addSchema({ $id: CONTRACT_ID, components: spec.components });

const validators = new Map<string, ReturnType<typeof ajv.compile>>();

/** Errors from validating `value` against a contract component schema (empty when valid). */
export function contractErrors(schemaName: string, value: unknown): string[] {
  let validate = validators.get(schemaName);
  if (validate === undefined) {
    validate = ajv.compile({ $ref: `${CONTRACT_ID}#/components/schemas/${schemaName}` });
    validators.set(schemaName, validate);
  }
  if (validate(value)) return [];
  return (validate.errors ?? []).map((error) => `${error.instancePath} ${error.message ?? ""}`);
}
