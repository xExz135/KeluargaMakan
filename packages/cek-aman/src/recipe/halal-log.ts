import { readContext } from "../log.js";
import type { SafetyLogContext } from "../log.js";
import {
  deriveWithLines,
  type CheckedLine,
  type RecipeHalalFinding,
  type RecipeHalalInput,
  type RecipeHalalResult,
  type RecipeHalalStatus,
} from "./halal.js";

/**
 * Companion to the safety log (`keluargamakan.safety-log/1`, unchanged): one
 * record per served recipe halal status (SAF-14, DAT-06, LIB-05).
 */
export const RECIPE_HALAL_LOG_FORMAT = "keluargamakan.recipe-halal-log/1";

/**
 * Recipe halal log record, built for the API to persist before the halal
 * status is served. It echoes every line as checked, with its reference
 * ingredient ID and the brands it was checked with, so a `halal` result (which
 * has no findings) can still be traced to the brand data behind it, and the
 * result can be reproduced from the logged versions. It holds no ingredient
 * names, member data or free text. Brand IDs are the household's own records,
 * so store it as personal data, beside the check's safety log record.
 */
export interface RecipeHalalLogRecord {
  readonly logFormat: typeof RECIPE_HALAL_LOG_FORMAT;
  readonly householdId: string;
  readonly subject: SafetyLogContext["subject"];
  readonly evaluatedAt: string;
  readonly ruleSetVersion: string;
  readonly referenceVersion: string;
  readonly status: RecipeHalalStatus;
  /** Every line, in recipe order: line ID, reference ingredient ID (null when unresolved) and brands. */
  readonly lines: readonly CheckedLine[];
  readonly findings: readonly RecipeHalalFinding[];
}

/**
 * The API entry point for a served recipe halal status, like `evaluateWithLog`.
 * The context is checked first, so an untraceable result is never produced.
 *
 * The API must persist `logRecord`, in the same transaction as the check's
 * safety log record, before it returns the halal status; when that write
 * fails, the food item is not served (SAF-02, SAF-14). This package cannot
 * write anything itself (SAF-01: no I/O).
 *
 * @throws CekAmanInputError for an unusable context or input.
 */
export function deriveRecipeHalalWithLog(
  input: RecipeHalalInput,
  context: SafetyLogContext,
): { readonly result: RecipeHalalResult; readonly logRecord: RecipeHalalLogRecord } {
  const checked = readContext(context);
  const { result, lines } = deriveWithLines(input);
  return {
    result,
    logRecord: {
      logFormat: RECIPE_HALAL_LOG_FORMAT,
      householdId: checked.householdId,
      subject: checked.subject,
      evaluatedAt: checked.evaluatedAt,
      ruleSetVersion: result.ruleSetVersion,
      referenceVersion: result.referenceVersion,
      status: result.status,
      lines,
      findings: result.findings,
    },
  };
}
