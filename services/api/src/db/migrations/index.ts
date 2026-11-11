import { migration0001 } from "./0001-household-profiles-consent.js";
import { migration0002 } from "./0002-kitchen-meals-feedback.js";
import { migration0003 } from "./0003-reference-safety-log.js";
import { migration0004 } from "./0004-health-data.js";
import { migration0005 } from "./0005-health-data-hardening.js";
import { migration0006 } from "./0006-ciphertext-padding.js";
import { migration0007 } from "./0007-sign-in-sessions.js";
import type { Migration } from "./types.js";

export type { Migration } from "./types.js";

/** Every migration, in order. Append only; never edit one that has been applied anywhere. */
export const MIGRATIONS: readonly Migration[] = Object.freeze([
  migration0001,
  migration0002,
  migration0003,
  migration0004,
  migration0005,
  migration0006,
  migration0007,
]);
