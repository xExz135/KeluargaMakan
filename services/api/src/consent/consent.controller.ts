import type { Schemas } from "@keluargamakan/contracts";
import {
  Body,
  Controller,
  Get,
  Headers,
  HttpCode,
  Inject,
  Param,
  Post,
  Query,
  Res,
} from "@nestjs/common";
import type { FastifyReply } from "fastify";

import { ApiError } from "../api-error.js";
import { Requires, Scope, type HouseholdScope } from "../authz/access.js";
import type { ConsentRecordRow } from "../db/consent.js";
import { NotFoundError } from "../db/errors.js";
import { isUuid } from "../db/ids.js";
import { parseIdempotencyKey } from "../http/requests.js";
import { CONSENT_SERVICE } from "../http/tokens.js";
import { BodyReader } from "../http/validation.js";
import type {
  ConsentService,
  GuardianConfirmationInput,
  HealthDataDecisionInput,
} from "./consent-service.js";
import type { ConsentLanguage, ConsentPurpose } from "./consent-texts.js";

/**
 * T-021 endpoints from packages/contracts/openapi.yaml: consent texts,
 * consent records, the health-data decision and its withdrawal (ACC-08,
 * SET-03, SET-04, SET-10). Profile IDs come from the path and are looked up
 * only inside the caller's household (NFR-09).
 */

const LANGUAGES: readonly ConsentLanguage[] = ["id", "en"];
const PURPOSES: readonly ConsentPurpose[] = ["health_data", "guardian_confirmation"];
export const TEXT_VERSION_PATTERN = /^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$/;

/** A path ID that cannot exist in this household answers 404, like one from another household. */
export function profileIdOf(value: unknown): string {
  if (!isUuid(value)) throw new NotFoundError("profile");
  return value;
}

export function consentRecordBody(row: ConsentRecordRow): Schemas["ConsentRecord"] {
  if (row.profileId === null || row.recordedByAccountId === null) {
    // Records listed under a profile always keep both links while the
    // household exists (ACC-03: the only account goes with the household).
    throw new ApiError("internal_error", 500, "Consent record lost its links");
  }
  return {
    id: row.id,
    profileId: row.profileId,
    purpose: row.purpose,
    decision: row.decision,
    textVersion: row.textVersion,
    language: row.language,
    decidedAt: row.decidedAt.toISOString(),
    recordedByAccountId: row.recordedByAccountId,
    withdrawnAt: row.withdrawnAt === null ? null : row.withdrawnAt.toISOString(),
    deletionDueBy: row.deletionDueBy === null ? null : row.deletionDueBy.toISOString(),
  };
}

export function parseHealthDataDecision(body: unknown): HealthDataDecisionInput {
  const reader = new BodyReader();
  const record = reader.object(body, "", ["decision", "textVersion", "language"]);
  if (record === null) return reader.done() as never;
  const decision = reader.enumValue(record, "decision", "", ["given", "declined"] as const, true);
  const textVersion = reader.string(record, "textVersion", "", {
    required: true,
    pattern: TEXT_VERSION_PATTERN,
  });
  const language = reader.enumValue(record, "language", "", LANGUAGES, true);
  reader.done();
  return { decision: decision!, textVersion: textVersion!, language: language! };
}

/** Contract `GuardianConfirmationInput`, at `pointer` inside a profile body. */
export function parseGuardianConfirmation(
  reader: BodyReader,
  value: unknown,
  pointer: string,
): GuardianConfirmationInput | null {
  const record = reader.object(value, pointer, ["confirmed", "textVersion", "language"]);
  if (record === null) return null;
  let confirmed: boolean | undefined;
  if (!Object.hasOwn(record, "confirmed")) reader.fail(`${pointer}/confirmed`, "required");
  else if (typeof record["confirmed"] !== "boolean") {
    reader.fail(`${pointer}/confirmed`, "invalid_type");
  } else confirmed = record["confirmed"];
  const textVersion = reader.string(record, "textVersion", pointer, {
    required: true,
    pattern: TEXT_VERSION_PATTERN,
  });
  const language = reader.enumValue(record, "language", pointer, LANGUAGES, true);
  if (confirmed === undefined || typeof textVersion !== "string" || language === undefined) {
    return null;
  }
  return { confirmed, textVersion, language };
}

@Controller("v1/consent-texts")
export class ConsentTextController {
  constructor(@Inject(CONSENT_SERVICE) private readonly consent: ConsentService) {}

  @Get(":purpose")
  @Requires("reference:read")
  get(
    @Param("purpose") purpose: string,
    @Query("language") language: unknown,
  ): Schemas["ConsentText"] {
    if (!(PURPOSES as readonly string[]).includes(purpose)) throw new NotFoundError("consent text");
    const reader = new BodyReader();
    if (typeof language !== "string" || !(LANGUAGES as readonly string[]).includes(language)) {
      reader.fail("/query/language", language === undefined ? "required" : "invalid_value");
    }
    reader.done();
    const text = this.consent.text(purpose as ConsentPurpose, language as ConsentLanguage);
    const localized = text.languages[text.language];
    return {
      purpose: text.purpose,
      version: text.version,
      language: text.language,
      title: localized.title,
      sections: localized.sections.map((section) => ({ ...section })),
      effectiveDate: text.effectiveDate,
      isDraft: text.isDraft,
    };
  }
}

@Controller("v1/household/profiles/:profileId/consents")
export class ConsentController {
  constructor(@Inject(CONSENT_SERVICE) private readonly consent: ConsentService) {}

  @Get()
  @Requires("consent:read")
  async list(
    @Scope() scope: HouseholdScope,
    @Param("profileId") profileId: string,
  ): Promise<Schemas["ConsentRecordList"]> {
    const rows = await this.consent.list(scope, profileIdOf(profileId));
    return { items: rows.map(consentRecordBody) };
  }

  @Post("health-data")
  @Requires("consent:write")
  async record(
    @Scope() scope: HouseholdScope,
    @Param("profileId") profileId: string,
    @Body() body: unknown,
    @Headers("idempotency-key") idempotencyKey: unknown,
    @Res({ passthrough: true }) reply: FastifyReply,
  ): Promise<Schemas["ConsentRecord"]> {
    const id = profileIdOf(profileId);
    const input = parseHealthDataDecision(body);
    const key = parseIdempotencyKey(idempotencyKey);
    const record = await this.consent.recordHealthData(scope, id, input, key);
    void reply.status(201);
    return consentRecordBody(record);
  }

  @Post("health-data/withdraw")
  @HttpCode(200)
  @Requires("consent:write")
  async withdraw(
    @Scope() scope: HouseholdScope,
    @Param("profileId") profileId: string,
  ): Promise<Schemas["ConsentRecord"]> {
    return consentRecordBody(await this.consent.withdraw(scope, profileIdOf(profileId)));
  }
}
