import { describe, expect, it } from "vitest";

import { MigrationError, migrationChecksum, validateMigrationList } from "./migrate.js";
import { MIGRATIONS } from "./migrations/index.js";
import { LATER_PHASE_ENTITIES, SCHEMA_TRACE, SRS_18_1_ENTITIES } from "./schema-trace.js";

const allSql = MIGRATIONS.map((migration) => migration.sql).join("\n");
const createdTables = [...allSql.matchAll(/CREATE TABLE (\w+)/g)].map((match) => match[1]);

describe("migrations", () => {
  it("are numbered 1..n with valid names", () => {
    expect(() => validateMigrationList(MIGRATIONS)).not.toThrow();
    expect(MIGRATIONS.length).toBeGreaterThanOrEqual(4);
  });

  it("reject gaps, bad names and empty migrations", () => {
    const [first, second] = MIGRATIONS;
    if (first === undefined || second === undefined) throw new Error("missing migrations");
    expect(() => validateMigrationList([second])).toThrow(MigrationError);
    expect(() => validateMigrationList([{ ...first, name: "Bad Name" }])).toThrow(MigrationError);
    expect(() => validateMigrationList([{ ...first, sql: " " }])).toThrow(MigrationError);
  });

  it("have stable, distinct checksums", () => {
    const sums = MIGRATIONS.map(migrationChecksum);
    expect(new Set(sums).size).toBe(sums.length);
    for (const sum of sums) expect(sum).toMatch(/^[0-9a-f]{64}$/);
  });

  it("SRS 18 every created table has a trace entry", () => {
    for (const table of createdTables) expect(Object.keys(SCHEMA_TRACE), table).toContain(table);
  });

  it("SRS 21 create no V2 or V3 tables (leftovers, plans, family recipes, shared links, nutrition, health profiles)", () => {
    for (const table of createdTables) {
      expect(table).not.toMatch(/leftover|plan|family_recipe|shared_link|nutrition|health_profile/);
    }
  });

  it("PRF-01 REC-07 SET-05 store no photos or photo URLs", () => {
    expect(allSql).not.toMatch(/photo|image|picture|_url\b/i);
  });

  it("SRS 22 store no shopping lists, costs or budgets", () => {
    expect(allSql).not.toMatch(/shopping|price|cost|budget/i);
  });
});

describe("SRS 18 trace map", () => {
  it("SRS 18 traces every table to an SRS 18.1 entity, with no V2 or V3 entity", () => {
    for (const [table, trace] of Object.entries(SCHEMA_TRACE)) {
      if (trace.entity === "infrastructure") {
        expect(table).toBe("schema_migration");
        continue;
      }
      expect(SRS_18_1_ENTITIES, table).toContain(trace.entity);
      expect(LATER_PHASE_ENTITIES, table).not.toContain(trace.entity);
    }
  });

  it("SRS 18 describes every column", () => {
    for (const [table, trace] of Object.entries(SCHEMA_TRACE)) {
      expect(Object.keys(trace.columns).length, table).toBeGreaterThan(0);
      for (const [column, attribute] of Object.entries(trace.columns)) {
        expect(attribute.trim(), `${table}.${column}`).not.toBe("");
      }
    }
  });

  it("DAT-02 marks hard rules and the safety log as health data", () => {
    expect(SCHEMA_TRACE["hard_rule"]?.sensitivity).toBe("health");
    expect(SCHEMA_TRACE["health_data_key"]?.sensitivity).toBe("health");
    expect(SCHEMA_TRACE["safety_log"]?.sensitivity).toBe("health");
    expect(SCHEMA_TRACE["safety_log_member"]?.sensitivity).toBe("health");
  });

  it("covers the V1 entities T-016 must store", () => {
    const entities = new Set(Object.values(SCHEMA_TRACE).map((trace) => trace.entity));
    for (const entity of [
      "Household",
      "Account",
      "Profile",
      "Hard rule",
      "Soft preference",
      "Consent record",
      "Kitchen item",
      "Ingredient set",
      "Meal",
      "Feedback",
      "Safety result log",
      "Ingredient",
    ]) {
      expect(entities, entity).toContain(entity);
    }
  });
});
