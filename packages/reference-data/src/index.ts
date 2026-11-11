/**
 * Cek Aman reference data: the built dataset format and the loader the API
 * uses (DAT-06, SAF-13, NFR-20). The values themselves come only from the
 * content team; this package never writes or changes them.
 */
export {
  BUILT_DATASET_FORMAT,
  FIXTURE_COMMENT,
  FIXTURE_MARKER,
  FIXTURE_PATH_PATTERN,
  FIXTURE_VERSION_PREFIX,
  HASH_ALGORITHM,
  ReferenceDataError,
  SOURCE_DATASET_SCHEMA,
  canonicalJson,
  computeContentHash,
  createBuiltDataset,
  isFixturePath,
  looksLikeFixtureVersion,
  sha256Hex,
  verifyBuiltDataset,
  type BuildInput,
  type BuiltReferenceDataset,
  type ContentHash,
  type VerifiedReference,
  type VerifyOptions,
} from "./dataset-format.js";
export {
  APP_ENVIRONMENTS,
  loadReferenceDataFromEnv,
  loadReferenceDataset,
  readReferenceDataConfig,
  type AppEnvironment,
  type LoaderIo,
  type ReferenceDataConfig,
} from "./load.js";
