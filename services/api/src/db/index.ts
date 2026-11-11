/**
 * Household data layer (T-016): PostgreSQL migrations, the SRS 18.1 schema,
 * DAT-02 separate-key encryption of health data, consent records, the minimal
 * safety log, and the data-layer pieces of deletion and retention.
 */
export { pgExecutor, type SqlExecutor, type SqlResult } from "./executor.js";
export { migrate, migrationChecksum, MigrationError, type MigrateResult } from "./migrate.js";
export { MIGRATIONS, type Migration } from "./migrations/index.js";
export * from "./errors.js";
export * from "./crypto/key-provider.js";
export { LocalKeyProvider, type LocalKeyMaterial } from "./crypto/local-key-provider.js";
export {
  CloudKmsKeyProvider,
  type CloudKmsKeyNames,
  type KmsClient,
} from "./crypto/cloud-kms-key-provider.js";
export { createKeyProvider, type KeyProviderEnv } from "./crypto/config.js";
export { HealthDataKeys, type MemberDataKey } from "./health-data-keys.js";
export * from "./consent.js";
export {
  confirmRuleMapping,
  deleteHardRule,
  insertHardRule,
  listProfileRules,
  loadRulesForEvaluation,
  type HardRuleRecord,
  type MemberRulesForEvaluation,
  type NewHardRule,
  type ProfileRules,
} from "./hard-rules.js";
export {
  insertSafetyLog,
  readSafetyLog,
  type LoggedReason,
  type SafetyLogMemberDetails,
  type StoredSafetyLog,
  type StoredSafetyLogMember,
} from "./safety-log.js";
export * from "./deletion.js";
export { SCHEMA_TRACE, SRS_18_1_ENTITIES, type Srs181Entity } from "./schema-trace.js";
