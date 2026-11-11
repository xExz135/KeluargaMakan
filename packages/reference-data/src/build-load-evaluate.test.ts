// TEST FIXTURE: not real safety or nutrition data
//
// End to end: the build command turns the reference-import fixtures into a
// built dataset, the loader verifies it the way the API will, and Cek Aman
// evaluates against it. Every value is fictional fixture data.

import { execFileSync } from "node:child_process";
import { mkdtempSync, readFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

import { afterAll, describe, expect, it } from "vitest";

import {
  evaluate,
  type HardRule,
  type RecordedBrand,
  type SafetyStatus,
  type StandardAllergen,
} from "@keluargamakan/cek-aman";

import { loadReferenceDataFromEnv } from "./load.js";

const repoRoot = fileURLToPath(new URL("../../../", import.meta.url));
const source = join(repoRoot, "data", "fixtures", "reference-import", "valid");
const work = mkdtempSync(join(tmpdir(), "km-e2e-"));
afterAll(() => rmSync(work, { recursive: true, force: true }));
const out = join(work, "fixture-reference-dataset.json");

execFileSync(
  process.execPath,
  [join(repoRoot, "scripts", "build-reference.mjs"), "--fixture", "--source", source, "--out", out],
  { stdio: "pipe" },
);
const built = JSON.parse(readFileSync(out, "utf8")) as { contentHash: { value: string } };
const loaded = loadReferenceDataFromEnv({
  APP_ENV: "test",
  REFERENCE_DATA_PATH: out,
  REFERENCE_DATA_SHA256: built.contentHash.value,
});

const allergy = (allergen: StandardAllergen): HardRule => ({
  ruleId: `r-${allergen}`,
  type: "allergy",
  allergen,
});
const halal: HardRule = { ruleId: "r-halal", type: "halal" };
const vegetarian: HardRule = { ruleId: "r-vegetarian", type: "vegetarian" };

function statusOf(
  ingredientId: string,
  rule: HardRule,
  recordedBrands: readonly RecordedBrand[] = [],
): SafetyStatus {
  const result = evaluate({
    ingredients: [{ ingredientId, rawName: ingredientId }],
    recordedBrands,
    members: [{ memberId: "m1", hardRules: [rule] }],
    reference: loaded.reference,
  });
  expect(result.referenceVersion).toBe(loaded.referenceVersion);
  return result.perMember[0]!.status;
}

const brand = (brandId: string): RecordedBrand[] => [{ ingredientId: "fx_imp_kecap", brandId }];

describe("SAF-06 SAF-07 SAF-08 DAT-06 built dataset through the loader into Cek Aman", () => {
  it("DAT-06 every result records the dataset version and content hash", () => {
    expect(loaded.referenceVersion).toBe(
      `TEST-FIXTURE-reference-import-1@sha256:${built.contentHash.value}`,
    );
  });

  const cases: [string, string, HardRule, RecordedBrand[], SafetyStatus][] = [
    ["SAF-06 terasi with a shrimp allergy", "fx_imp_terasi", allergy("shrimp"), [], "not_safe"],
    [
      "SAF-06 terasi with a shellfish allergy",
      "fx_imp_terasi",
      allergy("shellfish"),
      [],
      "not_safe",
    ],
    ["SAF-06 angciu with a halal rule", "fx_imp_angciu", halal, [], "not_safe"],
    ["SAF-08 pork with a vegetarian rule", "fx_imp_babi", vegetarian, [], "not_safe"],
    [
      "SAF-03 a plain ingredient with a shrimp allergy",
      "fx_imp_bawang",
      allergy("shrimp"),
      [],
      "safe",
    ],
    // Unverified data stays unverified through the build, so it is never Safe.
    ["SAF-09 petis: unverified halal data", "fx_imp_petis", halal, [], "check_label"],
    [
      "SAF-09 bouillon: unverified data, may contain milk",
      "fx_imp_kaldu",
      allergy("milk"),
      [],
      "check_label",
    ],
    [
      "SAF-03 bouillon: a listed wheat component fails even while unverified",
      "fx_imp_kaldu",
      allergy("wheat"),
      [],
      "not_safe",
    ],
    ["SAF-08 gelatin: halal status uncertain", "fx_imp_gelatin", halal, [], "check_label"],
    ["SAF-09 gelatin: unverified components", "fx_imp_gelatin", allergy("fish"), [], "check_label"],
    // SAF-07 brand variants.
    ["SAF-07 kecap without a recorded brand", "fx_imp_kecap", allergy("wheat"), [], "check_label"],
    [
      "SAF-07 kecap with a verified brand",
      "fx_imp_kecap",
      allergy("wheat"),
      brand("fx_imp_merek_a"),
      "safe",
    ],
    [
      "SAF-07 kecap with an unverified brand",
      "fx_imp_kecap",
      allergy("wheat"),
      brand("fx_imp_merek_b"),
      "check_label",
    ],
    [
      "SAF-06 kecap with a soy allergy, verified brand",
      "fx_imp_kecap",
      allergy("soy"),
      brand("fx_imp_merek_a"),
      "not_safe",
    ],
  ];
  for (const [name, id, rule, brands, expected] of cases) {
    it(`${name} gives ${expected}`, () => {
      expect(statusOf(id, rule, brands)).toBe(expected);
    });
  }

  it("SAF-09 an ingredient the dataset does not hold gives Check the label", () => {
    expect(statusOf("fx_imp_not_there", halal)).toBe("check_label");
  });

  it("SAF-01 the loaded reference cannot be changed after verification", () => {
    const petis = loaded.reference.ingredients.find((record) => record.id === "fx_imp_petis")!;
    expect(() => {
      (petis.components as { verification: string }).verification = "verified";
    }).toThrow(TypeError);
    expect(statusOf("fx_imp_petis", halal)).toBe("check_label");
  });
});
