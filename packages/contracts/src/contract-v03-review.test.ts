// Security review of contract 0.3 (T-040 review, 2026-11-16): one test per
// finding fixed in the contract. M3 (strict decoding of food items) belongs to
// the app (T-054, T-055).
import { readFileSync } from "node:fs";

import { describe, expect, it } from "vitest";

import {
  SPEC,
  allPropertyNames,
  operation,
  operations,
  schema,
  type OperationEntry,
  type SchemaObject,
} from "./testing/openapi-document.js";

const FOOD_ITEMS = [
  "LibraryRecipeListItem",
  "RecipeDetail",
  "RecipeVariant",
  "SubstitutionOption",
  "Suggestion",
];

const isAdmin = (entry: OperationEntry) => entry.operation.tags?.[0] === "Admin";
const v03Ops = () => operations().filter((entry) => entry.operation["x-server-task"] !== undefined);
const props = (name: string) => Object.keys(schema(name).properties ?? {});
const ext = (name: string) => schema(name) as SchemaObject & Record<string, unknown>;
const flat = (text: string | undefined) => (text ?? "").replace(/\s+/g, " ");
const info = flat(SPEC.info.description);

function nullableRef(s: SchemaObject | undefined): string | undefined {
  return s?.$ref ?? s?.oneOf?.find((o) => o.$ref)?.$ref ?? s?.allOf?.[0]?.$ref;
}

function parameter(name: string): { required?: boolean; description?: string; schema?: unknown } {
  const found = SPEC.components.parameters[name];
  if (!found) throw new Error(`parameter ${name} not in openapi.yaml`);
  return found;
}

describe("T-040 security review fixes", () => {
  it("H1 SAF-11 a result that holds only with a set-aside portion carries its condition", () => {
    expect(schema("MemberSafetyResult").required).toContain("condition");
    expect(nullableRef(schema("MemberSafetyResult").properties?.condition)).toBe(
      "#/components/schemas/SafetyCondition",
    );
    expect(schema("SafetyCondition").required).toEqual([
      "kind",
      "variantId",
      "separateBeforeStepId",
      "omittedLineIds",
    ]);
    expect(schema("SafetyConditionKind").enum).toEqual(["separate_portion"]);
    for (const name of [
      "SafetyStatus",
      "SafetyConditionKind",
      "SafetyCondition",
      "MemberSafetyResult",
    ]) {
      expect(flat(schema(name).description), name).toMatch(/Check the label/);
      expect(flat(schema(name).description), name).toMatch(/never a bare Safe/);
    }
    expect(info).toMatch(/never a bare Safe/);
    expect(flat(schema("SafetyCondition").description)).toMatch(
      /reused only together with its variant/,
    );
    // Every food item that can carry a variant ties it to the members' conditions.
    const withVariant = FOOD_ITEMS.filter((name) => props(name).includes("variant"));
    expect(withVariant.sort()).toEqual(["RecipeDetail", "RecipeVariant", "Suggestion"]);
    expect(flat(schema("RecipeSafety").description)).toMatch(
      /exactly the members in `variant.separatedMemberIds` carry that variant as their `condition`/,
    );
  });

  it("M1 a substitution carries the whole recipe checked with it", () => {
    expect(schema("SubstitutionOption").required).toContain("recipeSafetyWith");
    expect(schema("SubstitutionOption").properties?.recipeSafetyWith?.$ref).toBe(
      "#/components/schemas/RecipeSafety",
    );
    expect(allPropertyNames()).not.toContain("removesConflictFor");
    const description = flat(schema("SubstitutionOption").description);
    expect(description).toMatch(/replacement ingredients only/);
    expect(description).toMatch(/whole-recipe badges only from a whole-recipe result/);
  });

  it("M2 a variant names the lines left out, and those lines come after the separation", () => {
    expect(schema("AppliedVariant").required).toContain("omittedLineIds");
    expect(schema("SafetyCondition").required).toContain("omittedLineIds");
    const rule = flat(schema("AdminRecipeVariant").description);
    expect(rule).toMatch(/every omitted line is used by at least one step/);
    expect(rule).toMatch(/no step before `separateBeforeStepId` uses an omitted line/);
    expect(ext("AdminRecipeVariant")["x-validation"]).toBeDefined();
    for (const id of ["createRecipeDraft", "submitRecipeDraft", "decideRecipeDraft"]) {
      expect(flat(operation(id).operation.description), id).toMatch(/AdminRecipeVariant/);
    }
  });

  it("M4 SUG-04 every serve of 'show others' is checked again", () => {
    const more = flat(operation("requestMoreSuggestions").operation.description);
    expect(more).toMatch(/every serve, a repeat of the same page included, runs Cek Aman again/);
    expect(more).toMatch(/A stored or cached result is never replayed/);
  });

  it("M5 AI-written text passes the server's safety-word filter", () => {
    const filtered = Object.entries(SPEC.components.schemas).flatMap(([name, s]) =>
      Object.entries(s.properties ?? {})
        .filter(([, p]) => (p as Record<string, unknown>)["x-text-filter"] === "safety-words")
        .map(([prop]) => `${name}.${prop}`),
    );
    expect(filtered.sort()).toEqual([
      "AdaptationInfo.changes",
      "SubstitutionOption.effectNote",
      "TradeOff.text",
    ]);
    expect(info).toMatch(/same word lists as `pnpm check:safety-words`/);
    expect(info).toMatch(/replaced by curated content text or dropped/);
    expect(info).toMatch(/T-044, T-047, T-048, T-063/);
  });

  it("M6 member-linked stores say how deletion, withdrawal and export treat them", () => {
    for (const name of [
      "CookedMealInput",
      "CookedMeal",
      "SafetyReportCreate",
      "AdminSafetyReport",
      "AdaptationInfo",
      "SuggestionSet",
    ]) {
      const retention = ext(name)["x-retention"] as Record<string, string> | undefined;
      expect(Object.keys(retention ?? {}).sort(), name).toEqual([
        "accountDeletion",
        "consentWithdrawal",
        "export",
        "memberDeletion",
        "period",
      ]);
    }
    expect(info).toMatch(/deletion and export endpoints are T-069/);
  });

  it("L1 IDs the phone sends back are bound to the household", () => {
    expect(info).toMatch(/Household-bound IDs/);
    for (const id of ["adaptationId", "checkId", "substitutionId", "variantId", "mealId"]) {
      expect(info, id).toContain(`\`${id}\``);
    }
    expect(info).toMatch(/same answer, with the same timing, as an unknown or expired one/);
  });

  it("L2 reports take versions from the logged check and always carry an Idempotency-Key", () => {
    const refs = (operation("createSafetyReport").operation.parameters ?? []).map((p) => p.$ref);
    expect(refs).toEqual(["#/components/parameters/IdempotencyKeyRequired"]);
    expect(parameter("IdempotencyKeyRequired").required).toBe(true);
    expect(props("SafetyReportCreate")).not.toContain("ruleSetVersion");
    expect(props("SafetyReportCreate")).not.toContain("referenceVersion");
    const description = flat(operation("createSafetyReport").operation.description);
    expect(description).toMatch(/never from the phone/);
    expect(description).toMatch(/does not count against the rate limit/);
  });

  it("L3 staff never see custom ingredient names or the note verbatim", () => {
    expect(props("AdminIngredientRef")).toEqual(["ingredientId", "displayName", "isCustom"]);
    expect(props("AdminSafetyReport")).not.toContain("note");
    expect(flat(schema("AdminSafetyReport").description)).toMatch(/redactedNote/);
  });

  it("L4 meals: UUID IDs per household, the latest copy wins, rate-limited", () => {
    expect(parameter("MealId").schema).toMatchObject({ type: "string", format: "uuid" });
    expect(schema("CookedMealInput").required).toContain("ageMs");
    const op = operation("recordCookedMeal").operation;
    expect(op.responses["429"]?.$ref).toBe("#/components/responses/TooManyRequests");
    expect(flat(op.description)).toMatch(/keyed by household and meal ID/);
    expect(flat(schema("CookedMealInput").description)).toMatch(
      /a late older copy never overwrites a newer edit/,
    );
  });

  it("L5 consent replaces only Safe and never hides Not safe", () => {
    const member = flat(schema("MemberSafetyResult").description);
    expect(member).toMatch(/consent never hides a Not safe result/);
    expect(info).toMatch(/shows the neutral chip only in place of Safe/);
  });

  it("L6 staff and household tokens are distinct; every admin route can answer 403", () => {
    const schemes = (
      SPEC.components as unknown as {
        securitySchemes: Record<string, Record<string, unknown>>;
      }
    ).securitySchemes;
    expect(schemes["staffAuth"]?.["x-token-audience"]).toBe("staff");
    expect(schemes["bearerAuth"]?.["x-token-audience"]).toBe("household");
    expect(String(schemes["staffAuth"]?.["description"])).toMatch(/rejects the other's tokens/);
    for (const entry of operations().filter(isAdmin)) {
      expect(entry.operation.responses["403"]?.$ref, entry.operation.operationId).toBe(
        "#/components/responses/Forbidden",
      );
    }
  });

  it("L7 the new permissions are household permissions, never granted to staff", () => {
    const PENDING = ["library:read", "suggestion:request", "meal:write", "safety_report:write"];
    const roles = readFileSync(
      new URL("../../../services/api/src/authz/roles.ts", import.meta.url),
      "utf8",
    );
    const list = (name: string) =>
      [
        ...(new RegExp(`${name} = \\[([^\\]]*)\\]`).exec(roles)?.[1] ?? "").matchAll(
          /"([a-z_]+:[a-z_]+)"/g,
        ),
      ].map((m) => m[1]);
    const household = list("HOUSEHOLD_PERMISSIONS");
    const reference = list("REFERENCE_PERMISSIONS");
    const staff = /internal_admin: Object\.freeze\(\[([^\]]*)\]/.exec(roles)?.[1] ?? "";
    expect(household.length).toBeGreaterThan(5);
    expect(staff).toContain("reference_data:admin");
    for (const entry of v03Ops().filter((e) => !isAdmin(e))) {
      const op = entry.operation as typeof entry.operation & Record<string, unknown>;
      const permission = op["x-permission"] ?? "";
      if (op["x-permission-scope"] === "household") {
        expect(PENDING, permission).toContain(permission);
        // Added to HOUSEHOLD_PERMISSIONS (and SCOPED) when T-041, T-044,
        // T-045 and T-049 serve them; never a reference permission.
        expect(reference, permission).not.toContain(permission);
        expect(staff, permission).not.toContain(permission);
      } else {
        expect(op["x-permission-scope"], op.operationId).toBe("reference");
        expect(reference, permission).toContain(permission);
      }
    }
  });

  it("L8 a 304 counts only for the ETag sent, and images are checked again before use", () => {
    expect(flat(parameter("IfNoneMatch").description)).toMatch(
      /accepts a 304 only for a request in which it sent/,
    );
    for (const id of ["getReferenceVersions", "getLibraryImage"]) {
      const refs = (operation(id).operation.parameters ?? []).map((p) => p.$ref);
      expect(refs, id).toContain("#/components/parameters/IfNoneMatch");
    }
    const { headers } = SPEC.components as unknown as {
      headers: Record<string, { description?: string }>;
    };
    expect(headers["ImageCacheControl"]?.description).toMatch(/`private, no-cache`/);
    expect(headers["ImageCacheControl"]?.description).not.toMatch(/immutable/);
    expect(flat(operation("getLibraryImage").operation.description)).toMatch(
      /withdrawn or retired image answers 404/,
    );
  });

  it("L9 NUT-05 a nutrient range always has high above low", () => {
    const range = ext("NutrientRange");
    expect(range["x-constraint"]).toBe("high > low");
    expect(flat(range.description)).toMatch(/`high` is greater than `low`/);
    expect(flat(range.description)).toMatch(/treats a range with `low >= high` as `unavailable`/);
    const example = range["example"] as { low: number; high: number };
    expect(example.low).toBeLessThan(example.high);
  });
});
