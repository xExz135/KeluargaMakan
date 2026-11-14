// TEST FIXTURE: not real safety or nutrition data. Fictional ingredient names.
import { describe, expect, it } from "vitest";

import { CUSTOM_KEY_MAX, CUSTOM_NAME_MAX, customIngredientRef } from "./requests.js";

describe("KIT-05 custom ingredient names (security review T-030 L1)", () => {
  it("KIT-05 a name and its folded key are stored within the database limits", () => {
    expect(customIngredientRef("  Daun  Jeruk Fiktif ")).toEqual({
      kind: "custom",
      name: "Daun  Jeruk Fiktif",
      key: "daun jeruk fiktif",
    });
    expect(customIngredientRef("x".repeat(CUSTOM_NAME_MAX))?.key).toHaveLength(CUSTOM_NAME_MAX);
  });

  it("L1 a name whose NFKC key would exceed the database limit is refused, not stored", () => {
    const expanding = "ﷺ".repeat(CUSTOM_NAME_MAX);
    expect("ﷺ".normalize("NFKC").length * CUSTOM_NAME_MAX).toBeGreaterThan(CUSTOM_KEY_MAX);
    expect(customIngredientRef(expanding)).toBeNull();
    // A few expanding characters in an ordinary name still fit.
    expect(customIngredientRef("Sambal ﷺ fiktif")?.key.length).toBeLessThanOrEqual(CUSTOM_KEY_MAX);
  });

  it.each(["", "   ", "!!!", "x".repeat(CUSTOM_NAME_MAX + 1), "a​b", "a\u0000b"])(
    "refuses %j",
    (value) => {
      expect(customIngredientRef(value)).toBeNull();
    },
  );
});
