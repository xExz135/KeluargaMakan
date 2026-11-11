import {
  DecryptionError,
  KeyServiceError,
  type KeyEncryptionKey,
  type KeyProvider,
  type KeyPurpose,
  type WrappedKey,
} from "./key-provider.js";

/**
 * Cloud KMS key provider for staging and production (T-023 creates the keys).
 *
 * `KmsClient` is the subset of `KeyManagementServiceClient` from
 * `@google-cloud/kms` that this provider uses. The client is injected, so this
 * package does not depend on the Google library until T-023 wires it; a fake
 * client tests the provider. Credentials come from the runtime service account,
 * never from the repository.
 *
 * Each purpose uses its own crypto key (`KMS_GENERAL_DATA_KEY`,
 * `KMS_HEALTH_DATA_KEY`). The two must differ, and the service account that
 * serves general data must not hold decrypt rights on the health key (IAM,
 * T-023).
 */

type Bytes = Uint8Array | string | null | undefined;

/** Per-call options, as `CallOptions` in the Google client (`timeout` in milliseconds). */
export interface KmsCallOptions {
  readonly timeout: number;
}

export interface KmsClient {
  encrypt(
    request: {
      name: string;
      plaintext: Uint8Array;
      additionalAuthenticatedData: Uint8Array;
    },
    options?: KmsCallOptions,
  ): Promise<readonly [{ ciphertext?: Bytes }, ...unknown[]]>;
  decrypt(
    request: {
      name: string;
      ciphertext: Uint8Array;
      additionalAuthenticatedData: Uint8Array;
    },
    options?: KmsCallOptions,
  ): Promise<readonly [{ plaintext?: Bytes }, ...unknown[]]>;
}

/**
 * Security re-check T-016 N2: a deadline for every Cloud KMS call, passed to
 * the client and also enforced here, so a stuck call fails fast with
 * `KeyServiceError` instead of waiting for the client default (up to 60 s).
 * Not an SRS figure; operational default, overridable by `KMS_CALL_TIMEOUT_MS`.
 */
export const DEFAULT_KMS_CALL_TIMEOUT_MS = 2_000;

class DeadlineExceeded extends Error {}

function withDeadline<T>(promise: Promise<T>, ms: number): Promise<T> {
  let timer: NodeJS.Timeout | undefined;
  const deadline = new Promise<never>((_, reject) => {
    timer = setTimeout(() => reject(new DeadlineExceeded()), ms);
  });
  return Promise.race([promise, deadline]).finally(() => clearTimeout(timer));
}

const CRYPTO_KEY_NAME =
  /^projects\/[a-z][a-z0-9-]{4,28}[a-z0-9]\/locations\/[a-z0-9-]+\/keyRings\/[A-Za-z0-9_-]{1,63}\/cryptoKeys\/[A-Za-z0-9_-]{1,63}$/;

/** gRPC status codes that mean "this key cannot read this ciphertext". */
const INVALID_ARGUMENT = 3;

function toBytes(value: Bytes): Buffer | null {
  if (value === null || value === undefined) return null;
  return typeof value === "string" ? Buffer.from(value, "base64") : Buffer.from(value);
}

function aadFor(purpose: KeyPurpose, context: string): Buffer {
  return Buffer.from(`keluargamakan.kek.v1|${purpose}|${context}`, "utf8");
}

function isInvalidArgument(error: unknown): boolean {
  return (
    typeof error === "object" &&
    error !== null &&
    Object.hasOwn(error, "code") &&
    (error as { code: unknown }).code === INVALID_ARGUMENT
  );
}

class CloudKmsKek implements KeyEncryptionKey {
  readonly purpose: KeyPurpose;
  readonly keyRef: string;
  readonly #client: KmsClient;
  readonly #timeoutMs: number;

  constructor(purpose: KeyPurpose, keyName: string, client: KmsClient, timeoutMs: number) {
    this.purpose = purpose;
    this.keyRef = keyName;
    this.#client = client;
    this.#timeoutMs = timeoutMs;
  }

  async wrap(dataKey: Uint8Array, context: string): Promise<WrappedKey> {
    let response;
    try {
      [response] = await withDeadline(
        this.#client.encrypt(
          {
            name: this.keyRef,
            plaintext: dataKey,
            additionalAuthenticatedData: aadFor(this.purpose, context),
          },
          { timeout: this.#timeoutMs },
        ),
        this.#timeoutMs,
      );
    } catch (cause) {
      if (cause instanceof DeadlineExceeded) {
        throw new KeyServiceError(`Cloud KMS encrypt timed out for the ${this.purpose} key`);
      }
      throw new KeyServiceError(`Cloud KMS encrypt failed for the ${this.purpose} key`, { cause });
    }
    const wrapped = toBytes(response.ciphertext);
    if (wrapped === null || wrapped.length === 0) {
      throw new KeyServiceError("Cloud KMS returned no ciphertext");
    }
    return { keyRef: this.keyRef, wrapped };
  }

  async unwrap(wrapped: WrappedKey, context: string): Promise<Uint8Array> {
    if (wrapped.keyRef !== this.keyRef) {
      throw new DecryptionError("data key was wrapped by a different key");
    }
    let response;
    try {
      [response] = await withDeadline(
        this.#client.decrypt(
          {
            name: this.keyRef,
            ciphertext: wrapped.wrapped,
            additionalAuthenticatedData: aadFor(this.purpose, context),
          },
          { timeout: this.#timeoutMs },
        ),
        this.#timeoutMs,
      );
    } catch (cause) {
      if (cause instanceof DeadlineExceeded) {
        throw new KeyServiceError(`Cloud KMS decrypt timed out for the ${this.purpose} key`);
      }
      if (isInvalidArgument(cause)) throw new DecryptionError(undefined, { cause });
      throw new KeyServiceError(`Cloud KMS decrypt failed for the ${this.purpose} key`, { cause });
    }
    const plaintext = toBytes(response.plaintext);
    if (plaintext === null || plaintext.length !== 32) {
      throw new DecryptionError("Cloud KMS returned an invalid data key");
    }
    return plaintext;
  }
}

export interface CloudKmsKeyNames {
  /** Optional until API code uses the general key (least privilege). */
  readonly general: string | null;
  readonly health: string;
}

export class CloudKmsKeyProvider implements KeyProvider {
  readonly #general: CloudKmsKek | null;
  readonly #health: CloudKmsKek;

  constructor(
    keyNames: CloudKmsKeyNames,
    client: KmsClient,
    options: { readonly callTimeoutMs?: number } = {},
  ) {
    const timeoutMs = options.callTimeoutMs ?? DEFAULT_KMS_CALL_TIMEOUT_MS;
    if (!Number.isInteger(timeoutMs) || timeoutMs < 1 || timeoutMs > 60_000) {
      throw new KeyServiceError("the KMS call timeout must be 1 to 60000 milliseconds");
    }
    if (!CRYPTO_KEY_NAME.test(keyNames.health)) {
      throw new KeyServiceError("KMS health key name is not a Cloud KMS crypto key name");
    }
    if (keyNames.general !== null && !CRYPTO_KEY_NAME.test(keyNames.general)) {
      throw new KeyServiceError("KMS general key name is not a Cloud KMS crypto key name");
    }
    if (keyNames.general === keyNames.health) {
      throw new KeyServiceError("the general and health KMS keys must differ (DAT-02)");
    }
    this.#general =
      keyNames.general === null
        ? null
        : new CloudKmsKek("general", keyNames.general, client, timeoutMs);
    this.#health = new CloudKmsKek("health", keyNames.health, client, timeoutMs);
  }

  kek(purpose: KeyPurpose): KeyEncryptionKey {
    if (purpose === "health") return this.#health;
    if (this.#general === null) {
      throw new KeyServiceError("the general KMS key is not configured");
    }
    return this.#general;
  }
}
