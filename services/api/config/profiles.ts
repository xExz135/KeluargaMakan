/**
 * PRF-07: default portion size and rice portion per age group, used when a
 * profile has no value of its own (`Portions.*IsDefault`).
 *
 * The values are content, not engineering choices (QUESTIONS #30: "portion
 * defaults per group come from content config, not from agents"). Until the
 * content team sets them, every age group uses the neutral `normal`, marked
 * `pendingContentReview`. Overrides come from `PROFILE_CONFIG_JSON` without a
 * code change; unknown keys and values stop startup.
 */

export const AGE_GROUP_KEYS = ["infant", "child", "teen", "adult", "elderly"] as const;
export const PORTION_SIZES = ["small", "normal", "large"] as const;
export type PortionSize = (typeof PORTION_SIZES)[number];
type AgeGroupKey = (typeof AGE_GROUP_KEYS)[number];

export interface PortionDefaults {
  readonly portionSize: PortionSize;
  readonly ricePortion: PortionSize;
}

export interface ProfileConfig {
  readonly portionDefaults: Readonly<Record<AgeGroupKey, PortionDefaults>>;
  /** True while the defaults are the neutral placeholder, not content-team values. */
  readonly pendingContentReview: boolean;
}

const NEUTRAL: PortionDefaults = { portionSize: "normal", ricePortion: "normal" };

export const defaultProfileConfig: ProfileConfig = Object.freeze({
  portionDefaults: Object.freeze({
    infant: NEUTRAL,
    child: NEUTRAL,
    teen: NEUTRAL,
    adult: NEUTRAL,
    elderly: NEUTRAL,
  }),
  pendingContentReview: true,
});

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function portion(value: unknown, path: string): PortionSize {
  if (typeof value !== "string" || !(PORTION_SIZES as readonly string[]).includes(value)) {
    throw new Error(`profile config ${path} must be small, normal or large`);
  }
  return value as PortionSize;
}

/** Defaults with the given age groups replaced. `pendingContentReview` stays true until every group is set. */
export function resolveProfileConfig(overrides: unknown = {}): ProfileConfig {
  if (!isRecord(overrides)) throw new Error("profile config must be an object");
  for (const key of Object.keys(overrides)) {
    if (key !== "portionDefaults") throw new Error(`Unknown profile config: ${key}`);
  }
  const given = overrides["portionDefaults"] ?? {};
  if (!isRecord(given)) throw new Error("profile config portionDefaults must be an object");
  const out: Record<string, PortionDefaults> = {};
  for (const key of Object.keys(given)) {
    if (!(AGE_GROUP_KEYS as readonly string[]).includes(key)) {
      throw new Error(`Unknown age group in profile config: ${key}`);
    }
  }
  for (const group of AGE_GROUP_KEYS) {
    const entry = given[group];
    if (entry === undefined) {
      out[group] = defaultProfileConfig.portionDefaults[group];
      continue;
    }
    if (!isRecord(entry))
      throw new Error(`profile config portionDefaults.${group} must be an object`);
    for (const key of Object.keys(entry)) {
      if (key !== "portionSize" && key !== "ricePortion") {
        throw new Error(`Unknown profile config: portionDefaults.${group}.${key}`);
      }
    }
    out[group] = Object.freeze({
      portionSize: portion(entry["portionSize"], `portionDefaults.${group}.portionSize`),
      ricePortion: portion(entry["ricePortion"], `portionDefaults.${group}.ricePortion`),
    });
  }
  return Object.freeze({
    portionDefaults: Object.freeze(out),
    pendingContentReview: AGE_GROUP_KEYS.some((group) => given[group] === undefined),
  });
}

export function profileConfigFromEnv(
  env: Readonly<Record<string, string | undefined>>,
): ProfileConfig {
  const raw = env["PROFILE_CONFIG_JSON"]?.trim();
  if (raw === undefined || raw === "") return defaultProfileConfig;
  let parsed: unknown;
  try {
    parsed = JSON.parse(raw);
  } catch {
    throw new Error("PROFILE_CONFIG_JSON is not valid JSON");
  }
  return resolveProfileConfig(parsed);
}
