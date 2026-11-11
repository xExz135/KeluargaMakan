import { validationFailed, type FieldError } from "../api-error.js";

/**
 * Small validators for request bodies, following the contract schemas
 * (`additionalProperties: false`, lengths, patterns, enums). Field errors
 * name the JSON Pointer and a code, never the submitted value.
 */
export class BodyReader {
  readonly errors: FieldError[] = [];

  fail(pointer: string, code: FieldError["code"]): void {
    this.errors.push({ pointer, code });
  }

  /** Throws `validation_failed` when any field error was recorded. */
  done(): void {
    if (this.errors.length > 0) throw validationFailed(this.errors);
  }

  /** An object with only the allowed keys; reports `invalid_type` or `not_allowed`. */
  object(
    value: unknown,
    pointer: string,
    allowed: readonly string[],
  ): Readonly<Record<string, unknown>> | null {
    if (typeof value !== "object" || value === null || Array.isArray(value)) {
      this.fail(pointer === "" ? "" : pointer, value === undefined ? "required" : "invalid_type");
      return null;
    }
    const record = value as Record<string, unknown>;
    for (const key of Object.keys(record)) {
      if (!allowed.includes(key)) this.fail(`${pointer}/${escapePointer(key)}`, "not_allowed");
    }
    return record;
  }

  string(
    record: Readonly<Record<string, unknown>>,
    key: string,
    pointer: string,
    rules: {
      readonly required?: boolean;
      readonly nullable?: boolean;
      readonly minLength?: number;
      readonly maxLength?: number;
      readonly pattern?: RegExp;
    },
  ): string | null | undefined {
    const at = `${pointer}/${key}`;
    if (!Object.hasOwn(record, key)) {
      if (rules.required === true) this.fail(at, "required");
      return undefined;
    }
    const value = record[key];
    if (value === null && rules.nullable === true) return null;
    if (typeof value !== "string") {
      this.fail(at, "invalid_type");
      return undefined;
    }
    const length = [...value].length;
    if (rules.minLength !== undefined && length < rules.minLength) {
      this.fail(at, "too_short");
      return undefined;
    }
    if (rules.maxLength !== undefined && length > rules.maxLength) {
      this.fail(at, "too_long");
      return undefined;
    }
    if (rules.pattern !== undefined && !rules.pattern.test(value)) {
      this.fail(at, "invalid_format");
      return undefined;
    }
    return value;
  }

  enumValue<T extends string>(
    record: Readonly<Record<string, unknown>>,
    key: string,
    pointer: string,
    values: readonly T[],
    required: boolean,
  ): T | undefined {
    const at = `${pointer}/${key}`;
    if (!Object.hasOwn(record, key)) {
      if (required) this.fail(at, "required");
      return undefined;
    }
    const value = record[key];
    if (typeof value !== "string") {
      this.fail(at, "invalid_type");
      return undefined;
    }
    if (!(values as readonly string[]).includes(value)) {
      this.fail(at, "invalid_value");
      return undefined;
    }
    return value as T;
  }
}

function escapePointer(key: string): string {
  // Keys are reported, values never are. Keep pointers short and printable.
  const safe = key.length > 64 ? key.slice(0, 64) : key;
  return safe.replaceAll("~", "~0").replaceAll("/", "~1");
}

export const UUID_PATTERN =
  /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/;

/** IANA time zone names the runtime knows (NFR-16). */
export function isTimeZone(value: string): boolean {
  try {
    new Intl.DateTimeFormat("en-US", { timeZone: value });
    return true;
  } catch {
    return false;
  }
}
