#!/usr/bin/env node
// Fixture guard: test fixtures in data/fixtures/ must never be loaded outside
// tests. Fails if any non-test file in the repository references that folder
// (production config, infra, Dockerfiles, service code, env files and so on).
//
// Usage: node scripts/check-fixture-refs.mjs

import { execFileSync } from "node:child_process";
import { readFileSync } from "node:fs";
import { basename } from "node:path";
import { pathToFileURL } from "node:url";

export const FIXTURE_REF = /data[\\/]+fixtures/i;

// Paths where references to fixtures are expected: test code, the fixtures
// themselves, local-only dev config, and this guard. Workflows are not
// exempt: a deploy workflow is production configuration.
const EXEMPT_PREFIXES = ["tests/", "data/fixtures/"];
const EXEMPT_DIR_SEGMENTS = [
  "/test/",
  "/tests/",
  "/__tests__/",
  "/test_driver/",
  "/integration_test/",
];
const EXEMPT_FILES = new Set([
  "docker-compose.yml",
  "scripts/check-fixture-refs.mjs",
  "scripts/check-fixture-refs.test.mjs",
]);
const EXEMPT_BASENAME = [
  /\.(test|spec)\.[cm]?[jt]sx?$/,
  /^test_.*\.py$/,
  /_test\.(py|dart)$/,
  /^conftest\.py$/,
  /^vitest\.config\.[cm]?[jt]s$/,
];

/** @param {string} path repository-relative path with forward slashes */
export function isExempt(path) {
  if (EXEMPT_FILES.has(path)) return true;
  if (EXEMPT_PREFIXES.some((prefix) => path.startsWith(prefix))) return true;
  if (EXEMPT_DIR_SEGMENTS.some((segment) => `/${path}`.includes(segment))) return true;
  const name = basename(path);
  return EXEMPT_BASENAME.some((pattern) => pattern.test(name));
}

/**
 * @param {string[]} paths
 * @param {(path: string) => Buffer} read
 * @returns {{ path: string, line: number, text: string }[]}
 */
export function findViolations(paths, read) {
  const violations = [];
  for (const path of paths) {
    if (isExempt(path)) continue;
    let content;
    try {
      content = read(path);
    } catch {
      continue; // deleted in the working tree
    }
    if (content.subarray(0, 8000).includes(0)) continue; // binary
    const lines = content.toString("utf8").split(/\r?\n/);
    lines.forEach((text, index) => {
      if (FIXTURE_REF.test(text)) {
        violations.push({ path, line: index + 1, text: text.trim() });
      }
    });
  }
  return violations;
}

function listRepoFiles() {
  const output = execFileSync(
    "git",
    ["ls-files", "-z", "--cached", "--others", "--exclude-standard"],
    { encoding: "utf8" },
  );
  return [...new Set(output.split("\0").filter(Boolean))];
}

function main() {
  const violations = findViolations(listRepoFiles(), (path) => readFileSync(path));
  if (violations.length > 0) {
    console.error("Fixture guard failed: non-test files reference data/fixtures/.");
    console.error("Fixtures are test-only and must never be loaded outside tests.\n");
    for (const v of violations) {
      console.error(`  ${v.path}:${v.line}: ${v.text}`);
    }
    process.exit(1);
  }
  console.log("Fixture guard passed: no non-test file references data/fixtures/.");
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  main();
}
