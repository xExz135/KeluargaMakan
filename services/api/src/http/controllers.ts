import type { Schemas } from "@keluargamakan/contracts";
import {
  Body,
  Controller,
  Get,
  Headers,
  HttpCode,
  Inject,
  Patch,
  Post,
  Req,
  Res,
  UseGuards,
} from "@nestjs/common";
import type { FastifyReply, FastifyRequest } from "fastify";

import { ApiError, unauthenticated } from "../api-error.js";
import type { AccountView } from "../auth/accounts.js";
import type { AuthContext, AuthService, SessionTokens } from "../auth/auth-service.js";
import type { HouseholdService, HouseholdView } from "../households/household-service.js";
import { Auth, AuthGuard } from "./auth.guard.js";
import {
  parseHouseholdCreate,
  parseHouseholdUpdate,
  parseIdempotencyKey,
  parseSessionRefresh,
  parseSignInCodeRequest,
  parseSignInCodeVerification,
} from "./requests.js";
import { ACCOUNT_READER, AUTH_SERVICE, HOUSEHOLD_SERVICE } from "./tokens.js";

/**
 * T-017 endpoints from packages/contracts/openapi.yaml: sign-in with a code
 * (ACC-01), sessions (ACC-13), the account and the household (ACC-03).
 * Response bodies are typed by the generated contract schemas.
 */

export interface AccountReader {
  read(accountId: string): Promise<AccountView | null>;
}

const iso = (date: Date) => date.toISOString();

function accountBody(account: AccountView): Schemas["Account"] {
  return {
    id: account.id,
    role: account.role,
    householdId: account.householdId,
    signInMethods: [...account.signInMethods],
    phone: account.phone,
    email: account.email,
    createdAt: iso(account.createdAt),
  };
}

function tokensBody(tokens: SessionTokens): Schemas["SessionTokens"] {
  return {
    tokenType: "Bearer",
    accessToken: tokens.accessToken,
    accessTokenExpiresAt: iso(tokens.accessTokenExpiresAt),
    refreshToken: tokens.refreshToken,
    refreshTokenExpiresAt: iso(tokens.refreshTokenExpiresAt),
  };
}

function householdBody(household: HouseholdView): Schemas["Household"] {
  return {
    id: household.id,
    name: household.name,
    city: household.city,
    timeZone: household.timeZone,
    language: household.language,
    managerAccountId: household.managerAccountId,
    managerProfileId: household.managerProfileId,
    createdAt: iso(household.createdAt),
    updatedAt: iso(household.updatedAt),
  };
}

@Controller("v1/auth")
export class AuthController {
  constructor(@Inject(AUTH_SERVICE) private readonly auth: AuthService) {}

  @Post("code/request")
  @HttpCode(202)
  async requestCode(
    @Body() body: unknown,
    @Req() request: FastifyRequest,
  ): Promise<Schemas["SignInCodeChallenge"]> {
    const challenge = await this.auth.requestCode(parseSignInCodeRequest(body), request.ip);
    return {
      challengeId: challenge.challengeId,
      channel: challenge.channel,
      codeLength: challenge.codeLength,
      expiresAt: iso(challenge.expiresAt),
      resendAvailableAt: iso(challenge.resendAvailableAt),
    };
  }

  @Post("code/verify")
  @HttpCode(200)
  async verifyCode(
    @Body() body: unknown,
    @Req() request: FastifyRequest,
  ): Promise<Schemas["Session"]> {
    const signedIn = await this.auth.verifyCode(parseSignInCodeVerification(body), request.ip);
    return {
      tokens: tokensBody(signedIn.tokens),
      account: accountBody(signedIn.account),
      isNewAccount: signedIn.isNewAccount,
    };
  }

  /** ACC-02 is T-018. Until then the INT-13 fallback applies: phone or email sign-in. */
  @Post("google")
  google(): never {
    throw new ApiError("sign_in_method_unavailable", 503, "Google sign-in is not available");
  }

  @Post("refresh")
  @HttpCode(200)
  async refresh(
    @Body() body: unknown,
    @Req() request: FastifyRequest,
  ): Promise<Schemas["SessionTokens"]> {
    const { refreshToken } = parseSessionRefresh(body);
    return tokensBody(await this.auth.refresh(refreshToken, request.ip));
  }

  @Post("sign-out")
  @HttpCode(204)
  @UseGuards(AuthGuard)
  async signOut(@Auth() auth: AuthContext): Promise<void> {
    await this.auth.signOut(auth.sessionId);
  }
}

@Controller("v1/account")
@UseGuards(AuthGuard)
export class AccountController {
  constructor(@Inject(ACCOUNT_READER) private readonly accounts: AccountReader) {}

  @Get()
  async get(@Auth() auth: AuthContext): Promise<Schemas["Account"]> {
    const account = await this.accounts.read(auth.accountId);
    if (account === null) throw unauthenticated();
    return accountBody(account);
  }
}

@Controller("v1/household")
@UseGuards(AuthGuard)
export class HouseholdController {
  constructor(@Inject(HOUSEHOLD_SERVICE) private readonly households: HouseholdService) {}

  @Post()
  async create(
    @Auth() auth: AuthContext,
    @Body() body: unknown,
    @Headers("idempotency-key") idempotencyKey: unknown,
    @Res({ passthrough: true }) reply: FastifyReply,
  ): Promise<Schemas["Household"]> {
    const key = parseIdempotencyKey(idempotencyKey);
    const { household } = await this.households.create(auth, parseHouseholdCreate(body), key);
    // A replay with the same key answers like the first request (contract IdempotencyKey).
    void reply.status(201);
    return householdBody(household);
  }

  @Get()
  async get(@Auth() auth: AuthContext): Promise<Schemas["Household"]> {
    return householdBody(await this.households.get(auth));
  }

  @Patch()
  async update(@Auth() auth: AuthContext, @Body() body: unknown): Promise<Schemas["Household"]> {
    return householdBody(await this.households.update(auth, parseHouseholdUpdate(body)));
  }
}
