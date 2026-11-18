import {
  loadReferenceDataFromEnv,
  ReferenceDataError,
  type VerifiedReference,
} from "@keluargamakan/reference-data";

import { ApiError } from "../api-error.js";
import { isDevelopmentEnv } from "../app-env.js";
import { isReferenceVersion } from "../db/ids.js";
import type { ApiLogger } from "../logger.js";
import { CatalogFormatError, IngredientCatalog } from "./ingredient-catalog.js";

/**
 * The reference dataset the API serves (DAT-06, SAF-13): the built dataset
 * from `REFERENCE_DATA_PATH`, verified by `@keluargamakan/reference-data`
 * (content hash, pinned hash outside local and test, no fixtures in
 * production), plus the catalog built from it.
 *
 * Fail closed: when the dataset is missing, fails verification or has a
 * record the catalog cannot read, `current()` is null. Callers then answer
 * 503 `reference_data_unavailable`; they never fall back to other data or to
 * an empty list that looks like "no results". The rest of the API keeps
 * working (the saved kitchen stays readable, AI-08).
 */
export interface LoadedReference {
  readonly verified: VerifiedReference;
  readonly catalog: IngredientCatalog;
}

export interface ReferenceSource {
  current(): LoadedReference | null;
}

export const unavailableReference: ReferenceSource = Object.freeze({ current: () => null });

/**
 * Security review T-041 L4: a version that safety results cannot record
 * (DAT-06, SAF-14) makes the dataset unusable, so food routes answer 503
 * `reference_data_unavailable` instead of failing at the log write.
 */
export class ReferenceVersionError extends Error {
  constructor() {
    super("the reference version cannot be recorded with safety results");
    this.name = "ReferenceVersionError";
  }
}

/**
 * A source serving one verified dataset. Throws `CatalogFormatError` when a
 * record cannot be read, and `ReferenceVersionError` when the version does
 * not match the logged version pattern or differs from the engine input.
 */
export function referenceSourceOf(verified: VerifiedReference): ReferenceSource {
  if (
    !isReferenceVersion(verified.referenceVersion) ||
    verified.reference.version !== verified.referenceVersion
  ) {
    throw new ReferenceVersionError();
  }
  const loaded: LoadedReference = Object.freeze({
    verified,
    catalog: new IngredientCatalog(verified),
  });
  return Object.freeze({ current: () => loaded });
}

/**
 * Loads the dataset named by the environment. Any loading, verification or
 * catalog error gives the unavailable source and one log line with the
 * error class only (the messages name file paths and hashes, not people).
 */
export function referenceSourceFromEnv(
  env: Readonly<Record<string, string | undefined>>,
  logger: ApiLogger,
): ReferenceSource {
  let verified: VerifiedReference;
  try {
    verified = loadReferenceDataFromEnv(env);
  } catch (error) {
    if (!(error instanceof ReferenceDataError)) throw error;
    logger.error("reference_data_unavailable", { error: error.name, reason: error.message });
    return unavailableReference;
  }
  return loggedReferenceSource(verified, logger);
}

/**
 * The source for a loaded dataset, or the unavailable source (with one log
 * line naming the error class) when its catalog or its version cannot be used.
 */
export function loggedReferenceSource(
  verified: VerifiedReference,
  logger: ApiLogger,
): ReferenceSource {
  try {
    const source = referenceSourceOf(verified);
    const loaded = source.current();
    logger.info("reference_data_loaded", {
      referenceVersion: loaded?.verified.referenceVersion ?? null,
      fixture: loaded?.verified.fixture ?? null,
      ingredientCount: loaded?.verified.ingredientCount ?? null,
    });
    return source;
  } catch (error) {
    if (!(error instanceof CatalogFormatError) && !(error instanceof ReferenceVersionError)) {
      throw error;
    }
    logger.error("reference_data_unavailable", { error: error.name, reason: error.message });
    return unavailableReference;
  }
}

/**
 * Security review T-030 L2: outside local development and tests the API
 * does not start without a verified dataset, so a wrong pin or a broken
 * content update fails the deploy loudly instead of serving a kitchen where
 * no reference ingredient can be added. Local and test keep starting, with
 * the catalog routes answering 503 and `/health/ready` not ready.
 */
export function requireReferenceOutsideDevelopment(
  reference: ReferenceSource,
  appEnv: string | undefined,
): void {
  if (reference.current() === null && !isDevelopmentEnv(appEnv)) {
    throw new Error(
      "no verified reference dataset is loaded (REFERENCE_DATA_PATH, REFERENCE_DATA_SHA256); " +
        "it is required outside APP_ENV local and test",
    );
  }
}

export const referenceDataUnavailable = () =>
  new ApiError(
    "reference_data_unavailable",
    503,
    "The verified reference dataset is not available",
  );
