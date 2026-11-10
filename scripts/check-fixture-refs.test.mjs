import assert from "node:assert/strict";
import { describe, it } from "node:test";

import { findViolations, isExempt } from "./check-fixture-refs.mjs";

const files = {
  "infra/envs/production/main.tf": 'reference_dir = "../../data/fixtures/ingredients"',
  "services/api/config/reference.ts": 'export const dir = "data\\\\fixtures";',
  "services/api/src/app.ts": "export const ok = true;",
  "services/api/src/app.test.ts": 'load("data/fixtures/x.json")',
  "tests/safety-regression/cases.test.ts": 'load("../../data/fixtures/x.json")',
  "data/fixtures/x.json": '{ "note": "data/fixtures" }',
  "docker-compose.yml": "./data/fixtures:/fixtures:ro",
  "docker-compose.prod.yml": "./data/fixtures:/fixtures:ro",
  "image.png": "\0data/fixtures",
};
const read = (path) => Buffer.from(files[path]);

describe("fixture guard (docs workflow section 5)", () => {
  it("flags production config, infra and service code that reference fixtures", () => {
    const flagged = findViolations(Object.keys(files), read).map((v) => v.path);
    assert.deepEqual(flagged.sort(), [
      "docker-compose.prod.yml",
      "infra/envs/production/main.tf",
      "services/api/config/reference.ts",
    ]);
  });

  it("exempts tests, fixtures themselves and local-only compose", () => {
    assert.equal(isExempt("tests/e2e/flow.test.ts"), true);
    assert.equal(isExempt("services/ai/tests/test_health.py"), true);
    assert.equal(isExempt("data/fixtures/x.json"), true);
    assert.equal(isExempt("docker-compose.yml"), true);
    assert.equal(isExempt("infra/main.tf"), false);
    assert.equal(isExempt(".github/workflows/deploy.yml"), false);
    assert.equal(isExempt("services/api/.env.example"), false);
  });

  it("reports file and line", () => {
    const [v] = findViolations(["infra/envs/production/main.tf"], read);
    assert.deepEqual(v, {
      path: "infra/envs/production/main.tf",
      line: 1,
      text: 'reference_dir = "../../data/fixtures/ingredients"',
    });
  });
});
