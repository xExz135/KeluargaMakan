import { withDbErrors } from "../db/errors.js";
import type { SqlExecutor } from "../db/executor.js";
import { isUuid } from "../db/ids.js";

export type SignInMethod = "phone" | "email" | "google";

/** SRS 18.1 Account, as returned to its owner only (contract `Account`). */
export interface AccountView {
  readonly id: string;
  readonly role: "manager";
  readonly householdId: string | null;
  readonly signInMethods: readonly SignInMethod[];
  readonly phone: string | null;
  readonly email: string | null;
  readonly createdAt: Date;
}

export async function readAccount(db: SqlExecutor, accountId: string): Promise<AccountView | null> {
  if (!isUuid(accountId)) return null;
  const { rows } = await withDbErrors(() =>
    db.query<{
      id: string;
      household_id: string | null;
      sign_in_methods: SignInMethod[];
      phone: string | null;
      email: string | null;
      created_at: Date;
    }>(
      `SELECT id, household_id, sign_in_methods, phone, email, created_at
         FROM account WHERE id = $1`,
      [accountId],
    ),
  );
  const row = rows[0];
  if (row === undefined) return null;
  return {
    id: row.id,
    role: "manager",
    householdId: row.household_id,
    signInMethods: [...row.sign_in_methods],
    phone: row.phone,
    email: row.email,
    createdAt: row.created_at,
  };
}
