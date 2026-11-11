import { existsSync } from "node:fs";

import { describe, expect, it } from "vitest";

import {
  SPEC,
  SPEC_TEXT,
  allPropertyNames,
  directRefs,
  operation,
  operations,
  propertyEnum,
  refName,
  schema,
} from "./testing/openapi-document.js";

/** Requirement IDs that T-015 (OpenAPI v0.1) supports. */
const T015_REQUIREMENTS = [
  "ACC-01",
  "ACC-02",
  "ACC-03",
  "ACC-08",
  "ACC-13",
  "PRF-01",
  "PRF-02",
  "PRF-03",
  "PRF-04",
  "PRF-05",
  "PRF-06",
  "PRF-07",
  "PRF-08",
  "PRF-18",
  "SET-03",
] as const;

const errorCodes = schema("ErrorCode").enum ?? [];

function requestSchemaName(operationId: string): string {
  const ref =
    operation(operationId).operation.requestBody?.content?.["application/json"]?.schema?.$ref;
  if (!ref) throw new Error(`${operationId} has no JSON request body`);
  return refName(ref);
}

function responseSchemaName(operationId: string, status: string): string {
  const ref =
    operation(operationId).operation.responses[status]?.content?.["application/json"]?.schema?.$ref;
  if (!ref) throw new Error(`${operationId} has no JSON ${status} response`);
  return refName(ref);
}

function isPublic(operationId: string): boolean {
  const security = operation(operationId).operation.security;
  return Array.isArray(security) && security.length === 0;
}

describe("OpenAPI v0.1 structure", () => {
  it("every operation has a unique operationId, one tag and requirement IDs", () => {
    const ids = operations().map((entry) => entry.operation.operationId);
    expect(ids.every((id) => typeof id === "string" && id.length > 0)).toBe(true);
    expect(new Set(ids).size).toBe(ids.length);
    const tags = new Set(SPEC.tags.map((tag) => tag.name));
    for (const { operation: op } of operations()) {
      expect(op.tags, op.operationId).toHaveLength(1);
      expect(tags.has(op.tags?.[0] ?? ""), op.operationId).toBe(true);
      expect(op["x-requirements"]?.length, op.operationId).toBeGreaterThan(0);
      for (const id of op["x-requirements"] ?? []) expect(id).toMatch(/^[A-Z]{2,3}-\d{2}$/);
    }
  });

  it("every path is versioned under /v1", () => {
    for (const path of Object.keys(SPEC.paths)) expect(path).toMatch(/^\/v1\//);
  });

  it.each(T015_REQUIREMENTS)("%s is covered by at least one operation", (id) => {
    const covering = operations().filter((entry) =>
      entry.operation["x-requirements"]?.includes(id),
    );
    expect(covering.length).toBeGreaterThan(0);
  });

  it("requires a bearer token by default; only sign-in, verify and refresh are public", () => {
    expect(SPEC.security).toEqual([{ bearerAuth: [] }]);
    const publicOps = operations()
      .filter(
        (entry) => Array.isArray(entry.operation.security) && entry.operation.security.length === 0,
      )
      .map((entry) => entry.operation.operationId)
      .sort();
    expect(publicOps).toEqual([
      "refreshSession",
      "requestSignInCode",
      "signInWithGoogle",
      "verifySignInCode",
    ]);
  });

  it("every create POST outside sign-in accepts an Idempotency-Key for safe offline replay", () => {
    for (const id of [
      "createHousehold",
      "createProfile",
      "createHardRule",
      "recordHealthDataConsent",
    ]) {
      const refs = (operation(id).operation.parameters ?? []).map((p) => p.$ref);
      expect(refs, id).toContain("#/components/parameters/IdempotencyKey");
    }
  });
});

describe("error model (RFC 9457)", () => {
  it("every operation has a default error response", () => {
    for (const { operation: op } of operations())
      expect(op.responses.default, op.operationId).toBeDefined();
  });

  it("every error response is application/problem+json with the Problem schema", () => {
    for (const { operation: op } of operations()) {
      for (const [status, response] of Object.entries(op.responses)) {
        if (status !== "default" && Number(status) < 400) continue;
        expect(response.$ref, `${op.operationId} ${status}`).toMatch(/^#\/components\/responses\//);
        const resolved = SPEC.components.responses[refName(response.$ref ?? "")];
        expect(resolved?.content?.["application/problem+json"]?.schema?.$ref).toBe(
          "#/components/schemas/Problem",
        );
        expect(Object.keys(resolved?.content ?? {})).toEqual(["application/problem+json"]);
      }
    }
  });

  it("Problem carries a stable code, a request ID and field errors", () => {
    const problem = schema("Problem");
    expect(problem.required).toEqual(["type", "title", "status", "code", "requestId"]);
    expect(problem.properties?.code?.$ref).toBe("#/components/schemas/ErrorCode");
    expect(problem.properties?.errors?.items?.$ref).toBe("#/components/schemas/FieldError");
  });

  it("every error code named in the contract text exists in ErrorCode", () => {
    const named = [...SPEC_TEXT.matchAll(/\b(?:401|403|409|429|503) `([a-z_]+)`/g)].map(
      (m) => m[1],
    );
    expect(named.length).toBeGreaterThan(5);
    for (const code of named) expect(errorCodes, code).toContain(code);
  });

  it("documents rate limiting with Retry-After on sign-in code requests (ACC-01)", () => {
    expect(operation("requestSignInCode").operation.responses["429"]?.$ref).toBe(
      "#/components/responses/TooManyRequests",
    );
    expect(errorCodes).toContain("rate_limited");
  });
});

describe("accounts and households", () => {
  it("ACC-01 requests and verifies a sign-in code by phone or email", () => {
    expect(operation("requestSignInCode").path).toBe("/v1/auth/code/request");
    expect(operation("verifySignInCode").path).toBe("/v1/auth/code/verify");
    expect(isPublic("requestSignInCode") && isPublic("verifySignInCode")).toBe(true);
    expect(propertyEnum("SignInCodeRequest", "channel")).toEqual(["phone", "email"]);
    expect(responseSchemaName("verifySignInCode", "200")).toBe("Session");
    expect(errorCodes).toEqual(
      expect.arrayContaining(["code_invalid", "code_expired", "code_attempts_exceeded"]),
    );
  });

  it("ACC-01 the code request response never echoes the destination", () => {
    expect(
      Object.keys(schema(responseSchemaName("requestSignInCode", "202")).properties ?? {}),
    ).not.toContain("destination");
  });

  it("ACC-02 exchanges a Google ID token for a session; INT-13 has a documented fallback code", () => {
    expect(operation("signInWithGoogle").path).toBe("/v1/auth/google");
    expect(requestSchemaName("signInWithGoogle")).toBe("GoogleSignIn");
    expect(responseSchemaName("signInWithGoogle", "200")).toBe("Session");
    expect(errorCodes).toEqual(
      expect.arrayContaining(["google_token_invalid", "sign_in_method_unavailable"]),
    );
  });

  it("ACC-02 has no Apple sign-in anywhere (Android only, owner decision)", () => {
    const names = [
      ...Object.keys(SPEC.paths),
      ...operations().map((entry) => entry.operation.operationId ?? ""),
      ...Object.keys(SPEC.components.schemas),
      ...Object.values(SPEC.components.schemas).flatMap((s) => s.enum ?? []),
      ...allPropertyNames(),
    ];
    expect(names.filter((name) => /apple|ios/i.test(name))).toEqual([]);
    expect(schema("DevicePlatform").enum).toEqual(["android"]);
  });

  it("ACC-13 signs out and refreshes sessions; household data is fetched again after sign-in", () => {
    expect(operation("signOut").path).toBe("/v1/auth/sign-out");
    expect(isPublic("signOut")).toBe(false);
    expect(operation("signOut").operation.responses["204"]).toBeDefined();
    expect(responseSchemaName("refreshSession", "200")).toBe("SessionTokens");
    expect(operation("getHousehold").operation["x-requirements"]).toContain("ACC-13");
  });

  it("ACC-13 refresh documents the grace window, family revocation and retryable errors", () => {
    const refresh = operation("refreshSession").operation;
    expect(refresh.description).toMatch(/grace window/);
    expect(refresh.description).toMatch(/revokes the\s+whole session/);
    expect(refresh.responses["429"]?.$ref).toBe("#/components/responses/TooManyRequests");
    expect(refresh.responses["503"]?.$ref).toBe("#/components/responses/ServiceUnavailable");
    expect(operation("verifySignInCode").operation.responses["503"]?.$ref).toBe(
      "#/components/responses/ServiceUnavailable",
    );
  });

  it("ACC-03 one manager account per household; members are profiles, not accounts", () => {
    expect(schema("AccountRole").enum).toEqual(["manager"]);
    expect(schema("Household").required).toEqual(
      expect.arrayContaining(["managerAccountId", "managerProfileId"]),
    );
    expect(Object.keys(schema("Profile").properties ?? {})).not.toContain("accountId");
    expect(operation("createHousehold").operation.responses["409"]).toBeDefined();
    expect(errorCodes).toContain("household_exists");
  });

  it("ACC-03 the account's contact details are only in Account, never in a profile", () => {
    for (const name of Object.keys(SPEC.components.schemas)) {
      if (["Account", "SignInCodeRequest"].includes(name)) continue;
      const props = Object.keys(schema(name).properties ?? {});
      expect(
        props.filter((p) => /^(phone|email|destination)$/i.test(p)),
        name,
      ).toEqual([]);
    }
  });
});

describe("Keluarga Saya profiles", () => {
  it("PRF-01 adds, edits and removes profiles with name, avatar and age group", () => {
    const byId = (id: string) => `${operation(id).method} ${operation(id).path}`;
    expect(byId("listProfiles")).toBe("get /v1/household/profiles");
    expect(byId("createProfile")).toBe("post /v1/household/profiles");
    expect(byId("updateProfile")).toBe("patch /v1/household/profiles/{profileId}");
    expect(byId("deleteProfile")).toBe("delete /v1/household/profiles/{profileId}");
    expect(schema("ProfileCreate").required).toEqual(["name", "ageGroup"]);
    expect(Object.keys(schema("ProfileCreate").properties ?? {})).toContain("avatar");
  });

  it("PRF-01 age groups match the owner decision", () => {
    expect(schema("AgeGroup").enum).toEqual(["infant", "child", "teen", "adult", "elderly"]);
  });

  it("PRF-01 / QUESTIONS #27 has avatars only: no photo, image or picture field anywhere", () => {
    expect(allPropertyNames().filter((p) => /photo|image|picture/i.test(p))).toEqual([]);
    expect(schema("AvatarStyle").enum).toEqual(["initials", "illustration"]);
  });

  it("PRF-02 reports a configured profile limit of at least 12", () => {
    expect(schema("ProfileList").properties?.maxProfiles?.minimum).toBe(12);
    expect(errorCodes).toContain("profile_limit_reached");
  });

  it("PRF-05 stores spice level, less fried, sugar, salt and santan, and textures", () => {
    expect(schema("SpiceLevel").enum).toEqual(["not_spicy", "medium", "spicy"]);
    expect(schema("LessOf").enum).toEqual(["fried", "sugar", "salt", "santan"]);
    expect(schema("TexturePreference").enum).toEqual(["soft", "crunchy", "soupy"]);
    expect(requestSchemaName("replaceSoftPreferences")).toBe("SoftPreferencesInput");
  });

  it("PRF-06 stores likes and dislikes as ingredients or dishes", () => {
    expect(schema("FoodRefKind").enum).toEqual(["ingredient", "dish"]);
    expect(schema("LikesDislikesInput").required).toEqual(["likes", "dislikes"]);
  });

  it("PRF-07 stores portion size and rice portion with age-group defaults", () => {
    expect(schema("PortionSize").enum).toEqual(["small", "normal", "large"]);
    expect(schema("Portions").required).toEqual([
      "portionSize",
      "portionSizeIsDefault",
      "ricePortion",
      "ricePortionIsDefault",
    ]);
  });

  it("PRF-18 flags children; the flag is derived, not writable", () => {
    expect(schema("Profile").required).toContain("isChild");
    expect(Object.keys(schema("ProfileCreate").properties ?? {})).not.toContain("isChild");
    expect(Object.keys(schema("ProfileUpdate").properties ?? {})).not.toContain("isChild");
  });

  it("SET-10 child profiles need a guardian confirmation, recorded as a consent record", () => {
    expect(schema("ProfileCreate").properties?.guardianConfirmation?.$ref).toBe(
      "#/components/schemas/GuardianConfirmationInput",
    );
    expect(schema("ProfileUpdate").properties?.guardianConfirmation?.$ref).toBe(
      "#/components/schemas/GuardianConfirmationInput",
    );
    expect(schema("ConsentPurpose").enum).toContain("guardian_confirmation");
    expect(schema("GuardianConfirmation").required).toContain("consentRecordId");
    expect(errorCodes).toContain("guardian_confirmation_required");
  });

  it("SET-10 nothing marketing-related exists for any profile", () => {
    expect(allPropertyNames().filter((p) => /marketing|newsletter|promo/i.test(p))).toEqual([]);
  });
});

describe("hard rules", () => {
  it("PRF-03 stores allergy, halal, vegetarian, vegan, medical exclusion and free text", () => {
    expect(schema("HardRuleType").enum).toEqual([
      "allergy",
      "halal",
      "vegetarian",
      "vegan",
      "medical_exclusion",
      "free_text",
    ]);
    expect(operation("createHardRule").path).toBe("/v1/household/profiles/{profileId}/hard-rules");
    expect(operation("deleteHardRule").method).toBe("delete");
  });

  it("PRF-03 / SAF-12 offers no way to override a safety result", () => {
    const names = [
      ...allPropertyNames(),
      ...operations().map((entry) => entry.operation.operationId ?? ""),
    ];
    expect(names.filter((n) => /override|force|acknowledg|bypass|skip/i.test(n))).toEqual([]);
  });

  it("PRF-04 standard allergen list includes every required allergen, in order", () => {
    expect(schema("StandardAllergen").enum).toEqual([
      "peanut",
      "tree_nut",
      "shellfish",
      "shrimp",
      "fish",
      "egg",
      "milk",
      "soy",
      "wheat",
      "gluten",
      "sesame",
    ]);
    expect(responseSchemaName("listStandardAllergens", "200")).toBe("StandardAllergenList");
  });

  it("PRF-08 exposes mapping status and lets the manager confirm or reject a mapping", () => {
    expect(schema("MappingStatus").enum).toEqual(["mapped", "proposed", "unmapped"]);
    expect(schema("MappingConfirmer").enum).toEqual(["content_team", "manager"]);
    expect(schema("HardRule").required).toContain("mapping");
    expect(operation("confirmHardRuleMapping").method).toBe("put");
    expect(operation("rejectHardRuleMapping").method).toBe("delete");
    expect(operation("confirmHardRuleMapping").path).toBe(operation("rejectHardRuleMapping").path);
    expect(Object.keys(schema("HardRuleCreate").properties ?? {})).toContain("mappedIngredientIds");
    // T-017: an unmapped rule leaves the list out (or null); generated clients
    // must not default it to an empty list, which the server rejects.
    const mapped = schema("HardRuleCreate").properties?.["mappedIngredientIds"];
    expect(mapped?.oneOf?.map((option) => option.$ref ?? option.type)).toEqual([
      "#/components/schemas/MappedIngredientIds",
      "null",
    ]);
    expect(schema("MappedIngredientIds")).toMatchObject({ type: "array", minItems: 1 });
    // The client can never set a mapping status itself.
    expect(Object.keys(schema("HardRuleCreate").properties ?? {})).not.toContain("mapping");
  });

  it("QUESTIONS #39 rules that cannot be read fail the request instead of returning no rules", () => {
    expect(errorCodes).toContain("rules_unavailable");
    for (const id of ["listProfiles", "getProfile", "listHardRules"]) {
      expect(operation(id).operation.responses["503"], id).toBeDefined();
    }
  });
});

describe("consent", () => {
  it("ACC-08 hard rules cannot be stored without consent", () => {
    expect(operation("createHardRule").operation.responses["409"]).toBeDefined();
    expect(operation("createHardRule").operation.description).toContain("`consent_required`");
    expect(errorCodes).toContain("consent_required");
    expect(schema("ProfileRules").required).toEqual(["consent", "items"]);
  });

  it("ACC-08 / QUESTIONS #36 exposes each member's consent state, including declined and withdrawn", () => {
    expect(schema("RulesConsentStatus").enum).toEqual(["none", "given", "declined", "withdrawn"]);
    expect(schema("ConsentDecision").enum).toEqual(["given", "declined"]);
  });

  it("SET-03 records consent per member with date and text version, and can be withdrawn", () => {
    expect(schema("ConsentRecord").required).toEqual(
      expect.arrayContaining([
        "profileId",
        "purpose",
        "decision",
        "textVersion",
        "decidedAt",
        "withdrawnAt",
      ]),
    );
    expect(schema("HealthDataConsentDecision").required).toEqual([
      "decision",
      "textVersion",
      "language",
    ]);
    expect(operation("recordHealthDataConsent").path).toBe(
      "/v1/household/profiles/{profileId}/consents/health-data",
    );
    expect(operation("withdrawHealthDataConsent").path).toBe(
      "/v1/household/profiles/{profileId}/consents/health-data/withdraw",
    );
    expect(operation("listConsentRecords").method).toBe("get");
    expect(operation("getConsentText").path).toBe("/v1/consent-texts/{purpose}");
    expect(errorCodes).toEqual(
      expect.arrayContaining(["consent_text_outdated", "consent_not_active"]),
    );
  });

  it("SET-04 a withdrawal reports when the member's rules will have been deleted", () => {
    expect(schema("ConsentRecord").properties?.deletionDueBy).toBeDefined();
    expect(schema("RulesConsentState").properties?.deletionDueBy).toBeDefined();
  });
});

describe("data protection", () => {
  const LEVEL: Record<string, number> = {
    public: 0,
    personal: 1,
    credential: 2,
    sensitive_health: 2,
  };

  it("DAT-02 every schema is classified with x-data-sensitivity", () => {
    for (const [name, s] of Object.entries(SPEC.components.schemas)) {
      expect(Object.keys(LEVEL), name).toContain(s["x-data-sensitivity"]);
    }
  });

  it("DAT-02 hard-rule schemas are sensitive health data", () => {
    for (const name of [
      "HardRule",
      "HardRuleCreate",
      "HardRuleMapping",
      "HardRuleMappingConfirmation",
      "HardRuleType",
      "MappedIngredient",
      "MappingStatus",
      "ProfileRules",
      "Profile",
      "ProfileList",
    ]) {
      expect(schema(name)["x-data-sensitivity"], name).toBe("sensitive_health");
    }
  });

  it("DAT-02 a schema is at least as sensitive as every schema it contains", () => {
    for (const [name, s] of Object.entries(SPEC.components.schemas)) {
      const own = LEVEL[s["x-data-sensitivity"] ?? ""] ?? -1;
      for (const child of directRefs(s)) {
        const childLevel = LEVEL[schema(child)["x-data-sensitivity"] ?? ""] ?? 99;
        expect(own, `${name} contains ${child}`).toBeGreaterThanOrEqual(childLevel);
      }
    }
  });

  it("DAT-02 a sensitive_health schema is never inside a credential or public schema", () => {
    const sensitive = new Set(
      Object.entries(SPEC.components.schemas)
        .filter(([, s]) => s["x-data-sensitivity"] === "sensitive_health")
        .map(([name]) => name),
    );
    for (const [name, s] of Object.entries(SPEC.components.schemas)) {
      if (s["x-data-sensitivity"] === "sensitive_health") continue;
      expect(
        directRefs(s).filter((child) => sensitive.has(child)),
        name,
      ).toEqual([]);
    }
  });

  it("errors never carry health data: Problem and its parts are public", () => {
    for (const name of ["Problem", "FieldError", "FieldErrorCode", "ErrorCode"]) {
      expect(schema(name)["x-data-sensitivity"]).toBe("public");
    }
  });

  it("AI-03 the contract has no AI endpoints and device info carries no device name", () => {
    expect(Object.keys(SPEC.paths).filter((p) => /\bai\b|assistant|recogni/i.test(p))).toEqual([]);
    expect(Object.keys(schema("DeviceInfo").properties ?? {})).toEqual([
      "installationId",
      "platform",
      "appVersion",
    ]);
  });

  it("no V2 or V3 surfaces: co-cooks, invites, plans, shared links, fasting, nutrition, health profiles", () => {
    const surface = [
      ...Object.keys(SPEC.paths),
      ...Object.keys(SPEC.components.schemas),
      ...allPropertyNames(),
    ];
    expect(
      surface.filter((s) =>
        /co.?cook|invite|plan|share|fasting|ramadan|nutrition|health.?profile|journal/i.test(s),
      ),
    ).toEqual([]);
  });
});

// Parity with the Cek Aman vocabulary (T-012). Runs once packages/cek-aman is
// on the same branch; until then it is reported as skipped.
const VOCABULARY = new URL("../../cek-aman/src/vocabulary.ts", import.meta.url);

describe("Cek Aman vocabulary parity", () => {
  it.skipIf(!existsSync(VOCABULARY))(
    "PRF-03, PRF-04, PRF-08 contract enums equal the Cek Aman vocabulary",
    async () => {
      const vocabulary = (await import(VOCABULARY.href)) as Record<string, readonly string[]>;
      expect(schema("StandardAllergen").enum).toEqual(vocabulary.STANDARD_ALLERGENS);
      expect(schema("HardRuleType").enum).toEqual(vocabulary.HARD_RULE_TYPES);
      expect(schema("MappingStatus").enum).toEqual(vocabulary.MAPPING_STATUSES);
      expect(schema("MappingConfirmer").enum).toEqual(vocabulary.MAPPING_CONFIRMERS);
    },
  );
});
