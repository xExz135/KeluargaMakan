/**
 * PRF-18, SET-10: stricter handling for profiles under 18 (infant 0–1,
 * child 2–12, teen 13–17; DECISIONS 2026-11-10). The database derives
 * `profile.is_child` from the same age groups, and both are checked by a test.
 *
 * - Health data is off by default for every profile, children included: no
 *   consent is ever pre-given, so a new profile stores no hard rules until
 *   the manager records a health-data consent (ACC-08, QUESTIONS #13).
 * - A child profile also needs the manager's recorded confirmation as parent
 *   or guardian before the profile is saved (database constraint at commit)
 *   and before any health data (consent and hard-rule checks, and the
 *   `hard_rule` trigger).
 * - Children's profiles are never used for marketing. V1 has no marketing at
 *   all, and analytics (T-075) carry no profile data (DAT-08); this policy is
 *   the switch later features must consult.
 */

export const AGE_GROUPS = ["infant", "child", "teen", "adult", "elderly"] as const;
export type AgeGroup = (typeof AGE_GROUPS)[number];

export const CHILD_AGE_GROUPS: readonly AgeGroup[] = Object.freeze(["infant", "child", "teen"]);

export function isAgeGroup(value: unknown): value is AgeGroup {
  return typeof value === "string" && (AGE_GROUPS as readonly string[]).includes(value);
}

export function isChildAgeGroup(ageGroup: AgeGroup): boolean {
  return CHILD_AGE_GROUPS.includes(ageGroup);
}

export interface DataHandling {
  /** PRF-18 flag, returned as `Profile.isChild`. */
  readonly isChild: boolean;
  /** Every profile starts with health data off; only an explicit consent turns it on. */
  readonly healthDataByDefault: "off";
  /** SET-10: the manager's recorded parent or guardian confirmation is needed. */
  readonly guardianConfirmationRequired: boolean;
  /** SET-10: never true for a child. V1 has no marketing, so it is false for everyone. */
  readonly marketingUseAllowed: false;
}

export function dataHandlingFor(ageGroup: AgeGroup): DataHandling {
  const isChild = isChildAgeGroup(ageGroup);
  return {
    isChild,
    healthDataByDefault: "off",
    guardianConfirmationRequired: isChild,
    marketingUseAllowed: false,
  };
}
