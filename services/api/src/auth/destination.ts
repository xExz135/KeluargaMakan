/**
 * Normalizes a sign-in destination (ACC-01). Returns null when it is not a
 * valid phone number or email address; callers report a field error that
 * never echoes the value.
 */
export type SignInChannel = "phone" | "email";

const E164 = /^\+[1-9][0-9]{6,14}$/;
const EMAIL = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;

export function normalizeDestination(channel: SignInChannel, raw: string): string | null {
  const value = raw.trim();
  if (channel === "phone") return E164.test(value) ? value : null;
  const email = value.toLowerCase();
  return email.length >= 3 && email.length <= 254 && EMAIL.test(email) ? email : null;
}
