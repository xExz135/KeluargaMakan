import { isIP, isIPv4, isIPv6 } from "node:net";

import { isDevelopmentEnv, resolveAppEnv } from "../app-env.js";

/**
 * Client addresses for the sign-in rate limits (security review T-017 H1).
 *
 * Behind a load balancer the socket address is the balancer's, and the real
 * client is in `X-Forwarded-For`. Only hops listed in `TRUSTED_PROXY_CIDRS`
 * are skipped: Fastify walks the header from the right and stops at the first
 * address that is not a trusted proxy, so an entry written by the client
 * itself (on the left) is never used. Trusting every hop is refused outside
 * `APP_ENV` local and test.
 */
export class TrustedProxyConfigError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "TrustedProxyConfigError";
  }
}

const TRUST_ALL = new Set(["true", "*", "all"]);

/**
 * Parses `TRUSTED_PROXY_CIDRS` (comma-separated IP addresses or CIDR ranges).
 * Empty means no proxy is trusted and the socket address is the client.
 * Returns `true` (trust every hop) only for a trust-all value in local or test.
 */
export function parseTrustedProxies(
  value: string | undefined,
  appEnv: string | undefined,
): readonly string[] | true {
  const entries = (value ?? "")
    .split(",")
    .map((entry) => entry.trim())
    .filter((entry) => entry !== "");
  const ranges: string[] = [];
  let trustAll = false;
  for (const entry of entries) {
    if (TRUST_ALL.has(entry.toLowerCase())) {
      trustAll = true;
      continue;
    }
    const [address = "", prefix, ...rest] = entry.split("/");
    const family = isIP(address);
    const max = family === 4 ? 32 : 128;
    const bits = prefix === undefined ? max : Number(prefix);
    if (
      family === 0 ||
      rest.length > 0 ||
      (prefix !== undefined && !/^[0-9]{1,3}$/.test(prefix)) ||
      bits > max
    ) {
      throw new TrustedProxyConfigError(
        "TRUSTED_PROXY_CIDRS must list IP addresses or CIDR ranges",
      );
    }
    if (bits === 0) trustAll = true;
    else ranges.push(prefix === undefined ? address : `${address}/${bits}`);
  }
  if (trustAll) {
    if (!isDevelopmentEnv(appEnv)) {
      throw new TrustedProxyConfigError(
        `Trusting every proxy hop is refused in APP_ENV ${resolveAppEnv(appEnv)}; list the load balancer ranges`,
      );
    }
    return true;
  }
  return ranges;
}

function expandIPv6(address: string): number[] | null {
  let text = address;
  // An embedded IPv4 tail (`::ffff:192.0.2.1`) becomes two hex groups.
  const lastColon = text.lastIndexOf(":");
  const tail = text.slice(lastColon + 1);
  if (isIPv4(tail)) {
    const [a = 0, b = 0, c = 0, d = 0] = tail.split(".").map(Number);
    text = `${text.slice(0, lastColon + 1)}${((a << 8) | b).toString(16)}:${((c << 8) | d).toString(16)}`;
  }
  const halves = text.split("::");
  if (halves.length > 2) return null;
  const parse = (part: string | undefined) =>
    part === undefined || part === "" ? [] : part.split(":").map((group) => parseInt(group, 16));
  const head = parse(halves[0]);
  const rest = halves.length === 2 ? parse(halves[1]) : [];
  const fill = 8 - head.length - rest.length;
  if (fill < 0 || (halves.length === 1 && fill !== 0)) return null;
  const groups = [...head, ...new Array<number>(fill).fill(0), ...rest];
  return groups.every((g) => Number.isInteger(g) && g >= 0 && g <= 0xffff) ? groups : null;
}

/**
 * The rate-limit key for a client address: an IPv4 address as is (an
 * IPv4-mapped IPv6 address counts as IPv4), and an IPv6 address by its /64,
 * since one subscriber usually holds a whole /64.
 */
export function clientRateKey(address: string): string {
  const zone = address.indexOf("%");
  const ip = (zone >= 0 ? address.slice(0, zone) : address).trim().toLowerCase();
  if (isIPv4(ip)) return `v4:${ip}`;
  if (!isIPv6(ip)) return `unknown:${ip.slice(0, 64)}`;
  const groups = expandIPv6(ip);
  if (groups === null) return `unknown:${ip.slice(0, 64)}`;
  const [g0, g1, g2, g3, g4, g5, g6 = 0, g7 = 0] = groups;
  if (g0 === 0 && g1 === 0 && g2 === 0 && g3 === 0 && g4 === 0 && g5 === 0xffff) {
    return `v4:${g6 >> 8}.${g6 & 0xff}.${g7 >> 8}.${g7 & 0xff}`;
  }
  return `v6:${groups
    .slice(0, 4)
    .map((g) => g.toString(16))
    .join(":")}::/64`;
}
