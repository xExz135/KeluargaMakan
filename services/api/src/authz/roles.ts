/**
 * NFR-09 role-based access (T-019): manager, co-cook, shared-link viewer and
 * internal admin, each limited to what they need.
 *
 * V1 enforces two roles:
 * - `manager`: the household's single account (ACC-03). It holds every
 *   household permission, always scoped to its own household.
 * - `internal_admin`: staff who edit reference data in the admin tool (T-051,
 *   QUESTIONS #20). Staff never read household data: the role holds only
 *   reference permissions, and no household permission.
 *
 * `co_cook` (ACC-11) and `shared_link_viewer` (JRM) are V2. They are defined
 * so the model is complete, but they grant nothing until their phase: any
 * request made with them is refused (403 `forbidden`).
 *
 * Grants are an allowlist. A permission missing from a role's list is denied,
 * an unknown role gets nothing, and a route without a declared permission is
 * refused by the access guard (fail closed).
 */

export const ROLES = ["manager", "co_cook", "shared_link_viewer", "internal_admin"] as const;
export type Role = (typeof ROLES)[number];

/**
 * Household permissions act only on the caller's own household, taken from
 * the session (never from a path or body). Reference permissions are not
 * household data.
 */
export const HOUSEHOLD_PERMISSIONS = [
  "session:sign_out",
  "account:read",
  "household:create",
  "household:read",
  "household:write",
  "profile:read",
  "profile:write",
  "hard_rule:read",
  "hard_rule:write",
  "consent:read",
  "consent:write",
] as const;

export const REFERENCE_PERMISSIONS = [
  /** Read-only vocabularies such as the PRF-04 allergen list and consent texts. */
  "reference:read",
  /** Admin tool: propose and review reference data changes (T-051, two-step approval). */
  "reference_data:admin",
] as const;

export const PERMISSIONS = [...HOUSEHOLD_PERMISSIONS, ...REFERENCE_PERMISSIONS] as const;
export type Permission = (typeof PERMISSIONS)[number];
export type HouseholdPermission = (typeof HOUSEHOLD_PERMISSIONS)[number];

const GRANTS: Readonly<Record<Role, readonly Permission[]>> = Object.freeze({
  manager: Object.freeze([...HOUSEHOLD_PERMISSIONS, "reference:read"] as Permission[]),
  // V2 (ACC-11): grants nothing in V1.
  co_cook: Object.freeze([] as Permission[]),
  // V2 (JRM-01 to JRM-09): shared links are served by their own scoped
  // endpoints; this role grants nothing in V1.
  shared_link_viewer: Object.freeze([] as Permission[]),
  // Staff: reference data only, never household data (QUESTIONS #20).
  internal_admin: Object.freeze(["reference:read", "reference_data:admin"] as Permission[]),
});

export function isRole(value: unknown): value is Role {
  return typeof value === "string" && (ROLES as readonly string[]).includes(value);
}

/** The permissions a role holds. Unknown roles hold none. */
export function grantsOf(role: unknown): readonly Permission[] {
  return isRole(role) ? GRANTS[role] : [];
}

export function isAllowed(role: unknown, permission: Permission): boolean {
  return grantsOf(role).includes(permission);
}

export function isHouseholdPermission(permission: Permission): permission is HouseholdPermission {
  return (HOUSEHOLD_PERMISSIONS as readonly string[]).includes(permission);
}
