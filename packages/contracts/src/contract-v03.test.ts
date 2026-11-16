// Contract 0.3 (T-040): library, recipes, suggestions, substitutions, meal
// feedback, safety reports, reference versions and the staff admin endpoints.
// TEST FIXTURE: not real safety or nutrition data. The contract carries no values.
import { existsSync } from "node:fs";

import {
  REASON_CODES,
  REASON_KINDS,
  RECIPE_HALAL_STATUSES,
  SAFETY_STATUSES,
  SAFETY_SUBJECT_KINDS,
} from "@keluargamakan/cek-aman";
import { describe, expect, it } from "vitest";

import {
  SPEC,
  allPropertyNames,
  directRefs,
  operation,
  operations,
  reachableSchemas,
  refName,
  schema,
  type OperationEntry,
  type SchemaObject,
} from "./testing/openapi-document.js";

/** Requirement IDs that T-040 (OpenAPI v0.3) supports. */
const T040_REQUIREMENTS = [
  "SUG-01",
  "SUG-02",
  "SUG-03",
  "SUG-04",
  "SUG-05",
  "SUG-07",
  "SUG-08",
  "SUG-09",
  "SUG-10",
  "SUG-11",
  "SUG-12",
  "SUG-13",
  "SUG-16",
  "SUG-17",
  "LIB-01",
  "LIB-03",
  "LIB-04",
  "LIB-05",
  "LIB-06",
  "LIB-08",
  "LIB-11",
  "SAF-02",
  "SAF-04",
  "SAF-05",
  "SAF-11",
  "SAF-13",
  "SAF-14",
  "SAF-15",
  "PRF-09",
  "PRF-11",
  "PRF-12",
  "PRF-13",
  "PRF-14",
  "CKM-01",
  "CKM-09",
  "INT-15",
  "NUT-05",
  "AI-01",
  "AI-08",
  "DAT-06",
  "NFR-20",
] as const;

/** The food items a household can be shown; each requires `safety`. */
const FOOD_ITEMS = [
  "LibraryRecipeListItem",
  "RecipeDetail",
  "RecipeVariant",
  "SubstitutionOption",
  "Suggestion",
];

/** Recipe content that may appear only inside a food item (or in admin shapes). */
const FOOD_CONTENT = [
  "RecipeSummary",
  "RecipeIngredientLine",
  "RecipeStep",
  "KitchenMatch",
  "MissingIngredient",
  "AppliedVariant",
  "AdaptationInfo",
  "NutritionPerServing",
];

const isAdmin = (entry: OperationEntry) => entry.operation.tags?.[0] === "Admin";
const v03Ops = () => operations().filter((entry) => entry.operation["x-server-task"] !== undefined);
const errorCodes = schema("ErrorCode").enum ?? [];
const props = (name: string) => Object.keys(schema(name).properties ?? {});

/** JSON schemas (by name) an operation's request body and responses point at. */
function operationSchemas(entry: OperationEntry): string[] {
  const refs: string[] = [];
  const media = [
    ...Object.values(entry.operation.requestBody?.content ?? {}),
    ...Object.values(entry.operation.responses).flatMap((r) => Object.values(r.content ?? {})),
  ];
  for (const m of media) if (m.schema?.$ref) refs.push(refName(m.schema.$ref));
  return refs;
}

const householdSchemas = reachableSchemas(
  operations()
    .filter((entry) => !isAdmin(entry))
    .flatMap(operationSchemas),
);
const adminOnlySchemas = new Set(
  reachableSchemas(operations().filter(isAdmin).flatMap(operationSchemas)).filter(
    (name) => !householdSchemas.includes(name),
  ),
);

function nullableRef(s: SchemaObject | undefined): string | undefined {
  return s?.$ref ?? s?.oneOf?.find((o) => o.$ref)?.$ref ?? s?.allOf?.[0]?.$ref;
}

describe("contract 0.3 structure (T-040)", () => {
  it.each(T040_REQUIREMENTS)("%s is covered by at least one operation", (id) => {
    expect(
      operations().filter((entry) => entry.operation["x-requirements"]?.includes(id)).length,
    ).toBeGreaterThan(0);
  });

  it("every operation added in 0.3 names the backlog task that serves it", () => {
    const tasks = new Set(v03Ops().map((entry) => entry.operation["x-server-task"]));
    expect([...tasks].sort()).toEqual(["T-041", "T-044", "T-045", "T-048", "T-049", "T-050"]);
    const added = ["Library", "Suggestions", "Meals", "SafetyReports", "Admin"];
    for (const entry of operations()) {
      if (added.includes(entry.operation.tags?.[0] ?? "")) {
        expect(entry.operation["x-server-task"], entry.operation.operationId).toMatch(/^T-\d{3}$/);
      }
    }
    expect(operation("getReferenceVersions").operation["x-server-task"]).toBe("T-050");
  });

  it("NFR-09 every 0.3 operation declares its security and access, never the default", () => {
    for (const entry of v03Ops()) {
      const op = entry.operation;
      const id = op.operationId ?? "";
      expect(op.security, id).toBeDefined();
      if (isAdmin(entry)) {
        expect(op.security, id).toEqual([{ staffAuth: [] }]);
        expect(op["x-staff-roles"]?.length, id).toBeGreaterThan(0);
        expect(op["x-permission"], id).toBeUndefined();
      } else {
        expect(op.security, id).toEqual([{ bearerAuth: [] }]);
        expect(op["x-permission"], id).toMatch(/^[a-z_]+:[a-z_]+$/);
        expect(op["x-staff-roles"], id).toBeUndefined();
      }
    }
  });

  it("household routes take the household from the session, never from the path", () => {
    for (const entry of v03Ops()) expect(entry.path).not.toMatch(/household(Id)?\}/);
    const added = reachableSchemas(
      v03Ops()
        .filter((e) => !isAdmin(e))
        .flatMap(operationSchemas),
    );
    for (const name of added) expect(props(name), name).not.toContain("householdId");
  });

  it("every error code the new operations name exists", () => {
    expect(errorCodes).toEqual(
      expect.arrayContaining([
        "adaptation_expired",
        "substitution_not_available",
        "suggestion_set_expired",
        "draft_changed",
        "draft_not_editable",
        "second_person_required",
        "recipe_not_tested",
        "recipe_ingredients_unresolved",
        "report_already_reviewed",
      ]),
    );
  });
});

describe("Cek Aman results on every food item (SAF-02, SUG-04, AI-01)", () => {
  it("SAF-02 the food items are exactly the reviewed list and each requires `safety`", () => {
    const marked = Object.entries(SPEC.components.schemas)
      .filter(([, s]) => s["x-food-item"] === true)
      .map(([name]) => name)
      .sort();
    expect(marked).toEqual([...FOOD_ITEMS].sort());
    for (const name of FOOD_ITEMS) {
      expect(schema(name).required, name).toContain("safety");
      expect(schema(name).properties?.safety?.$ref, name).toBe("#/components/schemas/RecipeSafety");
    }
  });

  it("SAF-02 recipe content reaches a household only inside a food item", () => {
    for (const content of FOOD_CONTENT) {
      expect(householdSchemas, content).toContain(content);
      const parents = Object.entries(SPEC.components.schemas)
        .filter(([, s]) => directRefs(s).includes(content))
        .map(([name]) => name);
      for (const parent of parents) {
        const allowed =
          FOOD_ITEMS.includes(parent) ||
          FOOD_CONTENT.includes(parent) ||
          adminOnlySchemas.has(parent);
        expect(allowed, `${parent} contains ${content}`).toBe(true);
      }
    }
    expect(schema("RecipeSummary")["x-food-content"]).toBe(true);
  });

  it("SAF-02 every household operation that returns recipe content returns it with a result", () => {
    for (const entry of operations().filter((e) => !isAdmin(e))) {
      const reached = reachableSchemas(
        Object.values(entry.operation.responses)
          .flatMap((r) => Object.values(r.content ?? {}))
          .flatMap((m) => (m.schema?.$ref ? [refName(m.schema.$ref)] : [])),
      );
      if (reached.includes("RecipeSummary")) {
        expect(reached, entry.operation.operationId).toContain("RecipeSafety");
      }
    }
  });

  it("SAF-14 DAT-06 a result names its logged check and the versions it used", () => {
    expect(schema("RecipeSafety").required).toEqual([
      "checkId",
      "checkedAt",
      "ruleSetVersion",
      "referenceVersion",
      "members",
      "halalStatus",
    ]);
    expect(schema("RecipeSafety").properties?.members?.minItems).toBe(1);
  });

  it("SAF-04 SAF-05 PRF-11 per-member results by member ID, with the consent state at check time", () => {
    expect(schema("MemberSafetyResult").required).toEqual([
      "memberId",
      "rulesConsent",
      "status",
      "condition",
      "reasons",
    ]);
    expect(schema("MemberSafetyResult").properties?.rulesConsent?.$ref).toBe(
      "#/components/schemas/RulesConsentStatus",
    );
    expect(schema("RecipeSafety").description).toMatch(/exactly the selected eaters/);
    for (const name of [
      "MemberSafetyResult",
      "SafetyConflict",
      "TradeOff",
      "HiddenNotSafe",
      "AppliedVariant",
      "MemberMealFeedback",
      "AdminReportMember",
    ]) {
      expect(
        props(name).filter((p) => /name/i.test(p)),
        name,
      ).toEqual([]);
    }
  });

  it("SAF-04 statuses, reason kinds and reason codes follow the Cek Aman engine", () => {
    expect(schema("SafetyStatus").enum).toEqual(["safe", "not_safe", "check_label"]);
    expect(schema("SafetyReason").required).toEqual(
      expect.arrayContaining(["kind", "code", "rule", "ingredient", "componentPath"]),
    );
  });

  it("SAF-01 SAF-10 AI-01 no field reads as a safety verdict from AI or anything but Cek Aman", () => {
    const names = allPropertyNames();
    expect(
      names.filter((p) =>
        /^(safe|isSafe|allergenFree|halal|isHalal|verdict|safetyVerdict)$/i.test(p),
      ),
    ).toEqual([]);
    // A request filter that asks for Not safe recipes to be listed with that
    // result is not a verdict.
    const FILTERS = ["LibrarySearchRequest.includeNotSafe"];
    for (const [name, s] of Object.entries(SPEC.components.schemas)) {
      for (const [prop, value] of Object.entries(s.properties ?? {})) {
        if (value.type === "boolean" && !FILTERS.includes(`${name}.${prop}`)) {
          expect(prop, `${name}.${prop}`).not.toMatch(/safe|halal|allergen|verif|tested/i);
        }
      }
    }
    // AI adaptations and AI substitutions are labeled, never a result.
    expect(schema("SubstitutionSource").enum).toEqual(["content_team", "ai"]);
    expect(schema("AdaptationInfo").description).toMatch(/went through Cek Aman again/);
  });

  it("SAF-12 nothing in 0.3 can override, skip or acknowledge away a result", () => {
    const names = [
      ...allPropertyNames(),
      ...operations().map((entry) => entry.operation.operationId ?? ""),
    ];
    expect(names.filter((n) => /override|force|acknowledg|bypass|skip|ignore/i.test(n))).toEqual(
      [],
    );
  });

  it("Q58 unknown response values fail closed: each new response enum says how", () => {
    const cautious: Record<string, RegExp> = {
      SafetyStatus: /unknown value means no result/,
      HalalStatus: /never shown as halal/,
      RecipeOrigin: /unknown value like `generated`/,
      KitchenAvailability: /unknown value as `missing`/,
      NutritionStatus: /unknown value as `unavailable`/,
      AiAvailability: /unknown value as `unavailable`/,
      TradeOffKind: /no line for an unknown value/,
      SafetyReasonCode: /never hides a Not safe result/,
      DraftStatus: /unknown value as not editable and not approvable/,
      SafetyReportStatus: /unknown value as `open`/,
    };
    for (const [name, pattern] of Object.entries(cautious)) {
      expect(schema(name).description?.replace(/\s+/g, " "), name).toMatch(pattern);
    }
    // L5: consent replaces only Safe; it never hides Not safe or Check the label.
    const member = schema("MemberSafetyResult").description?.replace(/\s+/g, " ") ?? "";
    expect(member).toMatch(/a `safe` status is shown as the neutral/);
    expect(member).toMatch(/`not_safe` and `check_label` are always shown as they are/);
    expect(member).toMatch(/consent never hides a Not safe result/);
    expect(member).not.toMatch(/whatever `status` says/);
  });

  it("Q58 the new response enums match the reviewed lists (a change needs a version bump)", () => {
    const names = [
      "EaterMode",
      "SafetyStatus",
      "SafetyReasonKind",
      "HalalStatus",
      "MealType",
      "TimeAvailable",
      "Cuisine",
      "RecipeDifficulty",
      "RecipeSpiceLevel",
      "RecipeOrigin",
      "KitchenAvailability",
      "NutrientCode",
      "NutrientUnit",
      "NutritionStatus",
      "TradeOffKind",
      "AiAvailability",
      "SubstitutionSource",
      "MealRating",
      "MemberMealRating",
      "SafetySubjectKind",
      "SafetyReportType",
    ];
    expect(Object.fromEntries(names.map((n) => [n, schema(n).enum]))).toEqual({
      EaterMode: ["only_me", "whole_family", "selected"],
      SafetyStatus: ["safe", "not_safe", "check_label"],
      SafetyReasonKind: ["contains", "component", "unknown", "brand_uncertain", "unmapped_rule"],
      HalalStatus: ["halal", "not_halal", "check_label"],
      MealType: ["breakfast", "lunch", "dinner", "snack", "sahur", "buka"],
      TimeAvailable: ["up_to_15", "up_to_30", "up_to_60", "over_60"],
      Cuisine: ["indonesian", "japanese", "chinese", "fusion"],
      RecipeDifficulty: ["easy", "medium", "hard"],
      RecipeSpiceLevel: ["not_spicy", "medium", "spicy"],
      RecipeOrigin: ["library", "adapted_library", "family", "generated"],
      KitchenAvailability: ["available", "missing"],
      NutrientCode: [
        "energy",
        "protein",
        "carbohydrate",
        "fat",
        "saturated_fat",
        "fiber",
        "sugar",
        "sodium",
      ],
      NutrientUnit: ["kcal", "g", "mg"],
      NutritionStatus: ["estimate", "unavailable"],
      TradeOffKind: [
        "spice_separate",
        "less_santan",
        "not_fried",
        "less_salt",
        "less_sugar",
        "dislike_skipped",
        "other",
      ],
      AiAvailability: ["available", "off", "unavailable"],
      SubstitutionSource: ["content_team", "ai"],
      MealRating: ["yes", "mixed", "no"],
      MemberMealRating: ["liked", "ok", "disliked"],
      SafetySubjectKind: [
        "library_recipe",
        "suggestion",
        "substitution",
        "taste_tweak_fix",
        "planned_meal",
        "family_recipe",
        "leftover_remake",
      ],
      SafetyReportType: [
        "marked_safe_wrong",
        "marked_not_safe_wrong",
        "check_label_wrong",
        "wrong_ingredient",
        "other",
      ],
    });
  });
});

describe("Masak Apa Hari Ini suggestions", () => {
  it("SUG-01 SUG-11 three per page, and 'Show others' asks for a page by number", () => {
    expect(operation("requestSuggestions").path).toBe("/v1/household/suggestions");
    expect(operation("requestMoreSuggestions").path).toBe(
      "/v1/household/suggestions/{suggestionSetId}/more",
    );
    expect(schema("SuggestionSet").properties?.items?.maxItems).toBe(3);
    expect(schema("SuggestionMoreRequest").required).toEqual(["page"]);
    // M4: a repeated page offers the same recipes but is checked again.
    const more = operation("requestMoreSuggestions").operation.description?.replace(/\s+/g, " ");
    expect(more).toMatch(/every serve, a repeat of the same page included, runs Cek Aman again/);
    expect(more).toMatch(/against the selected members' current rules and consent/);
    expect(more).toMatch(/A stored or cached result is never replayed/);
    expect(more).toMatch(/A changed result is allowed/);
    expect(more).not.toMatch(/returns the same items/);
    expect(errorCodes).toContain("suggestion_set_expired");
  });

  it("SUG-02 SUG-03 SUG-12 PRF-09 the inputs; member IDs only, never rules or conditions", () => {
    expect(schema("SuggestionRequest").required).toEqual(["eaters", "mealType", "timeAvailable"]);
    expect(props("SuggestionRequest")).toEqual([
      "eaters",
      "mealType",
      "timeAvailable",
      "cuisine",
      "onlyWhatIHave",
    ]);
    expect(schema("EaterSelection").required).toEqual(["mode", "memberIds"]);
    expect(schema("Cuisine").description).toMatch(/V1 serves `indonesian` only/);
    const requests = reachableSchemas([
      "SuggestionRequest",
      "SuggestionMoreRequest",
      "LibrarySearchRequest",
      "RecipeDetailRequest",
      "SubstitutionRequest",
    ]);
    const names = requests.flatMap(props);
    expect(
      names.filter((p) =>
        /rule|allergen|condition|diagnos|medical|health|diet|halal|name/i.test(p),
      ),
    ).toEqual([]);
  });

  it("SUG-04 a suggestion that fails for any eater is replaced, not returned", () => {
    const description = operation("requestSuggestions").operation.description ?? "";
    expect(description).toMatch(/replaced, not returned/);
    expect(description).toMatch(/no suggestion\s+is ever returned without a completed result/);
    expect(operation("requestSuggestions").operation.responses["503"]).toBeDefined();
  });

  it("SUG-09 SUG-16 PRF-12 cards carry time, servings for the eaters, badges and one trade-off", () => {
    expect(schema("Suggestion").required).toEqual(
      expect.arrayContaining(["recipe", "servings", "kitchenMatch", "safety", "tradeOff"]),
    );
    expect(schema("RecipeSummary").required).toEqual(
      expect.arrayContaining(["name", "images", "totalMinutes", "baseServings"]),
    );
    expect(schema("TradeOff").required).toEqual([
      "kind",
      "memberIds",
      "otherMemberIds",
      "ingredient",
      "text",
    ]);
  });

  it("SUG-10 missing ingredients are a plain list: no quantities, prices or shopping lists", () => {
    expect(props("MissingIngredient")).toEqual([
      "lineId",
      "ingredientId",
      "displayName",
      "rawName",
    ]);
    const surface = [
      ...Object.keys(SPEC.paths),
      ...Object.keys(SPEC.components.schemas),
      ...allPropertyNames(),
    ];
    expect(
      surface.filter((s) =>
        /shopping|grocer|basket|price|cost|budget|rupiah|checkout|\bcart/i.test(s),
      ),
    ).toEqual([]);
  });

  it("SUG-17 Q28 no safe recipe: closest checked options and conflicts as text, never Not safe cards", () => {
    expect(schema("SuggestionSet").properties?.noSafeRecipe).toBeDefined();
    expect(schema("NoSafeRecipe").properties?.closestOptions?.items?.$ref).toBe(
      "#/components/schemas/Suggestion",
    );
    expect(schema("NoSafeRecipe").properties?.closestOptions?.maxItems).toBe(3);
    expect(schema("NoSafeRecipe").description).toMatch(/never Not safe recipes/);
    expect(props("SafetyConflict")).toEqual(["memberId", "rule", "ingredient", "componentPath"]);
  });

  it("AI-08 the AI state is reported beside results and never changes one", () => {
    for (const name of ["SuggestionSet", "RecipeDetail", "SubstitutionList"]) {
      expect(schema(name).properties?.aiAvailability?.$ref, name).toBe(
        "#/components/schemas/AiAvailability",
      );
    }
    expect(schema("AiAvailability").description).toMatch(/Never affects a\s+safety result/);
    expect(schema("RecipeSafety").properties ?? {}).not.toHaveProperty("aiAvailability");
  });
});

describe("library and recipe screen", () => {
  it("LIB-08 browse and search by name, ingredient, region, meal type and time, in the body", () => {
    const op = operation("searchLibraryRecipes");
    expect(`${op.method} ${op.path}`).toBe("post /v1/library/recipes/search");
    expect(props("LibrarySearchRequest")).toEqual([
      "eaters",
      "query",
      "regionIds",
      "mealTypes",
      "timeAvailable",
      "includeNotSafe",
      "cursor",
      "limit",
    ]);
    expect(schema("LibrarySearchResult").required).toEqual(
      expect.arrayContaining(["items", "nextCursor", "hiddenNotSafe"]),
    );
    expect(operation("listLibraryRegions").path).toBe("/v1/library/regions");
  });

  it("CKM-01 the recipe screen: ingredients with kitchen state, steps, time, servings, result", () => {
    const op = operation("getRecipeDetail");
    expect(`${op.method} ${op.path}`).toBe("post /v1/library/recipes/{recipeId}/detail");
    expect(schema("RecipeIngredientLine").required).toContain("inKitchen");
    expect(schema("RecipeStep").required).toEqual(
      expect.arrayContaining(["timerSeconds", "ingredientLineIds"]),
    );
    expect(op.operation.description).toMatch(/no way to override/);
  });

  it("LIB-01 NFR-23 only tested recipes are served, and no client can mark one tested", () => {
    expect(schema("RecipeSummary").required).toContain("testRecord");
    expect(schema("RecipeTestRecord").required).toEqual(["testedBy", "testedOn"]);
    expect(operation("searchLibraryRecipes").operation.description).toMatch(
      /tester and test date are ever served/,
    );
    // The only way to record a test is a staff-only admin operation.
    const recording = operations().filter((entry) =>
      operationSchemas(entry).some((name) =>
        reachableSchemas([name]).includes("RecipeTestRecordInput"),
      ),
    );
    expect(recording.map((entry) => entry.operation.operationId)).toEqual(["recordRecipeTest"]);
    expect(recording.every(isAdmin)).toBe(true);
    for (const name of householdSchemas) {
      expect(
        props(name).filter((p) => /^(tested|isTested|testRecordInput)$/i.test(p)),
        name,
      ).toEqual([]);
    }
    for (const name of ["AdminRecipeContent", "RecipeDraftCreate", "RecipeDraftUpdate"]) {
      expect(
        props(name).filter((p) => /tested|halal|nutri|safe/i.test(p)),
        name,
      ).toEqual([]);
    }
  });

  it("LIB-03 LIB-04 LIB-05 recipe fields, regional variants and the derived halal status", () => {
    expect(props("AdminRecipeContent")).toEqual(
      expect.arrayContaining([
        "name",
        "description",
        "cuisine",
        "regionId",
        "mealTypes",
        "baseServings",
        "prepMinutes",
        "cookMinutes",
        "difficulty",
        "ingredients",
        "steps",
        "tags",
        "imageIds",
        "baseRecipeId",
      ]),
    );
    expect(props("RecipeTags")).toEqual(["fried", "santan", "spiceLevel"]);
    expect(schema("RecipeDetail").properties?.regionalVariants?.items?.$ref).toBe(
      "#/components/schemas/LibraryRecipeListItem",
    );
    expect(schema("RecipeSafety").properties?.halalStatus?.$ref).toBe(
      "#/components/schemas/RecipeHalalStatus",
    );
    expect(schema("HalalStatus").description).toMatch(/never from AI/);
  });

  it("LIB-06 LIB-07 adapted and generated recipes are labeled and never presented as tested", () => {
    expect(schema("RecipeOrigin").description).toMatch(
      /Only\s+`library` may be presented as a tested recipe/,
    );
    expect(schema("RecipeSummary").description).toMatch(/not a test of the\s+adapted text/);
    expect(errorCodes).toContain("adaptation_expired");
  });

  it("CKM-09 SAF-11 substitutions and variants each carry their own result", () => {
    const op = operation("listRecipeSubstitutions");
    expect(`${op.method} ${op.path}`).toBe("post /v1/library/recipes/{recipeId}/substitutions");
    expect(op.operation.description).toMatch(/never listed/);
    expect(schema("SubstitutionList").required).toEqual(
      expect.arrayContaining(["lines", "variants", "hiddenCount"]),
    );
    expect(props("RecipeDetailRequest")).toEqual([
      "eaters",
      "adaptationId",
      "substitutionIds",
      "variantId",
    ]);
    expect(errorCodes).toContain("substitution_not_available");
  });

  it("NUT-05 nutrition is a labeled range or unavailable, never a single number", () => {
    expect(schema("NutrientRange").required).toEqual(["nutrient", "low", "high", "unit"]);
    expect(schema("NutritionPerServing").required).toEqual(["status", "ranges"]);
    expect(schema("NutritionStatus").description).toMatch(/V1 always sends\s+`unavailable`/);
    expect(schema("RecipeDetail").required).toContain("nutritionPerServing");
    expect(
      allPropertyNames().filter((p) =>
        /^(calories|kcal|energy|protein|fat|carbs?|carbohydrate|sugar|sodium|fiber)$/i.test(p),
      ),
    ).toEqual([]);
  });

  it("REC-07 recipe images are fetched by ID: no schema carries a URL", () => {
    expect(operation("getLibraryImage").path).toBe("/v1/library/images/{imageId}");
    expect(props("RecipeImage")).toEqual(["imageId", "width", "height", "alt"]);
    expect(allPropertyNames().filter((p) => /url|uri|href|link/i.test(p))).toEqual([]);
  });
});

describe("meal feedback and safety reports", () => {
  it("PRF-13 PRF-14 the cooked-meal record with feedback is one idempotent PUT", () => {
    const op = operation("recordCookedMeal");
    expect(`${op.method} ${op.path}`).toBe("put /v1/household/meals/{mealId}");
    expect(schema("MealFeedbackInput").required).toEqual(["overall", "members"]);
    expect(op.operation.description).toMatch(/replay it safely/);
    expect(op.operation.description).toMatch(/next request on \(PRF-14/);
    expect(props("CookedMealInput").filter((p) => /nutri|kcal|oil|fat/i.test(p))).toEqual([]);
  });

  it("SAF-15 SAF-14 a report quotes the check and its versions, with minimum data", () => {
    const op = operation("createSafetyReport");
    expect(`${op.method} ${op.path}`).toBe("post /v1/household/safety-reports");
    expect(props("SafetyReportCreate")).toEqual([
      "subject",
      "checkId",
      "memberIds",
      "reportType",
      "ingredientLineId",
      "note",
    ]);
    expect(schema("SafetyReportCreate").properties?.note).toMatchObject({ maxLength: 300 });
    expect(op.operation.responses["429"]).toBeDefined();
    expect(op.operation.description).toMatch(/never changes a result/);
  });

  it("SAF-15 Q40 staff see rule types and report-local labels, never names or IDs of people", () => {
    expect(props("AdminReportMember")).toEqual(["memberLabel", "status", "rules", "findings"]);
    expect(props("AdminRuleSummary")).toEqual(["type", "allergen"]);
    const staffView = reachableSchemas(["AdminSafetyReportList"]);
    expect(staffView).not.toContain("SafetyRuleRef");
    expect(staffView).not.toContain("MemberSafetyResult");
    // The reviewer's own note (`SafetyReportReview.note`) is staff text.
    const names = staffView.filter((n) => n !== "SafetyReportReview").flatMap(props);
    expect(
      names.filter((p) =>
        /^(memberId|memberIds|householdId|freeText|rawName|note|adaptationId|checkId)$/.test(p),
      ),
    ).toEqual([]);
    // L3: no household-typed text reaches staff verbatim.
    expect(staffView).not.toContain("SafetyIngredientRef");
    expect(staffView).not.toContain("SafetyReportSubject");
    expect(staffView).toContain("AdminIngredientRef");
    expect(props("AdminSafetyReport")).toContain("redactedNote");
    expect(schema("AdminSafetyReport").description).toMatch(
      /never see household-typed\s+text verbatim/,
    );
  });

  // The engine's own value lists, from its package root (SAF-01): any drift
  // between the engine and the contract fails here, and nothing is skipped.
  it("SAF-14 the report subject kinds are the Cek Aman safety-log kinds", () => {
    expect(SAFETY_SUBJECT_KINDS.length).toBeGreaterThan(0);
    expect(schema("SafetySubjectKind").enum).toEqual([...SAFETY_SUBJECT_KINDS]);
  });

  it("SAF-04 reason codes and kinds are the Cek Aman engine's", () => {
    expect(REASON_CODES.length).toBeGreaterThan(0);
    expect(schema("SafetyReasonCode").enum).toEqual([...REASON_CODES]);
    expect(schema("SafetyReasonKind").enum).toEqual([...REASON_KINDS]);
    expect(schema("SafetyStatus").enum).toEqual([...SAFETY_STATUSES]);
  });

  it("LIB-05 the recipe halal status values are the Cek Aman derivation's", () => {
    expect(schema("HalalStatus").enum).toEqual([...RECIPE_HALAL_STATUSES]);
  });
});

describe("reference versions and the admin tool", () => {
  it("SAF-13 DAT-06 NFR-20 versions in use, with a conditional read", () => {
    const op = operation("getReferenceVersions");
    expect(`${op.method} ${op.path}`).toBe("get /v1/reference/versions");
    expect(schema("ReferenceVersions").required).toEqual([
      "ruleSetVersion",
      "referenceVersion",
      "libraryVersion",
      "refreshWithinHours",
    ]);
    expect(op.operation.responses["304"]).toBeDefined();
  });

  it("INT-15 Q20 admin operations are staff-only, under /v1/admin, with known staff roles", () => {
    expect(SPEC.components).toHaveProperty("securitySchemes.staffAuth");
    const roles = schema("StaffRole").enum ?? [];
    expect(roles).toEqual(["content_editor", "safety_reviewer", "nutrition_reviewer", "admin"]);
    const admin = operations().filter(isAdmin);
    expect(admin.length).toBeGreaterThanOrEqual(20);
    for (const entry of admin) {
      expect(entry.path, entry.operation.operationId).toMatch(/^\/v1\/admin\//);
      for (const role of entry.operation["x-staff-roles"] ?? []) expect(roles).toContain(role);
    }
    for (const entry of operations().filter((e) => !isAdmin(e))) {
      expect(entry.path).not.toMatch(/^\/v1\/admin\//);
      expect(JSON.stringify(entry.operation.security ?? null)).not.toContain("staffAuth");
    }
  });

  it("INT-15 SAF-13 reference data and recipes need a second person to approve", () => {
    for (const id of ["decideIngredientDraft", "decideRecipeDraft"]) {
      const op = operation(id).operation;
      expect(op["x-staff-roles"], id).toEqual(["safety_reviewer"]);
      expect(op.description, id).toContain("409 `second_person_required`");
    }
    expect(schema("DraftStatus").enum).toEqual([
      "draft",
      "in_review",
      "approved",
      "rejected",
      "published",
      "discarded",
    ]);
    expect(schema("DraftDecision").enum).toEqual(["approve", "reject"]);
    expect(operation("decideRecipeDraft").operation.description).toContain(
      "409 `recipe_not_tested`",
    );
  });

  it("SAF-06 the ingredient draft content is the reference schema, validated by the server", () => {
    const content = schema("IngredientDraftContent") as SchemaObject & { "x-json-schema"?: string };
    expect(content["x-json-schema"]).toBe("ingredient.schema.json");
    expect(
      existsSync(new URL("../../../data/schema/ingredient.schema.json", import.meta.url)),
    ).toBe(true);
  });

  it("admin lists page with a cursor and answer nextCursor", () => {
    for (const id of [
      "listIngredientDrafts",
      "listAdminRecipes",
      "listRecipeDrafts",
      "listSafetyReports",
    ]) {
      const refs = (operation(id).operation.parameters ?? []).map((p) => p.$ref);
      expect(refs, id).toEqual(
        expect.arrayContaining([
          "#/components/parameters/Cursor",
          "#/components/parameters/PageLimit",
        ]),
      );
      const response =
        operation(id).operation.responses["200"]?.content?.["application/json"]?.schema;
      expect(schema(refName(nullableRef(response) ?? "")).required, id).toContain("nextCursor");
    }
  });

  it("DAT-02 every result, request about rules and report is classified as health data", () => {
    for (const name of [
      "RecipeSafety",
      "MemberSafetyResult",
      "SafetyReason",
      "SafetyRuleRef",
      "SafetyConflict",
      "SafetyReportCreate",
      "AdminSafetyReport",
      ...FOOD_ITEMS,
    ]) {
      expect(schema(name)["x-data-sensitivity"], name).toBe("sensitive_health");
    }
  });
});
