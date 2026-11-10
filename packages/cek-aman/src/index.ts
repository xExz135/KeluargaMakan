/**
 * Cek Aman: the deterministic food safety rule engine (SAF-01).
 *
 * This package must stay pure: no network, no AI calls, no clock, no
 * randomness, no I/O. It has no runtime dependencies. Only this engine assigns
 * a safety result; no other component may mark food as safe.
 */
export const CEK_AMAN_PACKAGE = "@keluargamakan/cek-aman" as const;

export { evaluate } from "./evaluate.js";
export { CekAmanInputError } from "./errors.js";
export {
  SAFETY_LOG_FORMAT,
  SAFETY_SUBJECT_KINDS,
  evaluateWithLog,
  type SafetyLogContext,
  type SafetyLogRecord,
  type SafetySubjectKind,
} from "./log.js";
export { RULE_SET_VERSION } from "./rule-set.js";
export type { RuleSummary } from "./rules.js";
export type * from "./types.js";
export * from "./vocabulary.js";
