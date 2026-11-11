/** A forward-only schema migration. Applied migrations are never edited (the checksum is enforced). */
export interface Migration {
  /** Positive, gap-free, ascending. */
  readonly version: number;
  /** Lowercase kebab-case. */
  readonly name: string;
  readonly sql: string;
}
