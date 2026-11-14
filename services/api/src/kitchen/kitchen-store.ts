import type { DefaultStaple, KitchenCategory } from "../../config/kitchen.js";
import { withDbErrors } from "../db/errors.js";
import type { SqlExecutor } from "../db/executor.js";

/**
 * Kitchen item rows (SRS 18.1 Kitchen item, migrations 0002 and 0008). Every
 * query is scoped by the household from the session (NFR-09). Item text
 * (custom names) never goes into an error message or a log.
 */

export type KitchenItemState = "available" | "out";
export type KitchenQuantity = "a_little" | "some" | "plenty";

export interface KitchenItemRow {
  readonly id: string;
  readonly ingredient_id: string | null;
  readonly custom_name: string | null;
  readonly category: KitchenCategory;
  readonly state: KitchenItemState;
  readonly quantity: KitchenQuantity | null;
  readonly brand_id: string | null;
  readonly brand_custom_name: string | null;
  readonly is_default_staple: boolean;
  readonly changed_at: Date;
  readonly created_at: Date;
}

const COLUMNS = `id, ingredient_id, custom_name, category, state, quantity, brand_id,
  brand_custom_name, is_default_staple, changed_at, created_at`;

/** The ingredient an item is for: a reference ID, or a custom name and its comparison key. */
export type IngredientRef =
  | { readonly kind: "reference"; readonly ingredientId: string }
  | { readonly kind: "custom"; readonly name: string; readonly key: string };

export async function listItems(db: SqlExecutor, householdId: string): Promise<KitchenItemRow[]> {
  const { rows } = await withDbErrors(() =>
    db.query<KitchenItemRow>(`SELECT ${COLUMNS} FROM kitchen_item WHERE household_id = $1`, [
      householdId,
    ]),
  );
  return rows;
}

export async function readItem(
  db: SqlExecutor,
  householdId: string,
  itemId: string,
  options: { readonly forUpdate?: boolean } = {},
): Promise<KitchenItemRow | null> {
  const { rows } = await withDbErrors(() =>
    db.query<KitchenItemRow>(
      `SELECT ${COLUMNS} FROM kitchen_item WHERE id = $1 AND household_id = $2${
        options.forUpdate === true ? " FOR UPDATE" : ""
      }`,
      [itemId, householdId],
    ),
  );
  return rows[0] ?? null;
}

/**
 * Serializes kitchen creates for one household (the item limit and the
 * one-item-per-ingredient rule). Returns false when the household is gone.
 */
export async function lockHouseholdKitchen(tx: SqlExecutor, householdId: string): Promise<boolean> {
  const { rows } = await withDbErrors(() =>
    tx.query(`SELECT id FROM household WHERE id = $1 FOR NO KEY UPDATE`, [householdId]),
  );
  return rows.length === 1;
}

/** The household's item for this ingredient, if any. Call under `lockHouseholdKitchen`. */
export async function findItemFor(
  tx: SqlExecutor,
  householdId: string,
  ref: IngredientRef,
): Promise<KitchenItemRow | null> {
  const { rows } = await withDbErrors(() =>
    ref.kind === "reference"
      ? tx.query<KitchenItemRow>(
          `SELECT ${COLUMNS} FROM kitchen_item
            WHERE household_id = $1 AND ingredient_id = $2 FOR UPDATE`,
          [householdId, ref.ingredientId],
        )
      : // The second test matches the older index (0002) on the trimmed lower-case name.
        tx.query<KitchenItemRow>(
          `SELECT ${COLUMNS} FROM kitchen_item
            WHERE household_id = $1 AND custom_name IS NOT NULL
              AND (custom_key = $2 OR lower(btrim(custom_name)) = lower(btrim($3)))
            ORDER BY created_at LIMIT 1 FOR UPDATE`,
          [householdId, ref.key, ref.name],
        ),
  );
  return rows[0] ?? null;
}

export async function countItems(tx: SqlExecutor, householdId: string): Promise<number> {
  const { rows } = await withDbErrors(() =>
    tx.query<{ n: number | string }>(
      `SELECT count(*) AS n FROM kitchen_item WHERE household_id = $1`,
      [householdId],
    ),
  );
  return Number(rows[0]?.n ?? 0);
}

export interface NewItem {
  readonly householdId: string;
  readonly accountId: string | null;
  readonly ref: IngredientRef;
  readonly category: KitchenCategory;
  readonly state: KitchenItemState;
  readonly isDefaultStaple: boolean;
  readonly now: Date;
}

export async function insertItem(tx: SqlExecutor, item: NewItem): Promise<KitchenItemRow> {
  const reference = item.ref.kind === "reference" ? item.ref.ingredientId : null;
  const name = item.ref.kind === "custom" ? item.ref.name : null;
  const key = item.ref.kind === "custom" ? item.ref.key : null;
  const { rows } = await withDbErrors(() =>
    tx.query<KitchenItemRow>(
      `INSERT INTO kitchen_item
         (household_id, ingredient_id, custom_name, custom_key, category, state,
          is_default_staple, changed_by_account_id, changed_at, client_changed_at, created_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $9, $9)
       RETURNING ${COLUMNS}`,
      [
        item.householdId,
        reference,
        name,
        key,
        item.category,
        item.state,
        item.isDefaultStaple,
        item.accountId,
        item.now,
      ],
    ),
  );
  const row = rows[0];
  if (row === undefined) throw new Error("kitchen item not stored");
  return row;
}

export interface ItemChange {
  readonly state?: KitchenItemState;
  readonly category?: KitchenCategory;
}

/**
 * KIT-16: a change made now on the server's clock. It is the latest change
 * for the ingredient, so it wins; the same change sent again gives the same
 * item. T-032 adds changes dated in the past (offline sync).
 */
export async function changeItem(
  tx: SqlExecutor,
  householdId: string,
  itemId: string,
  change: ItemChange,
  accountId: string,
  now: Date,
): Promise<KitchenItemRow | null> {
  const sets = ["changed_by_account_id = $3", "changed_at = $4", "client_changed_at = $4"];
  const params: unknown[] = [itemId, householdId, accountId, now];
  if (change.state !== undefined) {
    params.push(change.state);
    sets.push(`state = $${params.length}`);
  }
  if (change.category !== undefined) {
    params.push(change.category);
    sets.push(`category = $${params.length}`);
  }
  const { rows } = await withDbErrors(() =>
    tx.query<KitchenItemRow>(
      `UPDATE kitchen_item SET ${sets.join(", ")}
        WHERE id = $1 AND household_id = $2 RETURNING ${COLUMNS}`,
      params,
    ),
  );
  return rows[0] ?? null;
}

export async function deleteItem(
  db: SqlExecutor,
  householdId: string,
  itemId: string,
): Promise<boolean> {
  const { rowCount } = await withDbErrors(() =>
    db.query(`DELETE FROM kitchen_item WHERE id = $1 AND household_id = $2`, [itemId, householdId]),
  );
  return rowCount === 1;
}

/**
 * KIT-07, ACC-05: the configured default staples, created as available in
 * the same transaction as the household. They stay available until the user
 * marks them out; nothing in V1 expires them (freshness is V2, KIT-10).
 */
export async function insertDefaultStaples(
  tx: SqlExecutor,
  input: {
    readonly householdId: string;
    readonly accountId: string;
    readonly staples: readonly DefaultStaple[];
    readonly now: Date;
  },
): Promise<void> {
  for (const staple of input.staples) {
    await insertItem(tx, {
      householdId: input.householdId,
      accountId: input.accountId,
      ref: { kind: "reference", ingredientId: staple.ingredientId },
      category: staple.category,
      state: "available",
      isDefaultStaple: true,
      now: input.now,
    });
  }
}
