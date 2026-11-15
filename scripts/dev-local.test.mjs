// TEST FIXTURE: not real safety or nutrition data. Tests for the local test
// server scripts (pnpm dev:local, pnpm dev:app). Keys here are made per run
// in a temporary folder; nothing is written to .local-dev/.

import assert from "node:assert/strict";
import { execFile, execFileSync } from "node:child_process";
import { randomBytes } from "node:crypto";
import {
  existsSync,
  mkdirSync,
  mkdtempSync,
  readFileSync,
  readdirSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { createServer } from "node:net";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { after, describe, it } from "node:test";
import { pathToFileURL } from "node:url";

import {
  main as appMain,
  parseArgs as parseAppArgs,
  runningServerPort,
  serverStatus,
} from "./dev-app.mjs";
import {
  HELP,
  MADE_UP_DATA_ONLY,
  SECRET_NAMES,
  appCommand,
  checkSecrets,
  formatLogLine,
  generateSecrets,
  loadOrCreateSecrets,
  localPaths,
  parseArgs,
  parseEnvFile,
  parseWhoamiSid,
  readyBanner,
  releaseLock,
  restrictLocalDir,
  serializeSecrets,
  serverEnv,
  takeLock,
  windowsRestrictArgs,
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

  it("shows the made-up data warning in --help and when the server is up (review L2)", () => {
    assert.equal(MADE_UP_DATA_ONLY.length, 2);
    assert.match(MADE_UP_DATA_ONLY[1], /Use made-up family members only/);
    assert.match(MADE_UP_DATA_ONLY[1], /Do not enter real health or children's data/);
    assert.match(MADE_UP_DATA_ONLY[0], /Gunakan anggota keluarga rekaan saja/);
    for (const line of MADE_UP_DATA_ONLY) {
      assert.ok(HELP.includes(line));
      assert.ok(readyBanner(3000).includes(line));
    }
  });
});

describe("NFR-10 dev:local single-instance lock (review L4)", () => {
  it("creates the lock exclusively with this process and a unique token", () => {
    const paths = freshPaths();
    takeLock(paths);
    const [pid, token] = readFileSync(paths.lock, "utf8").trim().split(" ");
    assert.equal(pid, String(process.pid));
    assert.match(token, /^[0-9a-f-]{36}$/);
  });

  it("refuses while the holder runs, and names the lock file", () => {
    const paths = freshPaths();
    takeLock(paths, { pid: 111 });
    assert.throws(
      () => takeLock(paths, { pid: 222, alive: () => true }),
      /already running \(process 111\).*server\.lock/s,
    );
  });

  it("takes over a lock whose process is gone, leaving no stale files", () => {
    const paths = freshPaths();
    takeLock(paths, { pid: 111 });
    takeLock(paths, { pid: 222, alive: () => false });
    assert.match(readFileSync(paths.lock, "utf8"), /^222 /);
    assert.deepEqual(
      readdirSync(paths.dir).filter((name) => name.includes("stale")),
      [],
    );
  });

  it("refuses a takeover while another launcher holds the takeover file", () => {
    const paths = freshPaths();
    takeLock(paths, { pid: 111 });
    writeFileSync(`${paths.lock}.takeover`, "333 token\n");
    assert.throws(
      () => takeLock(paths, { pid: 222, alive: (pid) => pid === 333 }),
      /another local test server is starting/,
    );
    assert.throws(
      () => takeLock(paths, { pid: 222, alive: () => false }),
      /delete \.local-dev\/server\.lock\.takeover/,
    );
    assert.match(readFileSync(paths.lock, "utf8"), /^111 /);
  });

  it("releases only its own lock", () => {
    const paths = freshPaths();
    takeLock(paths, { pid: 111 });
    releaseLock(paths, 222);
    assert.equal(existsSync(paths.lock), true);
    releaseLock(paths, 111);
    assert.equal(existsSync(paths.lock), false);
  });

  it("lets exactly one of several launchers take over the same stale lock", async () => {
    const devLocal = pathToFileURL(join(import.meta.dirname, "dev-local.mjs")).href;
    for (let round = 0; round < 3; round += 1) {
      const paths = freshPaths();
      mkdirSync(paths.dir, { recursive: true });
      writeFileSync(paths.lock, "999999999 stale-token\n");
      const contender = join(work, `contender-${round}.mjs`);
      writeFileSync(
        contender,
        [
          `import { localPaths, takeLock } from ${JSON.stringify(devLocal)};`,
          `const paths = localPaths(${JSON.stringify(paths.dir)});`,
          "const start = Number(process.argv[2]);",
          "while (Date.now() < start) {}",
          "let result = 'won';",
          "try { takeLock(paths, { alive: (pid) => pid !== 999999999 }); }",
          "catch (error) { result = `lost: ${error.message}`; }",
          "console.log(result);",
          // Hold the lock while the others try, like a running server.
          "setTimeout(() => {}, 1500);",
        ].join("\n"),
      );
      const start = Date.now() + 1500;
      const results = await Promise.all(
        Array.from(
          { length: 6 },
          () =>
            new Promise((resolve, reject) => {
              execFile(process.execPath, [contender, String(start)], (error, stdout) =>
                error ? reject(error) : resolve(stdout.trim()),
              );
            }),
        ),
      );
      assert.equal(results.filter((line) => line === "won").length, 1, results.join("\n"));
      assert.equal(results.filter((line) => line.startsWith("lost")).length, 5);
      assert.deepEqual(
        readdirSync(paths.dir).filter((name) => name.includes("stale")),
        [],
      );
    }
  });
});

describe("NFR-10 dev:local folder permissions (review L1)", () => {
  const sid = "S-1-5-21-1111111111-2222222222-3333333333-1001";

  it("reads the SID from whoami and builds the icacls arguments", () => {
    assert.equal(parseWhoamiSid(`"laptop\\owner","${sid}"\r\n`), sid);
    assert.throws(() => parseWhoamiSid("Access is denied."), /SID/);
    assert.deepEqual(windowsRestrictArgs("D:\\repo\\.local-dev", sid), [
      "D:\\repo\\.local-dev",
      "/inheritance:r",
      "/grant:r",
      `*${sid}:(OI)(CI)F`,
    ]);
    assert.throws(() => windowsRestrictArgs("D:\\x", "Everyone"), /SID/);
  });

  it("on Windows runs whoami then icacls from System32", () => {
    const calls = [];
    const paths = freshPaths();
    restrictLocalDir(paths, {
      platform: "win32",
      run: (file, args) => {
        calls.push([file, args]);
        return file.endsWith("whoami.exe") ? `"laptop\\owner","${sid}"` : "";
      },
    });
    assert.equal(calls.length, 2);
    assert.match(calls[0][0], /System32[\\/]whoami\.exe$/i);
    assert.match(calls[1][0], /System32[\\/]icacls\.exe$/i);
    assert.deepEqual(calls[1][1], windowsRestrictArgs(paths.dir, sid));
  });

  it("refuses to start when the folder cannot be restricted", () => {
    const failing = () => {
      throw new Error("icacls failed\nmore detail");
    };
    assert.throws(
      () => restrictLocalDir(freshPaths(), { platform: "win32", run: failing }),
      /does not start \(icacls failed\)/,
    );
    assert.throws(
      () => restrictLocalDir(freshPaths(), { platform: "linux", chmod: failing }),
      /does not start/,
    );
  });

  it("on macOS and Linux sets 0700 on the folder and 0600 on the keys", () => {
    const paths = freshPaths();
    mkdirSync(paths.dir, { recursive: true });
    writeFileSync(paths.secrets, "x");
    const modes = [];
    restrictLocalDir(paths, {
      platform: "darwin",
      chmod: (path, mode) => modes.push([path, mode]),
    });
    assert.deepEqual(modes, [
      [paths.dir, 0o700],
      [paths.secrets, 0o600],
    ]);
  });

  it(
    "on this Windows machine leaves the folder to the current user alone",
    { skip: process.platform !== "win32" && "Windows only" },
    () => {
      const paths = freshPaths();
      mkdirSync(paths.dir, { recursive: true });
      restrictLocalDir(paths);
      const icacls = join(process.env["SystemRoot"] ?? "C:\\Windows", "System32", "icacls.exe");
      const acl = execFileSync(icacls, [paths.dir], { encoding: "utf8" });
      // One entry only (each entry is "<principal>:(flags)"), not inherited.
      assert.equal((acl.match(/:\(/g) ?? []).length, 1, acl);
      assert.doesNotMatch(acl, /\(I\)/);
      assert.match(acl, /\(OI\)\(CI\)\(F\)/);
    },
  );
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

  it("checks /health/ready on loopback before starting Flutter (review I1)", async () => {
    const asked = [];
    const answer = (status) => (url) => {
      asked.push(url);
      return Promise.resolve({ status });
    };
    assert.equal(await serverStatus(3004, answer(200)), "ready");
    assert.equal(await serverStatus(3004, answer(503)), "not_ready");
    assert.equal(await serverStatus(3004, answer(404)), "down");
    assert.equal(await serverStatus(3004, () => Promise.reject(new Error("ECONNREFUSED"))), "down");
    assert.equal(asked[0], "http://127.0.0.1:3004/health/ready");
  });

  it("stops with a clear message when no server answers", async () => {
    const errors = [];
    const original = console.error;
    console.error = (text) => errors.push(text);
    try {
      const code = await appMain(["--port", "3009"], { status: () => Promise.resolve("down") });
      assert.equal(code, 1);
    } finally {
      console.error = original;
    }
    assert.match(errors.join("\n"), /No local test server answers on port 3009.*pnpm dev:local/s);
  });

  it("finds a real stopped port as down", async () => {
    const server = createServer();
    const port = await new Promise((resolve) =>
      server.listen(0, "127.0.0.1", () => resolve(server.address().port)),
    );
    await new Promise((resolve) => server.close(resolve));
    assert.equal(await serverStatus(port), "down");
  });
});
