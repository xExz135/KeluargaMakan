import type { HardRule, ReferenceDataset, ReferenceIngredient } from "@keluargamakan/cek-aman";

/**
 * The reference records one Cek Aman check reads (security review T-041 M1,
 * re-check N1 and N4). Pure: no I/O, and only type imports from the engine.
 *
 * The index is built once per reference dataset object (one frozen dataset
 * per loaded reference version) and each check gets only the records it can
 * read: its lines' ingredients, every component of them and of their brand
 * variants (to any depth), and every ingredient a member's rule maps to.
 * Same schema and version. A record left out by mistake can only make a
 * result stricter (Cek Aman reports it as not in the reference: Check the
 * label), never Safe. Results are never cached or replayed (T-040 M4).
 *
 * N1: a dataset the engine would refuse as a whole (a record that is not an
 * object, has no string `id`, or repeats an ID) is refused as a whole here
 * too, when the index is built: `ReferenceIntegrityError`, never "first
 * copy wins". A rule read defensively (no `mapping`) adds no records, so the
 * engine gives its own result for it.
 *
 * N4: this copies the engine's lookup rules. The safety regression suite
 * runs every regression and recipe halal case through it with a read
 * tracker (tests/safety-regression/reference-subset.test.ts), so a rule set
 * that follows a new reference field fails CI until this module follows it
 * too. Review this module with every rule-set change.
 */

/** The dataset cannot be used as a whole (N1). */
export class ReferenceIntegrityError extends Error {
  constructor(what: string) {
    super(`the reference dataset cannot be used: ${what}`);
    this.name = "ReferenceIntegrityError";
  }
}

interface ReferenceIndex {
  readonly positions: ReadonlyMap<string, number>;
  readonly records: readonly ReferenceIngredient[];
}

const indexCache = new WeakMap<object, ReferenceIndex | ReferenceIntegrityError>();

function buildIndex(dataset: ReferenceDataset): ReferenceIndex | ReferenceIntegrityError {
  const records: unknown = (dataset as { ingredients?: unknown }).ingredients;
  if (!Array.isArray(records)) return new ReferenceIntegrityError("ingredients is not a list");
  const positions = new Map<string, number>();
  for (const [position, record] of (records as unknown[]).entries()) {
    const id =
      typeof record === "object" && record !== null ? (record as { id?: unknown }).id : undefined;
    if (typeof id !== "string" || id === "") {
      return new ReferenceIntegrityError("a record has no id");
    }
    if (positions.has(id)) return new ReferenceIntegrityError("a record id repeats");
    positions.set(id, position);
  }
  return { positions, records: records as ReferenceIngredient[] };
}

function indexOf(dataset: ReferenceDataset): ReferenceIndex {
  let index = indexCache.get(dataset);
  if (index === undefined) {
    index = buildIndex(dataset);
    indexCache.set(dataset, index);
  }
  if (index instanceof ReferenceIntegrityError) throw index;
  return index;
}

/** Throws `ReferenceIntegrityError` for a dataset the engine would refuse as a whole. */
export function assertReferenceIntegrity(dataset: ReferenceDataset): void {
  indexOf(dataset);
}

const idsIn = (value: unknown): string[] =>
  Array.isArray(value) ? value.filter((id): id is string => typeof id === "string") : [];

const field = (value: unknown, key: string): unknown =>
  typeof value === "object" && value !== null ? (value as Record<string, unknown>)[key] : undefined;

/** Component IDs of a record and of its brand variants. Read defensively: a record is data. */
function componentIds(record: ReferenceIngredient): string[] {
  const ids = idsIn(field(field(record, "components"), "ingredientIds"));
  const variants = field(record, "brandVariants");
  for (const variant of Array.isArray(variants) ? (variants as unknown[]) : []) {
    ids.push(...idsIn(field(field(variant, "components"), "ingredientIds")));
  }
  return ids;
}

/** Mapped (or proposed) ingredient IDs of a rule; none for a rule without a usable mapping. */
function ruleIngredientIds(rule: HardRule): string[] {
  const type = field(rule, "type");
  if (type !== "free_text" && type !== "medical_exclusion") return [];
  return idsIn(field(field(rule, "mapping"), "ingredientIds"));
}

/** The records one check reads, in dataset order. Throws `ReferenceIntegrityError` (N1). */
export function referenceSubset(
  dataset: ReferenceDataset,
  lineIngredientIds: readonly (string | null)[],
  rules: readonly HardRule[],
): ReferenceDataset {
  const index = indexOf(dataset);
  const queue = [
    ...lineIngredientIds.filter((id): id is string => typeof id === "string"),
    ...rules.flatMap(ruleIngredientIds),
  ];
  const kept = new Set<number>();
  const seen = new Set<string>();
  while (queue.length > 0) {
    const id = queue.pop() as string;
    if (seen.has(id)) continue;
    seen.add(id);
    const position = index.positions.get(id);
    if (position === undefined) continue;
    kept.add(position);
    const record = index.records[position];
    if (record !== undefined) queue.push(...componentIds(record));
  }
  return {
    schema: dataset.schema,
    version: dataset.version,
    ingredients: [...kept].sort((a, b) => a - b).map((position) => index.records[position]!),
  };
}
