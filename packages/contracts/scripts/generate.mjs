// Regenerates the API clients from openapi.yaml. Never edit their output:
//   src/generated/schema.ts   TypeScript types (openapi-typescript), used with openapi-fetch
//   generated/dart/           Dart package `keluargamakan_api` (OpenAPI Generator, `dart`)
//
// The Dart generator is a pinned OpenAPI Generator jar from Maven Central,
// verified against a SHA-256 checksum before it runs, and needs Java 11 or
// later. Set OPENAPI_GENERATOR_JAR to use a local copy of the same jar (it is
// verified too).
//
// `pnpm check:contracts` runs this and then fails if the output differs from
// what is committed.

import { spawnSync } from "node:child_process";
import { createHash } from "node:crypto";
import {
  existsSync,
  mkdirSync,
  readFileSync,
  readdirSync,
  renameSync,
  rmSync,
  statSync,
  writeFileSync,
} from "node:fs";
import { join } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

import openapiTS, { astToString } from "openapi-typescript";
import { parse } from "yaml";

export const OPENAPI_GENERATOR = {
  version: "7.26.0",
  sha256: "1760050094997b9cc790cc1350be095f15da8c08a996b184d3eadc4ccda5e35e",
};

const pkgDir = fileURLToPath(new URL("..", import.meta.url));
const specPath = join(pkgDir, "openapi.yaml");
const tsOut = join(pkgDir, "src", "generated", "schema.ts");
const dartOut = join(pkgDir, "generated", "dart");
const dartIgnoreFile = join(pkgDir, "codegen", "dart.openapi-generator-ignore");
const jarCacheDir = join(pkgDir, "node_modules", ".cache", "openapi-generator");
const DART_EXTRAS = [
  ".gitignore",
  ".openapi-generator-ignore",
  ".openapi-generator/FILES",
  ".travis.yml",
  "analysis_options.yaml",
  "doc",
  "git_push.sh",
  "test",
];

const log = (message) => process.stdout.write(`${message}\n`);

function fail(message) {
  process.stderr.write(`generate: ${message}\n`);
  process.exit(1);
}

function sha256(buffer) {
  return createHash("sha256").update(buffer).digest("hex");
}

/** Every file below `dir`, recursively. */
function listFiles(dir) {
  return readdirSync(dir).flatMap((name) => {
    const path = join(dir, name);
    return statSync(path).isDirectory() ? listFiles(path) : [path];
  });
}

/** Generators may write the platform line ending; the repository uses LF. */
function normalizeLineEndings(dir) {
  for (const file of listFiles(dir)) {
    const text = readFileSync(file, "utf8");
    if (text.includes("\r\n")) writeFileSync(file, text.replaceAll("\r\n", "\n"));
  }
}

async function generateTypeScript() {
  const ast = await openapiTS(pathToFileURL(specPath));
  const header = [
    "// GENERATED FILE: do not edit. Source: packages/contracts/openapi.yaml.",
    "// Regenerate with `pnpm --filter @keluargamakan/contracts run generate`.",
    "",
  ].join("\n");
  mkdirSync(join(pkgDir, "src", "generated"), { recursive: true });
  writeFileSync(tsOut, header + astToString(ast));
  log("TypeScript: src/generated/schema.ts");
}

async function resolveGeneratorJar() {
  const { version, sha256: expected } = OPENAPI_GENERATOR;
  const override = process.env.OPENAPI_GENERATOR_JAR;
  const jarPath = override ?? join(jarCacheDir, `openapi-generator-cli-${version}.jar`);

  if (!existsSync(jarPath)) {
    if (override) fail(`OPENAPI_GENERATOR_JAR points at a missing file: ${override}`);
    const url =
      "https://repo1.maven.org/maven2/org/openapitools/openapi-generator-cli/" +
      `${version}/openapi-generator-cli-${version}.jar`;
    log(`Downloading OpenAPI Generator ${version} from Maven Central`);
    const response = await fetch(url);
    if (!response.ok) fail(`download failed (${response.status}): ${url}`);
    const jar = Buffer.from(await response.arrayBuffer());
    if (sha256(jar) !== expected) fail(`checksum mismatch for ${url}; refusing to run it`);
    mkdirSync(jarCacheDir, { recursive: true });
    const partial = `${jarPath}.partial`;
    writeFileSync(partial, jar);
    renameSync(partial, jarPath);
  }

  if (sha256(readFileSync(jarPath)) !== expected) {
    fail(`checksum mismatch for ${jarPath}; expected OpenAPI Generator ${version}`);
  }
  return jarPath;
}

function generateDart(jarPath, spec) {
  const java = spawnSync("java", ["-version"], { encoding: "utf8" });
  if (java.error || java.status !== 0)
    fail("Java 11 or later is required to generate the Dart client");

  const properties = {
    pubName: "keluargamakan_api",
    pubLibrary: "keluargamakan_api",
    pubVersion: spec.info.version,
    pubDescription: "Generated KeluargaMakan API client. Do not edit.",
    pubHomepage: "https://github.com/xExz135/KeluargaMakan",
    pubPublishTo: "none",
    // enumUnknownDefaultCase stays off: in this generator it adds an
    // `unknownDefaultOpenApi` member that decoding never returns and that could
    // be sent back to the server. An unknown value decodes to null instead, so
    // a required enum field fails to decode (fail closed) and is never read as
    // a known value.
    useFinalProperties: "true",
    // Optional<T> keeps "absent" apart from "null", so PATCH bodies and
    // optional create fields are omitted rather than sent as null.
    useOptional: "true",
  };

  rmSync(dartOut, { recursive: true, force: true });
  const args = [
    "-Dfile.encoding=UTF-8",
    "-jar",
    jarPath,
    "generate",
    "--input-spec",
    specPath,
    "--generator-name",
    "dart",
    "--output",
    dartOut,
    "--ignore-file-override",
    dartIgnoreFile,
    "--global-property",
    "apiDocs=false,modelDocs=false,apiTests=false,modelTests=false",
    ...Object.entries(properties).flatMap(([key, value]) => [
      "--additional-properties",
      `${key}=${value}`,
    ]),
  ];
  const result = spawnSync("java", args, { encoding: "utf8", maxBuffer: 64 * 1024 * 1024 });
  if (result.error || result.status !== 0) {
    process.stderr.write(result.stdout ?? "");
    process.stderr.write(result.stderr ?? "");
    fail("Dart client generation failed");
  }
  for (const line of `${result.stdout}\n${result.stderr}`.split("\n")) {
    if (/\b(WARN|ERROR)\b/.test(line) && !line.includes("OpenAPI 3.1 support is still in beta")) {
      process.stderr.write(`${line}\n`);
    }
  }
  // Supporting files the ignore file does not reliably suppress: CI and git
  // helpers, an empty analysis_options.yaml, and the generator's manifest.
  // Markdown is never kept (the repository commits no *.md files).
  for (const extra of DART_EXTRAS) rmSync(join(dartOut, extra), { recursive: true, force: true });
  for (const file of listFiles(dartOut)) if (file.endsWith(".md")) rmSync(file);
  normalizeLineEndings(dartOut);
  log("Dart: generated/dart (package keluargamakan_api)");
}

const spec = parse(readFileSync(specPath, "utf8"));
await generateTypeScript();
generateDart(await resolveGeneratorJar(), spec);
