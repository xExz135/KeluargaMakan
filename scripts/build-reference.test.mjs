// TEST FIXTURE: not real safety or nutrition data
//
// Tests for the reference dataset build. Every ingredient value is fictional:
// the source files are the reference-import fixtures, or records built here in
// a temporary folder. Nothing is written to the reference data folder.

import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { existsSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { after, describe, it } from "node:test";

import {
  BUILT_DATASET_FORMAT,
  FIXTURE_COMMENT,
  verifyBuiltDataset,
} from "../packages/reference-data/src/dataset-format.ts";

import { buildReference, main } from "./build-reference.mjs";
import { INGREDIENT_DATASET, listFiles, repoRoot } from "./validate-reference.mjs";

const VALID = join(repoRoot, "data", "fixtures", "reference-import", "valid");
const INVALID = join(repoRoot, "data", "fixtures", "reference-import", "invalid");
const work = mkdtempSync(join(tmpdir(), "km-build-"));
after(() => rmSync(work, { recursive: true, force: true }));
const out = (name) => join(work, name);

const sourceRecords = () =>
  listFiles(VALID).flatMap((path) => JSON.parse(readFileSync(path, "utf8")).ingredients);

/** Every `verification` value and brand `verified` flag, by location. */
function verificationStates(records) {
  const states = {};
  for (const record of records) {
    for (const section of ["components", "allergens", "halal", "diet"]) {
      states[`${record.id}.${section}`] = record[section].verification;
    }
    for (const variant of record.brandVariants) {
      states[`${record.id}.${variant.brandId}.verified`] = variant.verified;
      for (const section of ["components", "allergens", "halal", "diet"]) {
        states[`${record.id}.${variant.brandId}.${section}`] = variant[section].verification;
      }
    }
  }
  return states;
}

describe("DAT-06 SAF-13 NFR-20 reference dataset build", () => {
  it("DAT-06 builds a versioned, hashed dataset from the fixture source files", () => {
    const result = buildReference({ source: VALID, out: out("a.json"), mode: "fixture" });
    assert.equal(result.ok, true, JSON.stringify(result));
    const written = JSON.parse(readFileSync(result.out, "utf8"));
    assert.deepEqual(written, result.dataset);
    assert.equal(written.$comment, FIXTURE_COMMENT);
    assert.equal(written.format, BUILT_DATASET_FORMAT);
    assert.equal(written.schema, INGREDIENT_DATASET);
    assert.equal(written.version, "TEST-FIXTURE-reference-import-1");
    assert.equal(written.fixture, true);
    assert.equal(written.ingredientCount, 12);
    assert.match(written.contentHash.value, /^[0-9a-f]{64}$/);
    const ids = written.ingredients.map((record) => record.id);
    assert.deepEqual(ids, [...ids].sort());
    const verified = verifyBuiltDataset(written, {
      allowFixture: true,
      expectedSha256: written.contentHash.value,
    });
    assert.equal(
      verified.referenceVersion,
      `TEST-FIXTURE-reference-import-1@sha256:${written.contentHash.value}`,
    );
  });

  it("SAF-07 SAF-09 copies every record exactly: unverified data stays unverified", () => {
    const { dataset } = buildReference({ source: VALID, out: out("b.json"), mode: "fixture" });
    const source = sourceRecords();
    const byId = new Map(dataset.ingredients.map((record) => [record.id, record]));
    assert.equal(byId.size, source.length);
    for (const record of source) assert.deepEqual(byId.get(record.id), record, record.id);
    const states = verificationStates(dataset.ingredients);
    assert.deepEqual(states, verificationStates(source));
    // The fixtures include unverified sections and an unverified brand, so the
    // comparison above is meaningful.
    assert.equal(states["fx_imp_petis.components"], "unverified");
    assert.equal(states["fx_imp_kaldu.allergens"], "unverified");
    assert.equal(states["fx_imp_kecap.fx_imp_merek_b.verified"], false);
  });

  it("DAT-06 the build is deterministic: same sources, same bytes and hash", () => {
    buildReference({ source: VALID, out: out("c1.json"), mode: "fixture" });
    buildReference({ source: VALID, out: out("c2.json"), mode: "fixture" });
    assert.equal(readFileSync(out("c1.json"), "utf8"), readFileSync(out("c2.json"), "utf8"));
  });

  it("SAF-13 rejects invalid source data and writes nothing", () => {
    const target = out("invalid.json");
    const result = buildReference({ source: INVALID, out: target, mode: "fixture" });
    assert.equal(result.ok, false);
    assert.equal(result.issues.length, 17);
    assert.equal(existsSync(target), false);
  });

  it("SAF-13 refuses to build real reference data from the fixtures folder", () => {
    for (const source of [
      VALID,
      join(repoRoot, "data", "reference", "..", "fixtures", "reference-import", "valid"),
    ]) {
      const result = buildReference({ source, out: out("refused.json") });
      assert.equal(result.ok, false);
      assert.match(
        result.errors[0],
        /refusing to build real reference data from the test fixtures/,
      );
    }
    assert.equal(existsSync(out("refused.json")), false);
  });

  it("SAF-13 refuses to write the built dataset inside data/", () => {
    for (const target of [
      join(repoRoot, "data", "reference", "built.json"),
      join(repoRoot, "data", "built.json"),
    ]) {
      const result = buildReference({ source: VALID, out: target, mode: "fixture" });
      assert.equal(result.ok, false);
      assert.match(result.errors[0], /must not be written inside data\//);
      assert.equal(existsSync(target), false);
    }
  });

  it("DAT-06 an empty source folder builds nothing (the real folder is empty until T-014)", () => {
    const result = buildReference({ out: out("empty.json") });
    assert.equal(result.ok, false);
    assert.match(result.errors[0], /no reference files found; nothing to build/);
  });

  it("DAT-06 a real (non-fixture) build is not flagged and loads as production data", () => {
    const source = mkdtempSync(join(work, "real-"));
    const record = JSON.parse(readFileSync(join(VALID, "basics.json"), "utf8")).ingredients[0];
    writeFileSync(
      join(source, "a.json"),
      JSON.stringify({ schema: INGREDIENT_DATASET, version: "2026.11.0", ingredients: [record] }),
    );
    const result = buildReference({ source, out: out("real.json") });
    assert.equal(result.ok, true, JSON.stringify(result));
    assert.equal(result.dataset.fixture, false);
    assert.equal(Object.hasOwn(result.dataset, "$comment"), false);
    const verified = verifyBuiltDataset(JSON.parse(readFileSync(result.out, "utf8")), {
      allowFixture: false,
      expectedSha256: result.dataset.contentHash.value,
    });
    assert.equal(verified.fixture, false);
  });

  it("DAT-06 a built dataset changed after the build is refused", () => {
    const { out: path } = buildReference({ source: VALID, out: out("d.json"), mode: "fixture" });
    const data = JSON.parse(readFileSync(path, "utf8"));
    const petis = data.ingredients.find((record) => record.id === "fx_imp_petis");
    petis.components.verification = "verified";
    assert.throws(
      () => verifyBuiltDataset(data, { allowFixture: true, expectedSha256: null }),
      /content hash does not match/,
    );
  });
});

describe("SAF-13 build command line", () => {
  const cli = (...args) => {
    try {
      const stdout = execFileSync(
        process.execPath,
        [join(repoRoot, "scripts", "build-reference.mjs"), ...args],
        { encoding: "utf8", stdio: ["ignore", "pipe", "pipe"] },
      );
      return { code: 0, stdout, stderr: "" };
    } catch (error) {
      return { code: error.status, stdout: error.stdout, stderr: error.stderr };
    }
  };

  it("SAF-13 prints the version, hash and API settings on success", () => {
    const target = out("cli.json");
    const result = cli("--fixture", "--source", VALID, "--out", target);
    assert.equal(result.code, 0, result.stderr);
    const { contentHash } = JSON.parse(readFileSync(target, "utf8"));
    assert.match(
      result.stdout,
      /Built TEST FIXTURE reference dataset TEST-FIXTURE-reference-import-1/,
    );
    assert.match(result.stdout, new RegExp(`REFERENCE_DATA_SHA256=${contentHash.value}`));
  });

  it("SAF-13 exits 1 with located errors, 1 on a refusal and 2 on bad arguments", () => {
    const invalid = cli("--fixture", "--source", INVALID, "--out", out("cli-bad.json"));
    assert.equal(invalid.code, 1);
    assert.match(invalid.stderr, /nothing was built/);
    assert.match(invalid.stderr, /ingredient fx_bad_deep_00 \(ingredients\[3\]\)/);
    const refused = cli("--source", VALID, "--out", out("cli-refused.json"));
    assert.equal(refused.code, 1);
    assert.match(refused.stderr, /refusing to build real reference data/);
    assert.equal(cli("--max-component-depth", "-1").code, 2);
  });

  it("SAF-13 main() returns 1 when the build is refused", () => {
    // Only the refusal path runs here, so nothing is written.
    assert.equal(main(["--source", VALID]), 1);
  });
});
