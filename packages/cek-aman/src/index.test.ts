import { describe, expect, it } from "vitest";

import * as cekAman from "./index.js";

describe("cek-aman scaffold", () => {
  it("loads the package entry point", () => {
    expect(cekAman.CEK_AMAN_PACKAGE).toBe("@keluargamakan/cek-aman");
  });
});
