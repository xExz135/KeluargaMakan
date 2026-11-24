// TEST FIXTURE: not real safety or nutrition data. Fictional versions only.
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";

import type { VerifiedReference } from "@keluargamakan/reference-data";
import { describe, expect, it } from "vitest";

import { REFERENCE_VERSION_PATTERN, isReferenceVersion } from "../db/ids.js";
import { MIGRATIONS } from "../db/migrations/index.js";
import type { ApiLogger, LogFields } from "../logger.js";
import {
  loggedReferenceSource,
  referenceSourceOf,
  ReferenceVersionError,
} from "./reference-data.js";

function verified(referenceVersion: string, engineVersion = referenceVersion): VerifiedReference {
  return {
    version: "TEST-FIXTURE-v",
    contentHash: "0".repeat(64),
    fixture: true,
    ingredientCount: 0,
    referenceVersion,
    reference: {
      schema: "keluargamakan.reference.ingredients/1",
      version: engineVersion,
      ingredients: [],
    },
  };
}

describe("L4 DAT-06 SAF-14 one reference version pattern", () => {
  it("DAT-06 the loader accepts a version results can record", () => {
    const good = `TEST-FIXTURE-1@sha256:${"a".repeat(64)}`;
    expect(isReferenceVersion(good)).toBe(true);
    expect(referenceSourceOf(verified(good)).current()?.verified.referenceVersion).toBe(good);
  });

  it.each(["TEST FIXTURE 1", "v1\n", "v1'--", "x".repeat(201), "", "@v1"])(
    "SAF-14 a dataset whose version cannot be logged is refused at load: %j",
    (version) => {
      expect(() => referenceSourceOf(verified(version))).toThrow(ReferenceVersionError);
    },
  );

  it("SAF-14 the engine input must carry the same version", () => {
    expect(() => referenceSourceOf(verified("TEST-FIXTURE-1", "TEST-FIXTURE-2"))).toThrow(
      ReferenceVersionError,
    );
  });

  it("NFR-04 a refused version gives the unavailable source and one log line with the error class", () => {
    const lines: string[] = [];
    const logger: ApiLogger = {
      info: (event: string, fields: LogFields = {}) =>
        lines.push(JSON.stringify({ event, ...fields })),
      error: (event: string, fields: LogFields = {}) =>
        lines.push(JSON.stringify({ event, ...fields })),
    };
    expect(loggedReferenceSource(verified("bad version"), logger).current()).toBeNull();
    expect(lines).toHaveLength(1);
    expect(lines[0]).toContain("ReferenceVersionError");
    expect(lines[0]).not.toContain("bad version");
  });

  it("SAF-14 N6 migration 0012 holds the same pattern as a literal, not the constant", () => {
    const library = MIGRATIONS.find((migration) => migration.name === "library-recipes");
    expect(library?.sql.split(`'${REFERENCE_VERSION_PATTERN}'`).length).toBe(3);
    const source = readFileSync(
      fileURLToPath(new URL("../db/migrations/0012-library-recipes.ts", import.meta.url)),
      "utf8",
    );
    expect(source).not.toContain("REFERENCE_VERSION_PATTERN");
  });
});
