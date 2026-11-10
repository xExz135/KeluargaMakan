/**
 * Home for every figure the SRS marks "(target)".
 *
 * Targets are proposed values that change after validation (SRS 1.3), so they
 * live here as configuration, never as constants in feature code. Each entry
 * records the SRS requirement it comes from and whether the value is still a
 * target or has been confirmed by the owner.
 *
 * Only V1 figures are listed. Later-phase targets (for example KIT-13, JRM-07,
 * DAT-04) are added when their phase starts. Mobile-only targets (NFR-01,
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

  for (const [group, entries] of Object.entries(given)) {
    const known = defaults[group];
    if (known === undefined) {
      throw new Error(`Unknown target group: ${group}`);
    }
    for (const key of Object.keys(entries ?? {})) {
      if (!(key in known)) {
        throw new Error(`Unknown target: ${group}.${key}`);
      }
    }
  }

  const resolved: Record<string, Record<string, Target<unknown>>> = {};
  for (const [group, entries] of Object.entries(defaults)) {
    const groupOverrides = given[group] ?? {};
    const out: Record<string, Target<unknown>> = {};
    for (const [key, entry] of Object.entries(entries)) {
      const value = groupOverrides[key];
      out[key] = value === undefined ? entry : { ...entry, value };
    }
    resolved[group] = out;
  }
  return deepFreeze(resolved) as unknown as Targets;
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
