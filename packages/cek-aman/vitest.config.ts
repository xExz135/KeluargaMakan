import { defineConfig } from "vitest/config";

// Cek Aman must keep 100% coverage, branches included: every fail-closed path
// is tested. Retries are disabled so a flaky safety test can never pass.
export default defineConfig({
  test: {
    include: ["src/**/*.test.ts"],
    passWithNoTests: false,
    retry: 0,
    coverage: {
      provider: "v8",
      include: ["src/**/*.ts"],
      exclude: ["src/**/*.test.ts", "src/test-fixtures.ts"],
      reporter: ["text", "json-summary"],
      thresholds: { branches: 100, functions: 100, lines: 100, statements: 100 },
    },
  },
});
