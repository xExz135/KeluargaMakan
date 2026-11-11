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

export interface KmsClient {
  encrypt(request: {
    name: string;
    plaintext: Uint8Array;
    additionalAuthenticatedData: Uint8Array;
  }): Promise<readonly [{ ciphertext?: Bytes }, ...unknown[]]>;
  decrypt(request: {
    name: string;
    ciphertext: Uint8Array;
    additionalAuthenticatedData: Uint8Array;
  }): Promise<readonly [{ plaintext?: Bytes }, ...unknown[]]>;
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

  constructor(purpose: KeyPurpose, keyName: string, client: KmsClient) {
    this.purpose = purpose;
    this.keyRef = keyName;
    this.#client = client;
  }

  async wrap(dataKey: Uint8Array, context: string): Promise<WrappedKey> {
    let response;
    try {
      [response] = await this.#client.encrypt({
        name: this.keyRef,
        plaintext: dataKey,
        additionalAuthenticatedData: aadFor(this.purpose, context),
      });
    } catch (cause) {
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
      [response] = await this.#client.decrypt({
        name: this.keyRef,
        ciphertext: wrapped.wrapped,
        additionalAuthenticatedData: aadFor(this.purpose, context),
      });
    } catch (cause) {
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
  readonly general: string;
  readonly health: string;
}

export class CloudKmsKeyProvider implements KeyProvider {
  readonly #keks: Record<KeyPurpose, CloudKmsKek>;

  constructor(keyNames: CloudKmsKeyNames, client: KmsClient) {
    for (const purpose of ["general", "health"] as const) {
      if (!CRYPTO_KEY_NAME.test(keyNames[purpose])) {
        throw new KeyServiceError(`KMS ${purpose} key name is not a Cloud KMS crypto key name`);
      }
    }
    if (keyNames.general === keyNames.health) {
      throw new KeyServiceError("the general and health KMS keys must differ (DAT-02)");
    }
    this.#keks = {
      general: new CloudKmsKek("general", keyNames.general, client),
      health: new CloudKmsKek("health", keyNames.health, client),
    };
  }

  kek(purpose: KeyPurpose): KeyEncryptionKey {
    return this.#keks[purpose];
  }
}
