import { fileURLToPath } from "node:url";

import { defineConfig } from "vitest/config";

// The database suite starts PGlite (PostgreSQL in WebAssembly) per file, so
// timeouts are longer than the default. Retries stay off: a flaky privacy or
// safety test must never pass on a second try.
export default defineConfig({
  resolve: {
    alias: {
      "@keluargamakan/cek-aman": fileURLToPath(
        new URL("../../packages/cek-aman/src/index.ts", import.meta.url),
      ),
    },
  },
  test: {
    include: ["src/**/*.test.ts", "config/**/*.test.ts"],
    passWithNoTests: false,
    retry: 0,
    testTimeout: 60_000,
    hookTimeout: 120_000,
  },
});
