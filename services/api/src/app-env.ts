/**
 * Deployment environment from `APP_ENV`, with the same rule as the reference
 * data loader (packages/reference-data): a missing or unknown value counts as
 * production, so a forgotten setting can only make the API stricter.
 */
export const APP_ENVIRONMENTS = ["local", "test", "staging", "production"] as const;
export type AppEnvironment = (typeof APP_ENVIRONMENTS)[number];

export function resolveAppEnv(value: string | undefined): AppEnvironment {
  const named = value?.trim();
  return APP_ENVIRONMENTS.find((candidate) => candidate === named) ?? "production";
}

/** True only for `local` and `test`, where development-only shortcuts are allowed. */
export function isDevelopmentEnv(value: string | undefined): boolean {
  const env = resolveAppEnv(value);
  return env === "local" || env === "test";
}
