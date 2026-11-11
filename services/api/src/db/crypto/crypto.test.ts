import { createCipheriv, createDecipheriv, randomBytes } from "node:crypto";

import { describe, expect, it } from "vitest";

import { CloudKmsKeyProvider, type KmsClient } from "./cloud-kms-key-provider.js";
import { createKeyProvider } from "./config.js";
import { decryptField, encryptField } from "./data-key-cipher.js";
import { DecryptionError, KeyServiceError } from "./key-provider.js";
import { LocalKeyProvider } from "./local-key-provider.js";

const keys = () => ({ general: randomBytes(32), health: randomBytes(32) });
const dataKey = () => randomBytes(32);

describe("DAT-02 local key provider", () => {
  it("DAT-02 wraps and unwraps a data key with the health key", async () => {
    const provider = new LocalKeyProvider(keys(), { appEnv: "test" });
    const dek = dataKey();
    const wrapped = await provider.kek("health").wrap(dek, "ctx");
    expect(Buffer.from(await provider.kek("health").unwrap(wrapped, "ctx"))).toEqual(dek);
  });

  it("DAT-02 the general key cannot unwrap a health data key", async () => {
    const provider = new LocalKeyProvider(keys(), { appEnv: "test" });
    const wrapped = await provider.kek("health").wrap(dataKey(), "ctx");
    await expect(provider.kek("general").unwrap(wrapped, "ctx")).rejects.toBeInstanceOf(
      DecryptionError,
    );
  });

  it("DAT-02 the general key cannot unwrap it even when the stored key reference and purpose byte are forged", async () => {
    const provider = new LocalKeyProvider(keys(), { appEnv: "test" });
    const general = provider.kek("general");
    const wrapped = await provider.kek("health").wrap(dataKey(), "ctx");
    const forged = Buffer.from(wrapped.wrapped);
    forged[1] = 0x01; // claim the general purpose
    await expect(
      general.unwrap({ keyRef: general.keyRef, wrapped: forged }, "ctx"),
    ).rejects.toBeInstanceOf(DecryptionError);
  });

  it("DAT-02 the raw general key material cannot decrypt health ciphertext", () => {
    // Bypasses every check in the provider: AES-GCM with the wrong key fails.
    const material = keys();
    const dek = dataKey();
    const health = new LocalKeyProvider(material, { appEnv: "test" }).kek("health");
    return health.wrap(dek, "ctx").then((wrapped) => {
      const bytes = Buffer.from(wrapped.wrapped);
      const iv = bytes.subarray(2, 14);
      const tag = bytes.subarray(14, 30);
      const decipher = createDecipheriv("aes-256-gcm", material.general, iv);
      decipher.setAAD(Buffer.from("keluargamakan.kek.v1|health|ctx"));
      decipher.setAuthTag(tag);
      decipher.update(bytes.subarray(30));
      expect(() => decipher.final()).toThrow();
    });
  });

  it("DAT-02 a wrapped key only unwraps in its own context", async () => {
    const provider = new LocalKeyProvider(keys(), { appEnv: "test" });
    const wrapped = await provider.kek("health").wrap(dataKey(), "member-a");
    await expect(provider.kek("health").unwrap(wrapped, "member-b")).rejects.toBeInstanceOf(
      DecryptionError,
    );
  });

  it("DAT-02 a different health key cannot unwrap the data key", async () => {
    const wrapped = await new LocalKeyProvider(keys(), { appEnv: "test" })
      .kek("health")
      .wrap(dataKey(), "ctx");
    const other = new LocalKeyProvider(keys(), { appEnv: "test" }).kek("health");
    await expect(
      other.unwrap({ keyRef: other.keyRef, wrapped: wrapped.wrapped }, "ctx"),
    ).rejects.toBeInstanceOf(DecryptionError);
    await expect(other.unwrap(wrapped, "ctx")).rejects.toBeInstanceOf(DecryptionError);
  });

  it("DAT-02 rejects truncated or unknown wrapped keys", async () => {
    const health = new LocalKeyProvider(keys(), { appEnv: "test" }).kek("health");
    await expect(
      health.unwrap({ keyRef: health.keyRef, wrapped: Buffer.from([1, 2, 3]) }, "ctx"),
    ).rejects.toBeInstanceOf(DecryptionError);
    const wrapped = await health.wrap(dataKey(), "ctx");
    const tampered = Buffer.from(wrapped.wrapped);
    tampered[0] = 0x09;
    await expect(
      health.unwrap({ keyRef: health.keyRef, wrapped: tampered }, "ctx"),
    ).rejects.toBeInstanceOf(DecryptionError);
  });

  it("DAT-02 M1 refuses the same key for both purposes, wrong key sizes, and any APP_ENV but local or test", () => {
    const same = randomBytes(32);
    expect(
      () => new LocalKeyProvider({ general: same, health: Buffer.from(same) }, { appEnv: "test" }),
    ).toThrow(KeyServiceError);
    expect(
      () =>
        new LocalKeyProvider(
          { general: randomBytes(16), health: randomBytes(32) },
          { appEnv: "test" },
        ),
    ).toThrow(/32 bytes/);
    for (const appEnv of [undefined, "", "production", "staging", "Local", "prod"]) {
      expect(() => new LocalKeyProvider(keys(), { appEnv }), String(appEnv)).toThrow(/APP_ENV/);
    }
    expect(() => new LocalKeyProvider(keys(), { appEnv: "local" })).not.toThrow();
  });

  it("DAT-02 key references name the purpose but no key material", () => {
    const material = keys();
    const provider = new LocalKeyProvider(material, { appEnv: "test" });
    expect(provider.kek("health").keyRef).toMatch(/^local:health:[0-9a-f]{16}$/);
    expect(provider.kek("general").keyRef).toMatch(/^local:general:[0-9a-f]{16}$/);
    expect(provider.kek("health").keyRef).not.toContain(
      material.health.toString("hex").slice(0, 16),
    );
  });
});

describe("DAT-02 field encryption", () => {
  it("round-trips and binds the ciphertext to its row context", () => {
    const dek = dataKey();
    const blob = encryptField(dek, '{"type":"allergy"}', "hard_rule:1:a:h");
    expect(blob.toString("utf8")).not.toContain("allergy");
    expect(decryptField(dek, blob, "hard_rule:1:a:h")).toBe('{"type":"allergy"}');
    expect(() => decryptField(dek, blob, "hard_rule:2:a:h")).toThrow(DecryptionError);
    expect(() => decryptField(dataKey(), blob, "hard_rule:1:a:h")).toThrow(DecryptionError);
  });

  it("rejects tampered and truncated ciphertext", () => {
    const dek = dataKey();
    const blob = encryptField(dek, "x", "c");
    const flipped = Buffer.from(blob);
    flipped[flipped.length - 1] = (flipped[flipped.length - 1] ?? 0) ^ 0xff;
    expect(() => decryptField(dek, flipped, "c")).toThrow(DecryptionError);
    expect(() => decryptField(dek, blob.subarray(0, 10), "c")).toThrow(DecryptionError);
  });

  it("uses a fresh IV every time", () => {
    const dek = dataKey();
    expect(encryptField(dek, "same", "c").equals(encryptField(dek, "same", "c"))).toBe(false);
  });
});

/** In-memory stand-in for Cloud KMS: one AES key per crypto key name. */
function fakeKms(names: readonly string[]): KmsClient & { calls: string[]; failNext?: Error } {
  const material = new Map(names.map((name) => [name, randomBytes(32)]));
  const fake: KmsClient & { calls: string[]; failNext?: Error } = {
    calls: [],
    encrypt(request) {
      fake.calls.push(`encrypt ${request.name}`);
      const key = material.get(request.name);
      if (key === undefined)
        return Promise.reject(Object.assign(new Error("not found"), { code: 5 }));
      const iv = randomBytes(12);
      const cipher = createCipheriv("aes-256-gcm", key, iv);
      cipher.setAAD(request.additionalAuthenticatedData);
      const ct = Buffer.concat([cipher.update(request.plaintext), cipher.final()]);
      return Promise.resolve([
        { ciphertext: Buffer.concat([iv, cipher.getAuthTag(), ct]) },
      ] as const);
    },
    decrypt(request) {
      fake.calls.push(`decrypt ${request.name}`);
      if (fake.failNext !== undefined) {
        const error = fake.failNext;
        delete fake.failNext;
        return Promise.reject(error);
      }
      const key = material.get(request.name);
      if (key === undefined)
        return Promise.reject(Object.assign(new Error("not found"), { code: 5 }));
      try {
        const bytes = Buffer.from(request.ciphertext);
        const decipher = createDecipheriv("aes-256-gcm", key, bytes.subarray(0, 12));
        decipher.setAAD(request.additionalAuthenticatedData);
        decipher.setAuthTag(bytes.subarray(12, 28));
        const plaintext = Buffer.concat([decipher.update(bytes.subarray(28)), decipher.final()]);
        return Promise.resolve([{ plaintext }] as const);
      } catch {
        return Promise.reject(Object.assign(new Error("Decryption failed"), { code: 3 }));
      }
    },
  };
  return fake;
}

const KMS_NAMES = {
  general:
    "projects/example-project/locations/asia-southeast2/keyRings/test/cryptoKeys/general-data",
  health: "projects/example-project/locations/asia-southeast2/keyRings/test/cryptoKeys/health-data",
};

describe("DAT-02 Cloud KMS key provider (fake client)", () => {
  it("DAT-02 wraps health data keys with the health crypto key only", async () => {
    const kms = fakeKms([KMS_NAMES.general, KMS_NAMES.health]);
    const provider = new CloudKmsKeyProvider(KMS_NAMES, kms);
    const dek = dataKey();
    const wrapped = await provider.kek("health").wrap(dek, "ctx");
    expect(wrapped.keyRef).toBe(KMS_NAMES.health);
    expect(Buffer.from(await provider.kek("health").unwrap(wrapped, "ctx"))).toEqual(dek);
    expect(kms.calls).toEqual([`encrypt ${KMS_NAMES.health}`, `decrypt ${KMS_NAMES.health}`]);
  });

  it("DAT-02 the general crypto key cannot unwrap a health data key", async () => {
    const kms = fakeKms([KMS_NAMES.general, KMS_NAMES.health]);
    const provider = new CloudKmsKeyProvider(KMS_NAMES, kms);
    const wrapped = await provider.kek("health").wrap(dataKey(), "ctx");
    const general = provider.kek("general");
    await expect(general.unwrap(wrapped, "ctx")).rejects.toBeInstanceOf(DecryptionError);
    await expect(
      general.unwrap({ keyRef: general.keyRef, wrapped: wrapped.wrapped }, "ctx"),
    ).rejects.toBeInstanceOf(DecryptionError);
  });

  it("DAT-02 a KMS outage is a key service error, never an empty result", async () => {
    const kms = fakeKms([KMS_NAMES.general, KMS_NAMES.health]);
    const provider = new CloudKmsKeyProvider(KMS_NAMES, kms);
    const wrapped = await provider.kek("health").wrap(dataKey(), "ctx");
    kms.failNext = Object.assign(new Error("unavailable"), { code: 14 });
    await expect(provider.kek("health").unwrap(wrapped, "ctx")).rejects.toBeInstanceOf(
      KeyServiceError,
    );
  });

  it("DAT-02 refuses identical or malformed key names", () => {
    const kms = fakeKms([]);
    expect(
      () => new CloudKmsKeyProvider({ general: KMS_NAMES.health, health: KMS_NAMES.health }, kms),
    ).toThrow(/must differ/);
    expect(
      () => new CloudKmsKeyProvider({ general: "general", health: KMS_NAMES.health }, kms),
    ).toThrow(/general key name/);
    expect(() => new CloudKmsKeyProvider({ ...KMS_NAMES, health: "health" }, kms)).toThrow(
      KeyServiceError,
    );
  });
});

describe("DAT-02 L3 the general KMS key is optional (least privilege)", () => {
  it("serves the health key without a general key, and refuses general use", async () => {
    const provider = new CloudKmsKeyProvider(
      { general: null, health: KMS_NAMES.health },
      fakeKms([KMS_NAMES.health]),
    );
    const dek = dataKey();
    const wrapped = await provider.kek("health").wrap(dek, "ctx");
    expect(Buffer.from(await provider.kek("health").unwrap(wrapped, "ctx"))).toEqual(dek);
    expect(() => provider.kek("general")).toThrow(KeyServiceError);
  });

  it("createKeyProvider does not require KMS_GENERAL_DATA_KEY", () => {
    const provider = createKeyProvider(
      { KEY_PROVIDER: "cloud_kms", KMS_HEALTH_DATA_KEY: KMS_NAMES.health },
      { kmsClient: fakeKms([KMS_NAMES.health]) },
    );
    expect(provider.kek("health").keyRef).toBe(KMS_NAMES.health);
    expect(() => provider.kek("general")).toThrow(/not configured/);
  });
});

describe("DAT-02 key provider configuration", () => {
  const b64 = () => randomBytes(32).toString("base64");

  it("builds the local provider from environment variables", () => {
    const provider = createKeyProvider({
      KEY_PROVIDER: "local",
      APP_ENV: "local",
      LOCAL_GENERAL_DATA_KEK: b64(),
      LOCAL_HEALTH_DATA_KEK: b64(),
    });
    expect(provider.kek("health").purpose).toBe("health");
  });

  it("has no default and no fallback without encryption", () => {
    expect(() => createKeyProvider({})).toThrow(/KEY_PROVIDER is not set/);
    expect(() => createKeyProvider({ KEY_PROVIDER: "none" })).toThrow(/local or cloud_kms/);
    expect(() =>
      createKeyProvider({ KEY_PROVIDER: "local", APP_ENV: "test", LOCAL_GENERAL_DATA_KEK: b64() }),
    ).toThrow(/LOCAL_HEALTH_DATA_KEK is not set/);
    expect(() =>
      createKeyProvider({
        KEY_PROVIDER: "local",
        APP_ENV: "test",
        LOCAL_GENERAL_DATA_KEK: b64(),
        LOCAL_HEALTH_DATA_KEK: "short",
      }),
    ).toThrow(/32-byte/);
    expect(() =>
      createKeyProvider({
        KEY_PROVIDER: "local",
        NODE_ENV: "development",
        LOCAL_GENERAL_DATA_KEK: b64(),
        LOCAL_HEALTH_DATA_KEK: b64(),
      }),
    ).toThrow(/APP_ENV/);
    expect(() =>
      createKeyProvider({
        KEY_PROVIDER: "local",
        APP_ENV: "staging",
        LOCAL_GENERAL_DATA_KEK: b64(),
        LOCAL_HEALTH_DATA_KEK: b64(),
      }),
    ).toThrow(/APP_ENV/);
  });

  it("needs a KMS client and both KMS key names for cloud_kms", () => {
    expect(() =>
      createKeyProvider({
        KEY_PROVIDER: "cloud_kms",
        KMS_GENERAL_DATA_KEY: KMS_NAMES.general,
        KMS_HEALTH_DATA_KEY: KMS_NAMES.health,
      }),
    ).toThrow(/client/);
    const provider = createKeyProvider(
      {
        KEY_PROVIDER: "cloud_kms",
        KMS_GENERAL_DATA_KEY: KMS_NAMES.general,
        KMS_HEALTH_DATA_KEY: KMS_NAMES.health,
      },
      { kmsClient: fakeKms([]) },
    );
    expect(provider.kek("health").keyRef).toBe(KMS_NAMES.health);
  });
});
