// Proves the generated Dart client compiles and behaves: copies generated/dart
// and codegen/dart-smoke to a temporary directory (so nothing is written into
// the package), then runs `dart pub get`, `dart analyze` (errors fail; the
// generator's own style warnings do not) and the smoke program.
//
// Needs the Dart SDK on PATH and network access to pub.dev.

import { spawnSync } from "node:child_process";
import { cpSync, mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

const pkgDir = fileURLToPath(new URL("..", import.meta.url));
const work = mkdtempSync(join(tmpdir(), "keluargamakan-dart-"));

function run(args, cwd) {
  process.stdout.write(`$ dart ${args.join(" ")}\n`);
  // On Windows `dart` is a .bat wrapper, which needs a shell.
  const result = spawnSync("dart", args, {
    cwd,
    stdio: "inherit",
    shell: process.platform === "win32",
  });
  if (result.error || result.status !== 0) {
    process.stderr.write(`verify-dart: dart ${args.join(" ")} failed\n`);
    rmSync(work, { recursive: true, force: true });
    process.exit(1);
  }
}

try {
  cpSync(join(pkgDir, "generated", "dart"), join(work, "dart"), { recursive: true });
  cpSync(join(pkgDir, "codegen", "dart-smoke"), join(work, "dart-smoke"), { recursive: true });
  run(["--version"], work);
  run(["pub", "get"], join(work, "dart"));
  run(["analyze", "--no-fatal-warnings"], join(work, "dart"));
  run(["pub", "get"], join(work, "dart-smoke"));
  run(["run", "bin/smoke.dart"], join(work, "dart-smoke"));
  process.stdout.write("verify-dart: generated Dart client OK\n");
} finally {
  rmSync(work, { recursive: true, force: true });
}
