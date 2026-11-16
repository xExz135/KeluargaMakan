#!/usr/bin/env node
// Engine boundary guard (SAF-01, SAF-12; T-025 security re-check N1). Only the
// package root `@keluargamakan/cek-aman` is the Cek Aman API. Its internals
// (for example `evaluateMember`) skip the input checks and can return "Safe"
// for a hand-built argument, so code outside packages/cek-aman must never
// reach into packages/cek-aman/src/** or dist/**: not by import, `new URL`,
// a test alias or any other path. Every occurrence of such a path in every JS
// or TS file outside the package is checked, comments included.
//
// The only deep paths allowed, each with no more power than the package root:
//   - src/index.(ts|js): the public entry itself (test aliases, the regression suite)
//   - src/vocabulary.(ts|js): closed value lists with no logic, read by tooling
//   - src/types.(ts|js): inside an `import type` or `export type` statement only
//
// Usage: node scripts/check-engine-imports.mjs

import { execFileSync } from "node:child_process";
import { readFileSync } from "node:fs";
import { pathToFileURL } from "node:url";

const SOURCE_FILE = /\.(?:[cm]?[jt]s|[jt]sx)$/;
/** A path into the engine package's sources or build output. */
const ENGINE_PATH = /\bcek-aman[\\/]+((?:src|dist)(?:[\\/][^"'`\s),;]*)?)(?=$|["'`\s),;])/g;
/** A subpath of the package name, which the exports map refuses anyway. */
const PACKAGE_SUBPATH = /@keluargamakan\/cek-aman\/[^"'`\s),;]*/g;
const TYPE_ONLY = /\b(?:import|export)\s+type\s[^;"'`]*?\bfrom\s*["'][^"'\n]+["']/g;
const ALWAYS_ALLOWED = /^src\/(?:index|vocabulary)\.[cm]?[jt]s$/;
const TYPES_ONLY = /^src\/types\.[cm]?[jt]s$/;

// This guard, its test and the matching lint rule name the paths they refuse.
const EXEMPT_FILES = new Set([
  "eslint.config.mjs",
  "scripts/check-engine-imports.mjs",
  "scripts/check-engine-imports.test.mjs",
]);

/** @param {string} path repository-relative path with forward slashes */
export function isChecked(path) {
  if (EXEMPT_FILES.has(path)) return false;
  if (path.startsWith("packages/cek-aman/")) return false;
  if (/(^|\/)(node_modules|dist|build|coverage)\//.test(path)) return false;
  return SOURCE_FILE.test(path);
}

/**
 * Why a path into the engine package is not allowed, or null.
 * @param {string} target the part after `cek-aman/`, for example `src/evaluate.js`
 * @param {boolean} typeOnly whether it is the specifier of a type-only import
 */
export function targetProblem(target, typeOnly) {
  const normalized = target.replaceAll("\\", "/").replace(/\/+/g, "/");
  if (ALWAYS_ALLOWED.test(normalized)) return null;
  if (TYPES_ONLY.test(normalized)) return typeOnly ? null : "src/types outside a type-only import";
  return `the engine internal ${normalized}`;
}

/**
 * @param {string[]} paths
 * @param {(path: string) => string} read
 * @returns {{ path: string, line: number, problem: string }[]}
 */
export function findViolations(paths, read) {
  const violations = [];
  for (const path of paths) {
    if (!isChecked(path)) continue;
    let code;
    try {
      code = read(path);
    } catch {
      continue; // deleted in the working tree
    }
    const typeSpans = [...code.matchAll(TYPE_ONLY)].map((m) => [m.index, m.index + m[0].length]);
    const inTypeOnly = (index) => typeSpans.some(([start, end]) => index >= start && index < end);
    const lineOf = (index) => code.slice(0, index).split("\n").length;
    for (const match of code.matchAll(ENGINE_PATH)) {
      const problem = targetProblem(match[1], inTypeOnly(match.index));
      if (problem !== null) violations.push({ path, line: lineOf(match.index), problem });
    }
    for (const match of code.matchAll(PACKAGE_SUBPATH)) {
      violations.push({
        path,
        line: lineOf(match.index),
        problem: `a subpath of the package (${match[0]})`,
      });
    }
  }
  return violations;
}

export function listRepoFiles() {
  const output = execFileSync(
    "git",
    ["ls-files", "-z", "--cached", "--others", "--exclude-standard"],
    { encoding: "utf8" },
  );
  return [...new Set(output.split("\0").filter(Boolean))];
}

export function checkRepo() {
  return findViolations(listRepoFiles(), (path) => readFileSync(path, "utf8"));
}

function main() {
  const violations = checkRepo();
  if (violations.length > 0) {
    console.error(
      "Engine boundary guard failed: code outside packages/cek-aman reaches its internals.",
    );
    console.error('Import Cek Aman only from "@keluargamakan/cek-aman" (SAF-01, SAF-12).\n');
    for (const v of violations) console.error(`  ${v.path}:${v.line}: ${v.problem}`);
    process.exit(1);
  }
  console.log(
    "Engine boundary guard passed: no code outside packages/cek-aman reaches its internals.",
  );
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  main();
}
