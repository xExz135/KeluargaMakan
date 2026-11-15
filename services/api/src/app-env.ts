/**
 * Deployment environment from `APP_ENV`, with the same rule as the reference
 * data loader (packages/reference-data): a missing or unknown value counts as
 * production, so a forgotten setting can only make the API stricter.
 *
 * Matching is exact: no trimming and no case folding (security review
 * 2026-11-15 I2). `" local"`, `"LOCAL"` or `"test\n"` are unknown values and
 * count as production, so a stray space in deploy config can never unlock
 * the development shortcuts.
 */
export const APP_ENVIRONMENTS = ["local", "test", "staging", "production"] as const;
export type AppEnvironment = (typeof APP_ENVIRONMENTS)[number];

export function resolveAppEnv(value: string | undefined): AppEnvironment {
  return APP_ENVIRONMENTS.find((candidate) => candidate === value) ?? "production";
}

/** True only for exactly `local` and `test`, where development-only shortcuts are allowed. */
export function isDevelopmentEnv(value: string | undefined): boolean {
  const env = resolveAppEnv(value);
  return env === "local" || env === "test";
}
