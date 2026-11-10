import { readFileSync } from "node:fs";

import { describe, expect, it } from "vitest";

import { CONTRACTS_PACKAGE } from "./index.js";

describe("contracts scaffold", () => {
  it("loads the package entry point", () => {
    expect(CONTRACTS_PACKAGE).toBe("@keluargamakan/contracts");
  });

  it("ships an OpenAPI 3.1 document", () => {
    const spec = readFileSync(new URL("../openapi.yaml", import.meta.url), "utf8");
    expect(spec).toMatch(/^openapi: 3\.1\.\d+$/m);
  });
});
