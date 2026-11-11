// TEST FIXTURE: not real safety or nutrition data. Fictional households for database tests.
import { randomBytes, randomUUID } from "node:crypto";

import { LocalKeyProvider } from "../crypto/local-key-provider.js";
import type { SqlExecutor } from "../executor.js";

let counter = 0;

/** A fictional, never-assigned phone number per call (no real personal data). */
function fakePhone(): string {
  counter += 1;
  return `+6200000${String(counter).padStart(6, "0")}${String(process.pid % 10)}`;
}

/** Random local keys for one test run. No key material is committed. */
export function randomLocalKeys(): LocalKeyProvider {
  return new LocalKeyProvider(
    { general: randomBytes(32), health: randomBytes(32) },
    { appEnv: "test" },
  );
}

export interface SeededHousehold {
  readonly householdId: string;
  readonly accountId: string;
  readonly managerProfileId: string;
}

/** A household with its manager account and the manager's own adult profile. */
export async function seedHousehold(db: SqlExecutor): Promise<SeededHousehold> {
  const householdId = randomUUID();
  const accountId = randomUUID();
  const managerProfileId = randomUUID();
  await db.transaction(async (tx) => {
    await tx.query(
      `INSERT INTO account (id, phone, sign_in_methods) VALUES ($1, $2, ARRAY['phone'])`,
      [accountId, fakePhone()],
    );
    await tx.query(
      `INSERT INTO household (id, name, time_zone, language, manager_account_id, manager_profile_id)
       VALUES ($1, 'Keluarga Uji', 'Asia/Jakarta', 'id', $2, $3)`,
      [householdId, accountId, managerProfileId],
    );
    await tx.query(`UPDATE account SET household_id = $1 WHERE id = $2`, [householdId, accountId]);
    await tx.query(
      `INSERT INTO profile (id, household_id, name, age_group) VALUES ($1, $2, 'Profil Pengelola', 'adult')`,
      [managerProfileId, householdId],
    );
  });
  return { householdId, accountId, managerProfileId };
}

/** Adds a profile. A child profile gets the guardian confirmation in the same transaction (SET-10). */
export async function addProfile(
  db: SqlExecutor,
  home: SeededHousehold,
  ageGroup: "infant" | "child" | "teen" | "adult" | "elderly",
  options: { readonly withGuardianConfirmation?: boolean } = {},
): Promise<string> {
  const profileId = randomUUID();
  const child = ageGroup === "infant" || ageGroup === "child" || ageGroup === "teen";
  await db.transaction(async (tx) => {
    await tx.query(
      `INSERT INTO profile (id, household_id, name, age_group) VALUES ($1, $2, 'Profil Uji', $3)`,
      [profileId, home.householdId, ageGroup],
    );
    if (options.withGuardianConfirmation ?? child) {
      await tx.query(
        `INSERT INTO consent_record
           (household_id, profile_id, purpose, decision, text_version, language, recorded_by_account_id)
         VALUES ($1, $2, 'guardian_confirmation', 'given', 'guardian-draft-1', 'id', $3)`,
        [home.householdId, profileId, home.accountId],
      );
    }
  });
  return profileId;
}
