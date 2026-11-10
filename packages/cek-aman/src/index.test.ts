import { describe, expect, it } from "vitest";

import * as cekAman from "./index.js";

describe("SAF-01 Cek Aman public surface", () => {
  it("SAF-01 exposes the engine, the logger and the versions, and no override API (SAF-12)", () => {
    expect(cekAman.CEK_AMAN_PACKAGE).toBe("@keluargamakan/cek-aman");
    const functions = Object.entries(cekAman)
      .filter(([, value]) => typeof value === "function")
      .map(([name]) => name)
      .sort();
    expect(functions).toEqual(["CekAmanInputError", "evaluate", "evaluateWithLog"]);
    expect(cekAman.RULE_SET_VERSION).toMatch(/^cek-aman-rules\/\d+\.\d+\.\d+$/);
  });

  it("SAF-01 vocabulary lists have unique values", () => {
    for (const list of [
      cekAman.STANDARD_ALLERGENS,
      cekAman.HALAL_VALUES,
      cekAman.NON_HALAL_SOURCES,
      cekAman.DIET_SUITABILITY,
      cekAman.HARD_RULE_TYPES,
      cekAman.MAPPING_STATUSES,
      cekAman.MAPPING_CONFIRMERS,
      cekAman.VERIFICATION_STATES,
      cekAman.SAFETY_SUBJECT_KINDS,
    ]) {
      expect(new Set(list).size).toBe(list.length);
    }
  });
});
