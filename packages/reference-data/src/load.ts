import { readFileSync, realpathSync } from "node:fs";
import { resolve } from "node:path";

import {
  FIXTURE_MARKER,
  ReferenceDataError,
  isFixturePath,
  verifyBuiltDataset,
  type VerifiedReference,
} from "./dataset-format.js";

/**
 * Deployment environments (docs/ARCHITECTURE.md section 8). Test fixtures may
 * be loaded only in `local` and `test`. A missing or unknown `APP_ENV` counts
 * as `production`, so a configuration mistake can only make loading stricter.
 */
export const APP_ENVIRONMENTS = ["local", "test", "staging", "production"] as const;
export type AppEnvironment = (typeof APP_ENVIRONMENTS)[number];

const FIXTURE_ENVIRONMENTS: readonly AppEnvironment[] = ["local", "test"];

export interface ReferenceDataConfig {
  readonly environment: AppEnvironment;
  /** Built dataset file written by `pnpm build:reference`. */
  readonly path: string;
  /** Pinned content hash. Required outside local development and tests. */
  readonly expectedSha256: string | null;
  readonly allowFixture: boolean;
}

/** File access used by the loader; tests replace it. */
export interface LoaderIo {
  readonly readFile: (path: string) => string;
  readonly realpath: (path: string) => string;
}

const nodeIo: LoaderIo = {
  readFile: (path) => readFileSync(path, "utf8"),
  realpath: (path) => realpathSync(path),
};

function fail(message: string): never {
  throw new ReferenceDataError(message);
}

function setting(env: Readonly<Record<string, string | undefined>>, name: string): string {
  return Object.hasOwn(env, name) ? (env[name] ?? "").trim() : "";
}

function refuseFixturePath(paths: readonly string[], environment: AppEnvironment): void {
  if (paths.some(isFixturePath)) {
    fail(`refusing reference data from the test fixtures folder in ${environment}`);
  }
}

/**
 * Reads the reference data settings: `APP_ENV`, `REFERENCE_DATA_PATH` and
 * `REFERENCE_DATA_SHA256`. Outside local development and tests, a path into
 * the fixtures folder is refused and a pinned hash is required.
 */
export function readReferenceDataConfig(
  env: Readonly<Record<string, string | undefined>>,
): ReferenceDataConfig {
  const named = setting(env, "APP_ENV");
  const environment = APP_ENVIRONMENTS.find((candidate) => candidate === named) ?? "production";
  const allowFixture = FIXTURE_ENVIRONMENTS.includes(environment);
  const path = setting(env, "REFERENCE_DATA_PATH");
  if (path === "") fail("REFERENCE_DATA_PATH is required (DAT-06)");
  if (!allowFixture) refuseFixturePath([path], environment);
  const pin = setting(env, "REFERENCE_DATA_SHA256").toLowerCase();
  if (pin !== "" && !/^[0-9a-f]{64}$/.test(pin)) {
    fail("REFERENCE_DATA_SHA256 must be 64 hexadecimal characters");
  }
  if (pin === "" && !allowFixture) {
    fail(`REFERENCE_DATA_SHA256 is required in ${environment}`);
  }
  return { environment, path, expectedSha256: pin === "" ? null : pin, allowFixture };
}

/**
 * Loads and verifies a built reference dataset. Throws `ReferenceDataError`
 * when it must not be used; the caller must then not evaluate anything, never
 * fall back to other data.
 */
export function loadReferenceDataset(
  config: ReferenceDataConfig,
  io: LoaderIo = nodeIo,
): VerifiedReference {
  const absolute = resolve(config.path);
  const attempt = (read: () => string): string => {
    try {
      return read();
    } catch (error) {
      return fail(`cannot read the reference dataset at ${absolute}: ${String(error)}`);
    }
  };
  const real = attempt(() => io.realpath(absolute));
  // The resolved path catches relative paths and symbolic links into the fixtures folder.
  if (!config.allowFixture) refuseFixturePath([absolute, real], config.environment);
  const text = attempt(() => io.readFile(real));
  if (!config.allowFixture && text.includes(FIXTURE_MARKER)) {
    fail(`refusing a test fixture dataset in ${config.environment}`);
  }
  let parsed: unknown;
  try {
    parsed = JSON.parse(text);
  } catch {
    return fail(`the reference dataset at ${absolute} is not valid JSON`);
  }
  return verifyBuiltDataset(parsed, {
    allowFixture: config.allowFixture,
    expectedSha256: config.expectedSha256,
  });
}

/** Reads the configuration from the environment, then loads and verifies the dataset. */
export function loadReferenceDataFromEnv(
  env: Readonly<Record<string, string | undefined>> = process.env,
  io: LoaderIo = nodeIo,
): VerifiedReference {
  return loadReferenceDataset(readReferenceDataConfig(env), io);
}
