import {
  createParamDecorator,
  Inject,
  Injectable,
  type CanActivate,
  type ExecutionContext,
} from "@nestjs/common";
import type { FastifyRequest } from "fastify";

import { unauthenticated } from "../api-error.js";
import type { AuthContext, AuthService } from "../auth/auth-service.js";
import { AUTH_SERVICE } from "./tokens.js";

type AuthedRequest = FastifyRequest & { auth?: AuthContext };

/** Requires `Authorization: Bearer <access token>` for an active session. */
@Injectable()
export class AuthGuard implements CanActivate {
  constructor(@Inject(AUTH_SERVICE) private readonly auth: AuthService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<AuthedRequest>();
    const header = request.headers.authorization;
    const match = typeof header === "string" ? /^Bearer ([^\s]+)$/.exec(header) : null;
    if (match?.[1] === undefined) throw unauthenticated();
    request.auth = await this.auth.authenticate(match[1]);
    return true;
  }
}

/** The caller's `AuthContext`, set by `AuthGuard`. */
export const Auth = createParamDecorator((_data: unknown, context: ExecutionContext) => {
  const auth = context.switchToHttp().getRequest<AuthedRequest>().auth;
  if (auth === undefined) throw unauthenticated();
  return auth;
});
