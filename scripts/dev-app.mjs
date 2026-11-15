#!/usr/bin/env node
// Runs the Flutter app on the Android emulator against the local test server
// started by `pnpm dev:local` (NFR-10). Debug build only: the app allows
// plain http only for localhost, 127.0.0.1 and 10.0.2.2 in debug builds.
// It does not start or stop the emulator.
//
// Run `pnpm dev:app --help` for usage.

import { spawn } from "node:child_process";
import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { parseArgs as parseNodeArgs } from "node:util";
import { pathToFileURL } from "node:url";

import { DEFAULT_DEVICE, DEFAULT_PORT, appCommand, localPaths } from "./dev-local.mjs";

export const HELP = `Run the KeluargaMakan app on the Android emulator against the local test server.

Usage (PowerShell, in the repository folder, while \`pnpm dev:local\` runs):
  pnpm dev:app                   run on ${DEFAULT_DEVICE}
  pnpm dev:app --device <id>     another device id from \`flutter devices\`
  pnpm dev:app --port <n>        the server port (default: the port the running
                                 server printed, else ${DEFAULT_PORT})

The same by hand:
  cd apps/mobile
  flutter run -d ${DEFAULT_DEVICE} --dart-define=KM_API_BASE_URL=http://10.0.2.2:${DEFAULT_PORT}

The emulator must already be running; this does not start or stop it.
In the flutter window: r = hot reload, R = hot restart, q = quit.
`;

export function parseArgs(argv) {
  const { values } = parseNodeArgs({
    args: argv,
    options: {
      device: { type: "string" },
      port: { type: "string" },
      help: { type: "boolean", short: "h", default: false },
    },
    strict: true,
    allowPositionals: false,
  });
  const device = values.device ?? null;
  // The command goes through the Windows shell, so only plain IDs.
  if (device !== null && !/^[A-Za-z0-9._:-]{1,64}$/.test(device)) {
    throw new Error("--device must be a device id such as emulator-5554");
  }
  let port = null;
  if (values.port !== undefined) {
    if (
      !/^[0-9]{1,5}$/.test(values.port) ||
      Number(values.port) < 1 ||
      Number(values.port) > 65535
    ) {
      throw new Error("--port must be a number from 1 to 65535");
    }
    port = Number(values.port);
  }
  return { device, port, help: values.help };
}

/** The port the running local server wrote, if any. */
export function runningServerPort(paths = localPaths()) {
  try {
    const { port } = JSON.parse(readFileSync(paths.state, "utf8"));
    return Number.isInteger(port) && port > 0 && port <= 65535 ? port : null;
  } catch {
    return null;
  }
}

/**
 * Security review 2026-11-15 I1: `server.json` can outlive a server that was
 * killed, so check that something answers `GET /health/ready` on the port
 * before starting Flutter. 200 (ready) and 503 (up, not ready) both mean the
 * local server is there. Returns "ready", "not_ready" or "down".
 */
export async function serverStatus(port, fetchImpl = fetch, timeoutMs = 2000) {
  try {
    const response = await fetchImpl(`http://127.0.0.1:${port}/health/ready`, {
      signal: AbortSignal.timeout(timeoutMs),
    });
    if (response.status === 200) return "ready";
    if (response.status === 503) return "not_ready";
    return "down";
  } catch {
    return "down";
  }
}

export async function main(argv, { status = serverStatus } = {}) {
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
  const port = options.port ?? runningServerPort() ?? DEFAULT_PORT;
  const state = await status(port);
  if (state === "down") {
    console.error(
      `No local test server answers on port ${port}. Start it with \`pnpm dev:local\` in ` +
        'another PowerShell window first, wait for "is running", then run `pnpm dev:app` ' +
        "again (add --port <n> if it printed another port).",
    );
    return 1;
  }
  if (state === "not_ready") {
    console.log(
      `The local test server on port ${port} is up but not ready (database or ingredient ` +
        "catalog); see its window. Starting the app anyway.",
    );
  }
  const app = appCommand({ port, device: options.device ?? DEFAULT_DEVICE });
  if (!existsSync(join(app.cwd, "pubspec.yaml"))) {
    console.error("apps/mobile/pubspec.yaml not found; run this from the repository");
    return 1;
  }
  console.log(`> cd apps/mobile\n> ${app.command} ${app.args.join(" ")}\n`);
  return new Promise((resolve) => {
    // flutter is a .bat file on Windows, which needs the shell; every
    // argument is a fixed string or a checked device id and port.
    const child = spawn(app.command, app.args, {
      cwd: app.cwd,
      stdio: "inherit",
      shell: process.platform === "win32",
    });
    child.once("error", (error) => {
      console.error(
        error.code === "ENOENT"
          ? "flutter was not found; install Flutter and add it to PATH"
          : error.message,
      );
      resolve(1);
    });
    child.once("exit", (code) => resolve(code ?? 1));
  });
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  process.exitCode = await main(process.argv.slice(2));
}
