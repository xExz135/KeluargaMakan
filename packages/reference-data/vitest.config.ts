import { fileURLToPath } from "node:url";

import { defineConfig } from "vitest/config";

// The loader decides which reference data the API trusts, so every refusal
// path is tested: 100% coverage, branches included, and no retries.
export default defineConfig({
  resolve: {
    alias: {
      "@keluargamakan/cek-aman": fileURLToPath(
        new URL("../cek-aman/src/index.ts", import.meta.url),
      ),
    },
  },
  test: {
    include: ["src/**/*.test.ts"],
    passWithNoTests: false,
    retry: 0,
    coverage: {
      provider: "v8",
      include: ["src/**/*.ts"],
      exclude: ["src/**/*.test.ts"],
      reporter: ["text", "json-summary"],
      thresholds: { branches: 100, functions: 100, lines: 100, statements: 100 },
    },
  },
});
