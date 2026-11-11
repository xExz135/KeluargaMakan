/**
 * Built reference dataset format (DAT-06, SAF-13, SAF-14; PR #5 security
 * review M3).
 *
 * The build (`pnpm build:reference`) turns the validated files in the
 * reference folder into one built dataset: the ingredients sorted by ID, the
 * data version, a format version and a SHA-256 hash over canonical JSON. The
 * API loads only a built dataset whose hash matches its content (and, outside
 * local development, the hash pinned in its configuration).
 *
 * This file must stay free of runtime imports other than `node:` modules, and
 * use only erasable TypeScript syntax, so the Node build scripts can load it
 * directly (the same rule as `packages/cek-aman/src/vocabulary.ts`). It never
 * changes ingredient values: the build copies every record as written, so
 * unverified data stays unverified.
 */
import { createHash } from "node:crypto";

import type { ReferenceDataset, ReferenceIngredient } from "@keluargamakan/cek-aman";

/** Format version of a built dataset file. Bump it when the envelope changes. */
export const BUILT_DATASET_FORMAT = "keluargamakan.reference.build/1";

/** `schema` of the source files and of the built dataset. Equals the engine's `INGREDIENT_DATASET_SCHEMA` (checked by a test). */
export const SOURCE_DATASET_SCHEMA = "keluargamakan.reference.ingredients/1";

export const HASH_ALGORITHM = "sha256";

/** Text that marks test fixtures. Never allowed in production data. */
export const FIXTURE_MARKER = "TEST FIXTURE";

/** `$comment` that every fixture source file and every fixture build carries. */
export const FIXTURE_COMMENT = "TEST FIXTURE: not real safety or nutrition data";

/** Every fixture data version starts with this, so logs show fixture use. */
export const FIXTURE_VERSION_PREFIX = "TEST-FIXTURE";

const FIXTURE_VERSION_PATTERN = /test[-_ ]?fixture/i;

/**
 * A path into the repository's test fixtures folder. Same pattern as the CI
 * fixture guard (`scripts/check-fixture-refs.mjs`), so anything the guard
 * would flag in configuration is also refused at run time.
 */
export const FIXTURE_PATH_PATTERN = /data[\\/]+fixtures/i;

const SHA256_HEX = /^[0-9a-f]{64}$/;

const BUILT_KEYS = new Set([
  "$comment",
  "format",
  "schema",
  "version",
  "fixture",
  "ingredientCount",
  "contentHash",
  "ingredients",
]);

export interface ContentHash {
  readonly algorithm: typeof HASH_ALGORITHM;
  /** Lowercase hex SHA-256 of the canonical JSON of every other field. */
  readonly value: string;
}

/** The file the build writes and the API loads. */
export interface BuiltReferenceDataset {
  /** Present only on fixture builds, and then always `FIXTURE_COMMENT`. */
  readonly $comment?: string;
  readonly format: typeof BUILT_DATASET_FORMAT;
  readonly schema: typeof SOURCE_DATASET_SCHEMA;
  /** Data version from the source files (DAT-06). */
  readonly version: string;
  /** True only for datasets built from test fixtures. */
  readonly fixture: boolean;
  readonly ingredientCount: number;
  readonly contentHash: ContentHash;
  /** Sorted by ID, each record exactly as written in the source files. */
  readonly ingredients: readonly ReferenceIngredient[];
}

/** A built dataset that passed `verifyBuiltDataset`. Deeply frozen. */
export interface VerifiedReference {
  /** Data version from the source files. */
  readonly version: string;
  /** Lowercase hex SHA-256 of the dataset content. */
  readonly contentHash: string;
  readonly fixture: boolean;
  readonly ingredientCount: number;
  /**
   * The version string to record with every result (DAT-06, SAF-14):
   * `<version>@sha256:<contentHash>`, so a log names the exact data used even
   * if two datasets ever share a version string.
   */
  readonly referenceVersion: string;
  /** Engine input; its `version` is `referenceVersion`. */
  readonly reference: ReferenceDataset;
}

export interface VerifyOptions {
  /** True only in local development and tests. */
  readonly allowFixture: boolean;
  /** Hash pinned in configuration, or null when none is configured. */
  readonly expectedSha256: string | null;
}

/** Thrown when reference data must not be used. The caller must not fall back to other data. */
export class ReferenceDataError extends Error {
  override readonly name = "ReferenceDataError";
}

function fail(message: string): never {
  throw new ReferenceDataError(message);
}

function isPlainObject(value: unknown): value is Readonly<Record<string, unknown>> {
  if (typeof value !== "object" || value === null || Array.isArray(value)) return false;
  const proto: unknown = Object.getPrototypeOf(value);
  return proto === Object.prototype || proto === null;
}

/**
 * Canonical JSON in the style of RFC 8785: object keys sorted by UTF-16 code
 * unit, no whitespace, JSON.stringify for strings and numbers. Throws on any
 * value plain JSON cannot hold, so no two different datasets share a text.
 */
export function canonicalJson(value: unknown): string {
  if (value === null || typeof value === "boolean" || typeof value === "string") {
    return JSON.stringify(value);
  }
  if (typeof value === "number") {
    if (!Number.isFinite(value))
      throw new TypeError("canonical JSON cannot hold a non-finite number");
    return JSON.stringify(value);
  }
  if (Array.isArray(value)) {
    const list: readonly unknown[] = value;
    const items = Array.from({ length: list.length }, (_, index) => {
      if (!Object.hasOwn(list, index))
        throw new TypeError("canonical JSON cannot hold an array hole");
      return canonicalJson(list[index]);
    });
    return `[${items.join(",")}]`;
  }
  if (isPlainObject(value)) {
    const keys = Object.keys(value).sort();
    return `{${keys.map((key) => `${JSON.stringify(key)}:${canonicalJson(value[key])}`).join(",")}}`;
  }
  throw new TypeError(`canonical JSON cannot hold a value of type ${typeof value}`);
}

export function sha256Hex(text: string): string {
  return createHash(HASH_ALGORITHM).update(text, "utf8").digest("hex");
}

/** Hash of every field except `contentHash` itself. */
export function computeContentHash(dataset: Readonly<Record<string, unknown>>): string {
  const body: Record<string, unknown> = {};
  for (const key of Object.keys(dataset)) {
    if (key !== "contentHash") body[key] = dataset[key];
  }
  return sha256Hex(canonicalJson(body));
}

export function looksLikeFixtureVersion(version: string): boolean {
  return FIXTURE_VERSION_PATTERN.test(version);
}

/** True when a path points into the test fixtures folder (see `FIXTURE_PATH_PATTERN`). */
export function isFixturePath(path: string): boolean {
  return FIXTURE_PATH_PATTERN.test(path);
}

export interface BuildInput {
  readonly version: string;
  readonly fixture: boolean;
  /** Validated records. They are copied as written, never changed. */
  readonly ingredients: readonly ReferenceIngredient[];
}

/**
 * Builds the dataset file content. Records are sorted by ID so the hash does
 * not depend on file order, and are deep-copied without any change, so a
 * verification status is never upgraded.
 */
export function createBuiltDataset(input: BuildInput): BuiltReferenceDataset {
  if (input.fixture !== looksLikeFixtureVersion(input.version)) {
    fail(
      input.fixture
        ? `a fixture dataset version must start with ${FIXTURE_VERSION_PREFIX}`
        : `version ${JSON.stringify(input.version)} looks like a test fixture version`,
    );
  }
  const ingredients = structuredClone([...input.ingredients]).sort((a, b) =>
    a.id < b.id ? -1 : a.id > b.id ? 1 : 0,
  );
  const body = {
    ...(input.fixture ? { $comment: FIXTURE_COMMENT } : {}),
    format: BUILT_DATASET_FORMAT,
    schema: SOURCE_DATASET_SCHEMA,
    version: input.version,
    fixture: input.fixture,
    ingredientCount: ingredients.length,
    ingredients,
  } as const;
  return {
    ...body,
    contentHash: { algorithm: HASH_ALGORITHM, value: computeContentHash(body) },
  };
}

function deepFreeze<T>(root: T): T {
  const pending: unknown[] = [root];
  while (pending.length > 0) {
    const value = pending.pop();
    if (typeof value === "object" && value !== null && !Object.isFrozen(value)) {
      Object.freeze(value);
      for (const child of Object.values(value) as unknown[]) pending.push(child);
    }
  }
  return root;
}

function copyOf(raw: unknown): unknown {
  try {
    return structuredClone(raw);
  } catch {
    return fail("reference dataset is not plain JSON data");
  }
}

/**
 * Checks a parsed built dataset and returns the engine input. Refuses
 * (throws `ReferenceDataError`) when the format or schema is unknown, a field
 * is missing or extra, the content hash does not match the content, the hash
 * differs from the pinned one, or the dataset is a test fixture and fixtures
 * are not allowed. Works on a private copy, so later changes to `raw` cannot
 * change what was verified.
 */
export function verifyBuiltDataset(raw: unknown, options: VerifyOptions): VerifiedReference {
  const data = copyOf(raw);
  if (!isPlainObject(data)) fail("reference dataset must be a JSON object");
  for (const key of Object.keys(data)) {
    if (!BUILT_KEYS.has(key)) fail(`reference dataset has an unknown field ${JSON.stringify(key)}`);
  }
  const { format, schema, version, fixture, ingredientCount, contentHash, ingredients } = data;
  if (format !== BUILT_DATASET_FORMAT) {
    fail(
      `unknown reference dataset format ${JSON.stringify(format)}; expected ${BUILT_DATASET_FORMAT}`,
    );
  }
  if (schema !== SOURCE_DATASET_SCHEMA) {
    fail(
      `unknown reference data schema ${JSON.stringify(schema)}; expected ${SOURCE_DATASET_SCHEMA}`,
    );
  }
  if (typeof version !== "string" || !/\S/.test(version)) {
    fail("reference dataset version is required (DAT-06)");
  }
  if (typeof fixture !== "boolean") fail("reference dataset must say whether it is a fixture");
  if (!Array.isArray(ingredients)) fail("reference dataset ingredients must be a list");
  const list: readonly unknown[] = ingredients;
  if (ingredientCount !== list.length) {
    fail(`ingredientCount ${String(ingredientCount)} does not match ${list.length} ingredients`);
  }
  const ids = new Set<string>();
  for (const [index, record] of list.entries()) {
    const id = isPlainObject(record) ? record.id : undefined;
    if (typeof id !== "string" || id === "") fail(`ingredients[${index}] has no id`);
    if (ids.has(id)) fail(`duplicate ingredient id ${id}`);
    ids.add(id);
  }
  if (
    !isPlainObject(contentHash) ||
    contentHash.algorithm !== HASH_ALGORITHM ||
    typeof contentHash.value !== "string" ||
    !SHA256_HEX.test(contentHash.value) ||
    Object.keys(contentHash).length !== 2
  ) {
    fail("reference dataset contentHash must be { algorithm: sha256, value: <64 lowercase hex> }");
  }
  const hash = computeContentHash(data);
  if (hash !== contentHash.value) {
    fail("reference dataset content hash does not match its content: it changed after the build");
  }
  if (options.expectedSha256 !== null && hash !== options.expectedSha256) {
    fail(`reference dataset hash ${hash} is not the configured hash ${options.expectedSha256}`);
  }
  const marked = looksLikeFixtureVersion(version) || canonicalJson(data).includes(FIXTURE_MARKER);
  if (!fixture && (marked || Object.hasOwn(data, "$comment"))) {
    fail("reference dataset is marked as real data but carries test fixture markers");
  }
  if (fixture && !looksLikeFixtureVersion(version)) {
    fail(`a fixture dataset version must start with ${FIXTURE_VERSION_PREFIX}`);
  }
  if (fixture && !options.allowFixture) {
    fail("refusing a test fixture dataset outside local development and tests");
  }
  const referenceVersion = `${version}@${HASH_ALGORITHM}:${hash}`;
  // Frozen so nothing can change the records after their hash was checked.
  const reference = {
    schema: SOURCE_DATASET_SCHEMA,
    version: referenceVersion,
    ingredients: deepFreeze(list as readonly ReferenceIngredient[]),
  };
  return deepFreeze({
    version,
    contentHash: hash,
    fixture,
    ingredientCount: list.length,
    referenceVersion,
    reference,
  });
}
