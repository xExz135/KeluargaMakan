#!/usr/bin/env node
// Reference data validator (SAF-06, SAF-13, DAT-06). Checks every file in
// data/reference/ against the JSON Schemas in data/schema/, plus the rules a
// schema cannot express: one data version per release, unique IDs, components
// that point at existing ingredients, no component cycles, unique brand IDs
// per ingredient, and no allergen listed as both "contains" and "may contain".
//
// It validates values written by the content team; it never writes values.
//
// Usage: node scripts/validate-reference.mjs [referenceDir]

import { readFileSync, readdirSync, statSync } from "node:fs";
import { join, relative, resolve } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

import Ajv2020 from "ajv/dist/2020.js";

const repoRoot = resolve(fileURLToPath(new URL("..", import.meta.url)));
export const SCHEMA_DIR = join(repoRoot, "data", "schema");
export const REFERENCE_DIR = join(repoRoot, "data", "reference");

export const INGREDIENT_DATASET = "keluargamakan.reference.ingredients/1";
const SCHEMA_BASE = "https://schemas.keluargamakan.example/v1/";
const FIXTURE_MARKER = "TEST FIXTURE";
const IGNORED_FILES = new Set([".gitkeep"]);

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

function overlap(a, b) {
  return a.filter((tag) => b.includes(tag));
}

/** Checks one ingredient (and its brand variants) beyond the schema. */
function ingredientErrors(ingredient, where) {
  const errors = [];
  const sections = [{ label: "", data: ingredient }];
  const brandIds = new Set();
  for (const variant of ingredient.brandVariants) {
    if (brandIds.has(variant.brandId)) {
      errors.push(`${where}: duplicate brandId ${variant.brandId}`);
    }
    brandIds.add(variant.brandId);
    sections.push({ label: ` brand ${variant.brandId}`, data: variant });
  }
  for (const { label, data } of sections) {
    for (const tag of overlap(data.allergens.contains, data.allergens.mayContain)) {
      errors.push(`${where}${label}: allergen ${tag} is in both contains and mayContain`);
    }
    if (data.components.ingredientIds.includes(ingredient.id)) {
      errors.push(`${where}${label}: lists itself as a component`);
    }
  }
  return errors;
}

/** Component IDs of an ingredient across its generic data and all brand variants. */
function componentIds(ingredient) {
  return [
    ...ingredient.components.ingredientIds,
    ...ingredient.brandVariants.flatMap((variant) => variant.components.ingredientIds),
  ];
}

function cycleErrors(byId) {
  const errors = [];
  const state = new Map(); // id -> "visiting" | "done"
  const visit = (id, path) => {
    if (state.get(id) === "done") return;
    if (state.get(id) === "visiting") {
      errors.push(`component cycle: ${[...path, id].join(" > ")}`);
      return;
    }
    state.set(id, "visiting");
    for (const child of componentIds(byId.get(id).ingredient)) {
      if (byId.has(child) && child !== id) visit(child, [...path, id]);
    }
    state.set(id, "done");
  };
  for (const id of [...byId.keys()].sort()) visit(id, []);
  return errors;
}

/**
 * Validates reference files.
 * @param {{ path: string, content: string }[]} files
 * @returns {string[]} errors, empty when valid
 */
export function validateReferenceFiles(files, validators = createValidators()) {
  const errors = [];
  const byId = new Map();
  const versions = new Map();

  for (const { path, content } of files) {
    if (content.includes(FIXTURE_MARKER)) {
      errors.push(`${path}: test fixtures must never be placed in reference data`);
      continue;
    }
    let data;
    try {
      data = JSON.parse(content);
    } catch (error) {
      errors.push(`${path}: not valid JSON (${error.message})`);
      continue;
    }
    if (data === null || typeof data !== "object" || data.schema !== INGREDIENT_DATASET) {
      errors.push(`${path}: unknown or missing "schema"; expected "${INGREDIENT_DATASET}"`);
      continue;
    }
    const invalid = schemaErrors(validators.dataset, data);
    if (invalid.length > 0) {
      errors.push(...invalid.map((message) => `${path}: ${message}`));
      continue;
    }
    versions.set(path, data.version);
    data.ingredients.forEach((ingredient, index) => {
      const where = `${path}: ingredients[${index}] ${ingredient.id}`;
      if (byId.has(ingredient.id)) {
        errors.push(`${where}: duplicate id, also in ${byId.get(ingredient.id).path}`);
        return;
      }
      byId.set(ingredient.id, { path, ingredient });
      errors.push(...ingredientErrors(ingredient, where));
    });
  }

  if (new Set(versions.values()).size > 1) {
    const list = [...versions].map(([path, version]) => `${path}=${version}`).join(", ");
    errors.push(`all reference files must share one data version (DAT-06): ${list}`);
  }
  for (const [id, { path, ingredient }] of byId) {
    for (const child of new Set(componentIds(ingredient))) {
      if (!byId.has(child)) errors.push(`${path}: ${id} has unknown component ${child}`);
    }
  }
  errors.push(...cycleErrors(byId));
  return errors;
}

/** Lists every file under a directory, with repository-relative paths. */
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

/** Validates a directory: every file must be a JSON dataset that passes. */
export function validateReferenceDir(dir = REFERENCE_DIR, validators = createValidators()) {
  const errors = [];
  const files = [];
  for (const full of listFiles(dir)) {
    const path = relative(repoRoot, full).replaceAll("\\", "/");
    if (!full.endsWith(".json")) {
      errors.push(`${path}: only JSON datasets are allowed in reference data`);
      continue;
    }
    files.push({ path, content: readFileSync(full, "utf8") });
  }
  return {
    fileCount: files.length,
    errors: [...errors, ...validateReferenceFiles(files, validators)],
  };
}

function main() {
  const dir = process.argv[2] ? resolve(process.argv[2]) : REFERENCE_DIR;
  const { fileCount, errors } = validateReferenceDir(dir);
  if (errors.length > 0) {
    console.error("Reference data validation failed:\n");
    for (const error of errors) console.error(`  ${error}`);
    process.exit(1);
  }
  console.log(`Reference data valid: ${fileCount} file(s) checked against data/schema/.`);
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  main();
}
