/**
 * KeluargaMakan API. `main.ts` starts the NestJS (Fastify) application;
 * `createApp` builds it for tests and other entry points.
 */
export { defaultTargets, resolveTargets } from "../config/targets.js";
export type { Target, Targets } from "../config/targets.js";
export { defaultApiConfig, resolveApiConfig, apiConfigFromEnv } from "../config/api.js";
export type { ApiConfig, ApiConfigOverrides, RateLimitRule } from "../config/api.js";
export { createApp, type AppDeps } from "./http/app.js";
export { AuthService, purgeExpiredSignInRecords } from "./auth/auth-service.js";
export {
  createCodeSender,
  DevCodeSender,
  UnavailableCodeSender,
  type SignInCodeSender,
} from "./auth/code-sender.js";
export { loadAuthSecrets, type AuthSecrets } from "./auth/secrets.js";
export { HouseholdService } from "./households/household-service.js";
