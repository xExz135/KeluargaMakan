// @ts-check
import js from "@eslint/js";
import prettier from "eslint-config-prettier";
import globals from "globals";
import tseslint from "typescript-eslint";

const ENGINE_BOUNDARY =
  'Import Cek Aman only from "@keluargamakan/cek-aman": its internals skip the input checks (SAF-01, SAF-12).';

export default tseslint.config(
  {
    ignores: [
      "**/node_modules/**",
      "**/dist/**",
      "**/build/**",
      "**/coverage/**",
      "**/.next/**",
      "**/generated/**",
    ],
  },
  js.configs.recommended,
  ...tseslint.configs.recommendedTypeChecked,
  {
    languageOptions: {
      globals: { ...globals.node },
      parserOptions: {
        projectService: true,
        tsconfigRootDir: import.meta.dirname,
      },
    },
    rules: {
      "@typescript-eslint/consistent-type-imports": "error",
      "@typescript-eslint/no-floating-promises": "error",
      "no-console": "warn",
    },
  },
  {
    files: ["**/*.{js,mjs,cjs}"],
    ...tseslint.configs.disableTypeChecked,
  },
  {
    files: ["scripts/**"],
    rules: { "no-console": "off" },
  },
  {
    // SAF-01, SAF-12 (T-025 security re-check N1): only the package root is the
    // Cek Aman API. Its internals skip the input checks and can return "Safe"
    // for a hand-built argument. scripts/check-engine-imports.mjs checks every
    // other path as well (URLs, aliases, comments).
    files: ["**/*.{ts,tsx,mts,cts,js,mjs,cjs}"],
    ignores: ["packages/cek-aman/**", "scripts/check-engine-imports*.mjs"],
    rules: {
      "@typescript-eslint/no-restricted-imports": [
        "error",
        {
          patterns: [
            { regex: "^@keluargamakan/cek-aman/.+", message: ENGINE_BOUNDARY },
            { regex: "(^|/)cek-aman/dist(/|$)", message: ENGINE_BOUNDARY },
            {
              regex: "(^|/)cek-aman/src(/(?!(index|vocabulary|types)\\.[cm]?[jt]s$).*)?$",
              message: ENGINE_BOUNDARY,
            },
            {
              regex: "(^|/)cek-aman/src/types\\.[cm]?[jt]s$",
              allowTypeImports: true,
              message: ENGINE_BOUNDARY,
            },
          ],
        },
      ],
    },
  },
  prettier,
);
