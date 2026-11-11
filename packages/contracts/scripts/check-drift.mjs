// Fails when packages/contracts differs from the committed state after
// `generate.mjs` has run: modified, deleted or new (untracked) files all count.
// `git diff --exit-code` alone would miss newly generated files.

import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const pkgDir = fileURLToPath(new URL("..", import.meta.url));

const status = spawnSync("git", ["status", "--porcelain", "--untracked-files=all", "--", "."], {
  cwd: pkgDir,
  encoding: "utf8",
});
if (status.error || status.status !== 0) {
  process.stderr.write(status.stderr ?? String(status.error));
  process.stderr.write("check-drift: git status failed\n");
  process.exit(1);
}

const changes = status.stdout.trim();
if (changes) {
  process.stderr.write(
    "check-drift: generated clients differ from openapi.yaml, or packages/contracts has uncommitted changes:\n",
  );
  process.stderr.write(`${changes}\n`);
  spawnSync("git", ["--no-pager", "diff", "--stat", "--", "."], { cwd: pkgDir, stdio: "inherit" });
  process.stderr.write(
    "Run `pnpm --filter @keluargamakan/contracts run generate` and commit the result. Never edit generated files by hand.\n",
  );
  process.exit(1);
}
process.stdout.write("check-drift: generated clients match openapi.yaml\n");
