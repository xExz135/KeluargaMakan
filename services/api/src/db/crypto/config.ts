import { CloudKmsKeyProvider, type KmsClient } from "./cloud-kms-key-provider.js";
import { KeyServiceError, type KeyProvider } from "./key-provider.js";
import { LocalKeyProvider } from "./local-key-provider.js";

/**
 * Builds the key provider from environment variables (see services/api/.env.example):
 *
 * - `KEY_PROVIDER=local`: development and tests. `LOCAL_GENERAL_DATA_KEK` and
 *   `LOCAL_HEALTH_DATA_KEK` are two different 32-byte keys, base64-encoded.
 *   Allowed only with `APP_ENV=local` or `APP_ENV=test`; a missing or unknown
 *   `APP_ENV` counts as production and is refused.
 * - `KEY_PROVIDER=cloud_kms`: staging and production. `KMS_HEALTH_DATA_KEY` is
 *   a Cloud KMS crypto key name; the KMS client is passed in by the caller
 *   (T-023). `KMS_GENERAL_DATA_KEY` is optional: no API code uses the general
 *   key yet, so the API service account should not hold it (least privilege).
 *
 * There is no default: a missing or unknown setting stops the API from
 * starting instead of running without health-data encryption.
 */
export type KeyProviderEnv = Readonly<Record<string, string | undefined>>;

export interface KeyProviderDeps {
  readonly kmsClient?: KmsClient;
}

function required(env: KeyProviderEnv, name: string): string {
  const value = env[name];
  if (value === undefined || value.trim() === "") {
    throw new KeyServiceError(`${name} is not set`);
  }
  return value.trim();
}

function optional(env: KeyProviderEnv, name: string): string | null {
  const value = env[name];
  return value === undefined || value.trim() === "" ? null : value.trim();
}

function base64Key(env: KeyProviderEnv, name: string): Buffer {
  const text = required(env, name);
  if (!/^[A-Za-z0-9+/]{43}=$/.test(text)) {
    throw new KeyServiceError(`${name} must be a base64-encoded 32-byte key`);
  }
  return Buffer.from(text, "base64");
}

export function createKeyProvider(env: KeyProviderEnv, deps: KeyProviderDeps = {}): KeyProvider {
  const kind = required(env, "KEY_PROVIDER");
  switch (kind) {
    case "local":
      return new LocalKeyProvider(
        {
          general: base64Key(env, "LOCAL_GENERAL_DATA_KEK"),
          health: base64Key(env, "LOCAL_HEALTH_DATA_KEK"),
        },
        { appEnv: env["APP_ENV"] },
      );
    case "cloud_kms": {
      if (deps.kmsClient === undefined) {
        throw new KeyServiceError("KEY_PROVIDER=cloud_kms needs a Cloud KMS client");
      }
      return new CloudKmsKeyProvider(
        {
          general: optional(env, "KMS_GENERAL_DATA_KEY"),
          health: required(env, "KMS_HEALTH_DATA_KEY"),
        },
        deps.kmsClient,
      );
    }
    default:
      throw new KeyServiceError("KEY_PROVIDER must be local or cloud_kms");
  }
}
