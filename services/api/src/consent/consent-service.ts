import type { ApiConfig } from "../../config/api.js";
import type { Targets } from "../../config/targets.js";
import { ApiError } from "../api-error.js";
import type { Clock } from "../auth/auth-service.js";
import { systemClock } from "../auth/auth-service.js";
import type { HouseholdScope } from "../authz/access.js";
import {
  consentStateOf,
  guardianConfirmation,
  latestHealthConsents,
  listConsentRecords,
  recordGuardianConfirmation,
  recordHealthConsent,
  withdrawHealthConsent,
  type ConsentDecision,
  type ConsentRecordRow,
  type Language,
} from "../db/consent.js";
import {
  ConsentRequiredError,
  GuardianConfirmationRequiredError,
  NotFoundError,
  withDbErrors,
} from "../db/errors.js";
import type { SqlExecutor } from "../db/executor.js";
import { isUuid } from "../db/ids.js";
import { lockMembers } from "../db/locks.js";
import { findReplay, remember, requestHash } from "../idempotency/idempotency.js";
import {
  CONSENT_TEXTS,
  currentConsentVersion,
  type ConsentLanguage,
  type ConsentPurpose,
  type ConsentTextContent,
} from "./consent-texts.js";

/**
 * ACC-08, SET-03, SET-10 (T-021): per-member consent for health data, the
 * guardian confirmation for children, and the gate every health-data write
 * passes first.
 *
 * - A decision is recorded per member with its date and the consent-text
 *   version the manager was shown; an outdated version is refused (409
 *   `consent_text_outdated`), so a record always names a text that existed.
 * - Withdrawal is possible at any time. The database then destroys the
 *   member's data key at once, which deletes the hard rules and redacts the
 *   safety-log details in the live database (T-016). `deletionDueBy` is set
 *   from `targets.dataManagement.healthConsentWithdrawalDeletionDays` (SET-04,
 *   target); the scheduled clean-up of caches and the backstop job are T-072.
 * - A child profile needs the manager's recorded parent or guardian
 *   confirmation before a health-data consent or any rule (SET-10).
 * - Every lookup is inside the caller's household; another household's
 *   profile answers 404 like a missing one (NFR-09).
 */

export const consentTextOutdated = () =>
  new ApiError("consent_text_outdated", 409, "The consent text version is not the current version");

export interface HealthDataDecisionInput {
  readonly decision: ConsentDecision;
  readonly textVersion: string;
  readonly language: Language;
}

export interface GuardianConfirmationInput {
  readonly confirmed: boolean;
  readonly textVersion: string;
  readonly language: Language;
}

export interface ConsentServiceDeps {
  readonly db: SqlExecutor;
  readonly config: ApiConfig;
  readonly targets: Targets;
  readonly hashKey: Buffer;
  readonly clock?: Clock;
}

const RECORD_HEALTH_DATA = "record_health_data_consent";

/**
 * SET-10: checks a guardian confirmation input and records it for a child
 * profile inside the caller's transaction (profile create or age change).
 */
export async function recordGuardian(
  tx: SqlExecutor,
  scope: HouseholdScope,
  profileId: string,
  input: GuardianConfirmationInput | null,
  now: Date,
): Promise<ConsentRecordRow> {
  if (input?.confirmed !== true) throw new GuardianConfirmationRequiredError();
  if (input.textVersion !== currentConsentVersion("guardian_confirmation")) {
    throw consentTextOutdated();
  }
  return recordGuardianConfirmation(tx, {
    householdId: scope.householdId,
    profileId,
    textVersion: input.textVersion,
    language: input.language,
    recordedByAccountId: scope.accountId,
    decidedAt: now,
  });
}

/**
 * ACC-08, SET-10 gate for every health-data write (hard rules). Throws
 * `ConsentRequiredError` (409 `consent_required`) unless the member's latest
 * health-data consent is given and not withdrawn, and
 * `GuardianConfirmationRequiredError` (409) for a child without a recorded
 * guardian confirmation. Run it before any key service work so the client
 * gets a clear 4xx; the data layer and the database check again under the
 * member lock.
 */
export async function assertHealthDataWritable(
  db: SqlExecutor,
  householdId: string,
  profileId: string,
): Promise<void> {
  const child = await isChildProfile(db, householdId, profileId);
  if (child && (await guardianConfirmation(db, householdId, profileId)) === null) {
    throw new GuardianConfirmationRequiredError();
  }
  const latest = (await withDbErrors(() => latestHealthConsents(db, householdId, [profileId]))).get(
    profileId,
  );
  if (consentStateOf(latest).status !== "given") throw new ConsentRequiredError();
}

async function isChildProfile(
  db: SqlExecutor,
  householdId: string,
  profileId: string,
): Promise<boolean> {
  if (!isUuid(householdId) || !isUuid(profileId)) throw new NotFoundError("profile");
  const { rows } = await withDbErrors(() =>
    db.query<{ is_child: boolean }>(
      `SELECT is_child FROM profile WHERE id = $1 AND household_id = $2`,
      [profileId, householdId],
    ),
  );
  const row = rows[0];
  if (row === undefined) throw new NotFoundError("profile");
  return row.is_child;
}

export class ConsentService {
  readonly #db: SqlExecutor;
  readonly #config: ApiConfig;
  readonly #targets: Targets;
  readonly #hashKey: Buffer;
  readonly #clock: Clock;

  constructor(deps: ConsentServiceDeps) {
    this.#db = deps.db;
    this.#config = deps.config;
    this.#targets = deps.targets;
    this.#hashKey = deps.hashKey;
    this.#clock = deps.clock ?? systemClock;
  }

  /** The current consent text for a purpose, in one language. */
  text(
    purpose: ConsentPurpose,
    language: ConsentLanguage,
  ): ConsentTextContent & {
    readonly language: ConsentLanguage;
  } {
    const content = CONSENT_TEXTS[purpose];
    return { ...content, language };
  }

  /** SET-03: every consent record of a member, newest first. */
  async list(scope: HouseholdScope, profileId: string): Promise<ConsentRecordRow[]> {
    await isChildProfile(this.#db, scope.householdId, profileId);
    return withDbErrors(() => listConsentRecords(this.#db, scope.householdId, profileId));
  }

  /**
   * ACC-08, SET-03: records an explicit decision, given or declined. A
   * decline (or a decision recorded while rules exist that declines) deletes
   * the member's data key and so their rules (database trigger).
   */
  async recordHealthData(
    scope: HouseholdScope,
    profileId: string,
    input: HealthDataDecisionInput,
    idempotencyKey: string | null,
  ): Promise<ConsentRecordRow> {
    if (input.textVersion !== currentConsentVersion("health_data")) throw consentTextOutdated();
    const now = this.#clock.now();
    const request =
      idempotencyKey === null
        ? null
        : {
            accountId: scope.accountId,
            key: idempotencyKey,
            operation: RECORD_HEALTH_DATA,
            requestHash: requestHash(this.#hashKey, RECORD_HEALTH_DATA, [
              profileId,
              input.decision,
              input.textVersion,
              input.language,
            ]),
            keptSince: new Date(
              now.getTime() - this.#config.retention.idempotencyKeyHours * 3600_000,
            ),
          };
    return withDbErrors(() =>
      this.#db.transaction(async (tx) => {
        // Lock first: the decision waits for an in-flight rule write (T-016 H4).
        await lockMembers(tx, scope.householdId, [profileId]);
        if (request !== null) {
          const previous = await findReplay(tx, request);
          if (previous !== null) {
            const record = (await listConsentRecords(tx, scope.householdId, profileId)).find(
              (row) => row.id === previous,
            );
            if (record === undefined) throw new NotFoundError("consent record");
            return record;
          }
        }
        if (
          (await isChildProfile(tx, scope.householdId, profileId)) &&
          (await guardianConfirmation(tx, scope.householdId, profileId)) === null
        ) {
          throw new GuardianConfirmationRequiredError();
        }
        const record = await recordHealthConsent(tx, {
          householdId: scope.householdId,
          profileId,
          decision: input.decision,
          textVersion: input.textVersion,
          language: input.language,
          recordedByAccountId: scope.accountId,
          decidedAt: now,
        });
        if (request !== null) await remember(tx, request, record.id, now);
        return record;
      }),
    );
  }

  /** SET-03, SET-04: withdraws the member's current health-data consent. */
  async withdraw(scope: HouseholdScope, profileId: string): Promise<ConsentRecordRow> {
    if (!isUuid(profileId)) throw new NotFoundError("profile");
    return withdrawHealthConsent(this.#db, {
      householdId: scope.householdId,
      profileId,
      withdrawnAt: this.#clock.now(),
      deletionWindowDays: this.#targets.dataManagement.healthConsentWithdrawalDeletionDays.value,
    });
  }
}
