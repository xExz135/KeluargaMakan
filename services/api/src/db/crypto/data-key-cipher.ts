import { IV_BYTES, TAG_BYTES, open, seal } from "./aes-gcm.js";
import { DecryptionError } from "./key-provider.js";

/**
 * Field encryption with an unwrapped data key (AES-256-GCM), with padding.
 *
 * AES-GCM does not hide the plaintext length, so every plaintext is padded to
 * a length chosen by the caller before it is encrypted (security re-check
 * T-016 N1). Hard rules all use one fixed size, and the members of one safety
 * log share one power-of-two bucket. That way the ciphertext length says
 * nothing about the rule type, the allergen or a member's result.
 *
 * Ciphertext: 0x02 | IV (12) | tag (16) | ciphertext of the padded plaintext.
 * Padded plaintext: content length (uint32, big-endian) | content (UTF-8) |
 * zero bytes up to the padded length. On decrypt, the length must fit and every
 * padding byte must be zero, otherwise decryption fails (fail closed). Content
 * that does not fit is refused, never truncated.
 *
 * `context` names the table, row and owner (for example
 * `hard_rule:<id>:<profileId>:<householdId>`) and is bound as AAD, so a
 * ciphertext copied into another row or another member's record does not
 * decrypt.
 */

const FORMAT = 0x02;
const LENGTH_PREFIX_BYTES = 4;
export const CIPHERTEXT_OVERHEAD_BYTES = 1 + IV_BYTES + TAG_BYTES;

/** Smallest and largest padded sizes for bucketed fields (safety log details). */
export const MIN_BUCKET_BYTES = 1024;
export const MAX_BUCKET_BYTES = 524_288;

export class PaddingError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "PaddingError";
  }
}

function aadFor(context: string): Buffer {
  return Buffer.from(`keluargamakan.field.v2|${context}`, "utf8");
}

/** The padded plaintext size needed for content of `contentBytes` UTF-8 bytes. */
export function paddedSizeFor(contentBytes: number): number {
  return contentBytes + LENGTH_PREFIX_BYTES;
}

/**
 * The power-of-two bucket (at least `MIN_BUCKET_BYTES`) that fits every given
 * content. Throws `PaddingError` above `MAX_BUCKET_BYTES`.
 */
export function bucketFor(contents: readonly string[]): number {
  const needed = Math.max(
    0,
    ...contents.map((content) => paddedSizeFor(Buffer.byteLength(content, "utf8"))),
  );
  let bucket = MIN_BUCKET_BYTES;
  while (bucket < needed) bucket *= 2;
  if (bucket > MAX_BUCKET_BYTES) throw new PaddingError("content too large to pad");
  return bucket;
}

export function encryptField(
  dataKey: Uint8Array,
  plaintext: string,
  context: string,
  paddedLength: number,
): Buffer {
  const content = Buffer.from(plaintext, "utf8");
  if (
    !Number.isInteger(paddedLength) ||
    paddedLength < LENGTH_PREFIX_BYTES ||
    paddedSizeFor(content.length) > paddedLength
  ) {
    throw new PaddingError("content does not fit the padded length");
  }
  const padded = Buffer.alloc(paddedLength); // zero-filled
  padded.writeUInt32BE(content.length, 0);
  content.copy(padded, LENGTH_PREFIX_BYTES);
  const sealed = seal(dataKey, padded, aadFor(context));
  return Buffer.concat([Buffer.from([FORMAT]), sealed.iv, sealed.tag, sealed.ciphertext]);
}

export function decryptField(dataKey: Uint8Array, blob: Uint8Array, context: string): string {
  const bytes = Buffer.from(blob);
  if (bytes.length < CIPHERTEXT_OVERHEAD_BYTES + LENGTH_PREFIX_BYTES || bytes[0] !== FORMAT) {
    throw new DecryptionError("unknown ciphertext format");
  }
  const padded = open(
    dataKey,
    {
      iv: bytes.subarray(1, 1 + IV_BYTES),
      tag: bytes.subarray(1 + IV_BYTES, CIPHERTEXT_OVERHEAD_BYTES),
      ciphertext: bytes.subarray(CIPHERTEXT_OVERHEAD_BYTES),
    },
    aadFor(context),
  );
  const length = padded.readUInt32BE(0);
  if (length > padded.length - LENGTH_PREFIX_BYTES) {
    throw new DecryptionError("invalid padding");
  }
  const end = LENGTH_PREFIX_BYTES + length;
  for (let index = end; index < padded.length; index += 1) {
    if (padded[index] !== 0) throw new DecryptionError("invalid padding");
  }
  try {
    return new TextDecoder("utf-8", { fatal: true }).decode(
      padded.subarray(LENGTH_PREFIX_BYTES, end),
    );
  } catch {
    throw new DecryptionError("invalid text encoding");
  }
}
