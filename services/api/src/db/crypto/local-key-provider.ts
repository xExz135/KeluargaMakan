import { createHash, timingSafeEqual } from "node:crypto";

import { IV_BYTES, TAG_BYTES, open, seal } from "./aes-gcm.js";
import {
  DecryptionError,
  KEY_PURPOSES,
  KeyServiceError,
  type KeyEncryptionKey,
  type KeyProvider,
  type KeyPurpose,
  type WrappedKey,
} from "./key-provider.js";

/**
 * Development and test key provider. Each purpose has its own 32-byte KEK,
 * given by the caller (from `LOCAL_GENERAL_DATA_KEK` and
 * `LOCAL_HEALTH_DATA_KEK`, or random keys made in a test). No key material is
 * ever committed. It refuses to run in production and refuses the same key for
 * both purposes, so key separation (DAT-02) holds in every environment.
 *
 * Wrapped key format: 0x01 | purpose byte | IV (12) | tag (16) | ciphertext.
 * The purpose and the caller's context are bound as AAD.
 */

const FORMAT = 0x01;
const PURPOSE_BYTE: Record<KeyPurpose, number> = { general: 0x01, health: 0x02 };
const HEADER_BYTES = 2;

function aadFor(purpose: KeyPurpose, context: string): Buffer {
  return Buffer.from(`keluargamakan.kek.v1|${purpose}|${context}`, "utf8");
}

class LocalKek implements KeyEncryptionKey {
  readonly purpose: KeyPurpose;
  readonly keyRef: string;
  readonly #key: Buffer;

  constructor(purpose: KeyPurpose, key: Uint8Array) {
    this.purpose = purpose;
    this.#key = Buffer.from(key);
    const fingerprint = createHash("sha256")
      .update("keluargamakan.local-kek-id|")
      .update(this.#key)
      .digest("hex")
      .slice(0, 16);
    this.keyRef = `local:${purpose}:${fingerprint}`;
  }

  wrap(dataKey: Uint8Array, context: string): Promise<WrappedKey> {
    const sealed = seal(this.#key, dataKey, aadFor(this.purpose, context));
    const wrapped = Buffer.concat([
      Buffer.from([FORMAT, PURPOSE_BYTE[this.purpose]]),
      sealed.iv,
      sealed.tag,
      sealed.ciphertext,
    ]);
    return Promise.resolve({ keyRef: this.keyRef, wrapped });
  }

  unwrap(wrapped: WrappedKey, context: string): Promise<Uint8Array> {
    const bytes = Buffer.from(wrapped.wrapped);
    if (wrapped.keyRef !== this.keyRef) {
      return Promise.reject(new DecryptionError("data key was wrapped by a different key"));
    }
    if (bytes.length < HEADER_BYTES + IV_BYTES + TAG_BYTES || bytes[0] !== FORMAT) {
      return Promise.reject(new DecryptionError("unknown wrapped key format"));
    }
    if (bytes[1] !== PURPOSE_BYTE[this.purpose]) {
      return Promise.reject(new DecryptionError("data key belongs to a different key purpose"));
    }
    try {
      return Promise.resolve(
        open(
          this.#key,
          {
            iv: bytes.subarray(HEADER_BYTES, HEADER_BYTES + IV_BYTES),
            tag: bytes.subarray(HEADER_BYTES + IV_BYTES, HEADER_BYTES + IV_BYTES + TAG_BYTES),
            ciphertext: bytes.subarray(HEADER_BYTES + IV_BYTES + TAG_BYTES),
          },
          aadFor(this.purpose, context),
        ),
      );
    } catch (error) {
      return Promise.reject(error instanceof Error ? error : new DecryptionError());
    }
  }
}

export type LocalKeyMaterial = Readonly<Record<KeyPurpose, Uint8Array>>;

export interface LocalKeyProviderOptions {
  /** `NODE_ENV`; the local provider is refused in production. */
  readonly nodeEnv?: string | undefined;
}

export class LocalKeyProvider implements KeyProvider {
  readonly #keks: Record<KeyPurpose, LocalKek>;

  constructor(keys: LocalKeyMaterial, options: LocalKeyProviderOptions = {}) {
    if (options.nodeEnv === "production") {
      throw new KeyServiceError("the local key provider must not be used in production");
    }
    for (const purpose of KEY_PURPOSES) {
      if (keys[purpose].byteLength !== 32) {
        throw new KeyServiceError(`the local ${purpose} key must be 32 bytes`);
      }
    }
    if (timingSafeEqual(Buffer.from(keys.general), Buffer.from(keys.health))) {
      throw new KeyServiceError("the general and health keys must differ (DAT-02)");
    }
    this.#keks = {
      general: new LocalKek("general", keys.general),
      health: new LocalKek("health", keys.health),
    };
  }

  kek(purpose: KeyPurpose): KeyEncryptionKey {
    return this.#keks[purpose];
  }
}
