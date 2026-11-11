#!/usr/bin/env node
// Reference data validator (SAF-06, SAF-13, DAT-06, NFR-20). Checks every file
// in the reference folder against the JSON Schemas in data/schema/, plus the
// rules a schema cannot express:
//   - one data version per release, and no fixture marker or fixture version
//   - unique ingredient IDs across files, unique brand IDs per ingredient
//   - names in NFC form, trimmed, with no control or zero-width characters,
//     and no two ingredients sharing a name after normalisation
//   - no allergen listed as both "contains" and "may contain"
//   - pork or a non-halal animal source implies not vegetarian
//   - components that point at existing ingredients, no component cycles and
//     no component chain deeper than a configurable limit
//
// Every problem is reported with the file, the record (index and ID) and the
// field. Nothing is ever fixed automatically: it validates values written by
// the content team and never writes or changes values.
//
// Usage: node scripts/validate-reference.mjs [dir] [--fixture] [--max-component-depth <n>]

import { readFileSync, readdirSync, statSync } from "node:fs";
import { isAbsolute, join, relative, resolve } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { parseArgs } from "node:util";

import Ajv2020 from "ajv/dist/2020.js";

import {
  FIXTURE_COMMENT,
  FIXTURE_MARKER,
  FIXTURE_VERSION_PREFIX,
  SOURCE_DATASET_SCHEMA,
  looksLikeFixtureVersion,
} from "../packages/reference-data/src/dataset-format.ts";

export const repoRoot = resolve(fileURLToPath(new URL("..", import.meta.url)));
export const SCHEMA_DIR = join(repoRoot, "data", "schema");
export const REFERENCE_DIR = join(repoRoot, "data", "reference");

export const INGREDIENT_DATASET = SOURCE_DATASET_SCHEMA;
/** Longest allowed chain of components below an ingredient (security review L1). */
export const DEFAULT_MAX_COMPONENT_DEPTH = 8;
/** "reference": real data, no fixture marker allowed. "fixture": test data, marker required. */
export const MODES = ["reference", "fixture"];

const SCHEMA_BASE = "https://schemas.keluargamakan.example/v1/";
const IGNORED_FILES = new Set([".gitkeep"]);
const ANIMAL_SOURCES = ["pork", "non_halal_animal"];
const DATASET_FILE = "(dataset)";

/** Loads the schemas and returns compiled validators. */
export function createValidators(schemaDir = SCHEMA_DIR) {
  const ajv = new Ajv2020({ allErrors: true, strict: true, strictTypes: false });
  for (const file of readdirSync(schemaDir).filter((name) => name.endsWith(".schema.json"))) {
    ajv.addSchema(JSON.parse(readFileSync(join(schemaDir, file), "utf8")));
  }
  const get = (name) => {
    const validate = ajv.getSchema(`${SCHEMA_BASE}${name}`);
    if (!validate) throw new Error(`schema not found: ${name}`);
    return validate;
  };
  return {
    dataset: get("reference-dataset.schema.json"),
    ingredient: get("ingredient.schema.json"),
    hardRule: get("hard-rule.schema.json"),
  };
}

/** @param {import("ajv").ValidateFunction} validate */
export function schemaErrors(validate, value) {
  if (validate(value)) return [];
  return (validate.errors ?? []).map(
    (error) => `${error.instancePath || "/"} ${error.message ?? "is invalid"}`,
  );
}

// ---------------------------------------------------------------------------
// Issues
// ---------------------------------------------------------------------------

/**
 * @typedef {object} Issue
 * @property {string} file repository-relative path, or "(dataset)" for the whole release
 * @property {number | null} index position in the file's `ingredients` list
 * @property {string | null} recordId ingredient ID, when it has one
 * @property {string | null} field dotted path inside the record (or the file)
 * @property {string} code stable machine-readable code
 * @property {string} message what is wrong and what is expected
 */

/** @returns {Issue} */
function makeIssue(file, code, message, { index = null, recordId = null, field = null } = {}) {
  return { file, index, recordId, field, code, message };
}

/** One line per issue: file, record, field, then the message and its code. */
export function formatIssue(issue) {
  const parts = [issue.file];
  if (issue.index !== null) {
    parts.push(
      issue.recordId === null
        ? `ingredients[${issue.index}]`
        : `ingredient ${issue.recordId} (ingredients[${issue.index}])`,
    );
  }
  if (issue.field !== null) parts.push(`field ${issue.field}`);
  return `${parts.join(", ")}: ${issue.message} [${issue.code}]`;
}

const show = (value) => (value === undefined ? "nothing" : JSON.stringify(value));

/** A name in quotes, with invisible characters spelled out (U+200B and so on). */
const showName = (text) =>
  JSON.stringify(text).replace(
    /[\p{Cf}]/gu,
    (char) => `<U+${char.codePointAt(0).toString(16).toUpperCase().padStart(4, "0")}>`,
  );

// ---------------------------------------------------------------------------
// Schema errors as readable issues
// ---------------------------------------------------------------------------

/** "/ingredients/3/halal" -> ["ingredients", "3", "halal"] */
function pointerSegments(pointer) {
  return pointer
    .split("/")
    .slice(1)
    .map((part) => part.replaceAll("~1", "/").replaceAll("~0", "~"));
}

/** ["brandVariants", "0", "halal"] -> "brandVariants[0].halal" */
function fieldPath(segments) {
  let out = "";
  for (const part of segments) {
    if (/^\d+$/.test(part)) out += `[${part}]`;
    else out += out === "" ? part : `.${part}`;
  }
  return out === "" ? null : out;
}

function valueAt(root, segments) {
  let value = root;
  for (const part of segments) {
    if (value === null || typeof value !== "object" || !Object.hasOwn(value, part))
      return undefined;
    value = value[part];
  }
  return value;
}

/** Readable explanations for the schema's cross-field rules, keyed by keyword location. */
const SCHEMA_HINTS = [
  {
    last: "nonHalalSources",
    schemaPath: "#/else/properties/nonHalalSources/maxItems",
    message: (section) =>
      `lists non-halal source(s) ${show(section?.nonHalalSources)} while halal.value is ` +
      `${show(section?.value)}: a record that lists alcohol, pork or a non-halal animal source ` +
      `must use "not_halal" (SAF-08)`,
  },
  {
    last: "nonHalalSources",
    schemaPath: "#/then/properties/nonHalalSources/minItems",
    message: () => `halal.value "not_halal" needs at least one nonHalalSources entry (SAF-08)`,
  },
  {
    last: "vegan",
    schemaPath: "#/allOf/0/then/properties/vegan/const",
    message: (section) =>
      `diet.vegetarian is "not_suitable", so diet.vegan must be "not_suitable" ` +
      `(found ${show(section?.vegan)}) (PRF-03)`,
  },
  {
    last: "vegetarian",
    schemaPath: "#/allOf/1/then/properties/vegetarian/const",
    message: (section) =>
      `diet.vegan "suitable" requires diet.vegetarian "suitable" ` +
      `(found ${show(section?.vegetarian)}) (PRF-03)`,
  },
  {
    last: "brandVariants",
    schemaPath: "#/then/properties/brandVariants/maxItems",
    message: () => `brandVariants must be empty when brandVaries is false (SAF-07)`,
  },
];

/** @returns {{ segments: string[], message: string }} where the error is and what it means */
function describeSchemaError(error, data) {
  const segments = pointerSegments(error.instancePath);
  const hint = SCHEMA_HINTS.find(
    (candidate) => error.schemaPath === candidate.schemaPath && segments.at(-1) === candidate.last,
  );
  if (hint) return { segments, message: hint.message(valueAt(data, segments.slice(0, -1))) };
  const params = error.params ?? {};
  switch (error.keyword) {
    case "required":
      return {
        segments: [...segments, params.missingProperty],
        message: "is required but missing",
      };
    case "additionalProperties":
      return {
        segments: [...segments, params.additionalProperty],
        message: "is not a known field",
      };
    case "enum":
      return {
        segments,
        message: `${show(valueAt(data, segments))} is not allowed; use one of ${params.allowedValues.map(show).join(", ")}`,
      };
    case "const":
      return { segments, message: `must be ${show(params.allowedValue)}` };
    default:
      return { segments, message: error.message ?? "is invalid" };
  }
}

/** Schema errors mapped to the record and field they concern. */
function schemaIssues(path, data, validators) {
  if (validators.dataset(data)) return [];
  const issues = [];
  for (const error of validators.dataset.errors ?? []) {
    // An `if` error only says "must match then/else"; the error behind it is reported too.
    if (error.keyword === "if") continue;
    const { segments, message } = describeSchemaError(error, data);
    if (segments[0] === "ingredients" && segments.length >= 2) {
      const id = valueAt(data, ["ingredients", segments[1], "id"]);
      issues.push(
        makeIssue(path, "schema", message, {
          index: Number(segments[1]),
          recordId: typeof id === "string" ? id : null,
          field: fieldPath(segments.slice(2)),
        }),
      );
    } else {
      issues.push(makeIssue(path, "schema", message, { field: fieldPath(segments) }));
    }
  }
  return issues;
}

// ---------------------------------------------------------------------------
// Names (security review L5)
// ---------------------------------------------------------------------------

/** Comparison key: case, accents, invisible characters, spaces and punctuation folded. */
export function nameKey(text) {
  return text
    .normalize("NFKD")
    .replace(/[\p{M}\p{Cc}\p{Cf}]/gu, "")
    .toLowerCase()
    .replace(/[\s\p{P}\p{S}]+/gu, " ")
    .trim();
}

/** Why a name is badly formed, or null. */
export function nameProblem(text) {
  if (text !== text.normalize("NFC")) return "is not in Unicode NFC form";
  if (text !== text.trim()) return "has leading or trailing spaces";
  if (/[\p{Cc}\p{Cf}]/u.test(text)) return "contains a control or invisible (zero-width) character";
  if (/\s{2,}/u.test(text)) return "contains repeated spaces";
  if (nameKey(text) === "") return "has no letters or digits";
  return null;
}

/** Name fields used to resolve recipe text to an ingredient. */
function resolvableNames(ingredient) {
  return [
    ["displayName.id", ingredient.displayName.id],
    ["displayName.en", ingredient.displayName.en],
    ...ingredient.localNames.map((name, i) => [`localNames[${i}]`, name]),
  ];
}

// ---------------------------------------------------------------------------
// Per-record checks
// ---------------------------------------------------------------------------

function overlap(a, b) {
  return a.filter((tag) => b.includes(tag));
}

/** The generic data and each brand variant, with the field prefix for reporting. */
function sections(ingredient) {
  return [
    { prefix: "", brandId: null, data: ingredient },
    ...ingredient.brandVariants.map((variant, i) => ({
      prefix: `brandVariants[${i}].`,
      brandId: variant.brandId,
      data: variant,
    })),
  ];
}

function recordIssues(ingredient, at) {
  const issues = [];
  const add = (code, field, message) => issues.push(at(code, field, message));

  for (const [field, text] of resolvableNames(ingredient)) {
    const problem = nameProblem(text);
    if (problem) add("name_format", field, `${showName(text)} ${problem}`);
  }
  const brandIds = new Set();
  ingredient.brandVariants.forEach((variant, i) => {
    if (brandIds.has(variant.brandId)) {
      add("duplicate_brand", `brandVariants[${i}].brandId`, `duplicate brandId ${variant.brandId}`);
    }
    brandIds.add(variant.brandId);
    const problem = nameProblem(variant.brandName);
    if (problem) {
      add(
        "name_format",
        `brandVariants[${i}].brandName`,
        `${showName(variant.brandName)} ${problem}`,
      );
    }
  });

  for (const { prefix, brandId, data } of sections(ingredient)) {
    const brand = brandId === null ? "" : ` (brand ${brandId})`;
    for (const tag of overlap(data.allergens.contains, data.allergens.mayContain)) {
      add(
        "allergen_overlap",
        `${prefix}allergens`,
        `allergen ${tag} is in both contains and mayContain${brand}`,
      );
    }
    if (data.components.ingredientIds.includes(ingredient.id)) {
      add(
        "self_component",
        `${prefix}components.ingredientIds`,
        `lists itself as a component${brand}`,
      );
    }
    // QA review L7: pork or a non-halal animal is never vegetarian.
    const animal = data.halal.nonHalalSources.filter((source) => ANIMAL_SOURCES.includes(source));
    if (animal.length > 0 && data.diet.vegetarian !== "not_suitable") {
      add(
        "halal_diet_conflict",
        `${prefix}diet.vegetarian`,
        `halal.nonHalalSources lists ${animal.join(", ")}, so diet.vegetarian must be ` +
          `"not_suitable" (found ${show(data.diet.vegetarian)})${brand} (PRF-03, SAF-08)`,
      );
    }
  }
  return issues;
}

// ---------------------------------------------------------------------------
// Component graph: cycles and depth. Iterative, so a crafted deep chain cannot
// overflow the stack (security review L1).
// ---------------------------------------------------------------------------

function knownChildren(ingredient, byId) {
  const ids = sections(ingredient).flatMap(({ data }) => data.components.ingredientIds);
  return [...new Set(ids)].filter((id) => id !== ingredient.id && byId.has(id));
}

function chainText(chain) {
  const shown = chain.length > 12 ? [...chain.slice(0, 6), "…", ...chain.slice(-5)] : chain;
  return shown.join(" > ");
}

function graphIssues(byId, maxDepth, atRecord) {
  const issues = [];
  const children = new Map();
  const hasParent = new Set();
  for (const [id, entry] of byId) {
    const list = entry.valid ? knownChildren(entry.ingredient, byId) : [];
    children.set(id, list);
    for (const child of list) hasParent.add(child);
  }

  const state = new Map(); // id -> "visiting" | "done"
  const depth = new Map(); // id -> longest chain of components below it
  const next = new Map(); // id -> the child on that chain
  for (const root of [...byId.keys()].sort()) {
    if (state.has(root)) continue;
    state.set(root, "visiting");
    const stack = [{ id: root, position: 0 }];
    while (stack.length > 0) {
      const frame = stack[stack.length - 1];
      const list = children.get(frame.id);
      if (frame.position < list.length) {
        const child = list[frame.position++];
        if (state.get(child) === "visiting") {
          const start = stack.findIndex((item) => item.id === child);
          const cycle = [...stack.slice(start).map((item) => item.id), child];
          issues.push(
            atRecord(
              child,
              "component_cycle",
              "components.ingredientIds",
              `component cycle: ${cycle.join(" > ")}`,
            ),
          );
        } else if (!state.has(child)) {
          state.set(child, "visiting");
          stack.push({ id: child, position: 0 });
        }
        continue;
      }
      let best = 0;
      let bestChild = null;
      for (const child of list) {
        // A child still being visited closes a cycle, which is reported above.
        if (state.get(child) === "done" && depth.get(child) + 1 > best) {
          best = depth.get(child) + 1;
          bestChild = child;
        }
      }
      depth.set(frame.id, best);
      next.set(frame.id, bestChild);
      state.set(frame.id, "done");
      stack.pop();
    }
  }

  const tooDeep = [...byId.keys()].sort().filter((id) => depth.get(id) > maxDepth);
  // Report the top of each over-limit chain only: everything below it is over
  // the limit because of it. When every one has a parent (cycles), report all.
  const tops = tooDeep.filter((id) => !hasParent.has(id));
  for (const id of tops.length > 0 ? tops : tooDeep) {
    const chain = [id];
    for (let child = next.get(id); child; child = next.get(child)) chain.push(child);
    issues.push(
      atRecord(
        id,
        "component_depth",
        "components.ingredientIds",
        `component chain is ${depth.get(id)} levels deep, more than the limit of ${maxDepth}: ` +
          chainText(chain),
      ),
    );
  }
  return issues;
}

// ---------------------------------------------------------------------------
// Files
// ---------------------------------------------------------------------------

function optionsOf(options = {}) {
  const mode = options.mode ?? "reference";
  if (!MODES.includes(mode)) throw new Error(`unknown mode ${mode}`);
  const maxComponentDepth = options.maxComponentDepth ?? DEFAULT_MAX_COMPONENT_DEPTH;
  if (!Number.isInteger(maxComponentDepth) || maxComponentDepth < 1) {
    throw new Error("maxComponentDepth must be a whole number of at least 1");
  }
  return { mode, maxComponentDepth, validators: options.validators ?? createValidators() };
}

/** File-level checks. Returns the parsed dataset, or null when it cannot be checked further. */
function readDatasetFile({ path, content }, mode, issues) {
  if (mode === "reference" && content.includes(FIXTURE_MARKER)) {
    issues.push(
      makeIssue(
        path,
        "fixture_in_reference",
        "test fixtures must never be placed in reference data",
      ),
    );
    return null;
  }
  let data;
  try {
    data = JSON.parse(content);
  } catch (error) {
    issues.push(makeIssue(path, "invalid_json", `not valid JSON (${error.message})`));
    return null;
  }
  const isObject = data !== null && typeof data === "object" && !Array.isArray(data);
  if (!isObject || data.schema !== INGREDIENT_DATASET) {
    issues.push(
      makeIssue(
        path,
        "unknown_kind",
        `unknown or missing "schema"; expected "${INGREDIENT_DATASET}"`,
        { field: "schema" },
      ),
    );
    return null;
  }
  const marked = typeof data.$comment === "string" && data.$comment.startsWith(FIXTURE_COMMENT);
  if (mode === "fixture" && !marked) {
    issues.push(
      makeIssue(
        path,
        "fixture_unmarked",
        `a fixture file must carry "$comment": "${FIXTURE_COMMENT}"`,
        { field: "$comment" },
      ),
    );
  }
  return data;
}

function versionIssue(path, version, mode) {
  if (mode === "reference" && looksLikeFixtureVersion(version)) {
    return makeIssue(
      path,
      "fixture_in_reference",
      `version ${show(version)} is a test fixture version`,
      { field: "version" },
    );
  }
  if (mode === "fixture" && !version.startsWith(FIXTURE_VERSION_PREFIX)) {
    return makeIssue(
      path,
      "fixture_unmarked",
      `a fixture version must start with ${FIXTURE_VERSION_PREFIX}`,
      { field: "version" },
    );
  }
  return null;
}

/**
 * Checks reference files.
 * @param {{ path: string, content: string }[]} files
 * @param {{ mode?: "reference" | "fixture", maxComponentDepth?: number, validators?: object }} [options]
 * @returns {{ issues: Issue[], version: string | null, ingredients: object[] }}
 *   `ingredients` holds the records exactly as written, in file order. Use it
 *   only when `issues` is empty.
 */
export function checkReferenceFiles(files, options) {
  const { mode, maxComponentDepth, validators } = optionsOf(options);
  const issues = [];
  /** @type {Map<string, { path: string, index: number, ingredient: any, valid: boolean }>} */
  const byId = new Map();
  const versions = new Map();
  const ingredients = [];

  for (const file of files) {
    const data = readDatasetFile(file, mode, issues);
    if (data === null) continue;
    const { path } = file;
    const invalid = schemaIssues(path, data, validators);
    issues.push(...invalid);
    if (invalid.some((issue) => issue.index === null)) continue; // the envelope itself is broken
    const invalidRecords = new Set(invalid.map((issue) => issue.index));

    versions.set(path, data.version);
    const badVersion = versionIssue(path, data.version, mode);
    if (badVersion) issues.push(badVersion);

    data.ingredients.forEach((ingredient, index) => {
      const id = typeof ingredient?.id === "string" ? ingredient.id : null;
      if (id === null) return; // reported by the schema
      const at = (code, field, message) =>
        makeIssue(path, code, message, { index, recordId: id, field });
      const first = byId.get(id);
      if (first) {
        issues.push(
          at(
            "duplicate_id",
            "id",
            `duplicate id, also in ${first.path} (ingredients[${first.index}])`,
          ),
        );
        return;
      }
      const valid = !invalidRecords.has(index);
      byId.set(id, { path, index, ingredient, valid });
      ingredients.push(ingredient);
      if (valid) issues.push(...recordIssues(ingredient, at));
    });
  }

  if (new Set(versions.values()).size > 1) {
    const list = [...versions].map(([path, version]) => `${path}=${version}`).join(", ");
    issues.push(
      makeIssue(
        DATASET_FILE,
        "version_mismatch",
        `all reference files must share one data version (DAT-06): ${list}`,
      ),
    );
  }

  const atRecord = (id, code, field, message) => {
    const { path, index } = byId.get(id);
    return makeIssue(path, code, message, { index, recordId: id, field });
  };

  // Every name must resolve to one ingredient only.
  const names = new Map();
  for (const [id, { path, ingredient, valid }] of byId) {
    if (!valid) continue;
    const seen = new Set();
    for (const [field, text] of resolvableNames(ingredient)) {
      const key = nameKey(text);
      if (key === "" || seen.has(key)) continue;
      seen.add(key);
      const first = names.get(key);
      if (first === undefined) {
        names.set(key, { id, path, field, text });
        continue;
      }
      issues.push(
        atRecord(
          id,
          "name_ambiguous",
          field,
          `${showName(text)} matches ${showName(first.text)} (${first.field} of ingredient ${first.id} ` +
            `in ${first.path}) after folding case, accents, spaces and punctuation; ` +
            `each name must point to one ingredient`,
        ),
      );
    }
  }

  // Every component must exist.
  for (const [id, { ingredient, valid }] of byId) {
    if (!valid) continue;
    for (const { prefix, data } of sections(ingredient)) {
      data.components.ingredientIds.forEach((child, j) => {
        if (!byId.has(child)) {
          issues.push(
            atRecord(
              id,
              "unknown_component",
              `${prefix}components.ingredientIds[${j}]`,
              `unknown component ${child}`,
            ),
          );
        }
      });
    }
  }

  issues.push(...graphIssues(byId, maxComponentDepth, atRecord));
  const [version = null] = versions.values();
  return { issues, version, ingredients };
}

/**
 * Validates reference files and returns readable error lines (empty when valid).
 * @param {{ path: string, content: string }[]} files
 */
export function validateReferenceFiles(files, validators = createValidators(), options = {}) {
  return checkReferenceFiles(files, { ...options, validators }).issues.map(formatIssue);
}

/** Lists every file under a directory. */
export function listFiles(dir) {
  const out = [];
  const walk = (current) => {
    for (const name of readdirSync(current).sort()) {
      const full = join(current, name);
      if (statSync(full).isDirectory()) walk(full);
      else if (!IGNORED_FILES.has(name)) out.push(full);
    }
  };
  walk(dir);
  return out;
}

/** Repository-relative path with forward slashes, or the absolute path outside the repository. */
export function displayPath(full) {
  const rel = relative(repoRoot, full);
  return (rel.startsWith("..") || isAbsolute(rel) ? full : rel).replaceAll("\\", "/");
}

/**
 * Checks a directory: every file must be a JSON dataset that passes.
 * @param {string} [dir]
 * @param {{ mode?: "reference" | "fixture", maxComponentDepth?: number, validators?: object }} [options]
 */
export function checkReferenceDir(dir = REFERENCE_DIR, options = {}) {
  const issues = [];
  const files = [];
  for (const full of listFiles(dir)) {
    const path = displayPath(full);
    if (!full.endsWith(".json")) {
      issues.push(makeIssue(path, "file_type", "only JSON datasets are allowed in reference data"));
      continue;
    }
    files.push({ path, content: readFileSync(full, "utf8") });
  }
  const result = checkReferenceFiles(files, options);
  return { ...result, fileCount: files.length, issues: [...issues, ...result.issues] };
}

/** Validates a directory and returns readable error lines. */
export function validateReferenceDir(dir = REFERENCE_DIR, options = {}) {
  const { fileCount, issues } = checkReferenceDir(dir, options);
  return { fileCount, errors: issues.map(formatIssue) };
}

/** Command-line options shared by the validate and build commands. */
export function parseCommonArgs(argv, extra = {}) {
  const { values, positionals } = parseArgs({
    args: argv,
    allowPositionals: true,
    options: {
      fixture: { type: "boolean", default: false },
      "max-component-depth": { type: "string" },
      ...extra,
    },
  });
  const rawDepth = values["max-component-depth"];
  const maxComponentDepth = rawDepth === undefined ? DEFAULT_MAX_COMPONENT_DEPTH : Number(rawDepth);
  if (!Number.isInteger(maxComponentDepth) || maxComponentDepth < 1) {
    throw new Error("--max-component-depth must be a whole number of at least 1");
  }
  return { values, positionals, mode: values.fixture ? "fixture" : "reference", maxComponentDepth };
}

/** Prints issues to stderr and returns exit code 1. */
export function reportIssues(heading, issues) {
  console.error(`${heading}\n`);
  for (const issue of issues) console.error(`  ${formatIssue(issue)}`);
  console.error(
    `\n${issues.length} problem(s). Nothing was changed; fix the source files and run again.`,
  );
  return 1;
}

/** @returns {number} exit code */
export function main(argv) {
  let args;
  try {
    args = parseCommonArgs(argv);
  } catch (error) {
    console.error(error.message);
    return 2;
  }
  const { positionals, mode, maxComponentDepth } = args;
  const dir = positionals[0] ? resolve(positionals[0]) : REFERENCE_DIR;
  const { fileCount, issues } = checkReferenceDir(dir, { mode, maxComponentDepth });
  if (issues.length > 0) return reportIssues("Reference data validation failed:", issues);
  console.log(
    `Reference data valid: ${fileCount} file(s) in ${displayPath(dir)} checked against ` +
      `data/schema/ (${mode} mode, component depth limit ${maxComponentDepth}).`,
  );
  return 0;
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  process.exitCode = main(process.argv.slice(2));
}
