import type { HardRule } from "@keluargamakan/cek-aman";
import type { Schemas } from "@keluargamakan/contracts";

import type { RulesConsentStatus } from "../db/consent.js";
import { NotFoundError, withDbErrors } from "../db/errors.js";
import type { SqlExecutor } from "../db/executor.js";
import { loadRulesForEvaluation } from "../db/hard-rules.js";
import type { HealthDataKeys } from "../db/health-data-keys.js";
import { isUuid } from "../db/ids.js";

/**
 * Who is eating (PRF-09) and their hard rules (PRF-11), for one safety check.
 *
 * - `only_me`: the manager's own profile; `whole_family`: every profile of
 *   the household, in the profile list order (manager first, then by
 *   creation); `selected`: the given profiles, in the given order.
 * - Only these members' rules are read, and nobody else's (PRF-11).
 * - A selected member outside the household answers 404 `not_found`, the
 *   same as an unknown ID, after the same queries (NFR-09).
 * - When any member's rules cannot be read the whole check stops with
 *   `RulesUnavailableError` (503 `rules_unavailable`), never a shorter list
 *   (QUESTIONS #39).
 * - A member without a given health-data consent has no rules checked:
 *   `hardRules` is empty and `rulesConsent` says why, so clients show the
 *   neutral "rules not saved" chip in place of Safe (QUESTIONS #36).
 */

export type EaterSelection = Schemas["EaterSelection"];

export interface CheckEater {
  readonly memberId: string;
  readonly rulesConsent: RulesConsentStatus;
  readonly hardRules: readonly HardRule[];
}

async function eaterIds(
  db: SqlExecutor,
  householdId: string,
  selection: EaterSelection,
): Promise<string[]> {
  switch (selection.mode) {
    case "only_me": {
      const { rows } = await withDbErrors(() =>
        db.query<{ id: string }>(`SELECT manager_profile_id AS id FROM household WHERE id = $1`, [
          householdId,
        ]),
      );
      const id = rows[0]?.id;
      if (id === undefined) throw new NotFoundError("household");
      return [id];
    }
    case "whole_family": {
      const { rows } = await withDbErrors(() =>
        db.query<{ id: string }>(
          `SELECT p.id
             FROM profile p
             JOIN household h ON h.id = p.household_id
            WHERE p.household_id = $1
            ORDER BY (p.id = h.manager_profile_id) DESC, p.created_at, p.id`,
          [householdId],
        ),
      );
      if (rows.length === 0) throw new NotFoundError("household");
      return rows.map((row) => row.id);
    }
    case "selected": {
      const ids = [...selection.memberIds];
      const known = ids.filter(isUuid);
      const { rows } = await withDbErrors(() =>
        db.query<{ id: string }>(
          `SELECT id FROM profile WHERE household_id = $1 AND id = ANY($2::uuid[])`,
          [householdId, known],
        ),
      );
      if (ids.length === 0 || rows.length !== ids.length || known.length !== ids.length) {
        throw new NotFoundError("profile");
      }
      return ids;
    }
  }
}

/** The selected eaters with their rules, in selection order. */
export async function loadCheckEaters(
  db: SqlExecutor,
  keys: HealthDataKeys,
  householdId: string,
  selection: EaterSelection,
): Promise<CheckEater[]> {
  const ids = await eaterIds(db, householdId, selection);
  const members = await loadRulesForEvaluation(db, keys, householdId, ids);
  return members.map((member) => ({
    memberId: member.profileId,
    rulesConsent: member.consent,
    hardRules: member.hardRules ?? [],
  }));
}
