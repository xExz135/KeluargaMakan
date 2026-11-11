/**
 * Household data layer (T-016): PostgreSQL migrations and the SRS 18.1 schema.
 */
export { pgExecutor, type SqlExecutor, type SqlResult } from "./executor.js";
export { migrate, migrationChecksum, MigrationError, type MigrateResult } from "./migrate.js";
export { MIGRATIONS, type Migration } from "./migrations/index.js";
export { SCHEMA_TRACE, SRS_18_1_ENTITIES, type Srs181Entity } from "./schema-trace.js";
