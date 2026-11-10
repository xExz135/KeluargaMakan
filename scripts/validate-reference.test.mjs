// TEST FIXTURE: not real safety or nutrition data
//
// Tests for the reference data validator. Every ingredient value below is
// fictional and exists only to exercise the validator.

import assert from "node:assert/strict";
import { mkdtempSync, mkdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { after, describe, it } from "node:test";

import { fixtureMembers } from "../data/fixtures/cek-aman/members.fixture.ts";
import { fixtureReference } from "../data/fixtures/cek-aman/reference.fixture.ts";
import * as vocabulary from "../packages/cek-aman/src/vocabulary.ts";
import {
  INGREDIENT_DATASET,
  SCHEMA_DIR,
  createValidators,
  schemaErrors,
  validateReferenceDir,
  validateReferenceFiles,
} from "./validate-reference.mjs";

const validators = createValidators();

const ingredient = (id, overrides = {}) => ({
  id,
  displayName: { id: `Fiksi ${id}`, en: `Fiction ${id}` },
  localNames: [],
  category: "fixture",
  components: { verification: "verified", ingredientIds: [] },
  allergens: { verification: "verified", contains: [], mayContain: [] },
  halal: { verification: "verified", value: "halal", nonHalalSources: [] },
  diet: { verification: "verified", vegetarian: "suitable", vegan: "suitable" },
  brandVaries: false,
  brandVariants: [],
  tkpiCode: null,
  ...overrides,
});
const variant = (brandId, overrides = {}) => {
  const { components, allergens, halal, diet } = ingredient("x");
  return {
    brandId,
    brandName: brandId,
    verified: true,
    components,
    allergens,
    halal,
    diet,
    ...overrides,
  };
};
const dataset = (ingredients, version = "fx-1") => ({
  schema: INGREDIENT_DATASET,
  version,
  ingredients,
});
const file = (path, data) => ({ path, content: JSON.stringify(data) });
const check = (...files) => validateReferenceFiles(files, validators);

describe("SAF-13 DAT-06 reference data validator", () => {
  it("DAT-06 the real data/reference/ folder passes (agents add no values)", () => {
    const { errors } = validateReferenceDir(undefined, validators);
    assert.deepEqual(errors, []);
  });

  it("SAF-06 the Cek Aman fixture dataset matches the schema (schema and engine types agree)", () => {
    // Validated as data, never written to data/reference/.
    const data = JSON.parse(JSON.stringify(fixtureReference));
    assert.deepEqual(schemaErrors(validators.dataset, data), []);
    const errors = validateReferenceFiles(
      [{ path: "memory/fixture.json", content: JSON.stringify(data) }],
      validators,
    );
    assert.deepEqual(errors, []);
  });

  it("PRF-03 PRF-08 every fixture hard rule matches the hard-rule schema", () => {
    for (const member of Object.values(fixtureMembers)) {
      for (const rule of member.hardRules) {
        assert.deepEqual(schemaErrors(validators.hardRule, rule), [], rule.ruleId);
      }
    }
  });

  it("accepts a minimal valid dataset", () => {
    assert.deepEqual(check(file("a.json", dataset([ingredient("fx_a")]))), []);
  });

  const invalid = [
    [
      "SAF-08 not_halal without a source",
      { halal: { verification: "verified", value: "not_halal", nonHalalSources: [] } },
    ],
    [
      "SAF-08 halal with a non-halal source",
      { halal: { verification: "verified", value: "halal", nonHalalSources: ["pork"] } },
    ],
    [
      "SAF-08 unknown halal value",
      { halal: { verification: "verified", value: "maybe", nonHalalSources: [] } },
    ],
    [
      "PRF-04 allergen not on the standard list",
      { allergens: { verification: "verified", contains: ["kiwi"], mayContain: [] } },
    ],
    [
      "PRF-03 vegan while not vegetarian",
      { diet: { verification: "verified", vegetarian: "not_suitable", vegan: "suitable" } },
    ],
    ["SAF-07 brand variants while brandVaries is false", { brandVariants: [variant("fx_b")] }],
    ["SAF-07 brandVaries missing", { brandVaries: undefined }],
    ["SAF-03 component verification missing", { components: { ingredientIds: [] } }],
    ["unknown property", { safeForEveryone: true }],
    ["bad id", { id: "Not An Id" }],
  ];
  for (const [name, overrides] of invalid) {
    it(`rejects ${name}`, () => {
      const data = JSON.parse(JSON.stringify(dataset([ingredient("fx_a", overrides)])));
      assert.notDeepEqual(check(file("a.json", data)), []);
    });
  }

  it("rejects test fixtures placed in reference data", () => {
    const errors = check({ path: "a.json", content: '{"note":"TEST FIXTURE: not real"}' });
    assert.match(errors[0], /test fixtures must never be placed/);
  });

  it("rejects invalid JSON and unknown dataset kinds", () => {
    assert.match(check({ path: "a.json", content: "{" })[0], /not valid JSON/);
    assert.match(check(file("a.json", { schema: "other" }))[0], /unknown or missing "schema"/);
    assert.match(check(file("a.json", null))[0], /unknown or missing "schema"/);
  });

  it("DAT-06 rejects files with different data versions", () => {
    const errors = check(
      file("a.json", dataset([ingredient("fx_a")], "1")),
      file("b.json", dataset([ingredient("fx_b")], "2")),
    );
    assert.match(errors[0], /one data version/);
  });

  it("rejects duplicate ingredient IDs across files", () => {
    const errors = check(
      file("a.json", dataset([ingredient("fx_a")])),
      file("b.json", dataset([ingredient("fx_a")])),
    );
    assert.match(errors[0], /duplicate id, also in a\.json/);
  });

  it("SAF-03 rejects unknown components, self-references and cycles", () => {
    const comps = (...ids) => ({ components: { verification: "verified", ingredientIds: ids } });
    const errors = check(
      file(
        "a.json",
        dataset([
          ingredient("fx_a", comps("fx_b", "fx_ghost")),
          ingredient("fx_b", comps("fx_c")),
          ingredient("fx_c", comps("fx_a")),
          ingredient("fx_self", comps("fx_self")),
        ]),
      ),
    );
    assert.ok(
      errors.some((e) => /fx_a has unknown component fx_ghost/.test(e)),
      errors.join("\n"),
    );
    assert.ok(
      errors.some((e) => /fx_self.*lists itself/.test(e)),
      errors.join("\n"),
    );
    assert.ok(
      errors.some((e) => /component cycle: fx_a > fx_b > fx_c > fx_a/.test(e)),
      errors.join("\n"),
    );
  });

  it("SAF-07 rejects duplicate brand IDs and contains/mayContain overlap in a variant", () => {
    const errors = check(
      file(
        "a.json",
        dataset([
          ingredient("fx_a", {
            brandVaries: true,
            brandVariants: [
              variant("fx_b"),
              variant("fx_b", {
                allergens: { verification: "verified", contains: ["soy"], mayContain: ["soy"] },
              }),
            ],
          }),
        ]),
      ),
    );
    assert.ok(errors.some((e) => /duplicate brandId fx_b/.test(e)));
    assert.ok(errors.some((e) => /brand fx_b: allergen soy is in both/.test(e)));
  });

  describe("directory scan", () => {
    const dir = mkdtempSync(join(tmpdir(), "km-reference-"));
    after(() => rmSync(dir, { recursive: true, force: true }));

    it("checks nested JSON files, ignores .gitkeep and rejects other file types", () => {
      mkdirSync(join(dir, "ingredients"));
      writeFileSync(join(dir, ".gitkeep"), "");
      writeFileSync(
        join(dir, "ingredients", "a.json"),
        JSON.stringify(dataset([ingredient("fx_a")])),
      );
      writeFileSync(join(dir, "notes.csv"), "id\nfx_a\n");
      const { fileCount, errors } = validateReferenceDir(dir, validators);
      assert.equal(fileCount, 1);
      assert.equal(errors.length, 1);
      assert.match(errors[0], /notes\.csv: only JSON datasets/);
    });
  });

  it("hard-rule schema rejects unmapped-as-mapped, unknown types and override fields", () => {
    const bad = [
      {
        ruleId: "r",
        type: "free_text",
        freeText: "x",
        mapping: { status: "mapped", ingredientIds: ["fx_a"] },
      },
      {
        ruleId: "r",
        type: "free_text",
        freeText: "x",
        mapping: { status: "mapped", ingredientIds: [], confirmedBy: "manager" },
      },
      { ruleId: "r", type: "allergy", allergen: "kiwi" },
      { ruleId: "r", type: "keto" },
      { ruleId: "r", type: "halal", override: true },
      { ruleId: "r", type: "free_text", freeText: " ", mapping: { status: "unmapped" } },
    ];
    for (const rule of bad)
      assert.notDeepEqual(schemaErrors(validators.hardRule, rule), [], JSON.stringify(rule));
  });
});

describe("SAF-01 schema vocabulary matches the engine", () => {
  const common = JSON.parse(readFileSync(join(SCHEMA_DIR, "common.schema.json"), "utf8")).$defs;
  const pairs = [
    ["standardAllergen", vocabulary.STANDARD_ALLERGENS],
    ["verification", vocabulary.VERIFICATION_STATES],
    ["halalValue", vocabulary.HALAL_VALUES],
    ["nonHalalSource", vocabulary.NON_HALAL_SOURCES],
    ["dietSuitability", vocabulary.DIET_SUITABILITY],
    ["hardRuleType", vocabulary.HARD_RULE_TYPES],
    ["mappingStatus", vocabulary.MAPPING_STATUSES],
    ["mappingConfirmer", vocabulary.MAPPING_CONFIRMERS],
  ];
  for (const [name, list] of pairs) {
    it(`${name} enum equals the engine list`, () => {
      assert.deepEqual(common[name].enum, [...list]);
    });
  }
  it("id pattern and dataset kind match", () => {
    assert.equal(common.id.pattern, vocabulary.ID_PATTERN);
    assert.equal(INGREDIENT_DATASET, vocabulary.INGREDIENT_DATASET_SCHEMA);
  });
});
