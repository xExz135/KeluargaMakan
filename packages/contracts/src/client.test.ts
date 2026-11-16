// TEST FIXTURE: not real safety or nutrition data. Fictional IDs only.
import { readFileSync } from "node:fs";

import { describe, expect, it } from "vitest";

import { createApiClient, type Problem, type Schemas } from "./index.js";
import { SPEC } from "./testing/openapi-document.js";

function recordingFetch(status: number, body: unknown, contentType = "application/json") {
  const requests: Request[] = [];
  const fetch = (request: Request): Promise<Response> => {
    requests.push(request);
    const payload = body === undefined ? null : JSON.stringify(body);
    return Promise.resolve(
      new Response(payload, { status, headers: { "content-type": contentType } }),
    );
  };
  return { fetch, requests };
}

describe("generated TypeScript client", () => {
  it("ACC-01 sends a typed sign-in code request", async () => {
    const challenge: Schemas["SignInCodeChallenge"] = {
      challengeId: "00000000-0000-4000-8000-000000000001",
      channel: "email",
      codeLength: 6,
      expiresAt: "2026-01-01T00:05:00Z",
      resendAvailableAt: "2026-01-01T00:00:30Z",
    };
    const mock = recordingFetch(202, challenge);
    const client = createApiClient({ baseUrl: "http://api.test", fetch: mock.fetch });

    const { data, error } = await client.POST("/v1/auth/code/request", {
      body: { channel: "email", destination: "someone@example.test", language: "id" },
    });

    expect(error).toBeUndefined();
    expect(data?.codeLength).toBe(6);
    const [request] = mock.requests;
    expect(request?.method).toBe("POST");
    expect(request?.url).toBe("http://api.test/v1/auth/code/request");
  });

  it("ACC-08 surfaces consent_required as a typed Problem", async () => {
    const problem: Problem = {
      type: "urn:keluargamakan:problem:consent_required",
      title: "Consent required",
      status: 409,
      code: "consent_required",
      requestId: "req-test-1",
    };
    const mock = recordingFetch(409, problem, "application/problem+json");
    const client = createApiClient({ baseUrl: "http://api.test", fetch: mock.fetch });

    const { data, error } = await client.POST("/v1/household/profiles/{profileId}/hard-rules", {
      params: { path: { profileId: "profile-test-1" } },
      body: { type: "allergy", allergen: "shrimp" },
    });

    expect(data).toBeUndefined();
    expect(error?.code).toBe("consent_required");
    const [request] = mock.requests;
    expect(request?.url).toBe("http://api.test/v1/household/profiles/profile-test-1/hard-rules");
    expect(await request?.json()).toEqual({ type: "allergy", allergen: "shrimp" });
  });

  it("ACC-13 signs out with no body and a 204", async () => {
    const mock = recordingFetch(204, undefined);
    const client = createApiClient({
      baseUrl: "http://api.test",
      fetch: mock.fetch,
      headers: { Authorization: "Bearer test-token" },
    });

    const { error, response } = await client.POST("/v1/auth/sign-out");

    expect(error).toBeUndefined();
    expect(response.status).toBe(204);
    expect(mock.requests[0]?.headers.get("authorization")).toBe("Bearer test-token");
  });
});

describe("generated TypeScript client, contract 0.3", () => {
  it("SUG-01 PRF-09 requests suggestions with member IDs only and reads per-member results", async () => {
    const set: Schemas["SuggestionSet"] = {
      id: "set-test-1",
      page: 1,
      inputs: {
        eaters: { mode: "only_me", memberIds: [] },
        mealType: "lunch",
        timeAvailable: "up_to_30",
      },
      memberIds: ["profile-test-1"],
      items: [],
      poolExhausted: false,
      noSafeRecipe: { closestOptions: [], conflicts: [] },
      aiAvailability: "off",
      libraryVersion: "TEST-FIXTURE-library-1",
      expiresAt: "2026-01-01T01:00:00Z",
    };
    const mock = recordingFetch(200, set);
    const client = createApiClient({ baseUrl: "http://api.test", fetch: mock.fetch });

    const { data, error } = await client.POST("/v1/household/suggestions", {
      body: {
        eaters: { mode: "only_me", memberIds: [] },
        mealType: "lunch",
        timeAvailable: "up_to_30",
      },
    });

    expect(error).toBeUndefined();
    expect(data?.noSafeRecipe?.closestOptions).toEqual([]);
    expect(await mock.requests[0]?.json()).toEqual({
      eaters: { mode: "only_me", memberIds: [] },
      mealType: "lunch",
      timeAvailable: "up_to_30",
    });
  });

  it("SAF-15 sends a wrong-result report with an Idempotency-Key", async () => {
    const mock = recordingFetch(202, {
      reportId: "report-test-1",
      receivedAt: "2026-01-01T00:00:00Z",
    });
    const client = createApiClient({ baseUrl: "http://api.test", fetch: mock.fetch });

    const { data } = await client.POST("/v1/household/safety-reports", {
      params: { header: { "Idempotency-Key": "00000000-0000-4000-8000-000000000002" } },
      body: {
        subject: {
          kind: "library_recipe",
          recipeId: "fx_test_recipe",
          recipeVersion: 1,
          adaptationId: null,
          substitutionId: null,
          variantId: null,
        },
        checkId: "check-test-1",
        ruleSetVersion: "TEST-FIXTURE-rules-1",
        referenceVersion: "TEST-FIXTURE-1",
        memberIds: ["profile-test-1"],
        reportType: "marked_safe_wrong",
        ingredientLineId: null,
        note: null,
      },
    });

    expect(data?.reportId).toBe("report-test-1");
    expect(mock.requests[0]?.headers.get("idempotency-key")).toBe(
      "00000000-0000-4000-8000-000000000002",
    );
  });
});

describe("generated output covers the whole contract", () => {
  const schemaTs = readFileSync(new URL("./generated/schema.ts", import.meta.url), "utf8");
  const dartDir = new URL("../generated/dart/", import.meta.url);
  const snake = (name: string) => name.replace(/([a-z0-9])([A-Z])/g, "$1_$2").toLowerCase();

  it("is marked as generated", () => {
    expect(schemaTs.startsWith("// GENERATED FILE: do not edit.")).toBe(true);
    const dartModel = readFileSync(new URL("lib/model/profile.dart", dartDir), "utf8");
    expect(dartModel).toContain("AUTO-GENERATED FILE, DO NOT MODIFY!");
  });

  it("TypeScript has every component schema and operation", () => {
    for (const name of Object.keys(SPEC.components.schemas)) {
      expect(schemaTs, name).toMatch(new RegExp(`^ {8}${name}: `, "m"));
    }
    for (const path of Object.keys(SPEC.paths)) expect(schemaTs).toContain(`"${path}": {`);
  });

  it("Dart has a model for every component schema and an API class per tag", () => {
    for (const name of Object.keys(SPEC.components.schemas)) {
      // Plain string aliases (Id, TimeZone, ...) become `String` in Dart.
      const s = SPEC.components.schemas[name];
      if (s?.type === "string" && !s.enum) continue;
      // Array aliases (MappedIngredientIds) become `Set<String>` or `List` in Dart.
      if (s?.type === "array") continue;
      // Free-form objects (IngredientDraftContent) become `Map<String, Object>`.
      if (s?.type === "object" && s.properties === undefined) continue;
      expect(
        () => readFileSync(new URL(`lib/model/${snake(name)}.dart`, dartDir)),
        name,
      ).not.toThrow();
    }
    for (const tag of SPEC.tags) {
      expect(
        () => readFileSync(new URL(`lib/api/${snake(tag.name)}_api.dart`, dartDir)),
        tag.name,
      ).not.toThrow();
    }
  });

  it("Dart enums have no catch-all member that could stand in for an unknown value", () => {
    // An unknown value decodes to null, so a required enum field fails to
    // decode; codegen/dart-smoke checks this at runtime (verify:dart).
    const enumFile = readFileSync(new URL("lib/model/rules_consent_status.dart", dartDir), "utf8");
    expect(enumFile).not.toContain("unknownDefaultOpenApi");
    expect(enumFile).toContain("default:");
  });
});
