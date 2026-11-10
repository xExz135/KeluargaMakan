import { fileURLToPath } from "node:url";

import { defineConfig } from "vitest/config";

// NFR-07: the suite must pass at 100%. A run that finds no cases fails, and
// retries are disabled so a flaky safety case can never pass on a second try.
export default defineConfig({
  resolve: {
    alias: {
      "@keluargamakan/cek-aman": fileURLToPath(
        new URL("../../packages/cek-aman/src/index.ts", import.meta.url),
      ),
    },
  },
  test: {
    include: ["**/*.test.ts"],
    passWithNoTests: false,
    retry: 0,
    bail: 0,
  },
});
