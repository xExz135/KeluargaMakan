import { readFileSync } from "node:fs";

import { describe, expect, it } from "vitest";

import { CONTRACT_VERSION, CONTRACTS_PACKAGE } from "./index.js";
import { SPEC } from "./testing/openapi-document.js";

describe("contracts package", () => {
  it("loads the package entry point", () => {
    expect(CONTRACTS_PACKAGE).toBe("@keluargamakan/contracts");
  });

  it("ships an OpenAPI 3.1 document at version 0.1.0", () => {
    expect(SPEC.openapi).toMatch(/^3\.1\.\d+$/);
    expect(SPEC.info.version).toBe("0.1.0");
  });

  it("keeps CONTRACT_VERSION, package.json and the Dart pubspec in step with info.version", () => {
    const pkg = JSON.parse(readFileSync(new URL("../package.json", import.meta.url), "utf8")) as {
      version: string;
    };
    const pubspec = readFileSync(
      new URL("../generated/dart/pubspec.yaml", import.meta.url),
      "utf8",
    );
    expect(CONTRACT_VERSION).toBe(SPEC.info.version);
    expect(pkg.version).toBe(SPEC.info.version);
    expect(pubspec).toMatch(
      new RegExp(`^version: '${SPEC.info.version.replaceAll(".", "\\.")}'$`, "m"),
    );
  });
});
