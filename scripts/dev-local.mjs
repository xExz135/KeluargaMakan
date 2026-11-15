#!/usr/bin/env node
// Local test server for the owner (NFR-10: no secrets in the repo, local
// shortcuts refused outside APP_ENV=local). One command starts the API on
// this computer so the app on the Android emulator can be clicked through.
// Private use, no cost, nothing deployed, no Docker.
//
// Run `pnpm dev:local --help` for usage.
//
// What it does:
//   1. Creates .local-dev/ (git-ignored) with local-only random keys in
//      .local-dev/.env on the first run. Keys are never printed.
//   2. Builds the API with TypeScript.
//   3. Builds the TEST FIXTURE kitchen catalog (fictional ingredients, every
//      safety value unverified, so Cek Aman can only say "Check the label")
//      with the real build-reference script, into .local-dev/reference/.
//   4. Starts the API with APP_ENV=local on an embedded PostgreSQL (PGlite)
//      in .local-dev/pgdata, after applying the migrations, listening on
//      127.0.0.1 only. Sign-in codes are printed in this terminal.
//
// This file names the test fixtures folder; the fixture guard exempts it
// because it is local development tooling (scripts/check-fixture-refs.mjs).

import { execFileSync, spawn } from "node:child_process";
import { randomBytes, randomUUID } from "node:crypto";
import {
  chmodSync,
  existsSync,
  mkdirSync,
  readFileSync,
  renameSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { createServer } from "node:net";
import { join, relative } from "node:path";
import { createInterface } from "node:readline";
import { createInterface as createPrompt } from "node:readline/promises";
import { parseArgs as parseNodeArgs } from "node:util";
import { pathToFileURL } from "node:url";

import { buildReference } from "./build-reference.mjs";
import { repoRoot } from "./validate-reference.mjs";

export const LOCAL_DIR = join(repoRoot, ".local-dev");
export const FIXTURE_CATALOG_SOURCE = join(repoRoot, "data/fixtures/kitchen-catalog");
export const API_ENTRY = join(repoRoot, "services/api/dist/src/local/main-local.js");
export const DEFAULT_PORT = 3000;
export const DEFAULT_DEVICE = "emulator-5554";
export const EMULATOR_HOST = "10.0.2.2";
export const EXAMPLE_PHONE = "+6281234567890";

/** Files under the local folder. */
export function localPaths(localDir = LOCAL_DIR) {
  return {
    dir: localDir,
    secrets: join(localDir, ".env"),
    pgdata: join(localDir, "pgdata"),
    reference: join(localDir, "reference", "fixture-kitchen-catalog.json"),
    lock: join(localDir, "server.lock"),
    state: join(localDir, "server.json"),
  };
}

/** Security review 2026-11-15 L2: shown in --help and when the server is up. */
export const MADE_UP_DATA_ONLY = [
  "Gunakan anggota keluarga rekaan saja. Jangan masukkan data kesehatan atau data anak yang asli.",
  "Use made-up family members only. Do not enter real health or children's data.",
];

export const HELP = `KeluargaMakan local test server (private, on this computer only)

${MADE_UP_DATA_ONLY.join("\n")}

Usage (PowerShell, in the repository folder):
  pnpm dev:local                 start the API for the Android emulator
  pnpm dev:local --reset         delete the local database and keys, then start empty
  pnpm dev:local --reset --yes   the same without the confirmation question
  pnpm dev:local --port 3001     use another port (default ${DEFAULT_PORT}; a free one
                                 is picked when ${DEFAULT_PORT} is taken)
  pnpm dev:local --no-build      skip the TypeScript build (after a previous run)

Then, in a second PowerShell window:
  pnpm dev:app                   flutter run on ${DEFAULT_DEVICE}, pointed at this server
  pnpm dev:app --device <id>     another emulator (see \`flutter devices\`)

Signing in: enter any test phone number in the app, for example
${EXAMPLE_PHONE} (or 081234567890). Nothing is sent by SMS: the code is
printed in this window, labelled LOCAL TEST SIGN-IN CODE.

What runs:
  - APP_ENV=local, embedded PostgreSQL (PGlite) in .local-dev/pgdata. Data
    stays between runs until --reset. The API refuses all of this outside
    APP_ENV=local.
  - Random local keys in .local-dev/.env, made on the first run, never
    printed and never committed (.local-dev/ is git-ignored). The folder is
    restricted to your user account (Windows: icacls; macOS and Linux: 0700);
    the server does not start if that fails.
  - The ingredient search uses the TEST FIXTURE kitchen catalog: fictional
    names, every safety value unverified, so Cek Aman can only answer
    "Check the label". It is not real safety or nutrition data.
  - The API listens on 127.0.0.1 only. The Android emulator reaches it as
    http://${EMULATOR_HOST}:<port>.

Stop the server with Ctrl+C.
`;

/** Command-line options. Throws on an unknown option. */
export function parseArgs(argv) {
  const { values } = parseNodeArgs({
    args: argv,
    options: {
      reset: { type: "boolean", default: false },
      yes: { type: "boolean", default: false },
      port: { type: "string" },
      "no-build": { type: "boolean", default: false },
      help: { type: "boolean", short: "h", default: false },
    },
    strict: true,
    allowPositionals: false,
  });
  let port = null;
  if (values.port !== undefined) {
    if (!/^[0-9]{1,5}$/.test(values.port) || Number(values.port) < 1024) {
      throw new Error("--port must be a number from 1024 to 65535");
    }
    port = Number(values.port);
    if (port > 65535) throw new Error("--port must be a number from 1024 to 65535");
  }
  if (values.yes && !values.reset) throw new Error("--yes only goes with --reset");
  return {
    reset: values.reset,
    yes: values.yes,
    port,
    build: !values["no-build"],
    help: values.help,
  };
}

// ---------- local secrets ----------

/** Every generated secret: base64 of 32 random bytes, all different. */
export const SECRET_NAMES = [
  "AUTH_TOKEN_KEY",
  "AUTH_HASH_KEY",
  "LOCAL_GENERAL_DATA_KEK",
  "LOCAL_HEALTH_DATA_KEK",
];
const KEY_FORMAT = /^[A-Za-z0-9+/]{43}=$/;

export function generateSecrets(random = randomBytes) {
  for (;;) {
    const secrets = Object.fromEntries(
      SECRET_NAMES.map((name) => [name, random(32).toString("base64")]),
    );
    if (new Set(Object.values(secrets)).size === SECRET_NAMES.length) return secrets;
  }
}

export function serializeSecrets(secrets) {
  return [
    "# KeluargaMakan local test server keys (pnpm dev:local). Made on this",
    "# computer for APP_ENV=local only. Never commit, share or reuse them.",
    "# `pnpm dev:local --reset` deletes them together with the local database.",
    ...SECRET_NAMES.map((name) => `${name}=${secrets[name]}`),
    "",
  ].join("\n");
}

export function parseEnvFile(text) {
  const values = {};
  for (const raw of text.split(/\r?\n/)) {
    const line = raw.trim();
    if (line === "" || line.startsWith("#")) continue;
    const equals = line.indexOf("=");
    if (equals <= 0) continue;
    values[line.slice(0, equals).trim()] = line.slice(equals + 1).trim();
  }
  return values;
}

/** Throws (without the values) unless every secret is a distinct 32-byte base64 key. */
export function checkSecrets(values) {
  const secrets = {};
  for (const name of SECRET_NAMES) {
    const value = values[name];
    if (typeof value !== "string" || !KEY_FORMAT.test(value)) {
      throw new Error(`${name} in .local-dev/.env is missing or is not a 32-byte base64 key`);
    }
    secrets[name] = value;
  }
  if (new Set(Object.values(secrets)).size !== SECRET_NAMES.length) {
    throw new Error("the keys in .local-dev/.env must all be different");
  }
  return secrets;
}

// ---------- folder permissions ----------

/**
 * Security review 2026-11-15 L1: the keys sit next to the database they
 * decrypt, so .local-dev/ must be readable by the current user only. On
 * Windows `mode` bits do nothing and a new folder inherits the drive's ACL
 * (often Authenticated Users: Modify), so inheritance is removed and only the
 * current user's SID is granted full control. Fixed executables from
 * System32 with fixed arguments; no shell.
 */
function system32(name, env = process.env) {
  return join(env["SystemRoot"] ?? env["SYSTEMROOT"] ?? "C:\\Windows", "System32", name);
}

/** Parses `whoami /user /fo csv /nh` output: `"host\user","S-1-5-..."`. */
export function parseWhoamiSid(output) {
  const match = /"(S-1-[0-9-]+)"\s*$/m.exec(output.trim());
  if (match === null) throw new Error("could not read the current Windows user's SID");
  return match[1];
}

/** The icacls arguments that leave `dir` to the user with `sid` alone. */
export function windowsRestrictArgs(dir, sid) {
  if (!/^S-1-[0-9-]+$/.test(sid)) throw new Error("not a Windows SID");
  return [dir, "/inheritance:r", "/grant:r", `*${sid}:(OI)(CI)F`];
}

/**
 * Restricts the local folder to the current user, or throws so the server
 * does not start. `run(file, args)` returns stdout and throws on failure.
 */
export function restrictLocalDir(paths, options = {}) {
  const platform = options.platform ?? process.platform;
  const run =
    options.run ??
    ((file, args) =>
      execFileSync(file, args, { encoding: "utf8", stdio: ["ignore", "pipe", "pipe"] }));
  try {
    if (platform === "win32") {
      const sid = parseWhoamiSid(run(system32("whoami.exe"), ["/user", "/fo", "csv", "/nh"]));
      run(system32("icacls.exe"), windowsRestrictArgs(paths.dir, sid));
    } else {
      (options.chmod ?? chmodSync)(paths.dir, 0o700);
      if (existsSync(paths.secrets)) (options.chmod ?? chmodSync)(paths.secrets, 0o600);
    }
  } catch (error) {
    throw new Error(
      "could not restrict .local-dev/ to your user account, so the local test server " +
        `does not start (${error instanceof Error ? error.message.split("\n")[0] : "unknown error"})`,
      { cause: error },
    );
  }
}

/**
 * Reads the local keys, or makes them on the first run. A database without
 * its keys is refused: its health data was encrypted with the lost keys.
 */
export function loadOrCreateSecrets(paths, random = randomBytes) {
  if (existsSync(paths.secrets)) {
    return {
      created: false,
      secrets: checkSecrets(parseEnvFile(readFileSync(paths.secrets, "utf8"))),
    };
  }
  if (existsSync(paths.pgdata)) {
    throw new Error(
      "the local database exists but its keys (.local-dev/.env) are gone; " +
        "run `pnpm dev:local --reset` to start with an empty database",
    );
  }
  const secrets = generateSecrets(random);
  mkdirSync(paths.dir, { recursive: true });
  writeFileSync(paths.secrets, serializeSecrets(secrets), {
    encoding: "utf8",
    mode: 0o600,
    flag: "wx",
  });
  return { created: true, secrets };
}

// ---------- server environment ----------

// Operating system variables the child needs; nothing else is inherited, so a
// DATABASE_URL, cloud key setting or real credential in this shell never
// reaches the local server.
const INHERITED = new Set([
  "PATH",
  "PATHEXT",
  "SYSTEMROOT",
  "SYSTEMDRIVE",
  "WINDIR",
  "COMSPEC",
  "TEMP",
  "TMP",
  "TMPDIR",
  "HOME",
  "USERPROFILE",
  "APPDATA",
  "LOCALAPPDATA",
  "LANG",
  "TERM",
]);

/**
 * Sign-in rate limits for one person clicking through the app: the
 * production limits (5 codes per number per hour) would lock the owner out
 * for an hour after a few test sign-ins. Code length, expiry, resend wait and
 * wrong-code attempts stay as in production. APP_ENV=local only; the
 * production floors in services/api/config/api.ts still apply everywhere else.
 */
export const LOCAL_API_CONFIG = Object.freeze({
  rateLimits: {
    codeRequestPerDestination: { limit: 30, windowSeconds: 60 * 60 },
    codeRequestPerDestinationDaily: { limit: 200, windowSeconds: 24 * 60 * 60 },
    codeVerifyFailuresPerDestination: { limit: 100, windowSeconds: 24 * 60 * 60 },
    codeRequestPerClient: { limit: 200, windowSeconds: 60 * 60 },
    codeVerifyPerClient: { limit: 200, windowSeconds: 15 * 60 },
  },
});

export function serverEnv({ secrets, port, dataDir, reference, baseEnv = process.env }) {
  const env = {};
  for (const [name, value] of Object.entries(baseEnv)) {
    if (value !== undefined && INHERITED.has(name.toUpperCase())) env[name] = value;
  }
  return {
    ...env,
    APP_ENV: "local",
    NODE_ENV: "development",
    HOST: "127.0.0.1",
    PORT: String(port),
    LOCAL_PGLITE_DIR: dataDir,
    CODE_SENDER: "dev",
    KEY_PROVIDER: "local",
    LOCAL_GENERAL_DATA_KEK: secrets.LOCAL_GENERAL_DATA_KEK,
    LOCAL_HEALTH_DATA_KEK: secrets.LOCAL_HEALTH_DATA_KEK,
    AUTH_TOKEN_KEY: secrets.AUTH_TOKEN_KEY,
    AUTH_HASH_KEY: secrets.AUTH_HASH_KEY,
    REFERENCE_DATA_PATH: reference.path,
    REFERENCE_DATA_SHA256: reference.sha256,
    API_CONFIG_JSON: JSON.stringify(LOCAL_API_CONFIG),
  };
}

export function appCommand({ port, device = DEFAULT_DEVICE }) {
  return {
    cwd: join(repoRoot, "apps/mobile"),
    command: "flutter",
    args: ["run", "-d", device, `--dart-define=KM_API_BASE_URL=http://${EMULATOR_HOST}:${port}`],
  };
}

// ---------- log output ----------

const RULE = "=".repeat(64);

/**
 * Turns one line of the API's JSON log into what the owner reads. Returns
 * null for nothing to print.
 */
export function formatLogLine(line, { port } = {}) {
  let entry;
  try {
    entry = JSON.parse(line);
  } catch {
    return line.trim() === "" ? null : `[api] ${line}`;
  }
  if (entry === null || typeof entry !== "object") return `[api] ${line}`;
  const { event, level, ...fields } = entry;
  switch (event) {
    case "dev_sign_in_code":
      return [
        "",
        RULE,
        `  LOCAL TEST SIGN-IN CODE / KODE MASUK UJI LOKAL:  ${String(fields.code)}`,
        "  Shown here only. Nothing was sent by SMS or email.",
        RULE,
        "",
      ].join("\n");
    case "request":
      return `  ${String(fields.method)} ${String(fields.route ?? "(no route)")} -> ${String(fields.status)}`;
    case "local_database_ready":
      return `Local database ready (schema version ${String(fields.schemaVersion)}, ${String(fields.appliedMigrations)} migration(s) applied now).`;
    case "reference_data_loaded":
      return `Ingredient catalog: ${fields.fixture === true ? "TEST FIXTURE " : ""}${String(fields.referenceVersion)} (${String(fields.ingredientCount)} ingredients).`;
    case "reference_data_unavailable":
      return `Ingredient catalog NOT loaded (${String(fields.error)}): ${String(fields.reason)}. Search answers 503.`;
    case "api_start_failed":
      return `The API did not start: ${String(fields.error)}`;
    case "api_started":
      return readyBanner(port ?? fields.port);
    default:
      return `[api] ${level === "error" ? "ERROR " : ""}${String(event)} ${JSON.stringify(fields)}`;
  }
}

export function readyBanner(port) {
  const app = appCommand({ port });
  const portFlag = port === DEFAULT_PORT ? "" : ` --port ${port}`;
  return [
    "",
    RULE,
    `  KeluargaMakan local test server is running: http://127.0.0.1:${port}`,
    `  The Android emulator reaches it as http://${EMULATOR_HOST}:${port}`,
    RULE,
    "",
    "Next, open a second PowerShell window in the repository folder and run:",
    `  pnpm dev:app${portFlag}`,
    "which runs:",
    `  cd ${relative(repoRoot, app.cwd).replaceAll("\\", "/")}`,
    `  ${app.command} ${app.args.join(" ")}`,
    "",
    `Sign in with a test phone number such as ${EXAMPLE_PHONE}; the code appears here.`,
    ...MADE_UP_DATA_ONLY,
    "Data is kept in .local-dev/pgdata. Stop with Ctrl+C. `pnpm dev:local --help` for more.",
    "",
  ].join("\n");
}

// ---------- steps ----------

function isRunning(pid) {
  try {
    process.kill(pid, 0);
    return true;
  } catch (error) {
    return error.code === "EPERM";
  }
}

const STARTING = "another local test server is starting on this folder; wait for it, or try again";

function readLock(path) {
  try {
    return readFileSync(path, "utf8");
  } catch (error) {
    if (error.code === "ENOENT") return null;
    throw error;
  }
}

/** Exclusive create; false when the file already exists. */
function createExclusive(path, content) {
  try {
    writeFileSync(path, content, { encoding: "utf8", flag: "wx" });
    return true;
  } catch (error) {
    if (error.code === "EEXIST") return false;
    throw error;
  }
}

function holderOf(content) {
  const holder = Number(content.trim().split(/\s+/)[0]);
  return Number.isInteger(holder) && holder > 0 ? holder : null;
}

/**
 * Refuses a second server on the same database folder (security review
 * 2026-11-15 L4).
 *
 * - The lock is created exclusively (`wx`), and each lock holds a unique
 *   token next to the process ID.
 * - A lock whose process is gone is taken over only while holding a second,
 *   exclusively created file (`server.lock.takeover`). Under it the launcher
 *   checks the lock still holds the same stale token, moves it aside with an
 *   atomic rename, and creates its own lock exclusively again. Of several
 *   launchers that see the same stale lock, only one wins; the others
 *   refuse. A plain rename-and-check is not enough: a second launcher could
 *   rename away the lock the first had just written (found by the race test).
 */
export function takeLock(paths, { alive = isRunning, pid = process.pid } = {}) {
  mkdirSync(paths.dir, { recursive: true });
  const content = `${pid} ${randomUUID()}\n`;
  if (createExclusive(paths.lock, content)) return;

  const seen = readLock(paths.lock);
  if (seen === null) throw new Error(STARTING);
  const holder = holderOf(seen);
  if (holder !== null && holder !== pid && alive(holder)) {
    throw new Error(
      `a local test server is already running (process ${holder}); stop it with Ctrl+C in its ` +
        "window first. If none is running, delete .local-dev/server.lock",
    );
  }

  const takeover = `${paths.lock}.takeover`;
  if (!createExclusive(takeover, content)) {
    const other = holderOf(readLock(takeover) ?? "");
    if (other !== null && !alive(other)) {
      throw new Error(
        "an earlier start stopped while taking over the lock; delete .local-dev/server.lock.takeover",
      );
    }
    throw new Error(STARTING);
  }
  try {
    if (readLock(paths.lock) !== seen) throw new Error(STARTING);
    const aside = `${paths.lock}.${pid}.stale`;
    renameSync(paths.lock, aside);
    rmSync(aside, { force: true });
    if (!createExclusive(paths.lock, content)) throw new Error(STARTING);
  } finally {
    rmSync(takeover, { force: true });
  }
}

/** Removes the lock only if it is still ours. */
export function releaseLock(paths, pid = process.pid) {
  const current = readLock(paths.lock);
  if (current !== null && Number(current.trim().split(/\s+/)[0]) === pid) {
    rmSync(paths.lock, { force: true });
  }
}

async function confirmReset() {
  if (!process.stdin.isTTY) {
    throw new Error("--reset needs a confirmation; run it in a terminal or add --yes");
  }
  const prompt = createPrompt({ input: process.stdin, output: process.stdout });
  try {
    const answer = await prompt.question(
      "This deletes the local test database and its keys (.local-dev). Type yes to continue: ",
    );
    return answer.trim().toLowerCase() === "yes";
  } finally {
    prompt.close();
  }
}

function canListen(port) {
  return new Promise((resolve) => {
    const server = createServer();
    server.once("error", () => resolve(null));
    server.listen({ port, host: "127.0.0.1", exclusive: true }, () => {
      const { port: bound } = server.address();
      server.close(() => resolve(bound));
    });
  });
}

/** The requested port, or the default, or any free port when the default is taken. */
async function choosePort(requested) {
  const preferred = requested ?? DEFAULT_PORT;
  const bound = await canListen(preferred);
  if (bound !== null) return bound;
  if (requested !== null) throw new Error(`port ${requested} is in use; pick another with --port`);
  const free = await canListen(0);
  if (free === null) throw new Error("no free port found");
  console.log(`Port ${DEFAULT_PORT} is in use; using port ${free} instead.`);
  return free;
}

function pnpmCommand(args) {
  const execPath = process.env["npm_execpath"] ?? "";
  if (/pnpm[^\\/]*\.(c|m)?js$/i.test(execPath)) {
    return { command: process.execPath, args: [execPath, ...args], shell: false };
  }
  return { command: "pnpm", args, shell: process.platform === "win32" };
}

function runQuiet({ command, args, shell }, cwd) {
  return new Promise((resolve, reject) => {
    const child = spawn(command, args, { cwd, shell, stdio: ["ignore", "pipe", "pipe"] });
    let output = "";
    child.stdout.on("data", (chunk) => (output += chunk));
    child.stderr.on("data", (chunk) => (output += chunk));
    child.once("error", reject);
    child.once("exit", (code) => (code === 0 ? resolve() : reject(new Error(output.trim()))));
  });
}

function buildFixtureCatalog(paths) {
  const result = buildReference({
    mode: "fixture",
    source: FIXTURE_CATALOG_SOURCE,
    out: paths.reference,
  });
  if (!result.ok) {
    const lines = [...result.errors, ...result.issues.map((issue) => JSON.stringify(issue))];
    throw new Error(`the TEST FIXTURE catalog did not build:\n${lines.join("\n")}`);
  }
  if (result.dataset.fixture !== true)
    throw new Error("the local catalog must be a TEST FIXTURE build");
  return { path: result.out, sha256: result.dataset.contentHash.value, dataset: result.dataset };
}

function runServer({ env, port, paths }) {
  return new Promise((resolve) => {
    const child = spawn(process.execPath, [API_ENTRY], {
      cwd: repoRoot,
      env: { ...env, LOCAL_STOP_ON_STDIN_CLOSE: "1" },
      // The API stops cleanly when this pipe closes: on Ctrl+C below, and
      // also when this script is killed, so it never outlives this window.
      stdio: ["pipe", "pipe", "pipe"],
    });
    const print = (stream, write) =>
      createInterface({ input: stream }).on("line", (line) => {
        const text = formatLogLine(line, { port });
        if (text === null) return;
        write(text);
        if (line.includes('"event":"api_started"')) {
          writeFileSync(paths.state, `${JSON.stringify({ port })}\n`, "utf8");
        }
      });
    print(child.stdout, (text) => console.log(text));
    print(child.stderr, (text) => console.error(text));

    // Closing stdin asks the API to close its database and exit (Ctrl+C also
    // reaches it directly in the same console). Give it time, then end it.
    let stopping = false;
    const stop = () => {
      if (stopping) return;
      stopping = true;
      console.log("\nStopping the local test server...");
      child.stdin.end();
      setTimeout(() => child.kill(), 10_000).unref();
    };
    child.stdin.on("error", () => undefined);
    process.on("SIGINT", stop);
    process.on("SIGTERM", stop);
    process.on("SIGHUP", stop);
    child.once("exit", (code) => resolve(stopping ? 0 : (code ?? 1)));
  });
}

export async function main(argv) {
  let options;
  try {
    options = parseArgs(argv);
  } catch (error) {
    console.error(`${error.message}\n\n${HELP}`);
    return 2;
  }
  if (options.help) {
    console.log(HELP);
    return 0;
  }
  const paths = localPaths();
  try {
    mkdirSync(paths.dir, { recursive: true });
    restrictLocalDir(paths);
    takeLock(paths);
  } catch (error) {
    console.error(error.message);
    return 1;
  }
  try {
    if (options.reset) {
      if (!options.yes && !(await confirmReset())) {
        console.log("Nothing was deleted.");
        return 1;
      }
      for (const path of [paths.pgdata, paths.secrets, paths.reference, paths.state]) {
        rmSync(path, { recursive: true, force: true });
      }
      console.log("Deleted the local test database and its keys; starting empty.");
    }

    const { created, secrets } = loadOrCreateSecrets(paths);
    console.log(
      created
        ? "Made new local-only keys in .local-dev/.env (git-ignored, not shown)."
        : "Using the local keys in .local-dev/.env.",
    );

    if (options.build) {
      console.log("Building the API (TypeScript)...");
      await runQuiet(pnpmCommand(["--filter", "@keluargamakan/api...", "run", "build"]), repoRoot);
    }
    if (!existsSync(API_ENTRY)) {
      throw new Error("the API is not built; run without --no-build");
    }

    const reference = buildFixtureCatalog(paths);
    console.log(
      `Built the TEST FIXTURE kitchen catalog (${reference.dataset.ingredientCount} fictional ingredients; ` +
        "not real safety data, Cek Aman answers Check the label for all of them).",
    );

    const port = await choosePort(options.port);
    const env = serverEnv({ secrets, port, dataDir: paths.pgdata, reference });
    console.log(`Starting the API on port ${port} (APP_ENV=local, embedded database)...`);
    return await runServer({ env, port, paths });
  } catch (error) {
    console.error(error.message);
    return 1;
  } finally {
    rmSync(paths.state, { force: true });
    releaseLock(paths);
  }
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  process.exitCode = await main(process.argv.slice(2));
}
