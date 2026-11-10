/**
 * Thrown when the input is structurally unusable (for example no members, a
 * missing reference version or duplicate IDs). No result is produced, so the
 * caller cannot show the food: this is fail-closed, not a fallback to "safe".
 */
export class CekAmanInputError extends Error {
  override readonly name = "CekAmanInputError";
}
