/**
 * Home for every figure the SRS marks "(target)".
 *
 * Targets are proposed values that change after validation (SRS 1.3), so they
 * live here as configuration, never as constants in feature code. Each entry
 * records the SRS requirement it comes from and whether the value is still a
 * target or has been confirmed by the owner.
 *
 * Only V1 figures are listed. Later-phase targets (for example KIT-13, JRM-07)
 * are added when their phase starts. DAT-04 (V2) is listed because V1 keeps
 * cooked-meal records under the same retention (QUESTIONS #19). Mobile-only targets (NFR-01,
 * NFR-02, INT-04) belong in the mobile remote config.
 */

export type TargetStatus = "target" | "confirmed";

export interface Target<T> {
  readonly value: T;
  readonly unit: string;
  /** SRS requirement ID(s) the value comes from. */
  readonly srsId: string;
  readonly status: TargetStatus;
}

export interface Targets {
  readonly household: {
    readonly maxProfiles: Target<number>;
  };
  readonly recognition: {
    readonly maxPhotosPerSession: Target<number>;
    readonly latencyP90Ms: Target<number>;
  };
  readonly suggestions: {
    readonly repetitionWindowDays: Target<number>;
    readonly maxConsecutiveSameMainProtein: Target<number>;
    readonly latencyP90Ms: Target<number>;
  };
  readonly tasteAndTweak: {
    readonly latencyP90Ms: Target<number>;
  };
  readonly referenceData: {
    readonly maxPropagationHours: Target<number>;
  };
  readonly notifications: {
    readonly maxPerDayDefault: Target<number>;
  };
  readonly dataManagement: {
    readonly healthConsentWithdrawalDeletionDays: Target<number>;
    readonly accountDeletionDays: Target<number>;
    readonly safetyLogRetentionYears: Target<number>;
    /** Cooked-meal records (QUESTIONS #19: DAT-04 retention applies in V1). */
    readonly mealHistoryRetentionYears: Target<number>;
    readonly backupRestoreTestIntervalMonths: Target<number>;
  };
  readonly serviceLevels: {
    readonly backendAvailabilityMonthlyPercent: Target<number>;
    readonly crashFreeSessionsPercent: Target<number>;
  };
  readonly aiCost: {
    /**
     * Plan limit per household per month. The SRS leaves this to the business
     * model (AI-09, open question 2): null means no limit is enforced; usage is
     * still tracked and alerting stays configurable.
     */
    readonly monthlyLimitPerHousehold: Target<number | null>;
  };
}

const target = <T>(value: T, unit: string, srsId: string): Target<T> => ({
  value,
  unit,
  srsId,
  status: "target",
});

export const defaultTargets: Targets = deepFreeze({
  household: {
    maxProfiles: target(12, "profiles", "PRF-02"),
  },
  recognition: {
    maxPhotosPerSession: target(5, "photos", "REC-01"),
    latencyP90Ms: target(10_000, "ms", "REC-08, NFR-03"),
  },
  suggestions: {
    repetitionWindowDays: target(3, "days", "SUG-07"),
    maxConsecutiveSameMainProtein: target(2, "meals", "SUG-07"),
    latencyP90Ms: target(5_000, "ms", "SUG-13, NFR-03"),
  },
  tasteAndTweak: {
    latencyP90Ms: target(4_000, "ms", "TNT-07, NFR-03"),
  },
  referenceData: {
    maxPropagationHours: target(24, "hours", "SAF-13"),
  },
  notifications: {
    maxPerDayDefault: target(2, "notifications", "NTF-03"),
  },
  dataManagement: {
    healthConsentWithdrawalDeletionDays: target(30, "days", "SET-04"),
    accountDeletionDays: target(30, "days", "SET-08"),
    safetyLogRetentionYears: target(2, "years", "DAT-05"),
    mealHistoryRetentionYears: target(2, "years", "DAT-04"),
    backupRestoreTestIntervalMonths: target(3, "months", "DAT-07"),
  },
  serviceLevels: {
    backendAvailabilityMonthlyPercent: target(99.5, "percent", "NFR-04"),
    crashFreeSessionsPercent: target(99.5, "percent", "NFR-06"),
  },
  aiCost: {
    monthlyLimitPerHousehold: target<number | null>(null, "plan units", "AI-09, NFR-22"),
  },
});

type ValueOf<X> = X extends Target<infer T> ? T : never;

/** Values-only overrides, for example loaded from environment or remote config. */
export type TargetOverrides = {
  readonly [G in keyof Targets]?: {
    readonly [K in keyof Targets[G]]?: ValueOf<Targets[G][K]>;
  };
};

/**
 * Returns the default targets with the given values replaced. Unknown groups or
 * keys throw, so a typo in configuration fails loudly instead of being ignored.
 */
export function resolveTargets(overrides: TargetOverrides = {}): Targets {
  const defaults = defaultTargets as unknown as Record<string, Record<string, Target<unknown>>>;
  const given = overrides as Record<string, Record<string, unknown> | undefined>;

  // Own properties only: a `__proto__` key from JSON must not match a default.
  for (const [group, entries] of Object.entries(given)) {
    if (!Object.hasOwn(defaults, group)) throw new Error(`Unknown target group: ${group}`);
    const known = defaults[group]!;
    if (
      entries !== undefined &&
      (typeof entries !== "object" || entries === null || Array.isArray(entries))
    ) {
      throw new Error(`Target group ${group} must be an object`);
    }
    for (const key of Object.keys(entries ?? {})) {
      if (!Object.hasOwn(known, key)) throw new Error(`Unknown target: ${group}.${key}`);
    }
  }

  const resolved: Record<string, Record<string, Target<unknown>>> = {};
  for (const [group, entries] of Object.entries(defaults)) {
    const groupOverrides = Object.hasOwn(given, group) ? (given[group] ?? {}) : {};
    const out: Record<string, Target<unknown>> = {};
    for (const [key, entry] of Object.entries(entries)) {
      const value = Object.hasOwn(groupOverrides, key) ? groupOverrides[key] : undefined;
      out[key] = value === undefined ? entry : { ...entry, value };
    }
    resolved[group] = out;
  }
  const targets = resolved as unknown as Targets;
  checkBounds(targets);
  return deepFreeze(targets);
}

/**
 * Security review T-019 L1: every target has a type and a range. Where the
 * SRS states a limit (PRF-02 "at least 12", SET-04 and SET-08 "within 30
 * days"), the range enforces it; elsewhere it only stops values that would
 * be absurd or break a requirement (negative retention, "never"). A value
 * outside its range stops startup.
 */
interface Bound {
  readonly min: number;
  readonly max: number;
  readonly integer: boolean;
  readonly nullable?: boolean;
  readonly why: string;
}

const whole = (min: number, max: number, why: string): Bound => ({
  min,
  max,
  integer: true,
  why,
});

export const TARGET_BOUNDS: Readonly<{
  readonly [G in keyof Targets]: { readonly [K in keyof Targets[G]]: Bound };
}> = Object.freeze({
  household: { maxProfiles: whole(12, 100, "PRF-02: at least 12 profiles") },
  recognition: {
    maxPhotosPerSession: whole(1, 20, "REC-01"),
    latencyP90Ms: whole(1, 60_000, "REC-08, NFR-03"),
  },
  suggestions: {
    repetitionWindowDays: whole(0, 30, "SUG-07"),
    maxConsecutiveSameMainProtein: whole(1, 14, "SUG-07"),
    latencyP90Ms: whole(1, 60_000, "SUG-13, NFR-03"),
  },
  tasteAndTweak: { latencyP90Ms: whole(1, 60_000, "TNT-07, NFR-03") },
  referenceData: { maxPropagationHours: whole(1, 72, "SAF-13") },
  notifications: { maxPerDayDefault: whole(0, 10, "NTF-03") },
  dataManagement: {
    healthConsentWithdrawalDeletionDays: whole(0, 30, "SET-04: deletion within 30 days"),
    accountDeletionDays: whole(0, 30, "SET-08: deletion within 30 days"),
    safetyLogRetentionYears: whole(1, 5, "DAT-05: a positive retention"),
    mealHistoryRetentionYears: whole(1, 5, "DAT-04: a positive retention"),
    backupRestoreTestIntervalMonths: whole(1, 12, "DAT-07: restore tested at least yearly"),
  },
  serviceLevels: {
    backendAvailabilityMonthlyPercent: { min: 90, max: 100, integer: false, why: "NFR-04" },
    crashFreeSessionsPercent: { min: 90, max: 100, integer: false, why: "NFR-06" },
  },
  aiCost: {
    monthlyLimitPerHousehold: {
      min: 1,
      max: 1_000_000,
      integer: true,
      nullable: true,
      why: "AI-09: null means no limit",
    },
  },
});

function checkBounds(targets: Targets): void {
  const values = targets as unknown as Record<string, Record<string, Target<unknown>>>;
  const bounds = TARGET_BOUNDS as unknown as Record<string, Record<string, Bound>>;
  for (const [group, entries] of Object.entries(values)) {
    for (const [key, entry] of Object.entries(entries)) {
      const bound = bounds[group]?.[key];
      if (bound === undefined) throw new Error(`target ${group}.${key} has no bound`);
      const value = entry.value;
      if (value === null && bound.nullable === true) continue;
      const ok =
        typeof value === "number" &&
        Number.isFinite(value) &&
        (!bound.integer || Number.isInteger(value)) &&
        value >= bound.min &&
        value <= bound.max;
      if (!ok) {
        throw new Error(
          `${group}.${key} must be ${bound.integer ? "a whole number" : "a number"} from ` +
            `${bound.min} to ${bound.max}${bound.nullable === true ? " or null" : ""} (${bound.why})`,
        );
      }
    }
  }
}

/**
 * Reads optional value overrides from `TARGETS_JSON` (deploy config), for
 * example {"household":{"maxProfiles":14}}. Unknown keys and invalid values
 * stop startup.
 */
export function targetsFromEnv(env: Readonly<Record<string, string | undefined>>): Targets {
  const raw = env["TARGETS_JSON"]?.trim();
  if (raw === undefined || raw === "") return resolveTargets();
  let parsed: unknown;
  try {
    parsed = JSON.parse(raw);
  } catch {
    throw new Error("TARGETS_JSON is not valid JSON");
  }
  if (typeof parsed !== "object" || parsed === null || Array.isArray(parsed)) {
    throw new Error("TARGETS_JSON must be an object");
  }
  return resolveTargets(parsed);
}

function deepFreeze<T>(value: T): T {
  if (value !== null && typeof value === "object") {
    for (const child of Object.values(value)) {
      deepFreeze(child);
    }
    Object.freeze(value);
  }
  return value;
}
