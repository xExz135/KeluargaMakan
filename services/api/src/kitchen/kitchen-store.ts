import type { DefaultStaple, KitchenCategory } from "../../config/kitchen.js";
import { withDbErrors } from "../db/errors.js";
import type { SqlExecutor } from "../db/executor.js";

/**
 * Kitchen rows (SRS 18.1 Kitchen item and Ingredient set; migrations 0002,
 * 0008 and 0009). Every query is scoped by the household from the session
 * (NFR-09). Item text (custom names, typed brands, set names) never goes
 * into an error message or a log.
 *
 * Every write to a household's kitchen runs under `lockHouseholdKitchen`
 * and takes the next `kitchen_change_seq` value, so a household's writes
 * commit in sequence order and a sync cursor never skips one (KIT-16).
 */

export type KitchenItemState = "available" | "out";
export type KitchenQuantity = "a_little" | "some" | "plenty";

export interface KitchenItemRow {
  readonly id: string;
  readonly ingredient_id: string | null;
  readonly custom_name: string | null;
  readonly custom_key: string | null;
  readonly category: KitchenCategory;
  readonly state: KitchenItemState;
  readonly quantity: KitchenQuantity | null;
  readonly brand_id: string | null;
  readonly brand_custom_name: string | null;
  readonly is_default_staple: boolean;
  readonly changed_at: Date;
  readonly client_changed_at: Date | null;
  readonly use_score: number;
  readonly use_score_at: Date | null;
  readonly change_seq: string;
  readonly created_at: Date;
}

const COLUMNS = `id, ingredient_id, custom_name, custom_key, category, state, quantity, brand_id,
  brand_custom_name, is_default_staple, changed_at, client_changed_at, use_score, use_score_at,
  change_seq::text AS change_seq, created_at`;

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

/** The household's items with these IDs, locked (IDs of other households are left out). */
export async function readItems(
  tx: SqlExecutor,
  householdId: string,
  itemIds: readonly string[],
): Promise<KitchenItemRow[]> {
  if (itemIds.length === 0) return [];
  const { rows } = await withDbErrors(() =>
    tx.query<KitchenItemRow>(
      `SELECT ${COLUMNS} FROM kitchen_item WHERE household_id = $1 AND id = ANY($2::uuid[])
        FOR UPDATE`,
      [householdId, [...itemIds]],
    ),
  );
  return rows;
}

/**
 * Serializes kitchen writes for one household: the item and set limits, the
 * one-item-per-ingredient rule and the sync order. Returns false when the
 * household is gone.
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

/** Every value of an item that a change can set. */
export interface ItemValues {
  readonly category: KitchenCategory;
  readonly state: KitchenItemState;
  readonly quantity: KitchenQuantity | null;
  readonly brandId: string | null;
  readonly brandCustomName: string | null;
  readonly useScore: number;
  readonly useScoreAt: Date | null;
  /** When the edit was made, on the server's clock (KIT-16 latest change wins). */
  readonly editedAt: Date;
}

export interface NewItem {
  /** Reuse this ID (a removed item added again); a new one otherwise. */
  readonly id?: string;
  readonly householdId: string;
  readonly accountId: string | null;
  readonly ref: IngredientRef;
  readonly values: ItemValues;
  readonly isDefaultStaple: boolean;
  readonly now: Date;
}

export async function insertItem(tx: SqlExecutor, item: NewItem): Promise<KitchenItemRow> {
  const reference = item.ref.kind === "reference" ? item.ref.ingredientId : null;
  const name = item.ref.kind === "custom" ? item.ref.name : null;
  const key = item.ref.kind === "custom" ? item.ref.key : null;
  const v = item.values;
  const { rows } = await withDbErrors(() =>
    tx.query<KitchenItemRow>(
      `INSERT INTO kitchen_item
         (id, household_id, ingredient_id, custom_name, custom_key, category, state, quantity,
          brand_id, brand_custom_name, use_score, use_score_at, is_default_staple,
          changed_by_account_id, changed_at, client_changed_at, created_at)
       VALUES (COALESCE($16::uuid, gen_random_uuid()), $1, $2, $3, $4, $5, $6, $7, $8, $9,
               $10, $11, $12, $13, $14, $15, $14)
       RETURNING ${COLUMNS}`,
      [
        item.householdId,
        reference,
        name,
        key,
        v.category,
        v.state,
        v.quantity,
        v.brandId,
        v.brandCustomName,
        v.useScore,
        v.useScoreAt,
        item.isDefaultStaple,
        item.accountId,
        item.now,
        v.editedAt,
        item.id ?? null,
      ],
    ),
  );
  const row = rows[0];
  if (row === undefined) throw new Error("kitchen item not stored");
  return row;
}

/** Writes every changeable value of an item and gives it the next sync position. */
export async function writeItem(
  tx: SqlExecutor,
  householdId: string,
  itemId: string,
  values: ItemValues,
  accountId: string,
  now: Date,
): Promise<KitchenItemRow | null> {
  const { rows } = await withDbErrors(() =>
    tx.query<KitchenItemRow>(
      `UPDATE kitchen_item
          SET category = $3, state = $4, quantity = $5, brand_id = $6, brand_custom_name = $7,
              use_score = $8, use_score_at = $9, client_changed_at = $10,
              changed_by_account_id = $11, changed_at = $12,
              change_seq = nextval('kitchen_change_seq')
        WHERE id = $1 AND household_id = $2
        RETURNING ${COLUMNS}`,
      [
        itemId,
        householdId,
        values.category,
        values.state,
        values.quantity,
        values.brandId,
        values.brandCustomName,
        values.useScore,
        values.useScoreAt,
        values.editedAt,
        accountId,
        now,
      ],
    ),
  );
  return rows[0] ?? null;
}

/**
 * The key a removal is kept under: the reference ingredient ID, or for a
 * custom ingredient an HMAC of its name key under the server's hash key
 * (security review T-032 L4), never the name itself.
 */
export type RemovalKey =
  | { readonly kind: "reference"; readonly ingredientId: string }
  | { readonly kind: "custom"; readonly keyHash: Buffer };

export interface Removal {
  readonly removedAt: Date;
  readonly itemId: string | null;
}

export async function readRemoval(
  tx: SqlExecutor,
  householdId: string,
  key: RemovalKey,
): Promise<Removal | null> {
  const { rows } = await withDbErrors(() =>
    key.kind === "reference"
      ? tx.query<{ removed_at: Date | string; item_id: string | null }>(
          `SELECT removed_at, item_id::text AS item_id FROM kitchen_item_tombstone
            WHERE household_id = $1 AND ingredient_id = $2`,
          [householdId, key.ingredientId],
        )
      : tx.query<{ removed_at: Date | string; item_id: string | null }>(
          `SELECT removed_at, item_id::text AS item_id FROM kitchen_item_tombstone
            WHERE household_id = $1 AND custom_key_hash = $2`,
          [householdId, key.keyHash],
        ),
  );
  const row = rows[0];
  return row === undefined ? null : { removedAt: new Date(row.removed_at), itemId: row.item_id };
}

/**
 * Records a removal, keeping one per ingredient: the newest removal time
 * wins, the latest removed item ID is kept, and the removal takes the next
 * sync position.
 */
export async function upsertRemoval(
  tx: SqlExecutor,
  householdId: string,
  key: RemovalKey,
  itemId: string | null,
  removedAt: Date,
  now: Date,
): Promise<void> {
  const update = `DO UPDATE SET
      removed_at = greatest(kitchen_item_tombstone.removed_at, EXCLUDED.removed_at),
      item_id = COALESCE(EXCLUDED.item_id, kitchen_item_tombstone.item_id),
      recorded_at = EXCLUDED.recorded_at,
      change_seq = nextval('kitchen_change_seq')`;
  await withDbErrors(() =>
    key.kind === "reference"
      ? tx.query(
          `INSERT INTO kitchen_item_tombstone
             (household_id, item_id, ingredient_id, removed_at, recorded_at)
           VALUES ($1, $2, $3, $4, $5)
           ON CONFLICT (household_id, ingredient_id) WHERE ingredient_id IS NOT NULL ${update}`,
          [householdId, itemId, key.ingredientId, removedAt, now],
        )
      : tx.query(
          `INSERT INTO kitchen_item_tombstone
             (household_id, item_id, custom_key_hash, removed_at, recorded_at)
           VALUES ($1, $2, $3, $4, $5)
           ON CONFLICT (household_id, custom_key_hash) WHERE custom_key_hash IS NOT NULL ${update}`,
          [householdId, itemId, key.keyHash, removedAt, now],
        ),
  );
}

/** Removes an item and records the removal (KIT-16), dated `removedAt` on the server's clock. */
export async function removeItem(
  tx: SqlExecutor,
  householdId: string,
  row: KitchenItemRow,
  key: RemovalKey,
  removedAt: Date,
  now: Date,
): Promise<void> {
  await withDbErrors(() =>
    tx.query(`DELETE FROM kitchen_item WHERE id = $1 AND household_id = $2`, [row.id, householdId]),
  );
  await upsertRemoval(tx, householdId, key, row.id, removedAt, now);
}

export interface SyncFloor {
  /** The newest removal time evicted at the cap: older changes never add an item. */
  readonly removedBefore: Date;
  /** When removals were last evicted: older cursors resync in full. */
  readonly evictedAt: Date;
}

export async function readSyncFloor(
  tx: SqlExecutor,
  householdId: string,
): Promise<SyncFloor | null> {
  const { rows } = await withDbErrors(() =>
    tx.query<{ removed_before: Date | string; evicted_at: Date | string }>(
      `SELECT removed_before, evicted_at FROM kitchen_sync_floor WHERE household_id = $1`,
      [householdId],
    ),
  );
  const row = rows[0];
  return row === undefined
    ? null
    : { removedBefore: new Date(row.removed_before), evictedAt: new Date(row.evicted_at) };
}

/**
 * Keeps at most `cap` removals for the household (security review T-032
 * L4): the oldest beyond it are deleted and the household's floor moves up
 * to the newest of them.
 */
export async function capRemovals(
  tx: SqlExecutor,
  householdId: string,
  cap: number,
  now: Date,
): Promise<void> {
  await withDbErrors(async () => {
    const { rows } = await tx.query<{ newest: Date | string | null }>(
      `WITH evicted AS (
         DELETE FROM kitchen_item_tombstone
          WHERE id IN (
            SELECT id FROM kitchen_item_tombstone WHERE household_id = $1
             ORDER BY removed_at DESC, id DESC OFFSET $2)
         RETURNING removed_at)
       SELECT max(removed_at) AS newest FROM evicted`,
      [householdId, cap],
    );
    const newest = rows[0]?.newest ?? null;
    if (newest === null) return;
    await tx.query(
      `INSERT INTO kitchen_sync_floor (household_id, removed_before, evicted_at)
       VALUES ($1, $2, $3)
       ON CONFLICT (household_id) DO UPDATE
         SET removed_before = greatest(kitchen_sync_floor.removed_before, EXCLUDED.removed_before),
             evicted_at = EXCLUDED.evicted_at`,
      [householdId, newest, now],
    );
  });
}

/** Items and removals after sync position `after` (all items when null), and the newest position. */
export async function changesSince(
  db: SqlExecutor,
  householdId: string,
  after: bigint | null,
): Promise<{ items: KitchenItemRow[]; removedItemIds: string[]; latest: bigint }> {
  return withDbErrors(async () => {
    const items =
      after === null
        ? await listItems(db, householdId)
        : (
            await db.query<KitchenItemRow>(
              `SELECT ${COLUMNS} FROM kitchen_item WHERE household_id = $1 AND change_seq > $2`,
              [householdId, after.toString()],
            )
          ).rows;
    const removed =
      after === null
        ? []
        : (
            await db.query<{ item_id: string }>(
              `SELECT item_id::text AS item_id FROM kitchen_item_tombstone
                WHERE household_id = $1 AND change_seq > $2 AND item_id IS NOT NULL
                ORDER BY change_seq`,
              [householdId, after.toString()],
            )
          ).rows.map((row) => row.item_id);
    const { rows } = await db.query<{ latest: string | null }>(
      `SELECT greatest(
         (SELECT max(change_seq) FROM kitchen_item WHERE household_id = $1),
         (SELECT max(change_seq) FROM kitchen_item_tombstone WHERE household_id = $1)
       )::text AS latest`,
      [householdId],
    );
    const latest = BigInt(rows[0]?.latest ?? "0");
    return { items, removedItemIds: [...new Set(removed)], latest };
  });
}

// ---------------------------------------------------------------- sync change records

export interface SyncChangeRecord {
  readonly request_hash: Uint8Array;
  readonly outcome: "applied" | "superseded" | "rejected";
  readonly item_id: string | null;
  readonly error_code: string | null;
}

export async function findSyncChange(
  tx: SqlExecutor,
  householdId: string,
  changeId: string,
  keptSince: Date,
): Promise<SyncChangeRecord | null> {
  const { rows } = await withDbErrors(() =>
    tx.query<SyncChangeRecord>(
      `SELECT request_hash, outcome, item_id::text AS item_id, error_code FROM kitchen_sync_change
        WHERE household_id = $1 AND change_id = $2 AND created_at >= $3`,
      [householdId, changeId, keptSince],
    ),
  );
  return rows[0] ?? null;
}

export async function rememberSyncChange(
  tx: SqlExecutor,
  householdId: string,
  changeId: string,
  record: {
    readonly requestHash: Buffer;
    readonly outcome: SyncChangeRecord["outcome"];
    readonly itemId: string | null;
    readonly errorCode: string | null;
  },
  now: Date,
): Promise<void> {
  await withDbErrors(() =>
    tx.query(
      `INSERT INTO kitchen_sync_change
         (household_id, change_id, request_hash, outcome, item_id, error_code, created_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       ON CONFLICT (household_id, change_id) DO UPDATE
         SET request_hash = EXCLUDED.request_hash, outcome = EXCLUDED.outcome,
             item_id = EXCLUDED.item_id, error_code = EXCLUDED.error_code,
             created_at = EXCLUDED.created_at`,
      [
        householdId,
        changeId,
        record.requestHash,
        record.outcome,
        record.itemId,
        record.errorCode,
        now,
      ],
    ),
  );
}

/**
 * Deletes sync change records and removals older than `before` (configured
 * retention; scheduled with the other purges in T-072). A cursor issued
 * before `before` then leads to a full sync.
 */
export async function purgeKitchenSyncRecords(db: SqlExecutor, before: Date): Promise<void> {
  await withDbErrors(async () => {
    await db.query(`DELETE FROM kitchen_sync_change WHERE created_at < $1`, [before]);
    await db.query(`DELETE FROM kitchen_item_tombstone WHERE recorded_at < $1`, [before]);
  });
}

// ---------------------------------------------------------------- ingredient sets

export interface IngredientSetRow {
  readonly id: string;
  readonly name: string;
  readonly item_ids: string[];
  readonly created_at: Date;
  readonly updated_at: Date;
}

const SET_SELECT = `SELECT s.id, s.name, s.created_at, s.updated_at,
    COALESCE(array_agg(i.kitchen_item_id::text ORDER BY i.kitchen_item_id)
             FILTER (WHERE i.kitchen_item_id IS NOT NULL), '{}') AS item_ids
  FROM ingredient_set s
  LEFT JOIN ingredient_set_item i ON i.set_id = s.id AND i.household_id = s.household_id`;

export async function listSets(db: SqlExecutor, householdId: string): Promise<IngredientSetRow[]> {
  const { rows } = await withDbErrors(() =>
    db.query<IngredientSetRow>(
      `${SET_SELECT} WHERE s.household_id = $1 GROUP BY s.id ORDER BY s.created_at, s.id`,
      [householdId],
    ),
  );
  return rows;
}

export async function readSet(
  db: SqlExecutor,
  householdId: string,
  setId: string,
): Promise<IngredientSetRow | null> {
  const { rows } = await withDbErrors(() =>
    db.query<IngredientSetRow>(
      `${SET_SELECT} WHERE s.household_id = $1 AND s.id = $2 GROUP BY s.id`,
      [householdId, setId],
    ),
  );
  return rows[0] ?? null;
}

export async function countSets(tx: SqlExecutor, householdId: string): Promise<number> {
  const { rows } = await withDbErrors(() =>
    tx.query<{ n: number | string }>(
      `SELECT count(*) AS n FROM ingredient_set WHERE household_id = $1`,
      [householdId],
    ),
  );
  return Number(rows[0]?.n ?? 0);
}

export async function insertSet(
  tx: SqlExecutor,
  householdId: string,
  name: string,
  now: Date,
): Promise<string> {
  const { rows } = await withDbErrors(() =>
    tx.query<{ id: string }>(
      `INSERT INTO ingredient_set (household_id, name, created_at, updated_at)
       VALUES ($1, $2, $3, $3) RETURNING id`,
      [householdId, name, now],
    ),
  );
  const id = rows[0]?.id;
  if (id === undefined) throw new Error("ingredient set not stored");
  return id;
}

/** Renames the set and replaces its items. Returns false when the set is not in the household. */
export async function replaceSet(
  tx: SqlExecutor,
  householdId: string,
  setId: string,
  name: string,
  itemIds: readonly string[],
  now: Date,
): Promise<boolean> {
  return withDbErrors(async () => {
    const { rowCount } = await tx.query(
      `UPDATE ingredient_set SET name = $3, updated_at = $4 WHERE id = $1 AND household_id = $2`,
      [setId, householdId, name, now],
    );
    if (rowCount !== 1) return false;
    await tx.query(`DELETE FROM ingredient_set_item WHERE set_id = $1 AND household_id = $2`, [
      setId,
      householdId,
    ]);
    for (const itemId of itemIds) {
      await tx.query(
        `INSERT INTO ingredient_set_item (set_id, household_id, kitchen_item_id) VALUES ($1, $2, $3)`,
        [setId, householdId, itemId],
      );
    }
    return true;
  });
}

export async function deleteSet(
  tx: SqlExecutor,
  householdId: string,
  setId: string,
): Promise<boolean> {
  const { rowCount } = await withDbErrors(() =>
    tx.query(`DELETE FROM ingredient_set WHERE id = $1 AND household_id = $2`, [
      setId,
      householdId,
    ]),
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
      values: {
        category: staple.category,
        state: "available",
        quantity: null,
        brandId: null,
        brandCustomName: null,
        useScore: 0,
        useScoreAt: null,
        editedAt: input.now,
      },
      isDefaultStaple: true,
      now: input.now,
    });
  }
}
