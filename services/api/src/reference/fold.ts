/**
 * The comparison form of a name (KIT-04 search, KIT-05 custom names): Unicode
 * NFKC (full-width and compatibility characters become their plain form),
 * lower case, accents and other combining marks removed, and every run of
 * characters that are not letters or digits turned into one space. So
 * "Témpé", "TEMPE", "ｔｅｍｐｅ" and " tempe " all compare as "tempe", and
 * "kecap-manis" as "kecap manis".
 */
export function foldName(value: string): string {
  return value
    .normalize("NFKC")
    .toLowerCase()
    .normalize("NFD")
    .replace(/\p{M}+/gu, "")
    .normalize("NFC")
    .replace(/[^\p{L}\p{N}]+/gu, " ")
    .trim();
}
