import {
  createParamDecorator,
  Inject,
  Injectable,
  SetMetadata,
  type CanActivate,
  type ExecutionContext,
} from "@nestjs/common";
import { Reflector } from "@nestjs/core";
import type { FastifyRequest } from "fastify";

import { ApiError, unauthenticated } from "../api-error.js";
import type { AuthContext } from "../auth/auth-service.js";
import { AUTH_SERVICE } from "../http/tokens.js";
import { isAllowed, isHouseholdPermission, type Permission, type Role } from "./roles.js";

/**
 * NFR-09 access control for every route (T-019).
 *
 * `AccessGuard` is registered as the global guard, so it runs for every
 * controller method. Each method must declare its access with `@Public()` or
 * `@Requires(permission)`; a method without a declaration is refused with 403
 * (fail closed), and a test checks that every route declares one.
 *
 * Household scoping: the household always comes from the caller's session,
 * read fresh from the account at authentication. No route takes a household
 * ID from the path, query or body. Child resources (profiles, rules, consent
 * records) are looked up inside that household only, so an ID from another
 * household answers 404 exactly like an ID that does not exist.
 */

export type AccessRule =
  | { readonly kind: "public" }
  | {
      readonly kind: "permission";
      readonly permission: Permission;
      /** The route acts on household data, so the caller must have a household (409 `household_required`). */
      readonly household: boolean;
    };

export const ACCESS_METADATA = "keluargamakan:access";

/** No authentication: sign-in, refresh. */
export const Public = () => SetMetadata(ACCESS_METADATA, { kind: "public" } satisfies AccessRule);

/**
 * Permissions on data inside a household (profiles, rules, consent). Their
 * routes get a `HouseholdScope` from the session and answer 409
 * `household_required` before one exists. The household routes themselves
 * (create, read, update) find the household from the account in their service.
 */
const SCOPED: ReadonlySet<Permission> = new Set<Permission>([
  "profile:read",
  "profile:write",
  "hard_rule:read",
  "hard_rule:write",
  "consent:read",
  "consent:write",
]);

/** Requires an authenticated caller whose role holds `permission`. */
export function Requires(permission: Permission) {
  return SetMetadata(ACCESS_METADATA, {
    kind: "permission",
    permission,
    household: SCOPED.has(permission) && isHouseholdPermission(permission),
  } satisfies AccessRule);
}

export const forbidden = () =>
  new ApiError("forbidden", 403, "The caller's role does not allow this request");

export const householdRequired = () =>
  new ApiError("household_required", 409, "The account has no household yet");

/** The caller's own household, from the session. Every household query is scoped by it. */
export interface HouseholdScope {
  readonly householdId: string;
  readonly accountId: string;
  readonly role: Role;
}

type GuardedRequest = FastifyRequest & {
  auth?: AuthContext;
  scope?: HouseholdScope;
};

/** The part of `AuthService` the guard uses (tests pass a stub). */
export interface Authenticator {
  authenticate(accessToken: string): Promise<AuthContext>;
}

@Injectable()
export class AccessGuard implements CanActivate {
  constructor(
    @Inject(Reflector) private readonly reflector: Reflector,
    @Inject(AUTH_SERVICE) private readonly auth: Authenticator,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const rule = this.reflector.getAllAndOverride<AccessRule | undefined>(ACCESS_METADATA, [
      context.getHandler(),
      context.getClass(),
    ]);
    // A route that declares nothing is refused (fail closed).
    if (rule === undefined) throw forbidden();
    if (rule.kind === "public") return true;

    const request = context.switchToHttp().getRequest<GuardedRequest>();
    const header = request.headers.authorization;
    const match = typeof header === "string" ? /^Bearer ([^\s]+)$/.exec(header) : null;
    if (match?.[1] === undefined) throw unauthenticated();
    const principal = await this.auth.authenticate(match[1]);
    request.auth = principal;

    if (!isAllowed(principal.role, rule.permission)) throw forbidden();
    if (rule.household) {
      if (principal.householdId === null) throw householdRequired();
      request.scope = {
        householdId: principal.householdId,
        accountId: principal.accountId,
        role: principal.role as Role,
      };
    }
    return true;
  }
}

/** The caller's `AuthContext`, set by `AccessGuard`. */
export const Auth = createParamDecorator((_data: unknown, context: ExecutionContext) => {
  const auth = context.switchToHttp().getRequest<GuardedRequest>().auth;
  if (auth === undefined) throw unauthenticated();
  return auth;
});

/** The caller's household scope, set by `AccessGuard` for household routes. */
export const Scope = createParamDecorator((_data: unknown, context: ExecutionContext) => {
  const scope = context.switchToHttp().getRequest<GuardedRequest>().scope;
  // Only reachable if a household route forgot `@Requires`: refuse.
  if (scope === undefined) throw forbidden();
  return scope;
});
