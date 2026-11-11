import { createCipheriv, createDecipheriv, randomBytes } from "node:crypto";

import { DecryptionError } from "./key-provider.js";

export const IV_BYTES = 12;
export const TAG_BYTES = 16;

export interface Sealed {
  readonly iv: Buffer;
  readonly tag: Buffer;
  readonly ciphertext: Buffer;
}

/** AES-256-GCM with a fresh random 96-bit IV per call. */
export function seal(key: Uint8Array, plaintext: Uint8Array, aad: Uint8Array): Sealed {
  if (key.byteLength !== 32) throw new RangeError("AES-256-GCM needs a 32-byte key");
  const iv = randomBytes(IV_BYTES);
  const cipher = createCipheriv("aes-256-gcm", key, iv, { authTagLength: TAG_BYTES });
  cipher.setAAD(aad);
  const ciphertext = Buffer.concat([cipher.update(plaintext), cipher.final()]);
  return { iv, tag: cipher.getAuthTag(), ciphertext };
}

/** Throws `DecryptionError` when the key, IV, tag, AAD or ciphertext do not match. */
export function open(key: Uint8Array, sealed: Sealed, aad: Uint8Array): Buffer {
  if (key.byteLength !== 32) throw new RangeError("AES-256-GCM needs a 32-byte key");
  try {
    const decipher = createDecipheriv("aes-256-gcm", key, sealed.iv, {
      authTagLength: TAG_BYTES,
    });
    decipher.setAAD(aad);
    decipher.setAuthTag(sealed.tag);
    return Buffer.concat([decipher.update(sealed.ciphertext), decipher.final()]);
  } catch (cause) {
    throw new DecryptionError(undefined, { cause });
  }
}
