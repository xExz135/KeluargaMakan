import type { Schemas } from "@keluargamakan/contracts";
import {
  Body,
  Controller,
  Delete,
  Get,
  Headers,
  HttpCode,
  Inject,
  Param,
  Patch,
  Post,
  Put,
  Res,
} from "@nestjs/common";
import type { FastifyReply } from "fastify";

import { Requires, Scope, type HouseholdScope } from "../authz/access.js";
import { profileIdOf } from "../consent/consent.controller.js";
import type { RulesConsentState } from "../db/consent.js";
import { NotFoundError } from "../db/errors.js";
import { isUuid } from "../db/ids.js";
import { parseIdempotencyKey } from "../http/requests.js";
import { PROFILE_SERVICE } from "../http/tokens.js";
import type {
  HardRuleView,
  ProfileRulesView,
  ProfileService,
  ProfileView,
} from "./profile-service.js";
import {
  parseHardRuleCreate,
  parseLikesDislikes,
  parseProfileCreate,
  parseProfileUpdate,
  parseSoftPreferences,
} from "./requests.js";

/**
 * T-020 endpoints from packages/contracts/openapi.yaml: Keluarga Saya
 * profiles, soft preferences, likes and dislikes, and hard rules (PRF-01 to
 * PRF-07, PRF-18). The mapping confirmation endpoints (PRF-08) are T-022.
 * Responses are typed by the generated contract schemas.
 */

const iso = (date: Date) => date.toISOString();

function consentBody(state: RulesConsentState): Schemas["RulesConsentState"] {
  return {
    status: state.status,
    consentRecordId: state.consentRecordId,
    decidedAt: state.decidedAt === null ? null : iso(state.decidedAt),
    textVersion: state.textVersion,
    deletionDueBy: state.deletionDueBy === null ? null : iso(state.deletionDueBy),
  };
}

function ruleBody(rule: HardRuleView): Schemas["HardRule"] {
  return {
    id: rule.id,
    type: rule.type,
    allergen: rule.allergen,
    freeText: rule.freeText,
    mapping:
      rule.mapping === null
        ? null
        : {
            status: rule.mapping.status,
            ingredients: rule.mapping.ingredients.map((item) => ({
              ingredientId: item.ingredientId,
              displayName: { id: item.displayName.id, en: item.displayName.en },
            })),
            confirmedBy: rule.mapping.confirmedBy,
            updatedAt: rule.mapping.updatedAt,
          },
    createdAt: iso(rule.createdAt),
  };
}

function rulesBody(rules: ProfileRulesView): Schemas["ProfileRules"] {
  return { consent: consentBody(rules.consent), items: rules.items.map(ruleBody) };
}

function preferencesBody(prefs: ProfileView["preferences"]): Schemas["SoftPreferences"] {
  return {
    spiceLevel: prefs.spiceLevel,
    lessOf: [...prefs.lessOf],
    textures: [...prefs.textures],
    updatedAt: prefs.updatedAt === null ? null : iso(prefs.updatedAt),
  };
}

function likesBody(likes: ProfileView["likesDislikes"]): Schemas["LikesDislikes"] {
  const ref = (item: ProfileView["likesDislikes"]["likes"][number]) => ({
    kind: item.kind,
    refId: item.refId,
    displayName: { id: item.displayName.id, en: item.displayName.en },
  });
  return {
    likes: likes.likes.map(ref),
    dislikes: likes.dislikes.map(ref),
    updatedAt: likes.updatedAt === null ? null : iso(likes.updatedAt),
  };
}

export function profileBody(view: ProfileView): Schemas["Profile"] {
  return {
    id: view.id,
    name: view.name,
    avatar: {
      style: view.avatar.style,
      colorToken: view.avatar.colorToken,
      illustrationId: view.avatar.illustrationId,
    },
    ageGroup: view.ageGroup,
    isChild: view.isChild,
    isManager: view.isManager,
    guardianConfirmation:
      view.guardianConfirmation === null
        ? null
        : {
            consentRecordId: view.guardianConfirmation.consentRecordId,
            confirmedAt: iso(view.guardianConfirmation.confirmedAt),
            textVersion: view.guardianConfirmation.textVersion,
          },
    portions: { ...view.portions },
    rules: rulesBody(view.rules),
    preferences: preferencesBody(view.preferences),
    likesDislikes: likesBody(view.likesDislikes),
    createdAt: iso(view.createdAt),
    updatedAt: iso(view.updatedAt),
  };
}

function ruleIdOf(value: unknown): string {
  if (!isUuid(value)) throw new NotFoundError("hard rule");
  return value;
}

@Controller("v1/household/profiles")
export class ProfilesController {
  constructor(@Inject(PROFILE_SERVICE) private readonly profiles: ProfileService) {}

  @Get()
  @Requires("profile:read")
  async list(@Scope() scope: HouseholdScope): Promise<Schemas["ProfileList"]> {
    const views = await this.profiles.list(scope);
    return { items: views.map(profileBody), maxProfiles: this.profiles.maxProfiles };
  }

  @Post()
  @Requires("profile:write")
  async create(
    @Scope() scope: HouseholdScope,
    @Body() body: unknown,
    @Headers("idempotency-key") idempotencyKey: unknown,
    @Res({ passthrough: true }) reply: FastifyReply,
  ): Promise<Schemas["Profile"]> {
    const input = parseProfileCreate(body);
    const key = parseIdempotencyKey(idempotencyKey);
    const view = await this.profiles.create(scope, input, key);
    void reply.status(201);
    return profileBody(view);
  }

  @Get(":profileId")
  @Requires("profile:read")
  async get(
    @Scope() scope: HouseholdScope,
    @Param("profileId") profileId: string,
  ): Promise<Schemas["Profile"]> {
    return profileBody(await this.profiles.get(scope, profileIdOf(profileId)));
  }

  @Patch(":profileId")
  @Requires("profile:write")
  async update(
    @Scope() scope: HouseholdScope,
    @Param("profileId") profileId: string,
    @Body() body: unknown,
  ): Promise<Schemas["Profile"]> {
    const id = profileIdOf(profileId);
    return profileBody(await this.profiles.update(scope, id, parseProfileUpdate(body)));
  }

  @Delete(":profileId")
  @HttpCode(204)
  @Requires("profile:write")
  async remove(
    @Scope() scope: HouseholdScope,
    @Param("profileId") profileId: string,
  ): Promise<void> {
    await this.profiles.remove(scope, profileIdOf(profileId));
  }

  @Put(":profileId/preferences")
  @Requires("profile:write")
  async preferences(
    @Scope() scope: HouseholdScope,
    @Param("profileId") profileId: string,
    @Body() body: unknown,
  ): Promise<Schemas["SoftPreferences"]> {
    const id = profileIdOf(profileId);
    return preferencesBody(
      await this.profiles.replacePreferences(scope, id, parseSoftPreferences(body)),
    );
  }

  @Put(":profileId/likes-dislikes")
  @Requires("profile:write")
  async likesDislikes(
    @Scope() scope: HouseholdScope,
    @Param("profileId") profileId: string,
    @Body() body: unknown,
  ): Promise<Schemas["LikesDislikes"]> {
    const id = profileIdOf(profileId);
    return likesBody(await this.profiles.replaceLikesDislikes(scope, id, parseLikesDislikes(body)));
  }

  @Get(":profileId/hard-rules")
  @Requires("hard_rule:read")
  async listRules(
    @Scope() scope: HouseholdScope,
    @Param("profileId") profileId: string,
  ): Promise<Schemas["ProfileRules"]> {
    return rulesBody(await this.profiles.listRules(scope, profileIdOf(profileId)));
  }

  @Post(":profileId/hard-rules")
  @Requires("hard_rule:write")
  async createRule(
    @Scope() scope: HouseholdScope,
    @Param("profileId") profileId: string,
    @Body() body: unknown,
    @Headers("idempotency-key") idempotencyKey: unknown,
    @Res({ passthrough: true }) reply: FastifyReply,
  ): Promise<Schemas["HardRule"]> {
    const id = profileIdOf(profileId);
    const rule = parseHardRuleCreate(body);
    const key = parseIdempotencyKey(idempotencyKey);
    const created = await this.profiles.createRule(scope, id, rule, key);
    void reply.status(201);
    return ruleBody(created);
  }

  @Delete(":profileId/hard-rules/:ruleId")
  @HttpCode(204)
  @Requires("hard_rule:write")
  async removeRule(
    @Scope() scope: HouseholdScope,
    @Param("profileId") profileId: string,
    @Param("ruleId") ruleId: string,
  ): Promise<void> {
    await this.profiles.removeRule(scope, profileIdOf(profileId), ruleIdOf(ruleId));
  }
}
