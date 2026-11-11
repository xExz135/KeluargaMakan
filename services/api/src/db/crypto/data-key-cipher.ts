import { IV_BYTES, TAG_BYTES, open, seal } from "./aes-gcm.js";
import { DecryptionError } from "./key-provider.js";

/**
 * Field encryption with an unwrapped data key (AES-256-GCM).
 *
 * Format: 0x01 | IV (12) | tag (16) | ciphertext. `context` names the table,
 * row and owner (for example `hard_rule:<id>:<profileId>`) and is bound as
 * AAD, so a ciphertext copied into another row or another member's record
 * does not decrypt.
 */

const FORMAT = 0x01;
export const MIN_CIPHERTEXT_BYTES = 1 + IV_BYTES + TAG_BYTES;

function aadFor(context: string): Buffer {
  return Buffer.from(`keluargamakan.field.v1|${context}`, "utf8");
}

export function encryptField(dataKey: Uint8Array, plaintext: string, context: string): Buffer {
  const sealed = seal(dataKey, Buffer.from(plaintext, "utf8"), aadFor(context));
  return Buffer.concat([Buffer.from([FORMAT]), sealed.iv, sealed.tag, sealed.ciphertext]);
}

export function decryptField(dataKey: Uint8Array, blob: Uint8Array, context: string): string {
  const bytes = Buffer.from(blob);
  if (bytes.length < MIN_CIPHERTEXT_BYTES || bytes[0] !== FORMAT) {
    throw new DecryptionError("unknown ciphertext format");
  }
  const plaintext = open(
    dataKey,
    {
      iv: bytes.subarray(1, 1 + IV_BYTES),
      tag: bytes.subarray(1 + IV_BYTES, MIN_CIPHERTEXT_BYTES),
      ciphertext: bytes.subarray(MIN_CIPHERTEXT_BYTES),
    },
    aadFor(context),
  );
  return new TextDecoder("utf-8", { fatal: true }).decode(plaintext);
}
