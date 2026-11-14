// TEST FIXTURE: not real safety or nutrition data. Builds a fixture reference
// dataset the way production builds the real one, for tests only.
import { execFileSync } from "node:child_process";
import { mkdtempSync, readFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

import { loadReferenceDataFromEnv, type VerifiedReference } from "@keluargamakan/reference-data";

export const REPO_ROOT = fileURLToPath(new URL("../../../../../", import.meta.url));

export interface BuiltFixture {
  readonly path: string;
  readonly sha256: string;
  readonly verified: VerifiedReference;
  readonly cleanup: () => void;
}

/**
 * Runs `pnpm build:reference --fixture` on `sourceDir` (which the calling
 * test names) into a temporary folder, then loads the result through the
 * verified loader with `APP_ENV=test`, exactly as the API does.
 */
export function buildFixtureReference(sourceDir: string): BuiltFixture {
  const work = mkdtempSync(join(tmpdir(), "km-kitchen-"));
  const out = join(work, "fixture-reference-dataset.json");
  execFileSync(
    process.execPath,
    [
      join(REPO_ROOT, "scripts", "build-reference.mjs"),
      "--fixture",
      "--source",
      sourceDir,
      "--out",
      out,
    ],
    { stdio: "pipe" },
  );
  const built = JSON.parse(readFileSync(out, "utf8")) as { contentHash: { value: string } };
  const verified = loadReferenceDataFromEnv({
    APP_ENV: "test",
    REFERENCE_DATA_PATH: out,
    REFERENCE_DATA_SHA256: built.contentHash.value,
  });
  return {
    path: out,
    sha256: built.contentHash.value,
    verified,
    cleanup: () => rmSync(work, { recursive: true, force: true }),
  };
}
