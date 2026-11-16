// TEST FIXTURE: not real safety or nutrition data
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";

import { afterEach, describe, expect, it, vi } from "vitest";

import {
  RECIPE_HALAL_STATUSES,
  RULE_SET_VERSION,
  deriveRecipeHalal,
  evaluate,
  type RecipeHalalInput,
  type RecipeHalalResult,
  type RecipeLineInput,
  type SafetyStatus,
} from "@keluargamakan/cek-aman";

import { fixtureMembers } from "../../data/fixtures/cek-aman/members.fixture.js";
import {
  FIXTURE_REFERENCE_VERSION,
  fixtureReference,
} from "../../data/fixtures/cek-aman/reference.fixture.js";
import { malformedReference, regressionCases, toInput } from "./cases.js";
import { recipeHalalCases, toLines, type RecipeHalalCase } from "./recipe-halal-cases.js";

const label = (c: RecipeHalalCase): string => `${c.id} [${c.requirements.join(", ")}] ${c.title}`;

const toHalalInput = (c: RecipeHalalCase): RecipeHalalInput => ({
  lines: toLines(c.lines),
  reference: c.malformed === true ? malformedReference : fixtureReference,
});

const HALAL_OF: Readonly<Record<SafetyStatus, string>> = {
  safe: "halal",
  not_safe: "not_halal",
  check_label: "check_label",
};

afterEach(() => {
  vi.unstubAllGlobals();
});

describe("NFR-07 LIB-05 recipe halal regression cases", () => {
  it("NFR-07 LIB-05 the recipe halal suite has cases and unique IDs", () => {
    expect(recipeHalalCases.length).toBeGreaterThanOrEqual(20);
    expect(new Set(recipeHalalCases.map((c) => c.id)).size).toBe(recipeHalalCases.length);
  });

  it.each(recipeHalalCases.map((c) => [label(c), c] as const))("%s", (_name, testCase) => {
    const result = deriveRecipeHalal(toHalalInput(testCase));
    const [status, ...codes] = testCase.expect;
    expect(result.status).toBe(status);
    const found = result.findings.map((finding) => finding.code);
    for (const code of codes) expect(found).toContain(code);
    if (status === "halal") expect(result.findings).toEqual([]);
    else expect(result.findings.length).toBeGreaterThan(0);
    // SAF-14, DAT-06: the versions actually used, for the log.
    expect(result.ruleSetVersion).toBe(RULE_SET_VERSION);
    expect(result.referenceVersion).toBe(
      testCase.malformed === true ? malformedReference.version : FIXTURE_REFERENCE_VERSION,
    );
  });
});

describe("LIB-05 SAF-08 the recipe halal status matches Cek Aman's halal rule", () => {
  /** Lines for a regression case: each line lists every brand recorded for its ingredient. */
  function linesFor(testCase: (typeof regressionCases)[number]): RecipeLineInput[] {
    const recorded = toInput(testCase).recordedBrands;
    return toInput(testCase).ingredients.map((item, index) => ({
      lineId: `fx-line-${index + 1}`,
      ingredientId: item.ingredientId,
      brandIds: recorded
        .filter((brand) => brand.ingredientId === item.ingredientId)
        .map((brand) => brand.brandId),
    }));
  }

  it("LIB-05 SAF-08 for every regression recipe, the derived status and findings equal a halal member's result", () => {
    let compared = 0;
    for (const testCase of regressionCases) {
      const lines = linesFor(testCase);
      const input = toInput(testCase);
      const engine = evaluate({ ...input, members: [fixtureMembers.ayah] }).perMember[0]!;
      const derived = deriveRecipeHalal({ lines, reference: input.reference });
      expect(derived.status, testCase.id).toBe(HALAL_OF[engine.status]);
      expect(
        derived.findings.map((f) => [
          f.kind,
          f.code,
          f.line?.index ?? null,
          f.componentPath,
          f.brandId,
          f.detail,
        ]),
        testCase.id,
      ).toEqual(
        engine.reasons.map((r) => [
          r.kind,
          r.code,
          r.ingredient?.index ?? null,
          r.componentPath,
          r.brandId,
          r.detail,
        ]),
      );
      compared += 1;
    }
    // Every regression recipe, the two-brand households (REG-023, REG-085) included.
    expect(compared).toBe(regressionCases.length);
  });

  it("LIB-05 SAF-07 SAF-08 for every recipe halal case, the status equals a halal member's result with the same recorded brands", () => {
    const perLineOnly: string[] = [];
    for (const testCase of recipeHalalCases) {
      const lines = toLines(testCase.lines);
      const brandsOf = (id: string | null): string =>
        JSON.stringify(lines.find((line) => line.ingredientId === id)?.brandIds ?? []);
      // The engine keys brands by ingredient; a case that gives two lines of one
      // ingredient different brands tests per-line brands and has no member equivalent.
      if (
        lines.some((line) => JSON.stringify(line.brandIds ?? []) !== brandsOf(line.ingredientId))
      ) {
        perLineOnly.push(testCase.id);
        continue;
      }
      const member = evaluate({
        ingredients: lines.map((line) => ({ ingredientId: line.ingredientId, rawName: "" })),
        recordedBrands: lines.flatMap((line) =>
          line.ingredientId === null
            ? []
            : (line.brandIds ?? []).map((brandId) => ({
                ingredientId: line.ingredientId!,
                brandId,
              })),
        ),
        members: [fixtureMembers.ayah],
        reference: toHalalInput(testCase).reference,
      }).perMember[0]!;
      const result = deriveRecipeHalal(toHalalInput(testCase));
      expect(result.status, testCase.id).toBe(HALAL_OF[member.status]);
    }
    expect(perLineOnly).toEqual(["HAL-017"]);
  });
});

describe("LIB-05 SAF-01 AI-08 the recipe halal status is independent of AI", () => {
  it("LIB-05 AI-08 disabling all AI services does not change any recipe halal status", () => {
    const baseline: RecipeHalalResult[] = recipeHalalCases.map((c) =>
      deriveRecipeHalal(toHalalInput(c)),
    );
    const unavailable = (): never => {
      throw new Error("AI services disabled for this test");
    };
    vi.stubGlobal("fetch", unavailable);
    vi.stubGlobal("XMLHttpRequest", unavailable);
    vi.stubGlobal("WebSocket", unavailable);
    expect(recipeHalalCases.map((c) => deriveRecipeHalal(toHalalInput(c)))).toEqual(baseline);
  });
});

describe("LIB-05 contract alignment", () => {
  const openapi = readFileSync(
    fileURLToPath(new URL("../../packages/contracts/openapi.yaml", import.meta.url)),
    "utf8",
  );
  const version = /^info:\r?\n(?:[ \t].*\r?\n)*?[ \t]+version:\s*(\d+)\.(\d+)/m.exec(openapi);
  const [major, minor] = [Number(version?.[1] ?? 0), Number(version?.[2] ?? 0)];
  const hasRecipeHalal = major > 0 || minor >= 3;

  it("LIB-05 the contract version can be read", () => {
    expect(version).not.toBeNull();
  });

  it.skipIf(!hasRecipeHalal)(
    "LIB-05 from contract 0.3 on, HalalStatus has exactly the values deriveRecipeHalal returns",
    () => {
      const block = /^ {4}HalalStatus:\r?\n((?: {6}.*\r?\n| *\r?\n)+)/m.exec(openapi);
      expect(block, "HalalStatus schema").not.toBeNull();
      const values = /^ {6}enum:\s*\[([^\]]*)\]/m.exec(block![1]!);
      expect(values, "HalalStatus enum").not.toBeNull();
      expect(values![1]!.split(",").map((v) => v.trim())).toEqual([...RECIPE_HALAL_STATUSES]);
    },
  );
});
