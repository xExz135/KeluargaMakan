#!/usr/bin/env node
// Safety word check (NFR-14, SAF-04, INT-03; owner decision 2026-11-11,
// QUESTIONS #41). Scans the app's ARB string files against the banned safety
// wording of docs/design/system/safety-badges.md v1.0 section 5, mirrored in
// scripts/safety-words/banned-words.json. Fails on:
//   - a softening word on a Not safe string (Tidak aman / Not safe)
//   - a softening word on a Cek label string (Cek label / Check the label),
//     except the data phrases the page allows there ("belum pasti",
//     "bisa mengandung", "may contain")
//   - an inflating word on a Safe string
//   - an override word on any safety string
//   - a safety state word ("aman", "cek", "safe", "check the label") used
//     outside the Cek Aman surfaces ("Cek Aman", the feature name, is fine)
//   - an exclamation mark, all caps, emoji or a health claim in badge text
//   - invisible characters, non-Latin letters or broken ICU syntax, which
//     could hide a banned word from this check
// Matching is case-insensitive, NFKC-normalized, ignores diacritics and
// zero-width characters, strips ICU placeholders, checks every plural and
// select branch, and uses whole-word boundaries (Indonesian particles -nya,
// -lah, -kah and -pun are part of the word).
//
// Usage: node scripts/check-safety-words.mjs [file.arb | dir ...]
// With no arguments it scans apps/mobile/lib/l10n/*.arb.

import { readdirSync, readFileSync, statSync } from "node:fs";
import { basename, dirname, join, relative } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const REPO_ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
export const WORD_LIST_PATH = join(REPO_ROOT, "scripts/safety-words/banned-words.json");
export const ALLOWLIST_PATH = join(REPO_ROOT, "scripts/safety-words/allowlist.json");
export const DEFAULT_TARGETS = [join(REPO_ROOT, "apps/mobile/lib/l10n")];

export const RULES = {
  "softener-not-safe": "softening word on a Not safe (Tidak aman) string",
  "softener-check-label": "softening word on a Cek label (Check the label) string",
  "inflation-safe": "inflating word on a Safe (Aman) string",
  "override-in-safety-string": "override word on a safety string",
  "state-word-outside-cek-aman": "safety state word used outside the Cek Aman surfaces",
  "badge-format": "exclamation mark, all caps or emoji in badge text",
  "health-claim-in-badge": "health claim in badge text",
  "invisible-character": "invisible or bidirectional control character",
  "non-latin-letter": "letter outside the Latin script (can disguise a banned word)",
  "icu-syntax": "ICU message syntax the check cannot read",
  "invalid-value": "ARB string value is not a string",
};

// Rules an allowlist entry may suppress. The softener, inflation, badge and
// syntax rules can never be allowlisted, and an override word can never be
// allowlisted on a string that carries Tidak aman or Cek label.
export const ALLOWLISTABLE_RULES = new Set([
  "state-word-outside-cek-aman",
  "override-in-safety-string",
  "non-latin-letter",
]);

const MAX_VARIANTS = 256;
const MIN_REASON_LENGTH = 20;

// ---------- word list ----------

const isStringArray = (v) =>
  Array.isArray(v) && v.length > 0 && v.every((s) => typeof s === "string" && s.trim() !== "");

const KEY_PATTERN = /^[a-z][A-Za-z0-9]*(\.[A-Za-z0-9]+)*(\.\*|\*)?$/;

/**
 * Checks the shape of banned-words.json. Throws on anything unexpected so a
 * broken list fails the build instead of silently checking nothing.
 */
export function validateWordList(list) {
  const errors = [];
  const expectKeys = (obj, path, keys) => {
    if (!obj || typeof obj !== "object" || Array.isArray(obj)) {
      errors.push(`${path} must be an object`);
      return false;
    }
    const extra = Object.keys(obj).filter((k) => !keys.includes(k) && k !== "$comment");
    const missing = keys.filter((k) => !(k in obj));
    if (extra.length) errors.push(`${path} has unexpected fields: ${extra.join(", ")}`);
    if (missing.length) errors.push(`${path} is missing fields: ${missing.join(", ")}`);
    return true;
  };
  const words = (v, path) => {
    if (!isStringArray(v)) errors.push(`${path} must be a non-empty list of words`);
  };
  const keys = (v, path) => {
    if (!isStringArray(v) || !v.every((k) => KEY_PATTERN.test(k))) {
      errors.push(`${path} must be a non-empty list of copy-deck key patterns`);
    }
  };

  if (expectKeys(list, "word list", ["schema", "source", "doc", "derived"])) {
    if (list.schema !== "keluargamakan.safety-words/1") {
      errors.push(
        `schema must be "keluargamakan.safety-words/1", got ${JSON.stringify(list.schema)}`,
      );
    }
    expectKeys(list.source, "source", ["document", "version", "section"]);
    const doc = list.doc;
    if (
      expectKeys(doc, "doc", [
        "softeners",
        "inflation",
        "overrides",
        "softenerKeys",
        "inflationKeys",
        "overrideKeys",
        "allowedInCheckLabel",
        "stateWordsNotForOtherUse",
        "badgeHealthClaims",
      ])
    ) {
      for (const f of [
        "softeners",
        "inflation",
        "overrides",
        "allowedInCheckLabel",
        "stateWordsNotForOtherUse",
        "badgeHealthClaims",
      ]) {
        words(doc[f], `doc.${f}`);
      }
      for (const f of ["softenerKeys", "inflationKeys", "overrideKeys"]) keys(doc[f], `doc.${f}`);
    }
    const derived = list.derived;
    if (
      expectKeys(derived, "derived", [
        "stateWords",
        "featureNames",
        "stateWordsNotForOtherUse",
        "notSafeKeys",
        "checkLabelKeys",
        "cekAmanSurfaceKeys",
        "badgeKeys",
      ])
    ) {
      if (expectKeys(derived.stateWords, "derived.stateWords", ["safe", "notSafe", "checkLabel"])) {
        for (const f of ["safe", "notSafe", "checkLabel"]) {
          words(derived.stateWords[f], `derived.stateWords.${f}`);
        }
      }
      words(derived.featureNames, "derived.featureNames");
      words(derived.stateWordsNotForOtherUse, "derived.stateWordsNotForOtherUse");
      for (const f of ["notSafeKeys", "checkLabelKeys", "cekAmanSurfaceKeys", "badgeKeys"]) {
        keys(derived[f], `derived.${f}`);
      }
    }
  }
  if (errors.length) throw new Error(`Invalid safety word list:\n  ${errors.join("\n  ")}`);
  return list;
}

// ---------- allowlist ----------

/** @returns {{ key: string, rule: string, terms: string[], locales?: string[], reason: string }[]} */
export function validateAllowlist(allowlist) {
  const errors = [];
  if (!allowlist || typeof allowlist !== "object" || Array.isArray(allowlist)) {
    throw new Error("Invalid safety word allowlist: must be an object");
  }
  if (allowlist.schema !== "keluargamakan.safety-words-allowlist/1") {
    errors.push('schema must be "keluargamakan.safety-words-allowlist/1"');
  }
  if (!Array.isArray(allowlist.entries)) errors.push("entries must be a list");
  const entries = Array.isArray(allowlist.entries) ? allowlist.entries : [];
  entries.forEach((e, i) => {
    const at = `entries[${i}]`;
    if (!e || typeof e !== "object" || Array.isArray(e)) {
      errors.push(`${at} must be an object`);
      return;
    }
    const extra = Object.keys(e).filter(
      (k) => !["key", "rule", "terms", "locales", "reason"].includes(k),
    );
    if (extra.length) errors.push(`${at} has unexpected fields: ${extra.join(", ")}`);
    if (typeof e.key !== "string" || !/^[a-z][A-Za-z0-9]*$/.test(e.key)) {
      errors.push(`${at}.key must be an ARB key (camelCase, for example "settingsPrivacyBody")`);
    }
    if (!ALLOWLISTABLE_RULES.has(e.rule)) {
      errors.push(
        `${at}.rule must be one of: ${[...ALLOWLISTABLE_RULES].join(", ")} (got ${JSON.stringify(e.rule)})`,
      );
    }
    if (!isStringArray(e.terms)) errors.push(`${at}.terms must list the allowed words`);
    if (e.locales !== undefined && !isStringArray(e.locales)) {
      errors.push(`${at}.locales must be a non-empty list of locales when present`);
    }
    if (typeof e.reason !== "string" || e.reason.trim().length < MIN_REASON_LENGTH) {
      errors.push(`${at}.reason is required (at least ${MIN_REASON_LENGTH} characters)`);
    }
  });
  if (errors.length) throw new Error(`Invalid safety word allowlist:\n  ${errors.join("\n  ")}`);
  return entries;
}

// ---------- key scopes ----------

/** `safety.badge.notSafe` -> `safetyBadgeNotSafe` (apps/mobile/l10n.yaml). */
export function deckKeyToArbKey(deckKey) {
  return deckKey
    .split(".")
    .map((part, i) => (i === 0 ? part : part.charAt(0).toUpperCase() + part.slice(1)))
    .join("");
}

/** Copy-deck key pattern -> predicate on ARB keys. */
export function keyMatcher(pattern) {
  if (pattern.endsWith(".*")) {
    const prefix = deckKeyToArbKey(pattern.slice(0, -2));
    return (key) =>
      key.length > prefix.length && key.startsWith(prefix) && /[A-Z0-9]/.test(key[prefix.length]);
  }
  if (pattern.endsWith("*")) {
    const prefix = deckKeyToArbKey(pattern.slice(0, -1));
    return (key) => key.startsWith(prefix);
  }
  const exact = deckKeyToArbKey(pattern);
  return (key) => key === exact;
}

const anyKey = (patterns) => {
  const matchers = patterns.map(keyMatcher);
  return (key) => matchers.some((m) => m(key));
};

// ---------- ICU message parsing ----------

class IcuError extends Error {}

/**
 * Parses an ICU message (Flutter gen_l10n, no apostrophe escaping) into
 * nodes: strings for literal text, null for a placeholder, and arrays of
 * branches (each a node list) for plural, select and selectordinal.
 */
export function parseIcu(source) {
  let i = 0;
  const parseMessage = (inBranch, inPlural) => {
    const nodes = [];
    let text = "";
    const flush = () => {
      if (text) nodes.push(text);
      text = "";
    };
    while (i < source.length) {
      const ch = source[i];
      if (ch === "{") {
        flush();
        nodes.push(parseArgument());
      } else if (ch === "}") {
        if (!inBranch) throw new IcuError(`unexpected "}" at ${i}`);
        flush();
        return nodes;
      } else if (ch === "#" && inPlural) {
        flush();
        nodes.push(null);
        i += 1;
      } else {
        text += ch;
        i += 1;
      }
    }
    if (inBranch) throw new IcuError("unclosed plural or select branch");
    flush();
    return nodes;
  };
  const readUntil = (stops) => {
    const start = i;
    while (i < source.length && !stops.includes(source[i])) i += 1;
    if (i >= source.length) throw new IcuError(`unclosed "{" at ${start - 1}`);
    return source.slice(start, i).trim();
  };
  const parseArgument = () => {
    i += 1; // "{"
    const name = readUntil([",", "}", "{"]);
    if (!/^[A-Za-z_][A-Za-z0-9_]*$/.test(name))
      throw new IcuError(`invalid placeholder name "${name}"`);
    if (source[i] === "{") throw new IcuError(`unexpected "{" in placeholder "${name}"`);
    if (source[i] === "}") {
      i += 1;
      return null;
    }
    i += 1; // ","
    const type = readUntil([",", "}", "{"]);
    if (source[i] === "{") throw new IcuError(`unexpected "{" in placeholder "${name}"`);
    if (source[i] === "}") {
      i += 1;
      return null;
    }
    i += 1; // ","
    if (!["plural", "select", "selectordinal"].includes(type)) {
      readUntil(["}", "{"]);
      if (source[i] === "{") throw new IcuError(`unexpected "{" in placeholder "${name}"`);
      i += 1;
      return null;
    }
    const branches = [];
    for (;;) {
      while (i < source.length && /\s/.test(source[i])) i += 1;
      if (i >= source.length) throw new IcuError(`unclosed ${type} "${name}"`);
      if (source[i] === "}") {
        i += 1;
        break;
      }
      const selector = readUntil(["{", "}"]);
      if (source[i] !== "{" || !selector || /\s/.test(selector.replace(/^offset:\s*\d+\s+/, ""))) {
        throw new IcuError(`invalid ${type} selector "${selector}" in "${name}"`);
      }
      i += 1; // "{"
      branches.push(parseMessage(true, type !== "select"));
      i += 1; // "}"
    }
    if (branches.length === 0) throw new IcuError(`${type} "${name}" has no branches`);
    return branches;
  };
  return parseMessage(false, false);
}

/** Every rendering of a message: one string per combination of branches. */
export function expandVariants(nodes) {
  let variants = [""];
  for (const node of nodes) {
    if (typeof node === "string") {
      variants = variants.map((v) => v + node);
    } else if (node === null) {
      variants = variants.map((v) => `${v} `);
    } else {
      const options = node.flatMap((branch) => expandVariants(branch));
      variants = variants.flatMap((v) => options.map((o) => v + o));
    }
    if (variants.length > MAX_VARIANTS)
      throw new IcuError(`more than ${MAX_VARIANTS} plural or select variants`);
  }
  return variants;
}

// ---------- normalization and matching ----------

// Soft hyphen, fillers, zero-width and bidi controls. The combining ones
// (grapheme joiner, Khmer inherent vowels, variation selectors) sit outside
// the class so no character in it combines with the one before.
const INVISIBLE =
  /[\u00AD\u061C\u115F\u1160\u180E\u200B-\u200F\u202A-\u202E\u2060-\u206F\u3164\uFEFF\uFFA0]|\u034F|\u17B4|\u17B5|\p{Variation_Selector}/gu;

/** Case-folded, NFKC, no diacritics, no invisible characters, one space. */
export function normalize(text) {
  return text
    .normalize("NFKC")
    .replace(INVISIBLE, "")
    .replace(/\p{Pd}/gu, "-")
    .replace(/[\u2018\u2019\u02BC`\u00B4\u2032]/gu, "'")
    .toLowerCase()
    .normalize("NFKD")
    .replace(/\p{M}/gu, "")
    .replace(/\u0131/gu, "i")
    .normalize("NFC")
    .replace(/\s+/gu, " ")
    .trim();
}

const escapeRegex = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");

/** Whole-word regex for a banned term, tolerant of spacing and particles. */
export function termRegex(term) {
  const t = normalize(term);
  let body = "";
  for (const ch of t) {
    if (ch === " ") body += "\\s+";
    else if (ch === "-") body += "[-\\s]*";
    else if (ch === "'") body += "'?";
    else if (ch === "%") body += "\\s*%";
    else body += escapeRegex(ch);
  }
  const first = t[0] ?? "";
  const last = t[t.length - 1] ?? "";
  const before = /[\p{L}\p{N}]/u.test(first) ? "(?<![\\p{L}\\p{N}])" : "";
  let after = "";
  if (/\p{L}/u.test(last)) after = "(?:nya|lah|kah|pun)?(?![\\p{L}\\p{N}])";
  else if (/\p{N}/u.test(last)) after = "(?![\\p{N}])";
  return new RegExp(before + body + after, "gu");
}

const compile = (terms) => terms.map((term) => ({ term, regex: termRegex(term) }));

function findTerms(text, compiled) {
  const found = [];
  for (const { term, regex } of compiled) {
    regex.lastIndex = 0;
    const match = regex.exec(text);
    if (match) found.push({ term, matched: match[0] });
  }
  return found;
}

function removeTerms(text, compiled) {
  let out = text;
  for (const { regex } of compiled) out = out.replace(regex, " ");
  return out;
}

// ---------- the check ----------

/** Builds a checker from the word list. */
export function createChecker(list) {
  validateWordList(list);
  const { doc, derived } = list;
  const terms = {
    softeners: compile(doc.softeners),
    inflation: compile(doc.inflation),
    overrides: compile(doc.overrides),
    allowedInCheckLabel: compile(doc.allowedInCheckLabel),
    otherUse: compile([...doc.stateWordsNotForOtherUse, ...derived.stateWordsNotForOtherUse]),
    healthClaims: compile(doc.badgeHealthClaims),
    featureNames: compile(derived.featureNames),
    notSafe: compile(derived.stateWords.notSafe),
    checkLabel: compile(derived.stateWords.checkLabel),
  };
  const scope = {
    notSafe: anyKey([...doc.softenerKeys, ...derived.notSafeKeys]),
    checkLabel: anyKey(derived.checkLabelKeys),
    safe: anyKey(doc.inflationKeys),
    safety: anyKey(doc.overrideKeys),
    cekAman: anyKey(derived.cekAmanSurfaceKeys),
    badge: anyKey(derived.badgeKeys),
  };

  /**
   * @param {string} key ARB key
   * @param {unknown} value ARB value
   * @returns {{ rule: string, term: string, detail?: string, protected: boolean }[]}
   */
  function checkMessage(key, value) {
    if (typeof value !== "string") {
      return [{ rule: "invalid-value", term: String(value), protected: true }];
    }
    const findings = [];
    const add = (rule, term, detail) => {
      if (!findings.some((f) => f.rule === rule && f.term === term))
        findings.push({ rule, term, detail });
    };

    const raw = value.normalize("NFKC");
    const invisible = value.match(INVISIBLE);
    if (invisible) {
      const codes = [...new Set(invisible)].map(
        (c) => `U+${c.codePointAt(0).toString(16).toUpperCase().padStart(4, "0")}`,
      );
      add("invisible-character", codes.join(" "));
    }
    const nonLatin = raw.match(/(?!\p{Script=Latin})\p{L}/gu);
    if (nonLatin) add("non-latin-letter", [...new Set(nonLatin)].join(""));

    let variants;
    try {
      variants = expandVariants(parseIcu(value));
    } catch (error) {
      if (!(error instanceof IcuError)) throw error;
      add("icu-syntax", value, error.message);
      variants = [value.replace(/[{}]/g, " ")]; // still check the words
    }

    let isNotSafe = scope.notSafe(key);
    let isCheckLabel = scope.checkLabel(key);
    const normalized = variants.map((v) => ({ raw: v.normalize("NFKC"), text: normalize(v) }));
    for (const { text } of normalized) {
      if (findTerms(text, terms.notSafe).length) isNotSafe = true;
      if (findTerms(text, terms.checkLabel).length) isCheckLabel = true;
    }

    for (const { raw: shown, text } of normalized) {
      if (isNotSafe) {
        for (const f of findTerms(text, terms.softeners)) add("softener-not-safe", f.term);
      }
      if (isCheckLabel && !isNotSafe) {
        const withoutDataPhrases = removeTerms(text, terms.allowedInCheckLabel);
        for (const f of findTerms(withoutDataPhrases, terms.softeners))
          add("softener-check-label", f.term);
      }
      if (scope.safe(key)) {
        for (const f of findTerms(text, terms.inflation)) add("inflation-safe", f.term);
      }
      if (scope.safety(key) || isNotSafe || isCheckLabel) {
        for (const f of findTerms(text, terms.overrides)) add("override-in-safety-string", f.term);
      }
      if (!scope.cekAman(key)) {
        const withoutFeatureName = removeTerms(text, terms.featureNames);
        for (const f of findTerms(withoutFeatureName, terms.otherUse))
          add("state-word-outside-cek-aman", f.term);
      }
      if (scope.badge(key)) {
        if (/[!\u00A1\u01C3]/u.test(shown)) add("badge-format", "!", "exclamation mark");
        const caps = shown.match(/\p{Lu}{2,}/u);
        if (caps) add("badge-format", caps[0], "all caps");
        const emoji = shown.match(/\p{Extended_Pictographic}|\p{Regional_Indicator}|\u20E3/u);
        if (emoji) add("badge-format", emoji[0], "emoji");
        for (const f of findTerms(text, terms.healthClaims)) add("health-claim-in-badge", f.term);
      }
    }
    // An override word next to Tidak aman or Cek label is the SAF-12 risk
    // ("tetap masak"), so it can never be allowlisted there.
    const carriesVerdict = isNotSafe || isCheckLabel;
    return findings.map((f) => ({
      ...f,
      protected: carriesVerdict && f.rule === "override-in-safety-string",
    }));
  }

  return { checkMessage };
}

// ---------- files ----------

function localeOf(path, arb) {
  if (typeof arb["@@locale"] === "string") return arb["@@locale"];
  const match = /_([A-Za-z]{2,3}(?:[_-][A-Za-z0-9]+)?)\.arb$/.exec(basename(path));
  return match ? match[1] : "";
}

function lineOf(content, key) {
  const needle = `"${key}"`;
  const lines = content.split(/\r?\n/);
  const index = lines.findIndex((line) => line.trimStart().startsWith(needle));
  return index === -1 ? 0 : index + 1;
}

/**
 * Checks ARB files. `files` maps a display path to its content.
 * @returns {{ violations: object[], allowed: object[], staleAllowlist: object[], strings: number }}
 */
export function checkFiles(files, list, allowlistEntries = []) {
  const checker = createChecker(list);
  const violations = [];
  const allowed = [];
  const used = new Set();
  const seenKeys = new Set();
  let strings = 0;

  for (const [path, content] of Object.entries(files)) {
    let arb;
    try {
      arb = JSON.parse(content);
    } catch (error) {
      violations.push({
        path,
        line: 0,
        key: "",
        rule: "icu-syntax",
        term: "",
        detail: `not valid JSON: ${error.message}`,
      });
      continue;
    }
    if (!arb || typeof arb !== "object" || Array.isArray(arb)) {
      violations.push({
        path,
        line: 0,
        key: "",
        rule: "invalid-value",
        term: "",
        detail: "ARB file must be a JSON object",
      });
      continue;
    }
    const locale = localeOf(path, arb);
    for (const [key, value] of Object.entries(arb)) {
      if (key.startsWith("@")) continue;
      strings += 1;
      seenKeys.add(key);
      for (const finding of checker.checkMessage(key, value)) {
        const violation = { path, line: lineOf(content, key), key, locale, value, ...finding };
        const entryIndex = allowlistEntries.findIndex(
          (e) =>
            e.key === key &&
            e.rule === finding.rule &&
            e.terms.some((t) => normalize(t) === normalize(finding.term)) &&
            (!e.locales || e.locales.includes(locale)),
        );
        if (entryIndex === -1) {
          violations.push(violation);
        } else if (finding.protected) {
          used.add(entryIndex);
          violations.push({
            ...violation,
            detail: `allowlist entries[${entryIndex}] refused: an override word next to Tidak aman or Cek label cannot be allowlisted`,
          });
        } else {
          used.add(entryIndex);
          allowed.push({ ...violation, reason: allowlistEntries[entryIndex].reason });
        }
      }
    }
  }
  const staleAllowlist = allowlistEntries
    .map((entry, index) => ({ ...entry, index, missingKey: !seenKeys.has(entry.key) }))
    .filter((entry) => !used.has(entry.index));
  return { violations, allowed, staleAllowlist, strings };
}

/** Expands files and directories into ARB file paths. */
export function collectArbFiles(targets) {
  const found = [];
  for (const target of targets) {
    if (statSync(target).isDirectory()) {
      for (const name of readdirSync(target).sort()) {
        if (name.endsWith(".arb")) found.push(join(target, name));
      }
    } else {
      found.push(target);
    }
  }
  return found;
}

export function formatViolation(v) {
  const where = v.line ? `${v.path}:${v.line}` : v.path;
  const key = v.key ? ` key "${v.key}"` : "";
  const word = v.term ? ` word "${v.term}"` : "";
  const detail = v.detail ? ` (${v.detail})` : "";
  return `${where}${key}: [${v.rule}]${word}${detail}: ${RULES[v.rule] ?? v.rule}`;
}

function main() {
  const args = process.argv.slice(2);
  const targets = args.length ? args : DEFAULT_TARGETS;
  const list = JSON.parse(readFileSync(WORD_LIST_PATH, "utf8"));
  const entries = validateAllowlist(JSON.parse(readFileSync(ALLOWLIST_PATH, "utf8")));
  const paths = collectArbFiles(targets);
  if (paths.length === 0) {
    console.error(`Safety word check failed: no ARB files found in ${targets.join(", ")}.`);
    process.exit(1);
  }
  const files = Object.fromEntries(
    paths.map((p) => [relative(REPO_ROOT, p).replaceAll("\\", "/"), readFileSync(p, "utf8")]),
  );
  const { violations, allowed, staleAllowlist, strings } = checkFiles(files, list, entries);

  for (const a of allowed) console.log(`allowlisted ${formatViolation(a)} Reason: ${a.reason}`);
  if (violations.length || staleAllowlist.length) {
    console.error("Safety word check failed (NFR-14, SAF-04, INT-03).");
    console.error(
      "Banned wording: docs/design/system/safety-badges.md section 5 (scripts/safety-words/banned-words.json).\n",
    );
    for (const v of violations) console.error(`  ${formatViolation(v)}`);
    for (const s of staleAllowlist) {
      const why = s.missingKey ? "the key no longer exists" : "it matches no finding";
      console.error(
        `  scripts/safety-words/allowlist.json entries[${s.index}] (key "${s.key}", ${s.rule}): remove it, ${why}`,
      );
    }
    console.error(
      "\nReword the string with ux-designer. Do not weaken the word list. Only these rules can be allowlisted, with a reason, in scripts/safety-words/allowlist.json: " +
        [...ALLOWLISTABLE_RULES].join(", "),
    );
    process.exit(1);
  }
  console.log(`Safety word check passed: ${strings} strings in ${paths.length} ARB files.`);
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  main();
}
