// TEST FIXTURE: not real safety or nutrition data
import { readdirSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

import { afterEach, describe, expect, it, vi } from "vitest";

import { evaluate, type CekAmanInput } from "@keluargamakan/cek-aman";

import { regressionCases, toInput } from "./cases.js";

const packageDir = fileURLToPath(new URL("../../packages/cek-aman/", import.meta.url));
const sourceDir = join(packageDir, "src");

function engineSources(): { file: string; code: string }[] {
  return readdirSync(sourceDir, { recursive: true, encoding: "utf8" })
    .filter((file) => file.endsWith(".ts") && !/\.(test|spec)\.ts$/.test(file))
    .filter((file) => !file.startsWith("test-fixtures"))
    .map((file) => ({ file, code: readFileSync(join(sourceDir, file), "utf8") }));
}

/** Simulates the API passing along whatever an AI service said. */
function withAiNoise(input: CekAmanInput): CekAmanInput {
  return {
    ...input,
    aiServiceStatus: "available",
    aiSafetyVerdict: "safe",
    ingredients: input.ingredients.map((item) => ({
      ...item,
      recognizedFrom: "photo",
      aiConfidence: 0.99,
      aiSaysHalal: true,
      aiSaysAllergenFree: true,
    })),
  } as CekAmanInput;
}

afterEach(() => {
  vi.unstubAllGlobals();
});

describe("SAF-01 SAF-10 AI-08 Cek Aman is independent of AI", () => {
  const baseline = regressionCases.map((testCase) => evaluate(toInput(testCase)));

  it("SAF acceptance: disabling all AI services does not change any safety result", () => {
    const unavailable = (): never => {
      throw new Error("AI services disabled for this test");
    };
    vi.stubGlobal("fetch", unavailable);
    vi.stubGlobal("XMLHttpRequest", unavailable);
    vi.stubGlobal("WebSocket", unavailable);
    const withAiDown = regressionCases.map((testCase) => evaluate(toInput(testCase)));
    expect(withAiDown).toEqual(baseline);
  });

  it("SAF-10 REC-06 AI-01 AI or recognition output in the input never changes a result", () => {
    const noisy = regressionCases.map((testCase) => evaluate(withAiNoise(toInput(testCase))));
    expect(noisy).toEqual(baseline);
  });

  it("SAF-01 the engine has no runtime dependencies", () => {
    const manifest = JSON.parse(readFileSync(join(packageDir, "package.json"), "utf8")) as Record<
      string,
      unknown
    >;
    expect(manifest["dependencies"]).toBeUndefined();
    expect(manifest["peerDependencies"]).toBeUndefined();
    expect(manifest["optionalDependencies"]).toBeUndefined();
  });

  it("SAF-01 engine sources import only each other and use no network, clock, randomness or I/O", () => {
    const sources = engineSources();
    expect(sources.length).toBeGreaterThan(3);
    const forbidden =
      /\b(fetch|XMLHttpRequest|WebSocket|Date|Math\.random|crypto|process|require|setTimeout|setInterval|globalThis|performance)\b|\bimport\s*\(/;
    for (const { file, code } of sources) {
      const specifiers = [...code.matchAll(/\bfrom\s+"([^"]+)"/g)].map((match) => match[1]);
      for (const specifier of specifiers) expect(specifier, file).toMatch(/^\.\//);
      // Strip comments before scanning for forbidden globals.
      const body = code.replace(/\/\*[\s\S]*?\*\//g, "").replace(/\/\/.*$/gm, "");
      expect(body, file).not.toMatch(forbidden);
    }
  });

  it("SAF-01 same input, same output, and the input is never modified", () => {
    const deepFreeze = <T>(value: T): T => {
      if (typeof value === "object" && value !== null) {
        Object.values(value).forEach(deepFreeze);
        Object.freeze(value);
      }
      return value;
    };
    regressionCases.forEach((testCase, index) => {
      const input = deepFreeze(structuredClone(toInput(testCase)));
      expect(evaluate(input)).toEqual(baseline[index]);
      expect(evaluate(input)).toEqual(evaluate(input));
    });
  });
});
