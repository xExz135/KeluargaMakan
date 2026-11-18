import { migration0001 } from "./0001-household-profiles-consent.js";
import { migration0002 } from "./0002-kitchen-meals-feedback.js";
import { migration0003 } from "./0003-reference-safety-log.js";
import { migration0004 } from "./0004-health-data.js";
import { migration0005 } from "./0005-health-data-hardening.js";
import { migration0006 } from "./0006-ciphertext-padding.js";
import { migration0007 } from "./0007-sign-in-sessions.js";
import { migration0008 } from "./0008-kitchen-custom-key.js";
import { migration0009 } from "./0009-kitchen-sync-usage.js";
import { migration0010 } from "./0010-kitchen-removals.js";
import { migration0011 } from "./0011-kitchen-floor-position.js";
import { migration0012 } from "./0012-library-recipes.js";
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
  migration0008,
  migration0009,
  migration0010,
  migration0011,
  migration0012,
]);
