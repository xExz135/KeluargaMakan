import { fileURLToPath } from "node:url";

import { defineConfig } from "vitest/config";

// The parity tests compare contract enums with the Cek Aman engine's own value
// lists, read from the package root (the only public entry, SAF-01). The alias
// points at its sources, as in the other workspace packages.
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
  },
});
