/**
 * DAT-02, NFR-08: key separation.
 *
 * Two key-encryption keys (KEKs) with different purposes:
 * - `general`: general household data. In staging and production this is the
 *   customer-managed key of the database storage and backups (Cloud SQL CMEK,
 *   `KMS_GENERAL_DATA_KEY`, T-023), and it is available to the API for any
 *   general field that needs application-level encryption.
 * - `health`: hard rules and other health data (`KMS_HEALTH_DATA_KEY`). Health
 *   data is encrypted in the application with data keys wrapped by this KEK,
 *   so a database dump, a backup or anyone holding only the general key cannot
 *   read it. Anyone who can use the health KEK can still read a backup taken
 *   before a deletion, until that backup is purged on its normal cycle.
 *
 * Both providers implement the same interface: `LocalKeyProvider` for
 * development and tests, `CloudKmsKeyProvider` for staging and production.
 * The KEK itself never leaves the provider (in Cloud KMS it never leaves KMS).
 */

export const KEY_PURPOSES = ["general", "health"] as const;
export type KeyPurpose = (typeof KEY_PURPOSES)[number];

export interface WrappedKey {
  /** Non-secret identifier of the KEK that wrapped the data key (stored with it). */
  readonly keyRef: string;
  readonly wrapped: Uint8Array;
}

export interface KeyEncryptionKey {
  readonly purpose: KeyPurpose;
  readonly keyRef: string;
  /**
   * Wraps a data key. `context` is bound as additional authenticated data,
   * so a wrapped key only unwraps for the same row and owner.
   */
  wrap(dataKey: Uint8Array, context: string): Promise<WrappedKey>;
  /** Throws `DecryptionError` for a key it did not wrap and `KeyServiceError` when the service fails. */
  unwrap(wrapped: WrappedKey, context: string): Promise<Uint8Array>;
}

export interface KeyProvider {
  kek(purpose: KeyPurpose): KeyEncryptionKey;
}

/** The ciphertext or wrapped key is not readable with this key (wrong key, wrong context or tampered). */
export class DecryptionError extends Error {
  constructor(message = "ciphertext could not be authenticated", options?: { cause?: unknown }) {
    super(message, options);
    this.name = "DecryptionError";
  }
}

/** The key service failed or is misconfigured. Never a reason to continue without the data. */
export class KeyServiceError extends Error {
  constructor(message: string, options?: { cause?: unknown }) {
    super(message, options);
    this.name = "KeyServiceError";
  }
}

export const DATA_KEY_BYTES = 32;
