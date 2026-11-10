import { describe, expect, it } from "vitest";

import { WEB_APP } from "./index.js";

describe("web scaffold", () => {
  it("loads the package entry point", () => {
    expect(WEB_APP).toBe("@keluargamakan/web");
  });
});
