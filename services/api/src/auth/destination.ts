import { domainToASCII } from "node:url";

/**
 * ACC-01 sign-in destinations (security review T-017 L1).
 *
 * `canonicalDestination` gives the one stored and delivered form of a phone
 * number or email address, so the same destination written differently is
 * the same account and the same challenge:
 * - phone: E.164, separators removed, digits only; a trunk `0` after `+62`
 *   is dropped (`+620812…` becomes `+62812…`).
 * - email: NFC, lower case, the domain in ASCII (punycode) without a
 *   trailing dot. Gmail dots and `+tags` are kept: they are part of the
 *   address the user owns, so folding them would change who an account is.
 *
 * Control characters (C0, C1, DEL), bidi controls and zero-width characters
 * are refused anywhere, and an email's local part must be printable ASCII (no
 * look-alike letters from other scripts). Refused input returns null and the
 * caller answers 400 without echoing it.
 *
 * `destinationRateKey` is stricter and only keys rate limits: it also folds
 * `+tags` for every domain and dots for Gmail, so one mailbox cannot get more
 * codes or guesses by spelling itself differently. Two different people can
 * at worst share a limit. It is never stored, delivered to or used to find an
 * account.
 */
export type SignInChannel = "phone" | "email";

// C0 and C1 controls, DEL, Arabic letter mark, zero-width space and joiners,
// bidi marks, embeddings, overrides and isolates, and the BOM.
function isForbidden(codePoint: number): boolean {
  return (
    codePoint <= 0x1f ||
    (codePoint >= 0x7f && codePoint <= 0x9f) ||
    codePoint === 0x061c ||
    (codePoint >= 0x200b && codePoint <= 0x200f) ||
    (codePoint >= 0x202a && codePoint <= 0x202e) ||
    (codePoint >= 0x2066 && codePoint <= 0x2069) ||
    codePoint === 0xfeff
  );
}

function hasForbidden(value: string): boolean {
  for (const char of value) if (isForbidden(char.codePointAt(0) ?? 0)) return true;
  return false;
}

const PHONE_SEPARATORS = /[\s().-]/g;
const E164 = /^\+[1-9][0-9]{6,14}$/;
const LOCAL_PART = /^[A-Za-z0-9!#$%&'*+/=?^_`{|}~.-]{1,64}$/;
const DOMAIN = /^(?=.{1,253}$)(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z0-9-]{2,63}$/;

function canonicalPhone(raw: string): string | null {
  let value = raw.replace(PHONE_SEPARATORS, "");
  if (value.startsWith("+620")) value = `+62${value.slice(4)}`;
  return E164.test(value) ? value : null;
}

function canonicalEmail(raw: string): string | null {
  const value = raw.normalize("NFC");
  const at = value.lastIndexOf("@");
  if (at <= 0 || at === value.length - 1) return null;
  const local = value.slice(0, at);
  let domain = value.slice(at + 1).toLowerCase();
  if (domain.endsWith(".")) domain = domain.slice(0, -1);
  if (!LOCAL_PART.test(local) || local.startsWith(".") || local.endsWith(".")) return null;
  if (local.includes("..")) return null;
  const ascii = domainToASCII(domain);
  if (ascii === "" || !DOMAIN.test(ascii)) return null;
  const email = `${local.toLowerCase()}@${ascii}`;
  return email.length <= 254 ? email : null;
}

/** The stored form of a destination, or null when it is not valid. */
export function canonicalDestination(channel: SignInChannel, raw: string): string | null {
  const value = raw.trim();
  if (value === "" || value.length > 254 || hasForbidden(value)) return null;
  return channel === "phone" ? canonicalPhone(value) : canonicalEmail(value);
}

const GMAIL_DOMAINS = new Set(["gmail.com", "googlemail.com"]);

/** The rate-limit key for a canonical destination (see the module comment). */
export function destinationRateKey(channel: SignInChannel, canonical: string): string {
  if (channel === "phone") return `phone:${canonical}`;
  const at = canonical.lastIndexOf("@");
  let local = canonical.slice(0, at);
  let domain = canonical.slice(at + 1);
  const plus = local.indexOf("+");
  if (plus > 0) local = local.slice(0, plus);
  if (GMAIL_DOMAINS.has(domain)) {
    local = local.replaceAll(".", "");
    domain = "gmail.com";
  }
  return `email:${local}@${domain}`;
}
