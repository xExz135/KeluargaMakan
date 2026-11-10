import { describe, expect, it } from "vitest";

import { CEK_AMAN_PACKAGE } from "@keluargamakan/cek-aman";

// Placeholder so the required CI gate runs. Real regression cases are added by
// the qa-engineer and safety-engine-engineer, one per reported error (NFR-07).
describe("NFR-07 safety regression harness", () => {
  it("NFR-07 harness resolves the Cek Aman package", () => {
    expect(CEK_AMAN_PACKAGE).toBe("@keluargamakan/cek-aman");
  });
});
