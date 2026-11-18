import { randomUUID } from "node:crypto";

import {
  CekAmanInputError,
  deriveRecipeHalalWithLog,
  evaluateWithLog,
  type CekAmanResult,
  type HardRule,
  type RecipeHalalFinding,
  type RecipeHalalLogRecord,
  type RecipeHalalResult,
  type SafetyLogRecord,
  type SafetyReason,
  type SafetyStatus,
  type SafetySubjectKind,
} from "@keluargamakan/cek-aman";
import type { Schemas } from "@keluargamakan/contracts";

import { InvalidDataError, RulesChangedError } from "../db/errors.js";
import type { SqlExecutor } from "../db/executor.js";
import type { HealthDataKeys } from "../db/health-data-keys.js";
import { insertRecipeHalalLog } from "../db/recipe-halal-log.js";
import { insertSafetyLogs } from "../db/safety-log.js";
import type { LoadedReference } from "../reference/reference-data.js";
import type { CheckEater } from "./eaters.js";

/**
 * The one way the API serves a food item's safety result (SAF-02, SAF-14,
 * AI-01; T-025 security review N2 to N4, QUESTIONS #87 and #88). T-041 serves
 * library recipes through it; T-043 and the later food routes (suggestions,
 * substitutions, Taste & Tweak fixes) use the same two steps.
 *
 * 1. `checkFood` runs Cek Aman for exactly the selected eaters (PRF-11) and
 *    derives the recipe halal status from the same reference snapshot
 *    (LIB-05). It writes nothing and returns a `PendingCheck`: the member
 *    statuses (so a caller can leave out or replace a Not safe item, SUG-04)
 *    and, hidden inside, the two log records and the response built from a
 *    copy of the results (N3). A check that Cek Aman refuses, or whose result
 *    cannot be shown in full, gives null: the item is left out, never shown
 *    without a result.
 * 2. `serveChecked` writes the safety log and the `recipe-halal-log/1` record
 *    of every check in one transaction, each under the check's own random
 *    `checkId` (the safety log row ID, N2), and returns the `RecipeSafety`
 *    bodies only after the commit (N4). When any write fails nothing is
 *    returned: the caller serves no item.
 *
 * Halal lines carry every brand the household recorded for the line's
 * ingredient, the same brands `evaluate` gets, never a brand from the
 * library line (QUESTIONS #87 default). Nothing here decides safety: only
 * the engine does (SAF-01). There is no override (SAF-12).
 *
 * A source test (`checked-serving.test.ts`) fails if `evaluate(`,
 * `evaluateWithLog(`, `deriveRecipeHalal(` or `deriveRecipeHalalWithLog(` is
 * called from any other non-test module of the API.
 */

export type RecipeSafetyBody = Schemas["RecipeSafety"];

/** One ingredient line of a food item, as Cek Aman gets it. */
export interface FoodLine {
  /** Unique within the item; reasons and halal findings point back at it. */
  readonly lineId: string;
  /** Reference ingredient ID, or null when the line does not resolve (SAF-09). */
  readonly ingredientId: string | null;
  /** The name as written, shown in reasons. Never logged. */
  readonly rawName: string;
  /** A Dapur Saya custom ingredient (KIT-05). */
  readonly isCustom?: boolean;
}

export interface FoodCandidate {
  readonly subject: {
    readonly kind: SafetySubjectKind;
    readonly id: string;
    readonly version: string | null;
  };
  /** Every line, optional ones included (QUESTIONS #86). */
  readonly lines: readonly FoodLine[];
}

export interface CheckContext {
  readonly householdId: string;
  /** Exactly the selected eaters, in selection order (PRF-09, PRF-11). */
  readonly eaters: readonly CheckEater[];
  /** SAF-07, QUESTIONS #87: every brand the household recorded, per reference ingredient. */
  readonly recordedBrands: ReadonlyMap<string, readonly string[]>;
  readonly reference: LoadedReference;
  /** One time for every check of a request, from the server clock. */
  readonly evaluatedAt: Date;
}

/** A check that ran and is not served yet. Its internals are reachable only from this module. */
export interface PendingCheck {
  readonly subjectId: string;
  /** Per eater, in selection order. For decisions only; never a response body. */
  readonly statuses: readonly { readonly memberId: string; readonly status: SafetyStatus }[];
  /** Eaters for whom the item is Not safe (SUG-04: leave out or replace it). */
  readonly notSafeFor: readonly string[];
}

/** A check whose logs are committed: the only source of a `RecipeSafety` body. */
export interface ServedCheck {
  readonly subjectId: string;
  readonly safety: RecipeSafetyBody;
}

interface PendingInternals {
  readonly checkId: string;
  readonly safetyLog: SafetyLogRecord;
  readonly halalLog: RecipeHalalLogRecord;
  readonly body: RecipeSafetyBody;
  /** Each eater's rule stamp when the check ran (security review T-041 L1). */
  readonly ruleStamps: ReadonlyMap<string, string>;
  served: boolean;
}

const internals = new WeakMap<PendingCheck, PendingInternals>();

/** The response could not show the result in full; the item is left out (fail closed). */
class UnshowableResultError extends Error {
  constructor(what: string) {
    super(`safety result cannot be shown: ${what}`);
    this.name = "UnshowableResultError";
  }
}

/** A log write was refused as invalid data: a server fault, never the caller's. */
export class SafetyLogWriteError extends Error {
  constructor() {
    super("the safety log could not be written");
    this.name = "SafetyLogWriteError";
  }
}

// ---------------------------------------------------------------- names

interface ReferenceNames {
  readonly ingredients: ReadonlyMap<string, { readonly id: string; readonly en: string }>;
  readonly brands: ReadonlyMap<string, string>;
}

const namesCache = new WeakMap<LoadedReference, ReferenceNames>();

function namesOf(reference: LoadedReference): ReferenceNames {
  let names = namesCache.get(reference);
  if (names === undefined) {
    const ingredients = new Map<string, { id: string; en: string }>();
    const brands = new Map<string, string>();
    for (const item of reference.verified.reference.ingredients) {
      ingredients.set(item.id, { id: item.displayName.id, en: item.displayName.en });
      for (const brand of item.brandVariants) {
        if (!brands.has(brand.brandId)) brands.set(brand.brandId, brand.brandName);
      }
    }
    names = { ingredients, brands };
    namesCache.set(reference, names);
  }
  return names;
}

// ---------------------------------------------------------------- response mapping

const FREE_TEXT_MAX = 200; // contract SafetyRuleRef.freeText
const DETAIL_MAX = 100; // contract SafetyReason.detail
const RAW_NAME_MAX = 120; // contract SafetyIngredientRef.rawName

function displayNameOf(names: ReferenceNames, ingredientId: string | null) {
  if (ingredientId === null) return null;
  const name = names.ingredients.get(ingredientId);
  return name === undefined ? null : { id: name.id, en: name.en };
}

function ingredientRef(
  names: ReferenceNames,
  candidate: FoodCandidate,
  ref: { readonly index: number; readonly ingredientId: string | null } | null,
): Schemas["SafetyIngredientRef"] | null {
  if (ref === null) return null;
  const line = candidate.lines[ref.index];
  if (line === undefined || line.ingredientId !== ref.ingredientId) {
    throw new UnshowableResultError("a reason points at no line");
  }
  const rawName = line.rawName.trim();
  if (rawName === "" || [...rawName].length > RAW_NAME_MAX) {
    throw new UnshowableResultError("a line name is out of range");
  }
  return {
    lineId: line.lineId,
    ingredientId: line.ingredientId,
    displayName: displayNameOf(names, line.ingredientId),
    rawName,
    isCustom: line.isCustom === true,
  };
}

function componentPath(names: ReferenceNames, ids: readonly string[]) {
  return ids.map((ingredientId) => ({
    ingredientId,
    displayName: displayNameOf(names, ingredientId),
  }));
}

function brandRef(names: ReferenceNames, brandId: string | null): Schemas["SafetyBrandRef"] | null {
  if (brandId === null) return null;
  const name = names.brands.get(brandId);
  if (name === undefined) throw new UnshowableResultError("a brand has no name");
  return { brandId, name };
}

function detailOf(detail: string | null): string | null {
  if (detail !== null && [...detail].length > DETAIL_MAX) {
    throw new UnshowableResultError("a reason detail is too long");
  }
  return detail;
}

function ruleRef(rules: readonly HardRule[], reason: SafetyReason): Schemas["SafetyRuleRef"] {
  const rule = rules.find((candidate) => candidate.ruleId === reason.rule.ruleId);
  if (rule === undefined || rule.type !== reason.rule.type) {
    throw new UnshowableResultError("a reason names no rule of the member");
  }
  const freeText =
    rule.type === "free_text" || rule.type === "medical_exclusion" ? rule.freeText : null;
  if (freeText !== null && [...freeText].length > FREE_TEXT_MAX) {
    throw new UnshowableResultError("a rule text is too long");
  }
  return {
    ruleId: rule.ruleId,
    type: rule.type,
    allergen: rule.type === "allergy" ? rule.allergen : null,
    freeText,
  };
}

function memberBodies(
  names: ReferenceNames,
  context: CheckContext,
  candidate: FoodCandidate,
  result: CekAmanResult,
): Schemas["MemberSafetyResult"][] {
  if (result.perMember.length !== context.eaters.length) {
    throw new UnshowableResultError("the result does not cover exactly the eaters");
  }
  return result.perMember.map((member, index) => {
    const eater = context.eaters[index];
    if (eater === undefined || eater.memberId !== member.memberId) {
      throw new UnshowableResultError("the result does not follow the eaters");
    }
    const reasons = member.reasons.map((reason): Schemas["SafetyReason"] => ({
      kind: reason.kind,
      code: reason.code,
      rule: ruleRef(eater.hardRules, reason),
      ingredient: ingredientRef(names, candidate, reason.ingredient),
      componentPath: componentPath(names, reason.componentPath),
      brand: brandRef(names, reason.brandId),
      detail: detailOf(reason.detail),
    }));
    if ((member.status === "safe") !== (reasons.length === 0)) {
      throw new UnshowableResultError("a status and its reasons disagree");
    }
    return {
      memberId: member.memberId,
      rulesConsent: eater.rulesConsent,
      status: member.status,
      // SAF-11: no portion variant is served yet (security review T-040 N1,
      // `safety.variantsServed`), so no result holds only on a condition.
      condition: null,
      reasons,
    };
  });
}

function findingBodies(
  names: ReferenceNames,
  candidate: FoodCandidate,
  halal: RecipeHalalResult,
): Schemas["SafetyFinding"][] {
  return halal.findings.map((finding: RecipeHalalFinding) => {
    if (
      finding.line !== null &&
      candidate.lines[finding.line.index]?.lineId !== finding.line.lineId
    ) {
      throw new UnshowableResultError("a halal finding points at no line");
    }
    return {
      kind: finding.kind,
      code: finding.code,
      ingredient: ingredientRef(
        names,
        candidate,
        finding.line === null
          ? null
          : { index: finding.line.index, ingredientId: finding.line.ingredientId },
      ),
      componentPath: componentPath(names, finding.componentPath),
      brand: brandRef(names, finding.brandId),
      detail: detailOf(finding.detail),
    };
  });
}

// ---------------------------------------------------------------- step 1: check

function brandsFor(context: CheckContext, ingredientId: string | null): string[] {
  if (ingredientId === null) return [];
  return [...(context.recordedBrands.get(ingredientId) ?? [])];
}

/**
 * Runs Cek Aman and the recipe halal derivation for one food item. Pure: it
 * writes nothing. Null when the item cannot be checked or its result cannot
 * be shown in full; the caller then leaves the item out.
 */
export function checkFood(context: CheckContext, candidate: FoodCandidate): PendingCheck | null {
  const reference = context.reference.verified;
  const logContext = {
    householdId: context.householdId,
    subject: {
      kind: candidate.subject.kind,
      id: candidate.subject.id,
      version: candidate.subject.version,
    },
    evaluatedAt: context.evaluatedAt.toISOString(),
  };
  const recordedBrands = [...context.recordedBrands].flatMap(([ingredientId, brandIds]) =>
    brandIds.map((brandId) => ({ ingredientId, brandId })),
  );
  try {
    const safety = evaluateWithLog(
      {
        ingredients: candidate.lines.map((line) => ({
          ingredientId: line.ingredientId,
          rawName: line.rawName,
        })),
        recordedBrands,
        members: context.eaters.map((eater) => ({
          memberId: eater.memberId,
          hardRules: eater.hardRules,
        })),
        reference: reference.reference,
      },
      logContext,
    );
    const halal = deriveRecipeHalalWithLog(
      {
        lines: candidate.lines.map((line) => ({
          lineId: line.lineId,
          ingredientId: line.ingredientId,
          brandIds: brandsFor(context, line.ingredientId),
        })),
        reference: reference.reference,
      },
      logContext,
    );
    // QUESTIONS #88: one rule set and one reference snapshot for both.
    if (
      safety.result.referenceVersion !== reference.referenceVersion ||
      halal.result.referenceVersion !== reference.referenceVersion ||
      safety.result.ruleSetVersion !== halal.result.ruleSetVersion
    ) {
      return null;
    }

    // N3: the response is built from a copy; the log records stay as made.
    const result = structuredClone(safety.result);
    const halalResult = structuredClone(halal.result);
    const names = namesOf(context.reference);
    const checkId = randomUUID();
    const body: RecipeSafetyBody = {
      checkId,
      checkedAt: logContext.evaluatedAt,
      ruleSetVersion: result.ruleSetVersion,
      referenceVersion: result.referenceVersion,
      members: memberBodies(names, context, candidate, result),
      halalStatus: {
        status: halalResult.status,
        findings: findingBodies(names, candidate, halalResult),
      },
    };
    const statuses = result.perMember.map((member) => ({
      memberId: member.memberId,
      status: member.status,
    }));
    const pending: PendingCheck = Object.freeze({
      subjectId: candidate.subject.id,
      statuses: Object.freeze(statuses),
      notSafeFor: Object.freeze(
        statuses.filter((entry) => entry.status === "not_safe").map((entry) => entry.memberId),
      ),
    });
    internals.set(pending, {
      checkId,
      safetyLog: safety.logRecord,
      halalLog: halal.logRecord,
      body,
      ruleStamps: new Map(context.eaters.map((eater) => [eater.memberId, eater.rulesStamp])),
      served: false,
    });
    return pending;
  } catch (error) {
    if (error instanceof CekAmanInputError || error instanceof UnshowableResultError) return null;
    throw error;
  }
}

// ---------------------------------------------------------------- step 2: log, then serve

/** The eaters' stamps of checks served together; one request, so they must agree. */
function ruleStampsOf(entries: readonly PendingInternals[]): Map<string, string> {
  const stamps = new Map<string, string>();
  for (const entry of entries) {
    for (const [memberId, stamp] of entry.ruleStamps) {
      const known = stamps.get(memberId);
      if (known !== undefined && known !== stamp) throw new RulesChangedError();
      stamps.set(memberId, stamp);
    }
  }
  return stamps;
}

/**
 * Writes the logs of every check in one transaction and returns the bodies
 * after the commit, in the given order. Throws when any write fails; then
 * nothing is stored and nothing may be served. A check is served once.
 */
export async function serveChecked(
  db: SqlExecutor,
  keys: HealthDataKeys,
  checks: readonly PendingCheck[],
): Promise<ServedCheck[]> {
  if (checks.length === 0) return [];
  const entries = checks.map((check) => {
    const entry = internals.get(check);
    if (entry === undefined || entry.served) {
      throw new Error("a check is served once, and only one made by checkFood");
    }
    return { check, entry };
  });
  try {
    await insertSafetyLogs(
      db,
      keys,
      entries.map(({ entry }) => ({ logId: entry.checkId, record: entry.safetyLog })),
      {
        inTransaction: async (tx) => {
          for (const { entry } of entries) {
            await insertRecipeHalalLog(tx, entry.checkId, entry.halalLog);
          }
        },
        // L1: the eaters' rules and consent must still be the ones checked.
        expectedRuleStamps: ruleStampsOf(entries.map(({ entry }) => entry)),
      },
    );
  } catch (error) {
    if (error instanceof InvalidDataError) throw new SafetyLogWriteError();
    throw error;
  }
  return entries.map(({ check, entry }) => {
    entry.served = true;
    return Object.freeze({ subjectId: check.subjectId, safety: entry.body });
  });
}
