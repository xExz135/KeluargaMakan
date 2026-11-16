import assert from "node:assert/strict";
import { describe, it } from "node:test";

import { checkRepo, findViolations, isChecked, targetProblem } from "./check-engine-imports.mjs";

const files = {
  // Refused: engine internals, by any path.
  "services/api/src/planted.ts":
    'import { evaluateMember } from "../../../packages/cek-aman/src/evaluate.js";',
  "services/api/src/dist-planted.ts":
    'export * from "../../../packages/cek-aman/dist/evaluate.js";',
  "services/api/src/subpath.ts":
    'import { readContext } from "@keluargamakan/cek-aman/dist/log.js";',
  "services/api/src/dynamic.ts":
    'const m = await import("../../../packages/cek-aman/src/recipe/halal.js");',
  "packages/contracts/src/url.test.ts":
    'new URL("../../cek-aman/src/normalize.ts", import.meta.url);',
  "services/api/src/windows.ts": 'load("..\\\\..\\\\packages\\\\cek-aman\\\\src\\\\rules.ts");',
  "services/api/src/types-value.ts":
    'import { type ReferenceDataset } from "../../../packages/cek-aman/src/types.js";',
  "services/api/src/folder.ts": 'const dir = "../../packages/cek-aman/src";',
  "services/api/src/multiline.ts": [
    "import {",
    "  analyzeIngredient,",
    "  evaluateMember,",
    '} from "../../../packages/cek-aman/src/evaluate.js";',
  ].join("\n"),
  // Refused too: reading engine sources as text (T-025 rebase; use the package root's lists).
  "packages/contracts/src/text-read.test.ts":
    'const text = readFileSync(new URL("../../cek-aman/src/log.ts", import.meta.url), "utf8");',
  // Allowed.
  "packages/contracts/src/parity.test.ts":
    'import { REASON_CODES, SAFETY_SUBJECT_KINDS } from "@keluargamakan/cek-aman";',
  "services/api/src/root.ts": 'import { evaluate } from "@keluargamakan/cek-aman";',
  "services/api/vitest.config.ts":
    'alias: { "@keluargamakan/cek-aman": new URL("../../packages/cek-aman/src/index.ts", import.meta.url) }',
  "tests/safety-regression/cases.ts":
    'import { evaluate } from "../../packages/cek-aman/src/index.js";',
  "scripts/validate-reference.test.mjs":
    'import * as vocabulary from "../packages/cek-aman/src/vocabulary.ts";',
  "data/fixtures/cek-aman/members.fixture.ts": [
    "import type {",
    "  MemberRulesInput,",
    '} from "../../../packages/cek-aman/src/types.js";',
  ].join("\n"),
  "tests/safety-regression/ai-independence.test.ts":
    'const packageDir = new URL("../../packages/cek-aman/", import.meta.url);',
  "packages/cek-aman/src/recipe/halal.ts": 'import { evaluateMember } from "../evaluate.js";',
  "docs/notes.md": "packages/cek-aman/src/evaluate.ts",
};
const read = (path) => files[path];

describe("SAF-01 SAF-12 engine boundary guard (T-025 security re-check N1)", () => {
  it("SAF-01 refuses every path into the engine internals from outside the package", () => {
    const flagged = [...new Set(findViolations(Object.keys(files), read).map((v) => v.path))];
    assert.deepEqual(flagged.sort(), [
      "packages/contracts/src/text-read.test.ts",
      "packages/contracts/src/url.test.ts",
      "services/api/src/dist-planted.ts",
      "services/api/src/dynamic.ts",
      "services/api/src/folder.ts",
      "services/api/src/multiline.ts",
      "services/api/src/planted.ts",
      "services/api/src/subpath.ts",
      "services/api/src/types-value.ts",
      "services/api/src/windows.ts",
    ]);
  });

  it("SAF-01 reports the file, the line and why", () => {
    assert.deepEqual(findViolations(["services/api/src/multiline.ts"], read), [
      {
        path: "services/api/src/multiline.ts",
        line: 4,
        problem: "the engine internal src/evaluate.js",
      },
    ]);
  });

  it("SAF-01 allows only the public entry, the vocabulary and type-only imports of the types", () => {
    assert.equal(targetProblem("src/index.ts", false), null);
    assert.equal(targetProblem("src/index.js", false), null);
    assert.equal(targetProblem("src/vocabulary.ts", false), null);
    assert.equal(targetProblem("src/types.js", true), null);
    assert.match(targetProblem("src/types.js", false), /type-only/);
    assert.match(targetProblem("src/evaluate.js", true), /internal/);
    assert.match(targetProblem("dist/index.js", false), /internal/);
    assert.match(targetProblem("src/recipe/halal.ts", false), /internal/);
    assert.match(targetProblem("src", false), /internal/);
  });

  it("SAF-01 checks code everywhere except inside the engine package and build output", () => {
    assert.equal(isChecked("services/api/src/app.ts"), true);
    assert.equal(isChecked("services/api/test/app.test.ts"), true);
    assert.equal(isChecked("tests/safety-regression/cases.ts"), true);
    assert.equal(isChecked("data/fixtures/cek-aman/members.fixture.ts"), true);
    assert.equal(isChecked("scripts/validate-reference.mjs"), true);
    assert.equal(isChecked("packages/cek-aman/src/evaluate.ts"), false);
    assert.equal(isChecked("services/api/dist/app.js"), false);
    assert.equal(isChecked("docs/notes.md"), false);
    assert.equal(isChecked("eslint.config.mjs"), false);
  });

  it("SAF-01 SAF-12 no code in this repository reaches the engine internals", () => {
    assert.deepEqual(checkRepo(), []);
  });
});
