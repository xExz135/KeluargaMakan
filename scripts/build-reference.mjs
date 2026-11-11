#!/usr/bin/env node
// Reference dataset build (SAF-06, SAF-13, DAT-06, NFR-20). Validates the
// source files (scripts/validate-reference.mjs), then writes one versioned
// dataset that the API loads with @keluargamakan/reference-data: the
// ingredients sorted by ID and copied exactly as written, the data version,
// the format version and a SHA-256 content hash.
//
// It never changes a value: an unverified section stays unverified, so the
// engine returns "Check the label" for it. Invalid data is rejected and
// nothing is written.
//
// Usage:
//   node scripts/build-reference.mjs [--source <dir>] [--out <file>]
//                                    [--max-component-depth <n>]
//   node scripts/build-reference.mjs --fixture --source <fixture dir> [--out <file>]
//
// Without --fixture the source must be real reference data: a source inside
// the test fixtures folder is refused. With --fixture every source file must
// carry the TEST FIXTURE marker and the output is flagged as a fixture, which
// the API refuses outside local development and tests.

import { mkdirSync, readFileSync, realpathSync, renameSync, rmSync, writeFileSync } from "node:fs";
import { dirname, isAbsolute, join, relative, resolve } from "node:path";
import { pathToFileURL } from "node:url";

import {
  createBuiltDataset,
  isFixturePath,
  verifyBuiltDataset,
} from "../packages/reference-data/src/dataset-format.ts";

import {
  REFERENCE_DIR,
  checkReferenceDir,
  displayPath,
  parseCommonArgs,
  reportIssues,
  repoRoot,
} from "./validate-reference.mjs";

export const DEFAULT_OUT_DIR = join(repoRoot, "dist", "reference-data");
const DATA_DIR = join(repoRoot, "data");

function realpathOrSelf(path) {
  try {
    return realpathSync(path);
  } catch {
    return path;
  }
}

const refuse = (error) => ({ ok: false, errors: [error], issues: [] });

function inside(parent, child) {
  const rel = relative(parent, child);
  return rel === "" || (!rel.startsWith("..") && !isAbsolute(rel));
}

/**
 * Builds the dataset. When nothing was written it returns `{ ok: false }` with
 * the validation `issues` or other `errors` (readable lines); otherwise
 * `{ ok: true, out, dataset }`.
 * @param {{ source?: string, out?: string, mode?: "reference" | "fixture", maxComponentDepth?: number }} options
 */
export function buildReference(options = {}) {
  const mode = options.mode ?? "reference";
  const fixture = mode === "fixture";
  const source = resolve(options.source ?? REFERENCE_DIR);
  const out = resolve(
    options.out ??
      join(DEFAULT_OUT_DIR, fixture ? "fixture-reference-dataset.json" : "reference-dataset.json"),
  );

  if (!fixture && [options.source ?? "", source, realpathOrSelf(source)].some(isFixturePath)) {
    return refuse(
      `${displayPath(source)}: refusing to build real reference data from the test fixtures ` +
        "folder; use --fixture for a test build",
    );
  }
  if (
    inside(DATA_DIR, out) ||
    inside(DATA_DIR, realpathOrSelf(dirname(out))) ||
    isFixturePath(out)
  ) {
    return refuse(`${displayPath(out)}: the built dataset must not be written inside data/`);
  }

  const check = checkReferenceDir(source, {
    mode,
    maxComponentDepth: options.maxComponentDepth,
  });
  if (check.issues.length > 0) return { ok: false, errors: [], issues: check.issues };
  if (check.fileCount === 0 || check.version === null) {
    return refuse(`${displayPath(source)}: no reference files found; nothing to build`);
  }

  const dataset = createBuiltDataset({
    version: check.version,
    fixture,
    ingredients: check.ingredients,
  });
  mkdirSync(dirname(out), { recursive: true });
  const temporary = `${out}.tmp-${process.pid}`;
  writeFileSync(temporary, `${JSON.stringify(dataset, null, 2)}\n`, "utf8");
  try {
    // Read it back exactly as the API will, pinned to the hash just computed,
    // before it replaces any earlier build.
    verifyBuiltDataset(JSON.parse(readFileSync(temporary, "utf8")), {
      allowFixture: fixture,
      expectedSha256: dataset.contentHash.value,
    });
  } catch (error) {
    rmSync(temporary, { force: true });
    throw error;
  }
  renameSync(temporary, out);
  return { ok: true, out, dataset };
}

/** @returns {number} exit code */
export function main(argv) {
  let args;
  try {
    args = parseCommonArgs(argv, { source: { type: "string" }, out: { type: "string" } });
  } catch (error) {
    console.error(error.message);
    return 2;
  }
  const { values, mode, maxComponentDepth } = args;
  const result = buildReference({
    source: values.source,
    out: values.out,
    mode,
    maxComponentDepth,
  });
  if (!result.ok && result.issues.length > 0) {
    return reportIssues("Reference data validation failed; nothing was built:", result.issues);
  }
  if (!result.ok) {
    for (const error of result.errors) console.error(error);
    return 1;
  }
  const { dataset, out } = result;
  console.log(
    [
      `Built ${dataset.fixture ? "TEST FIXTURE " : ""}reference dataset ${dataset.version}`,
      `  ingredients: ${dataset.ingredientCount}`,
      `  format:      ${dataset.format}`,
      `  sha256:      ${dataset.contentHash.value}`,
      `  written to:  ${displayPath(out)}`,
      "Configure the API with REFERENCE_DATA_PATH=<this file> and " +
        `REFERENCE_DATA_SHA256=${dataset.contentHash.value}`,
    ].join("\n"),
  );
  return 0;
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  process.exitCode = main(process.argv.slice(2));
}
