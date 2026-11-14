// TEST FIXTURE: not real safety or nutrition data. Fictional households and accounts.
import "reflect-metadata";

import type { ExecutionContext } from "@nestjs/common";
import { Reflector } from "@nestjs/core";
import { describe, expect, it } from "vitest";

import { ApiError } from "../api-error.js";
import type { AuthContext } from "../auth/auth-service.js";
import { CONTROLLERS } from "../http/app.js";
import { AccessGuard, ACCESS_METADATA, Requires, type AccessRule } from "./access.js";
import {
  grantsOf,
  HOUSEHOLD_PERMISSIONS,
  isAllowed,
  isHouseholdPermission,
  PERMISSIONS,
  REFERENCE_PERMISSIONS,
  ROLES,
} from "./roles.js";

type Handler = (...args: never[]) => unknown;

/** Every route handler of a controller class (methods carrying Nest's route metadata). */
function routesOf(controller: new (...args: never[]) => unknown): [string, Handler][] {
  const proto = controller.prototype as Record<string, unknown>;
  return Object.getOwnPropertyNames(proto)
    .filter((name) => name !== "constructor")
    .map((name) => [name, proto[name]] as [string, unknown])
    .filter(
      (entry): entry is [string, Handler] =>
        typeof entry[1] === "function" && Reflect.getMetadata("method", entry[1]) !== undefined,
    );
}

/** A prototype method by name, without detaching it through a property access. */
function methodOf(controller: { prototype: object }, name: string): Handler {
  const value = Object.getOwnPropertyDescriptor(controller.prototype, name)?.value as unknown;
  if (typeof value !== "function") throw new Error(`no method ${name}`);
  return value as Handler;
}

function contextFor(
  handler: Handler,
  controller: object,
  request: Record<string, unknown>,
): ExecutionContext {
  return {
    getHandler: () => handler,
    getClass: () => controller,
    switchToHttp: () => ({ getRequest: () => request }),
  } as unknown as ExecutionContext;
}

function guardFor(context: Partial<AuthContext>): AccessGuard {
  const auth: AuthContext = {
    accountId: "0b7f3c2e-6f1a-4c55-9d3e-2a1b4c5d6e7f",
    sessionId: "1b7f3c2e-6f1a-4c55-9d3e-2a1b4c5d6e7f",
    householdId: "2b7f3c2e-6f1a-4c55-9d3e-2a1b4c5d6e7f",
    role: "manager",
    ...context,
  };
  return new AccessGuard(new Reflector(), { authenticate: () => Promise.resolve(auth) });
}

async function outcome(promise: Promise<boolean>): Promise<string> {
  try {
    return (await promise) ? "allowed" : "denied";
  } catch (error) {
    return error instanceof ApiError ? `${error.status} ${error.code}` : "error";
  }
}

function ruleOf(controller: object, handler: Handler): AccessRule | undefined {
  return new Reflector().getAllAndOverride<AccessRule | undefined>(ACCESS_METADATA, [
    handler,
    controller as Handler,
  ]);
}

describe("NFR-09 role-based access (T-019)", () => {
  it("NFR-09 the four SRS roles are defined", () => {
    expect([...ROLES].sort()).toEqual(
      ["co_cook", "internal_admin", "manager", "shared_link_viewer"].sort(),
    );
  });

  it("NFR-09 the manager holds every household permission", () => {
    for (const permission of HOUSEHOLD_PERMISSIONS) {
      expect(isAllowed("manager", permission), permission).toBe(true);
    }
    expect(isAllowed("manager", "reference_data:admin")).toBe(false);
  });

  it("NFR-09 co-cook and shared-link viewer are defined but grant nothing until V2", () => {
    expect(grantsOf("co_cook")).toEqual([]);
    expect(grantsOf("shared_link_viewer")).toEqual([]);
    for (const permission of PERMISSIONS) {
      expect(isAllowed("co_cook", permission)).toBe(false);
      expect(isAllowed("shared_link_viewer", permission)).toBe(false);
    }
  });

  it("NFR-09 the internal admin holds reference permissions only, never household data", () => {
    for (const permission of HOUSEHOLD_PERMISSIONS) {
      expect(isAllowed("internal_admin", permission), permission).toBe(false);
    }
    for (const permission of REFERENCE_PERMISSIONS) {
      expect(isAllowed("internal_admin", permission), permission).toBe(true);
    }
  });

  it("NFR-09 an unknown or missing role grants nothing (fail closed)", () => {
    for (const role of ["", "admin", "MANAGER", null, undefined, 1, "manager "]) {
      expect(grantsOf(role)).toEqual([]);
    }
  });

  it("NFR-09 every route of every controller declares its access", () => {
    const missing: string[] = [];
    let count = 0;
    for (const controller of CONTROLLERS) {
      for (const [name, handler] of routesOf(controller)) {
        count += 1;
        if (ruleOf(controller, handler) === undefined) missing.push(`${controller.name}.${name}`);
      }
    }
    expect(count).toBeGreaterThan(5);
    expect(missing).toEqual([]);
  });

  it("NFR-09 only sign-in routes and the readiness probe are public", () => {
    const publicRoutes: string[] = [];
    for (const controller of CONTROLLERS) {
      for (const [name, handler] of routesOf(controller)) {
        if (ruleOf(controller, handler)?.kind === "public") {
          publicRoutes.push(`${controller.name}.${name}`);
        }
      }
    }
    expect(publicRoutes.sort()).toEqual(
      [
        "AuthController.google",
        "AuthController.refresh",
        "AuthController.requestCode",
        "AuthController.verifyCode",
        // Security review T-030 L2: says only ready or not ready.
        "HealthController.ready",
      ].sort(),
    );
  });

  describe("access guard", () => {
    class Undeclared {
      route(): void {}
    }
    class Declared {
      @Requires("profile:read")
      route(): void {}
    }
    const bearer = { headers: { authorization: "Bearer token" } };

    it("NFR-09 a route without an access declaration is refused (403), even for the manager", async () => {
      const guard = guardFor({ role: "manager" });
      const handler = methodOf(Undeclared, "route");
      expect(await outcome(guard.canActivate(contextFor(handler, Undeclared, bearer)))).toBe(
        "403 forbidden",
      );
    });

    it("NFR-09 a protected route without a bearer token is 401", async () => {
      const guard = guardFor({ role: "manager" });
      const handler = methodOf(Declared, "route");
      expect(await outcome(guard.canActivate(contextFor(handler, Declared, { headers: {} })))).toBe(
        "401 unauthenticated",
      );
    });

    it("NFR-09 on every household route the manager is allowed and every other role is refused", async () => {
      for (const controller of CONTROLLERS) {
        for (const [name, handler] of routesOf(controller)) {
          const rule = ruleOf(controller, handler);
          if (rule?.kind !== "permission") continue;
          for (const role of ROLES) {
            const request: Record<string, unknown> = { ...bearer };
            const result = await outcome(
              guardFor({ role }).canActivate(contextFor(handler, controller, request)),
            );
            const expected = isAllowed(role, rule.permission) ? "allowed" : "403 forbidden";
            expect(result, `${role} ${controller.name}.${name}`).toBe(expected);
            if (role !== "manager" && isHouseholdPermission(rule.permission)) {
              expect(result, `${role} ${controller.name}.${name}`).toBe("403 forbidden");
            }
          }
        }
      }
    });

    it("NFR-09 the household scope comes from the session; scoped routes need a household", async () => {
      const handler = methodOf(Declared, "route");
      const request: Record<string, unknown> = { ...bearer };
      const guard = guardFor({ householdId: "3b7f3c2e-6f1a-4c55-9d3e-2a1b4c5d6e7f" });
      expect(await outcome(guard.canActivate(contextFor(handler, Declared, request)))).toBe(
        "allowed",
      );
      expect(request["scope"]).toMatchObject({
        householdId: "3b7f3c2e-6f1a-4c55-9d3e-2a1b4c5d6e7f",
        role: "manager",
      });
      expect(
        await outcome(
          guardFor({ householdId: null }).canActivate(contextFor(handler, Declared, { ...bearer })),
        ),
      ).toBe("409 household_required");
    });
  });
});
