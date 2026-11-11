import type { DeviceInfo } from "../auth/auth-service.js";
import { canonicalDestination, type SignInChannel } from "../auth/destination.js";
import type {
  AvatarInput,
  HouseholdCreateInput,
  HouseholdUpdateInput,
  Language,
} from "../households/household-service.js";
import { BodyReader, isTimeZone, UUID_PATTERN } from "./validation.js";

/** Request body parsers, one per contract request schema. */

const LANGUAGES: readonly Language[] = ["id", "en"];
const TOKEN_PATTERN = /^[a-z0-9_]{1,32}$/;

export function parseSignInCodeRequest(body: unknown): {
  channel: SignInChannel;
  destination: string;
  language: Language;
} {
  const reader = new BodyReader();
  const record = reader.object(body, "", ["channel", "destination", "language"]);
  if (record === null) return reader.done() as never;
  const channel = reader.enumValue(record, "channel", "", ["phone", "email"] as const, true);
  const raw = reader.string(record, "destination", "", {
    required: true,
    minLength: 3,
    maxLength: 254,
  });
  const language = reader.enumValue(record, "language", "", LANGUAGES, true);
  let destination: string | null = null;
  if (channel !== undefined && typeof raw === "string") {
    destination = canonicalDestination(channel, raw);
    if (destination === null) reader.fail("/destination", "invalid_format");
  }
  reader.done();
  return { channel: channel!, destination: destination!, language: language! };
}

function parseDevice(reader: BodyReader, value: unknown, pointer: string): DeviceInfo | null {
  const record = reader.object(value, pointer, ["installationId", "platform", "appVersion"]);
  if (record === null) return null;
  const installationId = reader.string(record, "installationId", pointer, {
    required: true,
    pattern: UUID_PATTERN,
  });
  const platform = reader.enumValue(record, "platform", pointer, ["android"] as const, true);
  const appVersion = reader.string(record, "appVersion", pointer, {
    required: true,
    minLength: 1,
    maxLength: 32,
  });
  if (
    typeof installationId !== "string" ||
    platform === undefined ||
    typeof appVersion !== "string"
  ) {
    return null;
  }
  return { installationId: installationId.toLowerCase(), platform, appVersion };
}

export function parseSignInCodeVerification(body: unknown): {
  challengeId: string;
  code: string;
  device: DeviceInfo;
} {
  const reader = new BodyReader();
  const record = reader.object(body, "", ["challengeId", "code", "device"]);
  if (record === null) return reader.done() as never;
  const challengeId = reader.string(record, "challengeId", "", {
    required: true,
    pattern: UUID_PATTERN,
  });
  const code = reader.string(record, "code", "", { required: true, pattern: /^[0-9]{4,8}$/ });
  const device = Object.hasOwn(record, "device")
    ? parseDevice(reader, record["device"], "/device")
    : (reader.fail("/device", "required"), null);
  reader.done();
  return { challengeId: challengeId!.toLowerCase(), code: code!, device: device! };
}

export function parseSessionRefresh(body: unknown): { refreshToken: string } {
  const reader = new BodyReader();
  const record = reader.object(body, "", ["refreshToken"]);
  if (record === null) return reader.done() as never;
  const refreshToken = reader.string(record, "refreshToken", "", {
    required: true,
    minLength: 1,
    maxLength: 4096,
  });
  reader.done();
  return { refreshToken: refreshToken! };
}

function parseAvatar(reader: BodyReader, value: unknown, pointer: string): AvatarInput | null {
  const record = reader.object(value, pointer, ["style", "colorToken", "illustrationId"]);
  if (record === null) return null;
  const style = reader.enumValue(
    record,
    "style",
    pointer,
    ["initials", "illustration"] as const,
    true,
  );
  const colorToken = reader.string(record, "colorToken", pointer, {
    nullable: true,
    pattern: TOKEN_PATTERN,
  });
  const illustrationId = reader.string(record, "illustrationId", pointer, {
    nullable: true,
    pattern: TOKEN_PATTERN,
  });
  // PRF-01: initials on a colour, or an illustration; never both.
  if (style === "initials" && typeof illustrationId === "string") {
    reader.fail(`${pointer}/illustrationId`, "not_allowed");
  }
  if (style === "illustration" && typeof colorToken === "string") {
    reader.fail(`${pointer}/colorToken`, "not_allowed");
  }
  if (style === undefined) return null;
  return { style, colorToken: colorToken ?? null, illustrationId: illustrationId ?? null };
}

function parseTimeZone(
  reader: BodyReader,
  record: Readonly<Record<string, unknown>>,
  required: boolean,
): string | undefined {
  const value = reader.string(record, "timeZone", "", { required, minLength: 1, maxLength: 64 });
  if (typeof value !== "string") return undefined;
  if (!isTimeZone(value)) {
    reader.fail("/timeZone", "invalid_value");
    return undefined;
  }
  return value;
}

export function parseHouseholdCreate(body: unknown): HouseholdCreateInput {
  const reader = new BodyReader();
  const record = reader.object(body, "", [
    "name",
    "city",
    "timeZone",
    "language",
    "managerProfile",
  ]);
  if (record === null) return reader.done() as never;
  const name = reader.string(record, "name", "", { minLength: 1, maxLength: 60 });
  const city = reader.string(record, "city", "", { minLength: 1, maxLength: 80 });
  const timeZone = parseTimeZone(reader, record, true);
  const language = reader.enumValue(record, "language", "", LANGUAGES, true);
  let manager: HouseholdCreateInput["managerProfile"] | null = null;
  if (!Object.hasOwn(record, "managerProfile")) {
    reader.fail("/managerProfile", "required");
  } else {
    const profile = reader.object(record["managerProfile"], "/managerProfile", ["name", "avatar"]);
    if (profile !== null) {
      const profileName = reader.string(profile, "name", "/managerProfile", {
        required: true,
        minLength: 1,
        maxLength: 30,
      });
      const avatar = Object.hasOwn(profile, "avatar")
        ? parseAvatar(reader, profile["avatar"], "/managerProfile/avatar")
        : null;
      if (typeof profileName === "string") manager = { name: profileName, avatar };
    }
  }
  reader.done();
  return {
    name: name ?? null,
    city: city ?? null,
    timeZone: timeZone!,
    language: language!,
    managerProfile: manager!,
  };
}

export function parseHouseholdUpdate(body: unknown): HouseholdUpdateInput {
  const reader = new BodyReader();
  const record = reader.object(body, "", ["name", "city", "timeZone", "language"]);
  if (record === null) return reader.done() as never;
  if (Object.keys(record).length === 0) reader.fail("", "required");
  const name = reader.string(record, "name", "", { nullable: true, minLength: 1, maxLength: 60 });
  const city = reader.string(record, "city", "", { nullable: true, minLength: 1, maxLength: 80 });
  const timeZone = parseTimeZone(reader, record, false);
  const language = reader.enumValue(record, "language", "", LANGUAGES, false);
  reader.done();
  return {
    ...(name === undefined ? {} : { name }),
    ...(city === undefined ? {} : { city }),
    ...(timeZone === undefined ? {} : { timeZone }),
    ...(language === undefined ? {} : { language }),
  };
}

export function parseIdempotencyKey(header: unknown): string | null {
  if (header === undefined) return null;
  const reader = new BodyReader();
  if (typeof header !== "string" || !UUID_PATTERN.test(header)) {
    reader.fail("/headers/Idempotency-Key", "invalid_format");
  }
  reader.done();
  return (header as string).toLowerCase();
}
