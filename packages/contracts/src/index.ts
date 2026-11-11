/**
 * API contracts. `openapi.yaml` in this package is the source of truth for API
 * shapes. `src/generated/schema.ts` (TypeScript) and `generated/dart` (Dart)
 * are generated from it by `scripts/generate.mjs` and must never be edited by
 * hand.
 */
import createClient, { type ClientOptions } from "openapi-fetch";

import type { components, operations, paths } from "./generated/schema.js";

export type { components, operations, paths };

export const CONTRACTS_PACKAGE = "@keluargamakan/contracts" as const;

/** Contract version, equal to `info.version` in openapi.yaml (a test checks this). */
export const CONTRACT_VERSION = "0.1.0" as const;

/** Every named schema in the contract, for example `Schemas["Profile"]`. */
export type Schemas = components["schemas"];

/** RFC 9457 error body returned by every endpoint. */
export type Problem = Schemas["Problem"];

/** Stable machine-readable error codes. Treat unknown codes like `internal_error`. */
export type ErrorCode = Schemas["ErrorCode"];

/**
 * Typed fetch client for the KeluargaMakan API (web and tooling). The mobile
 * app uses the generated Dart package `keluargamakan_api` instead.
 */
export function createApiClient(options: ClientOptions) {
  return createClient<paths>(options);
}

export type ApiClient = ReturnType<typeof createApiClient>;
