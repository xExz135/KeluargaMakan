import {
  loadReferenceDataFromEnv,
  ReferenceDataError,
  type VerifiedReference,
} from "@keluargamakan/reference-data";

import { ApiError } from "../api-error.js";
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

/** A source serving one verified dataset. Throws `CatalogFormatError` when a record cannot be read. */
export function referenceSourceOf(verified: VerifiedReference): ReferenceSource {
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
  try {
    const source = referenceSourceOf(loadReferenceDataFromEnv(env));
    const loaded = source.current();
    logger.info("reference_data_loaded", {
      referenceVersion: loaded?.verified.referenceVersion ?? null,
      fixture: loaded?.verified.fixture ?? null,
      ingredientCount: loaded?.verified.ingredientCount ?? null,
    });
    return source;
  } catch (error) {
    if (!(error instanceof ReferenceDataError) && !(error instanceof CatalogFormatError)) {
      throw error;
    }
    logger.error("reference_data_unavailable", { error: error.name, reason: error.message });
    return unavailableReference;
  }
}

export const referenceDataUnavailable = () =>
  new ApiError(
    "reference_data_unavailable",
    503,
    "The verified reference dataset is not available",
  );
