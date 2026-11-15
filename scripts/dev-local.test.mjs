// TEST FIXTURE: not real safety or nutrition data. Tests for the local test
// server scripts (pnpm dev:local, pnpm dev:app). Keys here are made per run
// in a temporary folder; nothing is written to .local-dev/.

import assert from "node:assert/strict";
import { randomBytes } from "node:crypto";
import { existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { after, describe, it } from "node:test";

import { parseArgs as parseAppArgs, runningServerPort } from "./dev-app.mjs";
import {
  SECRET_NAMES,
  appCommand,
  checkSecrets,
  formatLogLine,
  generateSecrets,
  loadOrCreateSecrets,
  localPaths,
  parseArgs,
  parseEnvFile,
  serializeSecrets,
  serverEnv,
  takeLock,
} from "./dev-local.mjs";

const work = mkdtempSync(join(tmpdir(), "km-dev-local-"));
after(() => rmSync(work, { recursive: true, force: true }));
let counter = 0;
const freshPaths = () => localPaths(join(work, `local-${(counter += 1)}`));

describe("NFR-10 dev:local local-only keys", () => {
  it("makes four distinct 32-byte base64 keys", () => {
    const secrets = generateSecrets();
    assert.deepEqual(Object.keys(secrets), SECRET_NAMES);
    for (const value of Object.values(secrets)) {
      assert.equal(Buffer.from(value, "base64").length, 32);
    }
    assert.equal(new Set(Object.values(secrets)).size, 4);
    assert.notEqual(secrets.AUTH_TOKEN_KEY, secrets.AUTH_HASH_KEY);
    assert.notEqual(secrets.LOCAL_GENERAL_DATA_KEK, secrets.LOCAL_HEALTH_DATA_KEK);
  });

  it("draws again when a random source repeats itself", () => {
    let calls = 0;
    const repeating = (size) => {
      calls += 1;
      return calls <= 4 ? Buffer.alloc(size, 7) : randomBytes(size);
    };
    const secrets = generateSecrets(repeating);
    assert.equal(new Set(Object.values(secrets)).size, 4);
  });

  it("round-trips the env file and refuses weak, missing or repeated keys", () => {
    const secrets = generateSecrets();
    assert.deepEqual(checkSecrets(parseEnvFile(serializeSecrets(secrets))), secrets);
    assert.throws(() => checkSecrets({ ...secrets, AUTH_HASH_KEY: "c2hvcnQ=" }), /AUTH_HASH_KEY/);
    const missing = { ...secrets };
    delete missing.AUTH_TOKEN_KEY;
    assert.throws(() => checkSecrets(missing), /AUTH_TOKEN_KEY/);
    assert.throws(
      () => checkSecrets({ ...secrets, LOCAL_HEALTH_DATA_KEK: secrets.LOCAL_GENERAL_DATA_KEK }),
      /different/,
    );
  });

  it("keeps the key values out of error messages", () => {
    const secrets = generateSecrets();
    const bad = { ...secrets, AUTH_HASH_KEY: `${secrets.AUTH_HASH_KEY}x` };
    assert.throws(
      () => checkSecrets(bad),
      (error) => !Object.values(bad).some((value) => error.message.includes(value)),
    );
  });

  it("creates the keys once and reuses them on the next run", () => {
    const paths = freshPaths();
    const first = loadOrCreateSecrets(paths);
    assert.equal(first.created, true);
    const second = loadOrCreateSecrets(paths);
    assert.equal(second.created, false);
    assert.deepEqual(second.secrets, first.secrets);
  });

  it("refuses a database whose keys are gone instead of making new ones", () => {
    const paths = freshPaths();
    mkdirSync(paths.pgdata, { recursive: true });
    assert.throws(() => loadOrCreateSecrets(paths), /--reset/);
    assert.equal(existsSync(paths.secrets), false);
  });
});

describe("NFR-10 dev:local server environment", () => {
  const secrets = generateSecrets();
  const reference = { path: join(work, "fixture.json"), sha256: "a".repeat(64) };
  const env = serverEnv({
    secrets,
    port: 3000,
    dataDir: join(work, "pgdata"),
    reference,
    baseEnv: {
      Path: "C:\\Windows",
      SystemRoot: "C:\\Windows",
      APP_ENV: "production",
      DATABASE_URL: "postgres://db.example/prod",
      KEY_PROVIDER: "cloud_kms",
      KMS_HEALTH_DATA_KEY: "projects/x/keys/y",
      GOOGLE_APPLICATION_CREDENTIALS: "C:\\creds.json",
    },
  });

  it("is always APP_ENV=local on loopback, with the dev sender and local keys", () => {
    assert.equal(env.APP_ENV, "local");
    assert.equal(env.HOST, "127.0.0.1");
    assert.equal(env.PORT, "3000");
    assert.equal(env.CODE_SENDER, "dev");
    assert.equal(env.KEY_PROVIDER, "local");
    assert.equal(env.REFERENCE_DATA_PATH, reference.path);
    assert.equal(env.REFERENCE_DATA_SHA256, reference.sha256);
    for (const name of SECRET_NAMES) assert.equal(env[name], secrets[name]);
  });

  it("relaxes only the sign-in rate limits, not the code itself", () => {
    const config = JSON.parse(env.API_CONFIG_JSON);
    assert.deepEqual(Object.keys(config), ["rateLimits"]);
    assert.ok(config.rateLimits.codeRequestPerDestination.limit >= 30);
  });

  it("inherits only operating system variables from the shell", () => {
    assert.equal(env.Path, "C:\\Windows");
    assert.equal(env.SystemRoot, "C:\\Windows");
    assert.equal(env.DATABASE_URL, undefined);
    assert.equal(env.KMS_HEALTH_DATA_KEY, undefined);
    assert.equal(env.GOOGLE_APPLICATION_CREDENTIALS, undefined);
  });
});

describe("NFR-10 dev:local options and output", () => {
  it("parses the options and refuses unknown ones", () => {
    assert.deepEqual(parseArgs([]), {
      reset: false,
      yes: false,
      port: null,
      build: true,
      help: false,
    });
    assert.equal(parseArgs(["--reset", "--yes"]).yes, true);
    assert.equal(parseArgs(["--port", "3001"]).port, 3001);
    assert.equal(parseArgs(["--no-build"]).build, false);
    assert.throws(() => parseArgs(["--yes"]), /--reset/);
    assert.throws(() => parseArgs(["--port", "80"]), /--port/);
    assert.throws(() => parseArgs(["--port", "70000"]), /--port/);
    assert.throws(() => parseArgs(["--wipe"]));
  });

  it("labels sign-in codes as local test codes", () => {
    const text = formatLogLine(
      JSON.stringify({
        level: "info",
        event: "dev_sign_in_code",
        challengeId: "c",
        code: "123456",
      }),
    );
    assert.match(text, /LOCAL TEST SIGN-IN CODE/);
    assert.match(text, /123456/);
    assert.match(text, /Nothing was sent/);
  });

  it("prints the app command for the emulator when the API is up", () => {
    const text = formatLogLine(JSON.stringify({ event: "api_started", port: 3005 }), {
      port: 3005,
    });
    assert.match(text, /pnpm dev:app --port 3005/);
    assert.match(
      text,
      /flutter run -d emulator-5554 --dart-define=KM_API_BASE_URL=http:\/\/10\.0\.2\.2:3005/,
    );
  });

  it("keeps request lines short and passes other output through", () => {
    assert.equal(
      formatLogLine(
        JSON.stringify({ event: "request", method: "GET", route: "/v1/household", status: 200 }),
      ),
      "  GET /v1/household -> 200",
    );
    assert.equal(formatLogLine("plain text"), "[api] plain text");
    assert.equal(formatLogLine("   "), null);
  });

  it("refuses a second server on the same database folder", () => {
    const paths = freshPaths();
    mkdirSync(paths.dir, { recursive: true });
    writeFileSync(paths.lock, `${process.ppid}\n`);
    assert.throws(() => takeLock(paths), /already running/);
    writeFileSync(paths.lock, "999999999\n");
    takeLock(paths);
    assert.equal(readFileSync(paths.lock, "utf8").trim(), String(process.pid));
  });
});

describe("NFR-10 dev:app", () => {
  it("builds the flutter command for the emulator", () => {
    assert.deepEqual(appCommand({ port: 3000 }).args, [
      "run",
      "-d",
      "emulator-5554",
      "--dart-define=KM_API_BASE_URL=http://10.0.2.2:3000",
    ]);
    assert.deepEqual(appCommand({ port: 3001, device: "emulator-5556" }).args.slice(2), [
      "emulator-5556",
      "--dart-define=KM_API_BASE_URL=http://10.0.2.2:3001",
    ]);
  });

  it("accepts plain device ids and ports only (the command runs through a shell)", () => {
    assert.equal(parseAppArgs(["--device", "emulator-5556"]).device, "emulator-5556");
    assert.equal(parseAppArgs(["--port", "3001"]).port, 3001);
    assert.throws(() => parseAppArgs(["--device", "x & del *"]), /--device/);
    assert.throws(() => parseAppArgs(["--port", "3000;"]), /--port/);
  });

  it("reads the port the running server wrote", () => {
    const paths = freshPaths();
    assert.equal(runningServerPort(paths), null);
    mkdirSync(paths.dir, { recursive: true });
    writeFileSync(paths.state, JSON.stringify({ port: 3002 }));
    assert.equal(runningServerPort(paths), 3002);
    writeFileSync(paths.state, JSON.stringify({ port: "3002; x" }));
    assert.equal(runningServerPort(paths), null);
  });
});
