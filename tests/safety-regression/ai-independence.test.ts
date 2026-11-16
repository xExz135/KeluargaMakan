// TEST FIXTURE: not real safety or nutrition data
import { readdirSync, readFileSync } from "node:fs";
import { basename, dirname, isAbsolute, join, relative, resolve, sep } from "node:path";
import { fileURLToPath } from "node:url";

import { afterEach, describe, expect, it, vi } from "vitest";

import { evaluate, type CekAmanInput } from "@keluargamakan/cek-aman";

import { regressionCases, toInput } from "./cases.js";

const packageDir = fileURLToPath(new URL("../../packages/cek-aman/", import.meta.url));
const sourceDir = join(packageDir, "src");

/** Globals and constructs engine code may never use (SAF-01: no network, clock, randomness, I/O or dynamic code). */
const FORBIDDEN =
  /\b(fetch|XMLHttpRequest|WebSocket|Date|Math\.random|crypto|process|require|setTimeout|setInterval|globalThis|global|performance|eval)\b|\bimport\s*\(|\bFunction\s*\(/;

/** `from "..."` and side-effect `import "..."` specifiers, either quote style. */
function importSpecifiers(code: string): string[] {
  return [
    ...code.matchAll(/\bfrom\s+["']([^"']+)["']/g),
    ...code.matchAll(/^\s*import\s+["']([^"']+)["']/gm),
  ].map((match) => match[1]!);
}

/**
 * Why an engine source may not import `specifier`, or null. Only relative
 * imports that stay inside the package sources, and never test code: the build
 * excludes tests and fixtures, but an import would compile them in.
 */
function importProblem(file: string, specifier: string): string | null {
  if (!/^\.\.?\//.test(specifier)) return "not a relative import";
  const target = resolve(dirname(join(sourceDir, file)), specifier);
  const inside = relative(sourceDir, target);
  if (inside === "" || inside === ".." || inside.startsWith(`..${sep}`) || isAbsolute(inside)) {
    return "outside the package sources";
  }
  const name = basename(target);
  if (/\.(test|spec)\.[jt]s$/.test(name) || name.startsWith("test-fixtures")) {
    return "imports test code";
  }
  return null;
}

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
    for (const { file, code } of sources) {
      for (const specifier of importSpecifiers(code)) {
        expect(importProblem(file, specifier), `${file}: ${specifier}`).toBeNull();
      }
      // Strip comments before scanning for forbidden globals.
      const body = code.replace(/\/\*[\s\S]*?\*\//g, "").replace(/\/\/.*$/gm, "");
      expect(body, file).not.toMatch(FORBIDDEN);
    }
  });

  it("SAF-01 the purity scan itself rejects escapes, test code and dynamic code", () => {
    // A sibling folder that shares the "src" prefix (security review T-025 L4).
    expect(importProblem("index.ts", "../src-shadow/net.js")).toMatch(/outside/);
    expect(importProblem(join("recipe", "halal.ts"), "../../src-shadow/net.js")).toMatch(/outside/);
    expect(importProblem("index.ts", "node:fs")).toMatch(/relative/);
    expect(importProblem("index.ts", "./test-fixtures.js")).toMatch(/test code/);
    expect(importProblem(join("recipe", "halal.ts"), "./halal.test.js")).toMatch(/test code/);
    expect(importProblem(join("recipe", "halal.ts"), "../evaluate.js")).toBeNull();
    expect(importSpecifiers(`import 'node:net';\nexport * from "./x.js";`)).toEqual([
      "./x.js",
      "node:net",
    ]);
    for (const code of ["global.fetch", "eval(text)", "new Function(text)", "Function (text)"]) {
      expect(code).toMatch(FORBIDDEN);
    }
    expect("globalThisless evaluate(input) FunctionName").not.toMatch(FORBIDDEN);
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
