/**
 * Security review T-019 L5: user-written text that is stored and shown again
 * (profile names, free-text hard rules). The text is put in Unicode NFC, and
 * refused when it contains code points that hide or reorder what a reader
 * sees, so two names or rules cannot look the same while differing:
 *
 * - Cc: control characters (C0, DEL, C1)
 * - Cf: format characters, including zero-width spaces and joiners (U+200B
 *   to U+200D, U+2060), bidirectional marks and overrides, the soft hyphen
 *   (U+00AD) and the byte-order mark (U+FEFF)
 * - Cs: lone surrogate halves (not valid text)
 * - Co: private-use characters
 *
 * Callers report only a field pointer and a code, never the value.
 */
const HIDDEN = /[\p{Cc}\p{Cf}\p{Cs}\p{Co}]/u;

/** The NFC form of `value`, or null when it is blank or contains hidden or invalid code points. */
export function cleanUserText(value: string): string | null {
  if (HIDDEN.test(value)) return null;
  const normalized = value.normalize("NFC").trim();
  if (normalized === "" || HIDDEN.test(normalized)) return null;
  return normalized;
}

/** Length in code points, as the contract's `minLength` and `maxLength` count. */
export function codePointLength(value: string): number {
  return [...value].length;
}
