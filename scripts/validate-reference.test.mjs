// TEST FIXTURE: not real safety or nutrition data
//
// Tests for the reference data validator. Every ingredient value below is
// fictional and exists only to exercise the validator.

import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { mkdtempSync, mkdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { after, describe, it } from "node:test";

import { malformedIngredients } from "../data/fixtures/cek-aman/malformed-reference.fixture.ts";
import { fixtureMembers } from "../data/fixtures/cek-aman/members.fixture.ts";
import { fixtureReference } from "../data/fixtures/cek-aman/reference.fixture.ts";
import * as vocabulary from "../packages/cek-aman/src/vocabulary.ts";
import { FIXTURE_COMMENT } from "../packages/reference-data/src/dataset-format.ts";
import {
  DEFAULT_MAX_COMPONENT_DEPTH,
  INGREDIENT_DATASET,
  SCHEMA_DIR,
  checkReferenceDir,
  checkReferenceFiles,
  createValidators,
  formatIssue,
  nameKey,
  nameProblem,
  parseCommonArgs,
  repoRoot,
  schemaErrors,
  validateReferenceDir,
  validateReferenceFiles,
} from "./validate-reference.mjs";

const validators = createValidators();
const IMPORT_FIXTURES = join(repoRoot, "data", "fixtures", "reference-import");

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
const comps = (...ids) => ({ components: { verification: "verified", ingredientIds: ids } });
const dataset = (ingredients, version = "fx-1") => ({
  schema: INGREDIENT_DATASET,
  version,
  ingredients,
});
const file = (path, data) => ({ path, content: JSON.stringify(data) });
const check = (...files) => validateReferenceFiles(files, validators);
const issuesOf = (files, options = {}) =>
  checkReferenceFiles(files, { validators, ...options }).issues;
/** Issues reduced to the fields a reader uses to find the record. */
const located = (issues) =>
  issues.map(({ file: path, recordId, field, code }) => ({ path, recordId, field, code }));

describe("SAF-13 DAT-06 reference data validator", () => {
  it("DAT-06 the real data/reference/ folder passes (agents add no values)", () => {
    const { errors } = validateReferenceDir(undefined, { validators });
    assert.deepEqual(errors, []);
  });

  it("SAF-06 the Cek Aman fixture dataset matches the schema (schema and engine types agree)", () => {
    // Validated as fixture data, never written to data/reference/.
    const data = { $comment: FIXTURE_COMMENT, ...JSON.parse(JSON.stringify(fixtureReference)) };
    assert.deepEqual(schemaErrors(validators.dataset, data), []);
    const issues = issuesOf([{ path: "memory/fixture.json", content: JSON.stringify(data) }], {
      mode: "fixture",
    });
    assert.deepEqual(issues.map(formatIssue), []);
  });

  it("SAF-08 PRF-03 DAT-06 every record of the malformed fixture is rejected by the schema", () => {
    assert.ok(malformedIngredients.length > 0);
    for (const record of malformedIngredients) {
      const data = JSON.parse(JSON.stringify(record));
      assert.notDeepEqual(schemaErrors(validators.ingredient, data), [], record.id);
    }
  });

  it("PRF-03 PRF-08 every fixture hard rule matches the hard-rule schema", () => {
    for (const member of Object.values(fixtureMembers)) {
      for (const rule of member.hardRules) {
        assert.deepEqual(schemaErrors(validators.hardRule, rule), [], rule.ruleId);
      }
    }
  });

  it("SAF-13 accepts a minimal valid dataset", () => {
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
    [
      "PRF-03 vegan suitable while vegetarian uncertain",
      { diet: { verification: "verified", vegetarian: "uncertain", vegan: "suitable" } },
    ],
    [
      "PRF-03 vegan suitable while vegetarian unknown",
      { diet: { verification: "verified", vegetarian: "unknown", vegan: "suitable" } },
    ],
    [
      "SAF-08 halal with a non-halal animal source",
      {
        halal: {
          verification: "verified",
          value: "halal",
          nonHalalSources: ["non_halal_animal"],
        },
      },
    ],
    ["SAF-07 brand variants while brandVaries is false", { brandVariants: [variant("fx_b")] }],
    ["SAF-07 brandVaries missing", { brandVaries: undefined }],
    ["SAF-03 component verification missing", { components: { ingredientIds: [] } }],
    ["SAF-12 unknown property", { safeForEveryone: true }],
    ["SAF-13 bad id", { id: "Not An Id" }],
  ];
  for (const [name, overrides] of invalid) {
    it(`rejects ${name}`, () => {
      const data = JSON.parse(JSON.stringify(dataset([ingredient("fx_a", overrides)])));
      assert.notDeepEqual(check(file("a.json", data)), []);
    });
  }

  it("SAF-13 DAT-06 rejects test fixtures placed in reference data", () => {
    const errors = check({ path: "a.json", content: '{"note":"TEST FIXTURE: not real"}' });
    assert.match(errors[0], /test fixtures must never be placed/);
  });

  it("SAF-13 rejects invalid JSON and unknown dataset kinds", () => {
    assert.match(check({ path: "a.json", content: "{" })[0], /not valid JSON/);
    assert.match(check(file("a.json", { schema: "other" }))[0], /unknown or missing "schema"/);
    assert.match(check(file("a.json", null))[0], /unknown or missing "schema"/);
    assert.match(check(file("a.json", [INGREDIENT_DATASET]))[0], /unknown or missing "schema"/);
  });

  it("DAT-06 rejects files with different data versions", () => {
    const errors = check(
      file("a.json", dataset([ingredient("fx_a")], "1")),
      file("b.json", dataset([ingredient("fx_b")], "2")),
    );
    assert.match(errors[0], /one data version.*a\.json=1, b\.json=2/);
  });

  it("DAT-06 rejects a missing version and skips further checks on a broken envelope", () => {
    const issues = issuesOf([file("a.json", { schema: INGREDIENT_DATASET, ingredients: [] })]);
    assert.deepEqual(located(issues), [
      { path: "a.json", recordId: null, field: "version", code: "schema" },
    ]);
  });

  it("SAF-13 rejects duplicate ingredient IDs across files, naming both places", () => {
    const errors = check(
      file("a.json", dataset([ingredient("fx_a")])),
      file("b.json", dataset([ingredient("fx_a")])),
    );
    assert.equal(
      errors[0],
      "b.json, ingredient fx_a (ingredients[0]), field id: duplicate id, also in a.json " +
        "(ingredients[0]) [duplicate_id]",
    );
  });

  it("SAF-03 rejects unknown components, self-references and cycles", () => {
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
    const has = (pattern) =>
      assert.ok(
        errors.some((e) => pattern.test(e)),
        errors.join("\n"),
      );
    has(/ingredient fx_a .*field components\.ingredientIds\[1\]: unknown component fx_ghost/);
    has(/ingredient fx_self .*lists itself/);
    has(/component cycle: fx_a > fx_b > fx_c > fx_a/);
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
                components: { verification: "verified", ingredientIds: ["fx_a"] },
              }),
            ],
          }),
        ]),
      ),
    );
    assert.ok(errors.some((e) => /brandVariants\[1\]\.brandId: duplicate brandId fx_b/.test(e)));
    assert.ok(errors.some((e) => /allergen soy is in both .* \(brand fx_b\)/.test(e)));
    assert.ok(errors.some((e) => /lists itself as a component \(brand fx_b\)/.test(e)));
  });

  describe("directory scan", () => {
    const dir = mkdtempSync(join(tmpdir(), "km-reference-"));
    after(() => rmSync(dir, { recursive: true, force: true }));

    it("SAF-13 checks nested JSON files, ignores .gitkeep and rejects other file types", () => {
      mkdirSync(join(dir, "ingredients"));
      writeFileSync(join(dir, ".gitkeep"), "");
      writeFileSync(
        join(dir, "ingredients", "a.json"),
        JSON.stringify(dataset([ingredient("fx_a")])),
      );
      writeFileSync(join(dir, "notes.csv"), "id\nfx_a\n");
      const { fileCount, errors } = validateReferenceDir(dir, { validators });
      assert.equal(fileCount, 1);
      assert.equal(errors.length, 1);
      assert.match(errors[0], /notes\.csv: only JSON datasets/);
      // Paths outside the repository are shown in full, with forward slashes.
      assert.ok(errors[0].startsWith(dir.replaceAll("\\", "/")), errors[0]);
    });
  });

  it("PRF-08 SAF-12 hard-rule schema rejects unmapped-as-mapped, unknown types and override fields", () => {
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

describe("SAF-13 readable errors point to the file, record and field", () => {
  const one = (overrides) => issuesOf([file("a.json", dataset([ingredient("fx_a", overrides)]))]);

  it("SAF-08 halal value with a listed source names the field and explains the rule", () => {
    const [issue, ...rest] = one({
      halal: { verification: "verified", value: "halal", nonHalalSources: ["alcohol"] },
    });
    assert.deepEqual(rest, []);
    assert.equal(
      formatIssue(issue),
      "a.json, ingredient fx_a (ingredients[0]), field halal.nonHalalSources: lists non-halal " +
        'source(s) ["alcohol"] while halal.value is "halal": a record that lists alcohol, pork ' +
        'or a non-halal animal source must use "not_halal" (SAF-08) [schema]',
    );
  });

  it("SAF-08 PRF-03 SAF-07 explains each cross-field schema rule", () => {
    const cases = [
      [
        { halal: { verification: "verified", value: "not_halal", nonHalalSources: [] } },
        "halal.nonHalalSources",
        /needs at least one nonHalalSources entry/,
      ],
      [
        { diet: { verification: "verified", vegetarian: "not_suitable", vegan: "uncertain" } },
        "diet.vegan",
        /diet\.vegan must be "not_suitable" \(found "uncertain"\)/,
      ],
      [
        { diet: { verification: "verified", vegetarian: "uncertain", vegan: "suitable" } },
        "diet.vegetarian",
        /requires diet\.vegetarian "suitable" \(found "uncertain"\)/,
      ],
      [{ brandVariants: [variant("fx_b")] }, "brandVariants", /empty when brandVaries is false/],
    ];
    for (const [overrides, field, message] of cases) {
      const issues = one(overrides);
      assert.equal(issues.length, 1, JSON.stringify(issues));
      assert.equal(issues[0].field, field);
      assert.equal(issues[0].recordId, "fx_a");
      assert.match(issues[0].message, message);
    }
  });

  it("SAF-13 required, unknown, enum, const and type errors name the field", () => {
    const record = ingredient("fx_a", { safeForEveryone: true, tkpiCode: 5 });
    delete record.halal;
    record.allergens = { verification: "verified", contains: ["kiwi"], mayContain: [] };
    const issues = issuesOf([
      file("a.json", { ...dataset([record, "not an object"]), schema: INGREDIENT_DATASET }),
    ]);
    assert.deepEqual(
      issues.map(({ index, field, message }) => ({ index, field, message })),
      [
        { index: 0, field: "halal", message: "is required but missing" },
        { index: 0, field: "safeForEveryone", message: "is not a known field" },
        {
          index: 0,
          field: "allergens.contains[0]",
          message:
            '"kiwi" is not allowed; use one of "peanut", "tree_nut", "shellfish", "shrimp", ' +
            '"fish", "egg", "milk", "soy", "wheat", "gluten", "sesame"',
        },
        { index: 0, field: "tkpiCode", message: "must be string,null" },
        { index: 1, field: null, message: "must be object" },
      ],
    );
    assert.equal(formatIssue(issues[4]), "a.json, ingredients[1]: must be object [schema]");
  });

  it("SAF-13 a file-level const error names the field", () => {
    const issues = issuesOf([
      file("a.json", { ...dataset([]), schema: INGREDIENT_DATASET, ingredients: {} }),
    ]);
    assert.deepEqual(located(issues), [
      { path: "a.json", recordId: null, field: "ingredients", code: "schema" },
    ]);
  });
});

describe("SAF-08 PRF-03 cross-field consistency (QA review L7)", () => {
  it("SAF-08 PRF-03 pork or a non-halal animal source requires not vegetarian", () => {
    for (const source of ["pork", "non_halal_animal"]) {
      for (const vegetarian of ["suitable", "uncertain", "unknown"]) {
        const vegan = vegetarian === "suitable" ? "suitable" : "unknown";
        const issues = issuesOf([
          file(
            "a.json",
            dataset([
              ingredient("fx_a", {
                halal: { verification: "verified", value: "not_halal", nonHalalSources: [source] },
                diet: { verification: "unverified", vegetarian, vegan },
              }),
            ]),
          ),
        ]);
        assert.deepEqual(located(issues), [
          {
            path: "a.json",
            recordId: "fx_a",
            field: "diet.vegetarian",
            code: "halal_diet_conflict",
          },
        ]);
        assert.match(issues[0].message, new RegExp(`lists ${source}, so diet.vegetarian`));
      }
    }
  });

  it("SAF-08 alcohol alone does not imply not vegetarian, and an animal source that is not vegetarian passes", () => {
    const issues = issuesOf([
      file(
        "a.json",
        dataset([
          ingredient("fx_a", {
            halal: { verification: "verified", value: "not_halal", nonHalalSources: ["alcohol"] },
          }),
          ingredient("fx_b", {
            halal: { verification: "verified", value: "not_halal", nonHalalSources: ["pork"] },
            diet: { verification: "verified", vegetarian: "not_suitable", vegan: "not_suitable" },
          }),
        ]),
      ),
    ]);
    assert.deepEqual(issues, []);
  });

  it("SAF-07 SAF-08 the rule applies to each brand variant", () => {
    const issues = issuesOf([
      file(
        "a.json",
        dataset([
          ingredient("fx_a", {
            brandVaries: true,
            brandVariants: [
              variant("fx_b", {
                halal: {
                  verification: "verified",
                  value: "not_halal",
                  nonHalalSources: ["non_halal_animal"],
                },
                diet: { verification: "verified", vegetarian: "unknown", vegan: "unknown" },
              }),
            ],
          }),
        ]),
      ),
    ]);
    assert.deepEqual(located(issues), [
      {
        path: "a.json",
        recordId: "fx_a",
        field: "brandVariants[0].diet.vegetarian",
        code: "halal_diet_conflict",
      },
    ]);
  });
});

describe("SAF-09 names resolve to one ingredient (security review L5)", () => {
  it("SAF-09 rejects badly formed names", () => {
    const cases = [
      ["émping", /NFC/],
      [" terasi", /leading or trailing spaces/],
      ["tera​si", /invisible.*/],
      ["tera\u0007si", /control/],
      ["kecap  manis", /repeated spaces/],
      ["!!!", /no letters or digits/],
    ];
    for (const [text, pattern] of cases) assert.match(nameProblem(text), pattern, text);
    assert.equal(nameProblem("Kecap manis"), null);

    const issues = issuesOf([
      file(
        "a.json",
        dataset([
          ingredient("fx_a", {
            localNames: ["tera​si"],
            brandVaries: true,
            brandVariants: [variant("fx_b", { brandName: "Merek " })],
          }),
        ]),
      ),
    ]);
    assert.deepEqual(
      issues.map((issue) => [issue.field, issue.code]),
      [
        ["localNames[0]", "name_format"],
        ["brandVariants[0].brandName", "name_format"],
      ],
    );
    assert.match(issues[0].message, /"tera<U\+200B>si"/);
  });

  it("SAF-09 normalisation folds case, accents, invisible characters, spaces and punctuation", () => {
    assert.equal(nameKey("Kecap  Manis"), "kecap manis");
    assert.equal(nameKey("kecap-manis"), "kecap manis");
    assert.equal(nameKey("TEMPÉ"), "tempe");
    assert.equal(nameKey("tem​pe"), "tempe");
    assert.equal(nameKey("ｔｅｍｐｅ"), "tempe");
  });

  it("SAF-09 rejects a name shared by two ingredients after normalisation, in any name field", () => {
    const issues = issuesOf([
      file(
        "a.json",
        dataset([
          ingredient("fx_a", { localNames: ["Terasi Udang", "terasi udang"] }),
          ingredient("fx_b", {
            displayName: { id: "terasi-udang", en: "Fiction fx_b" },
            localNames: ["Fiksi FX_A"],
          }),
        ]),
      ),
    ]);
    assert.deepEqual(
      issues.map((issue) => [issue.recordId, issue.field, issue.code]),
      [
        ["fx_b", "displayName.id", "name_ambiguous"],
        ["fx_b", "localNames[0]", "name_ambiguous"],
      ],
    );
    assert.match(issues[0].message, /matches "Terasi Udang" \(localNames\[0\] of ingredient fx_a/);
  });

  it("SAF-09 a repeated name within one ingredient is not ambiguous", () => {
    const record = ingredient("fx_a", {
      displayName: { id: "Kecap", en: "kecap" },
      localNames: ["KECAP"],
    });
    assert.deepEqual(issuesOf([file("a.json", dataset([record]))]), []);
  });
});

describe("SAF-03 component depth limit (security review L1)", () => {
  const chain = (length, prefix = "fx_d") =>
    Array.from({ length }, (_, i) =>
      ingredient(`${prefix}${i}`, comps(...(i + 1 < length ? [`${prefix}${i + 1}`] : []))),
    );

  it("SAF-03 a chain at the limit passes; one level more is rejected at the top only", () => {
    const limit = DEFAULT_MAX_COMPONENT_DEPTH;
    assert.deepEqual(issuesOf([file("a.json", dataset(chain(limit + 1)))]), []);
    const issues = issuesOf([file("a.json", dataset(chain(limit + 2)))]);
    assert.deepEqual(located(issues), [
      {
        path: "a.json",
        recordId: "fx_d0",
        field: "components.ingredientIds",
        code: "component_depth",
      },
    ]);
    assert.match(
      issues[0].message,
      new RegExp(`${limit + 1} levels deep, more than the limit of ${limit}`),
    );
  });

  it("SAF-03 the limit is configurable and counts brand-variant components", () => {
    const records = [
      ingredient("fx_a", {
        brandVaries: true,
        brandVariants: [variant("fx_brand", comps("fx_b"))],
      }),
      ingredient("fx_b", comps("fx_c")),
      ingredient("fx_c"),
    ];
    assert.deepEqual(issuesOf([file("a.json", dataset(records))], { maxComponentDepth: 2 }), []);
    const issues = issuesOf([file("a.json", dataset(records))], { maxComponentDepth: 1 });
    assert.equal(issues.length, 1);
    assert.match(issues[0].message, /2 levels deep, more than the limit of 1: fx_a > fx_b > fx_c/);
  });

  it("SAF-03 uses the longest of several paths and reports each top-level chain", () => {
    const records = [
      ingredient("fx_a", comps("fx_short", "fx_b")),
      ingredient("fx_short"),
      ingredient("fx_b", comps("fx_c")),
      ingredient("fx_c"),
      ingredient("fx_x", comps("fx_b")),
    ];
    const issues = issuesOf([file("a.json", dataset(records))], { maxComponentDepth: 1 });
    assert.deepEqual(
      issues.map((issue) => issue.recordId),
      ["fx_a", "fx_x"],
    );
    assert.match(issues[0].message, /fx_a > fx_b > fx_c$/);
  });

  it("SAF-03 a very deep crafted chain is reported without overflowing the stack", () => {
    const issues = issuesOf([file("a.json", dataset(chain(20_000)))]);
    assert.equal(issues.length, 1);
    assert.match(issues[0].message, /19999 levels deep.*fx_d0 > fx_d1 .* … .* > fx_d19999$/);
  });

  it("SAF-03 when every over-limit record is inside a cycle, each one is reported", () => {
    const records = [
      ingredient("fx_a", comps("fx_b")),
      ingredient("fx_b", comps("fx_c", "fx_a")),
      ingredient("fx_c", comps("fx_d")),
      ingredient("fx_d"),
    ];
    const issues = issuesOf([file("a.json", dataset(records))], { maxComponentDepth: 1 });
    assert.deepEqual(issues.map((issue) => issue.code).sort(), [
      "component_cycle",
      "component_depth",
      "component_depth",
    ]);
  });

  it("SAF-03 rejects an invalid limit", () => {
    for (const maxComponentDepth of [0, 1.5, Number.NaN]) {
      assert.throws(() => issuesOf([], { maxComponentDepth }), /at least 1/);
    }
    assert.throws(() => issuesOf([], { mode: "production" }), /unknown mode/);
  });

  it("SAF-03 a record that fails the schema adds no components to the graph", () => {
    const issues = issuesOf([
      file(
        "a.json",
        dataset([
          ingredient("fx_a", { ...comps("fx_ghost"), safeForEveryone: true }),
          ingredient("fx_b", comps("fx_a")),
        ]),
      ),
    ]);
    assert.deepEqual(
      issues.map((issue) => [issue.recordId, issue.code]),
      [["fx_a", "schema"]],
    );
  });
});

describe("SAF-13 DAT-06 fixture mode", () => {
  const marked = (data) => ({ $comment: FIXTURE_COMMENT, ...data });

  it("DAT-06 a fixture file needs the marker and a TEST-FIXTURE version", () => {
    const issues = issuesOf(
      [
        file("a.json", dataset([ingredient("fx_a")], "fx-1")),
        file("b.json", marked(dataset([ingredient("fx_b")], "TEST-FIXTURE-1"))),
      ],
      { mode: "fixture" },
    );
    assert.deepEqual(
      issues.map((issue) => [issue.file, issue.field, issue.code]),
      [
        ["a.json", "$comment", "fixture_unmarked"],
        ["a.json", "version", "fixture_unmarked"],
        ["(dataset)", null, "version_mismatch"],
      ],
    );
  });

  it("DAT-06 reference mode rejects a fixture version even without the marker text", () => {
    const issues = issuesOf([file("a.json", dataset([ingredient("fx_a")], "test_fixture-2"))]);
    assert.deepEqual(located(issues), [
      { path: "a.json", recordId: null, field: "version", code: "fixture_in_reference" },
    ]);
  });

  it("SAF-06 the reference-import fixtures: the valid set passes and is refused as real data", () => {
    const valid = join(IMPORT_FIXTURES, "valid");
    const fixture = checkReferenceDir(valid, { validators, mode: "fixture" });
    assert.deepEqual(fixture.issues.map(formatIssue), []);
    assert.equal(fixture.fileCount, 2);
    assert.equal(fixture.version, "TEST-FIXTURE-reference-import-1");
    const real = checkReferenceDir(valid, { validators });
    assert.deepEqual(
      real.issues.map((issue) => issue.code),
      ["fixture_in_reference", "fixture_in_reference"],
    );
  });

  it("SAF-06 SAF-08 PRF-03 SAF-03 SAF-09 the invalid fixture set gives one located issue per defect", () => {
    const { issues } = checkReferenceDir(join(IMPORT_FIXTURES, "invalid"), {
      validators,
      mode: "fixture",
    });
    const records = "data/fixtures/reference-import/invalid/records.json";
    const graph = "data/fixtures/reference-import/invalid/graph.json";
    const expected = [
      [records, "fx_bad_halal_listed_source", "halal.nonHalalSources", "schema"],
      [records, "fx_bad_vegan_not_vegetarian", "diet.vegetarian", "schema"],
      [records, "fx_bad_allergen_not_standard", "allergens.contains[0]", "schema"],
      [records, "fx_bad_unknown_field", "safeForEveryone", "schema"],
      [records, "fx_bad_missing_halal", "halal", "schema"],
      [records, "fx_bad_pork_vegetarian", "diet.vegetarian", "halal_diet_conflict"],
      [
        records,
        "fx_bad_animal_brand_vegetarian",
        "brandVariants[0].diet.vegetarian",
        "halal_diet_conflict",
      ],
      [records, "fx_bad_allergen_overlap", "allergens", "allergen_overlap"],
      [records, "fx_bad_self_component", "components.ingredientIds", "self_component"],
      [records, "fx_bad_name_spaces", "localNames[0]", "name_format"],
      [records, "fx_bad_name_zero_width", "displayName.id", "name_format"],
      [records, "fx_bad_duplicate_brand", "brandVariants[1].brandId", "duplicate_brand"],
      [records, "fx_bad_duplicate_id", "id", "duplicate_id"],
      [graph, "fx_bad_name_b", "displayName.id", "name_ambiguous"],
      [records, "fx_bad_unknown_component", "components.ingredientIds[0]", "unknown_component"],
      [graph, "fx_bad_cycle_a", "components.ingredientIds", "component_cycle"],
      [graph, "fx_bad_deep_00", "components.ingredientIds", "component_depth"],
    ];
    assert.deepEqual(
      issues.map((issue) => [issue.file, issue.recordId, issue.field, issue.code]),
      expected,
    );
  });
});

describe("SAF-13 command line", () => {
  const cli = (...args) => {
    try {
      const stdout = execFileSync(
        process.execPath,
        [join(repoRoot, "scripts", "validate-reference.mjs"), ...args],
        { encoding: "utf8", stdio: ["ignore", "pipe", "pipe"] },
      );
      return { code: 0, stdout, stderr: "" };
    } catch (error) {
      return { code: error.status, stdout: error.stdout, stderr: error.stderr };
    }
  };

  it("SAF-13 exits 0 on the empty reference folder and 1 with located errors", () => {
    assert.equal(cli().code, 0);
    const bad = cli(join(IMPORT_FIXTURES, "invalid"), "--fixture");
    assert.equal(bad.code, 1);
    assert.match(
      bad.stderr,
      /records\.json, ingredient fx_bad_pork_vegetarian \(ingredients\[2\]\), field diet\.vegetarian: /,
    );
    assert.match(bad.stderr, /17 problem\(s\)\. Nothing was changed/);
    const ok = cli(join(IMPORT_FIXTURES, "valid"), "--fixture", "--max-component-depth", "3");
    assert.equal(ok.code, 0, ok.stderr);
    assert.match(ok.stdout, /2 file\(s\).*fixture mode, component depth limit 3/);
  });

  it("SAF-13 exits 2 on bad arguments", () => {
    assert.equal(cli("--max-component-depth", "zero").code, 2);
    assert.equal(cli("--unknown").code, 2);
    assert.throws(() => parseCommonArgs(["--max-component-depth", "0"]), /at least 1/);
    assert.deepEqual(parseCommonArgs([]).mode, "reference");
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
    it(`SAF-01 ${name} enum equals the engine list`, () => {
      assert.deepEqual(common[name].enum, [...list]);
    });
  }
  it("SAF-01 DAT-06 id pattern and dataset kind match", () => {
    assert.equal(common.id.pattern, vocabulary.ID_PATTERN);
    assert.equal(INGREDIENT_DATASET, vocabulary.INGREDIENT_DATASET_SCHEMA);
  });
});
