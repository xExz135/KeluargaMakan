// Tests for the safety word check (NFR-14, SAF-04, INT-03; QUESTIONS #41).
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdtempSync, readFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { describe, it } from "node:test";
import { fileURLToPath } from "node:url";

import {
  ALLOWLIST_PATH,
  ALLOWLISTABLE_RULES,
  RULES,
  WORD_LIST_PATH,
  checkFiles,
  createChecker,
  deckKeyToArbKey,
  expandVariants,
  formatViolation,
  keyMatcher,
  normalize,
  parseIcu,
  validateAllowlist,
  validateWordList,
} from "./check-safety-words.mjs";

const HERE = dirname(fileURLToPath(import.meta.url));
const SCRIPT = join(HERE, "check-safety-words.mjs");
const FIXTURES = join(HERE, "fixtures/safety-words");
const list = JSON.parse(readFileSync(WORD_LIST_PATH, "utf8"));
const { checkMessage } = createChecker(list);

/** Rule ids (and words) found for one ARB string. */
const rules = (key, value) => checkMessage(key, value).map((f) => f.rule);
const hits = (key, value) => checkMessage(key, value).map((f) => `${f.rule}:${f.term}`);
const fixture = (name) => readFileSync(join(FIXTURES, name), "utf8");
const run = (...args) => spawnSync(process.execPath, [SCRIPT, ...args], { encoding: "utf8" });

// The lists exactly as written in docs/design/system/safety-badges.md v1.0
// section 5. If this test fails, the JSON drifted from the page: change both
// together (ux-designer owns the page), never just one.
const DOC_SECTION_5 = {
  softeners: [
    "mungkin",
    "sebaiknya",
    "agak",
    "kurang",
    "sedikit",
    "sepertinya",
    "disarankan",
    "kemungkinan",
    "cukup",
    "relatif",
    "may",
    "might",
    "maybe",
    "probably",
    "possibly",
    "slightly",
    "a bit",
    "consider",
    "suggest",
    "try to avoid",
  ],
  inflation: [
    "100%",
    "dijamin",
    "pasti",
    "terjamin",
    "sepenuhnya",
    "benar-benar",
    "guaranteed",
    "completely",
    "totally",
    "fully",
    "certified",
    "always safe",
  ],
  overrides: [
    "abaikan",
    "lewati",
    "tetap",
    "saya yakin",
    "saya tahu",
    "izinkan",
    "buka kunci",
    "ignore",
    "skip",
    "override",
    "anyway",
    "I'm sure",
    "unlock",
  ],
  softenerKeys: [
    "safety.state.notSafe",
    "safety.badge.notSafe*",
    "safety.a11y.notSafe*",
    "safety.why.notSafeTitle",
    "safety.why.ingredient",
    "safety.why.rule",
    "safety.why.component",
    "recipe.notSafeDialog.*",
    "cook.safetyNote.*",
    "help.cekAman.stateNotSafe",
  ],
  inflationKeys: [
    "safety.state.safe",
    "safety.badge.safe*",
    "safety.a11y.safe",
    "help.cekAman.stateSafe",
    "help.cekAman.savedBody",
  ],
  overrideKeys: [
    "safety.*",
    "help.cekAman.*",
    "recipe.notSafeDialog.*",
    "cook.safetyNote.*",
    "cook.checkLabelNote*",
  ],
  allowedInCheckLabel: ["belum pasti", "bisa mengandung", "may contain"],
  stateWordsNotForOtherUse: ["aman", "cek"],
  badgeHealthClaims: ["baik untuk", "sehat", "cocok untuk diabetes"],
};

describe("NFR-14 word list mirrors safety-badges.md section 5", () => {
  it("NFR-14 doc lists and key scopes match the page exactly", () => {
    assert.equal(list.schema, "keluargamakan.safety-words/1");
    assert.deepEqual(list.source, {
      document: "docs/design/system/safety-badges.md",
      version: "1.0",
      section: "5. Banned wording",
    });
    assert.deepEqual(list.doc, DOC_SECTION_5);
  });

  it("NFR-14 derived scopes are pinned (stricter reading, no new banned words)", () => {
    assert.deepEqual(list.derived.stateWords, {
      safe: ["aman", "safe"],
      notSafe: ["tidak aman", "not safe"],
      checkLabel: ["cek label", "check the label"],
    });
    assert.deepEqual(list.derived.featureNames, ["cek aman"]);
    assert.deepEqual(list.derived.stateWordsNotForOtherUse, ["safe", "check the label"]);
    assert.deepEqual(list.derived.notSafeKeys, ["safety.mini.notSafe*", "safety.rule.*"]);
    assert.deepEqual(list.derived.badgeKeys, [
      "safety.state.*",
      "safety.badge.*",
      "safety.mini.*",
      "safety.a11y.*",
    ]);
    assert.ok(list.derived.checkLabelKeys.includes("safety.reason.*"));
    assert.ok(list.derived.cekAmanSurfaceKeys.includes("safety.*"));
    // Every derived word is a state word from section 3.1, not a new ban.
    const stateWords = Object.values(list.derived.stateWords).flat();
    for (const w of list.derived.stateWordsNotForOtherUse) assert.ok(stateWords.includes(w), w);
  });

  it("NFR-14 the real word list passes its own shape check", () => {
    assert.doesNotThrow(() => validateWordList(structuredClone(list)));
  });

  it("NFR-14 a drifted shape fails closed instead of checking nothing", () => {
    const broken = (mutate) => {
      const copy = structuredClone(list);
      mutate(copy);
      return () => validateWordList(copy);
    };
    assert.throws(
      broken((l) => delete l.doc.softeners),
      /missing fields: softeners/,
    );
    assert.throws(
      broken((l) => (l.doc.softeners = [])),
      /doc\.softeners must be a non-empty list/,
    );
    assert.throws(
      broken((l) => (l.doc.overrides = ["skip", 3])),
      /doc\.overrides/,
    );
    assert.throws(
      broken((l) => (l.doc.extraList = ["x"])),
      /unexpected fields: extraList/,
    );
    assert.throws(
      broken((l) => (l.schema = "keluargamakan.safety-words/2")),
      /schema must be/,
    );
    assert.throws(
      broken((l) => (l.doc.softenerKeys = ["Safety badge"])),
      /doc\.softenerKeys/,
    );
    assert.throws(
      broken((l) => delete l.derived.stateWords.checkLabel),
      /derived\.stateWords is missing/,
    );
    assert.throws(
      broken((l) => delete l.source),
      /missing fields: source/,
    );
  });
});

describe("NFR-14 copy-deck key scopes map to ARB keys", () => {
  it("NFR-14 deck keys become camelCase ARB keys (apps/mobile/l10n.yaml)", () => {
    assert.equal(deckKeyToArbKey("safety.badge.notSafe"), "safetyBadgeNotSafe");
    assert.equal(deckKeyToArbKey("help.cekAman.stateNotSafe"), "helpCekAmanStateNotSafe");
    assert.equal(deckKeyToArbKey("nav.home"), "navHome");
  });

  it("NFR-14 exact, prefix and segment patterns", () => {
    assert.equal(keyMatcher("safety.state.notSafe")("safetyStateNotSafe"), true);
    assert.equal(keyMatcher("safety.state.notSafe")("safetyStateNotSafeX"), false);
    assert.equal(keyMatcher("safety.badge.notSafe*")("safetyBadgeNotSafeComponent"), true);
    assert.equal(keyMatcher("safety.*")("safetyPanelTitle"), true);
    assert.equal(keyMatcher("safety.*")("safety"), false);
    assert.equal(keyMatcher("safety.*")("safetynet"), false);
    assert.equal(keyMatcher("cook.safety.*")("cookSafetyNotEating"), true);
    assert.equal(keyMatcher("cook.safety.*")("cookTimerTitle"), false);
  });
});

describe("SAF-04 softening words on Not safe (Tidak aman) strings fail", () => {
  it("SAF-04 every softener in the list fails on a Not safe badge, in Indonesian and English", () => {
    for (const word of list.doc.softeners) {
      assert.ok(
        rules(
          "safetyBadgeNotSafe",
          `Tidak aman untuk {name}, ${word} mengandung {ingredient}`,
        ).includes("softener-not-safe"),
        word,
      );
      assert.ok(
        rules("safetyA11yNotSafe", `Not safe for {name}: ${word} contains {ingredient}`).includes(
          "softener-not-safe",
        ),
        word,
      );
    }
  });

  it("SAF-04 a softener on any string that carries Tidak aman fails, whatever the key", () => {
    assert.ok(
      rules("planShareBody", "Resep ini tidak aman, sebaiknya jangan").includes(
        "softener-not-safe",
      ),
    );
    assert.ok(
      rules("tweakHint", "This is NOT SAFE for Kakak, probably").includes("softener-not-safe"),
    );
  });

  it("SAF-04 'may contain' is never allowed next to Tidak aman", () => {
    assert.deepEqual(hits("safetyBadgeNotSafe", "Not safe for {name}: may contain {ingredient}"), [
      "softener-not-safe:may",
    ]);
  });

  it("SAF-04 the real Not safe copy passes", () => {
    assert.deepEqual(
      rules("safetyBadgeNotSafe", "Tidak aman untuk {name}: mengandung {ingredient} \u00B7 {rule}"),
      [],
    );
    assert.deepEqual(
      rules(
        "safetyBadgeNotSafeComponent",
        "Not safe for {name}: contains {component} ({ingredient}) \u00B7 {rule}",
      ),
      [],
    );
    assert.deepEqual(rules("recipeNotSafeDialogTitle", "Resep ini tidak aman untuk {names}"), []);
  });
});

describe("SAF-04 softening words on Cek label (Check the label) strings fail", () => {
  it("SAF-04 softeners fail on Cek label badges and reasons", () => {
    assert.deepEqual(
      hits("safetyBadgeCheckLabel", "Cek label untuk {name}: kemungkinan {ingredient}"),
      ["softener-check-label:kemungkinan"],
    );
    assert.deepEqual(hits("safetyReasonBrandVaries", "isi bahan agak beda tiap merek"), [
      "softener-check-label:agak",
    ]);
    assert.deepEqual(hits("kitchenNote", "Check the label, it might be fine"), [
      "softener-check-label:might",
      "state-word-outside-cek-aman:check the label",
    ]);
  });

  it("SAF-04 the data phrases the page allows pass on Cek label strings", () => {
    assert.deepEqual(rules("safetyReasonMayContain", "bisa mengandung {allergen}"), []);
    assert.deepEqual(rules("safetyReasonMayContain", "may contain {allergen}"), []);
    assert.deepEqual(rules("safetyReasonDietUncertain", "belum pasti cocok untuk {rule}"), []);
    assert.deepEqual(
      rules(
        "cookCheckLabelNote",
        "Check the label of {ingredient} before using it for {names} \u00B7 {reason}",
      ),
      [],
    );
  });

  it("SAF-04 'may' on its own is still a softener on a Cek label string", () => {
    assert.deepEqual(hits("safetyReasonMissingData", "data may be incomplete"), [
      "softener-check-label:may",
    ]);
  });
});

describe("SAF-04 inflating words on Safe (Aman) strings fail", () => {
  it("SAF-04 every inflation word fails on the Safe badge", () => {
    for (const word of list.doc.inflation) {
      assert.ok(
        rules("safetyBadgeSafe", `Aman untuk {names}, ${word}`).includes("inflation-safe"),
        word,
      );
    }
  });

  it("SAF-04 inflation is checked in the Safe strings only (per the page)", () => {
    assert.deepEqual(rules("safetyReasonDietUncertain", "belum pasti cocok untuk {rule}"), []);
    assert.deepEqual(rules("helpCekAmanSavedBody", "Aman berarti pasti tidak melanggar aturan"), [
      "inflation-safe",
    ]);
  });
});

describe("SAF-12 override words on safety strings fail", () => {
  it("SAF-12 every override word fails on every safety key prefix", () => {
    const keys = [
      "safetyPanelTitle",
      "helpCekAmanTitle",
      "recipeNotSafeDialogOtherRecipe",
      "cookSafetyNoteSeparate",
      "cookCheckLabelNote",
    ];
    for (const word of list.doc.overrides) {
      for (const key of keys) {
        assert.ok(
          rules(key, `Masak ${word} untuk semua`).includes("override-in-safety-string"),
          `${key}: ${word}`,
        );
      }
    }
  });

  it("SAF-12 override words outside safety strings pass", () => {
    assert.deepEqual(rules("cookTimerSkip", "Lewati langkah ini"), []);
    assert.deepEqual(rules("onboardingSkip", "Skip for now"), []);
  });
});

describe("INT-03 safety state words are not used outside the Cek Aman surfaces", () => {
  it("INT-03 'aman', 'cek', 'safe' and 'check the label' fail on other keys", () => {
    assert.deepEqual(hits("settingsPrivacyBody", "Data Anda aman"), [
      "state-word-outside-cek-aman:aman",
    ]);
    assert.deepEqual(hits("kitchenScanHint", "Cek foto dulu"), ["state-word-outside-cek-aman:cek"]);
    assert.deepEqual(hits("settingsPrivacyBody", "Your data is safe"), [
      "state-word-outside-cek-aman:safe",
    ]);
    assert.deepEqual(hits("kitchenNote", "Please check the label"), [
      "state-word-outside-cek-aman:check the label",
    ]);
  });

  it("INT-03 the feature name 'Cek Aman' is not a verdict", () => {
    assert.deepEqual(rules("noResultBody", "Hasil Cek Aman untuk pilihan ini belum ada."), []);
    assert.deepEqual(rules("onboardingIntro", "CEK AMAN checks every recipe"), []);
    assert.deepEqual(hits("onboardingIntro", "Cek Aman bilang aman"), [
      "state-word-outside-cek-aman:aman",
    ]);
  });

  it("INT-03 whole-word matching: other words that contain the letters pass", () => {
    assert.deepEqual(rules("settingsSecurity", "Keamanan akun"), []);
    assert.deepEqual(rules("noResultTitle", "Belum bisa dicek"), []);
    assert.deepEqual(rules("settingsSafety", "Safety information"), []);
    assert.deepEqual(rules("settingsCheck", "Periksa koneksi"), []);
  });

  it("INT-03 Indonesian particles are part of the word", () => {
    assert.deepEqual(hits("homeTip", "Amankah resep ini?"), ["state-word-outside-cek-aman:aman"]);
    assert.deepEqual(hits("homeTip", "Dijamin amannya"), ["state-word-outside-cek-aman:aman"]);
  });
});

describe("INT-03 badge text has no exclamation marks, all caps, emoji or health claims", () => {
  it("INT-03 exclamation, all caps and emoji fail in badge keys", () => {
    assert.deepEqual(hits("safetyStateNotSafe", "Tidak aman!"), ["badge-format:!"]);
    assert.deepEqual(hits("safetyStateNotSafe", "Tidak aman\uFF01"), ["badge-format:!"]);
    assert.deepEqual(hits("safetyBadgeSafe", "AMAN untuk {names}"), ["badge-format:AMAN"]);
    assert.deepEqual(hits("safetyMiniCheckLabel", "Cek label \u26A0 {reason}"), [
      "badge-format:\u26A0",
    ]);
    assert.ok(rules("safetyBadgeSafe", "Aman untuk {names} \u2705").includes("badge-format"));
  });

  it("INT-03 health claims fail in badge keys", () => {
    assert.deepEqual(hits("safetyBadgeSafeDetail", "Baik untuk {names}"), [
      "health-claim-in-badge:baik untuk",
    ]);
    assert.deepEqual(hits("safetyBadgeSafeDetail", "Sehat dan aman"), [
      "health-claim-in-badge:sehat",
    ]);
  });

  it("INT-03 the same text outside badge keys is not a badge-format finding", () => {
    assert.deepEqual(rules("homeHeroTitle", "Masak apa hari ini?!"), []);
  });
});

describe("NFR-14 ICU placeholders and plural syntax", () => {
  it("NFR-14 placeholder names are not words", () => {
    assert.deepEqual(
      rules("safetyBadgeNotSafe", "Tidak aman untuk {maybe}: {mungkin} \u00B7 {rule}"),
      [],
    );
    assert.deepEqual(rules("settingsGreeting", "Halo {aman}"), []);
  });

  it("NFR-14 every plural and select branch is checked", () => {
    assert.deepEqual(
      hits(
        "safetyBadgeMoreReasons",
        "Not safe {count, plural, =1{and 1 more reason} other{and probably {count} more}}",
      ),
      ["softener-not-safe:probably"],
    );
    assert.deepEqual(
      hits(
        "libraryHidden",
        "{count, plural, =1{1 recipe is} other{{count} recipes are}} hidden: {who, select, a{not safe, maybe} other{fine}}",
      ),
      ["softener-not-safe:maybe", "state-word-outside-cek-aman:safe"],
    );
    assert.deepEqual(
      hits("safetyBadgeSafe", "{n, selectordinal, one{#st} other{dijamin #th}} aman"),
      ["inflation-safe:dijamin"],
    );
  });

  it("NFR-14 '#' in a plural is a number, and a plain '#' is text", () => {
    const [variant] = expandVariants(parseIcu("{count, plural, other{# resep}}"));
    assert.equal(variant, "  resep");
    assert.deepEqual(expandVariants(parseIcu("Langkah #1")), ["Langkah #1"]);
  });

  it("NFR-14 typed placeholders and plural offsets are stripped", () => {
    assert.deepEqual(expandVariants(parseIcu("Dicek {time, time, short}")), ["Dicek  "]);
    assert.deepEqual(expandVariants(parseIcu("{n, plural, offset:1 =0{nol} other{# lagi}}")), [
      "nol",
      "  lagi",
    ]);
  });

  it("NFR-14 broken ICU fails closed and the words are still checked", () => {
    assert.deepEqual(
      hits("safetyBadgeNotSafe", "Tidak aman {name").map((h) => h.split(":")[0]),
      ["icu-syntax"],
    );
    assert.ok(rules("safetyBadgeNotSafe", "Tidak aman } mungkin").includes("icu-syntax"));
    assert.ok(rules("safetyBadgeNotSafe", "Tidak aman } mungkin").includes("softener-not-safe"));
    assert.ok(rules("homeTitle", "{count, plural, =1{satu}").includes("icu-syntax"));
    assert.ok(rules("homeTitle", "{bad name}").includes("icu-syntax"));
  });
});

describe("NFR-14 case and Unicode tricks do not hide a banned word", () => {
  it("NFR-14 upper case, full-width and diacritics", () => {
    assert.ok(
      rules("safetyWhyRule", "Aturan {name}: MUNGKIN {rule}").includes("softener-not-safe"),
    );
    assert.ok(
      rules(
        "safetyWhyRule",
        "Aturan {name}: \uFF4D\uFF55\uFF4E\uFF47\uFF4B\uFF49\uFF4E {rule}",
      ).includes("softener-not-safe"),
    );
    assert.ok(
      rules("safetyWhyRule", "Aturan {name}: mungk\u00EDn {rule}").includes("softener-not-safe"),
    );
    assert.ok(rules("safetyPanelTitle", "SK\u0130P").includes("override-in-safety-string"));
    assert.ok(rules("safetyPanelTitle", "sk\u0131p").includes("override-in-safety-string"));
  });

  it("NFR-14 zero-width and soft hyphen characters are removed and reported", () => {
    assert.deepEqual(hits("safetyWhyRule", "Aturan {name}: mun\u200Bgkin").sort(), [
      "invisible-character:U+200B",
      "softener-not-safe:mungkin",
    ]);
    assert.ok(
      rules("settingsPrivacyBody", "Data Anda a\u00ADman").includes("state-word-outside-cek-aman"),
    );
    assert.ok(rules("settingsPrivacyBody", "Data Anda a\u00ADman").includes("invisible-character"));
    // Grapheme joiner, variation selectors and a bidi override.
    assert.deepEqual(hits("settingsPrivacyBody", "a\u034Fman\uFE0F \u202Eok"), [
      "invisible-character:U+034F U+FE0F U+202E",
      "state-word-outside-cek-aman:aman",
    ]);
  });

  it("NFR-14 odd spacing, dashes and apostrophes in multi-word terms", () => {
    assert.ok(
      rules("safetyWhyIngredient", "Contains {ingredient}, a\u00A0bit").includes(
        "softener-not-safe",
      ),
    );
    assert.ok(
      rules("safetyWhyIngredient", "Contains a   bit of {ingredient}").includes(
        "softener-not-safe",
      ),
    );
    assert.ok(rules("safetyPanelTitle", "I\u2019m sure").includes("override-in-safety-string"));
    assert.ok(rules("safetyBadgeSafe", "Aman benar\u2013benar").includes("inflation-safe"));
    assert.ok(rules("safetyBadgeSafe", "Aman benar benar").includes("inflation-safe"));
    assert.ok(rules("safetyBadgeSafe", "Aman 100 %").includes("inflation-safe"));
  });

  it("NFR-14 look-alike letters from other scripts are reported", () => {
    // Cyrillic "\u0430" (U+0430) in "\u0430man".
    assert.deepEqual(hits("settingsPrivacyBody", "Data Anda \u0430man"), [
      "non-latin-letter:\u0430",
    ]);
  });

  it("NFR-14 word boundaries: longer words and numbers do not match", () => {
    assert.deepEqual(rules("safetyBadgeNotSafe", "Tidak aman: mayones \u00B7 tetapi kurangi"), []);
    assert.deepEqual(rules("safetyBadgeSafe", "Aman untuk 1100%"), []);
    assert.deepEqual(rules("safetyPanelTitle", "Skipjack tuna"), []);
  });

  it("NFR-14 normalize folds case, width, marks and spaces", () => {
    assert.equal(normalize("  \uFF34\uFF29\uFF24\uFF21\uFF2B\u00A0Am\u00E1n\u200B "), "tidak aman");
  });

  it("NFR-14 non-string values fail", () => {
    assert.deepEqual(rules("safetyStateSafe", 3), ["invalid-value"]);
  });
});

describe("NFR-14 ARB files", () => {
  it("NFR-14 copy-deck wording passes in both locales", () => {
    const result = checkFiles(
      { "pass_id.arb": fixture("pass_id.arb"), "pass_en.arb": fixture("pass_en.arb") },
      list,
    );
    assert.deepEqual(result.violations, []);
    assert.equal(result.strings, 28);
  });

  it("NFR-14 banned wording fails with file, line, key, word and rule", () => {
    const { violations } = checkFiles(
      { "fail_id.arb": fixture("fail_id.arb"), "fail_en.arb": fixture("fail_en.arb") },
      list,
    );
    const summary = violations.map((v) => `${v.path}:${v.line} ${v.key} ${v.rule} ${v.term}`);
    assert.deepEqual(summary, [
      "fail_id.arb:4 safetyBadgeNotSafe softener-not-safe mungkin",
      "fail_id.arb:5 safetyBadgeCheckLabel softener-check-label sebaiknya",
      "fail_id.arb:6 safetyBadgeSafe inflation-safe dijamin",
      "fail_id.arb:7 safetyPanelOverride override-in-safety-string abaikan",
      "fail_id.arb:7 safetyPanelOverride override-in-safety-string tetap",
      "fail_id.arb:8 settingsPrivacyBody state-word-outside-cek-aman aman",
      "fail_id.arb:9 kitchenScanHint state-word-outside-cek-aman cek",
      "fail_id.arb:10 safetyStateNotSafeLoud badge-format !",
      "fail_id.arb:10 safetyStateNotSafeLoud badge-format TIDAK",
      "fail_en.arb:4 planShareBody softener-not-safe try to avoid",
      "fail_en.arb:4 planShareBody state-word-outside-cek-aman safe",
      "fail_en.arb:5 settingsPrivacyBody state-word-outside-cek-aman safe",
      "fail_en.arb:6 safetyBadgeCheckLabel softener-check-label probably",
    ]);
    assert.equal(
      formatViolation(violations[0]),
      'fail_id.arb:4 key "safetyBadgeNotSafe": [softener-not-safe] word "mungkin": softening word on a Not safe (Tidak aman) string',
    );
  });

  it("NFR-14 invalid JSON and non-object files fail", () => {
    assert.equal(checkFiles({ "x.arb": "{ nope" }, list).violations[0].rule, "icu-syntax");
    assert.equal(checkFiles({ "x.arb": "[]" }, list).violations[0].rule, "invalid-value");
  });

  it("NFR-14 every rule has a description", () => {
    for (const rule of ALLOWLISTABLE_RULES) assert.ok(RULES[rule], rule);
  });
});

describe("NFR-14 allowlist", () => {
  const entries = validateAllowlist(JSON.parse(fixture("allowlist.fixture.json")));
  const result = checkFiles({ "allowlisted_en.arb": fixture("allowlisted_en.arb") }, list, entries);

  it("NFR-14 an entry exempts its key, rule and word, and the reason is reported", () => {
    assert.deepEqual(
      result.allowed.map((a) => `${a.key} ${a.rule} ${a.term}`),
      [
        "settingsSafeModeTitle state-word-outside-cek-aman safe",
        "safetyPanelStillSaved override-in-safety-string anyway",
        "planShareBody state-word-outside-cek-aman safe",
      ],
    );
    assert.match(result.allowed[0].reason, /device mode/);
  });

  it("SAF-12 an override word next to Not safe can never be allowlisted", () => {
    assert.deepEqual(
      result.violations.map((v) => `${v.key} ${v.rule} ${v.term}`),
      ["planShareBody override-in-safety-string ignore"],
    );
    assert.match(result.violations[0].detail, /refused/);
  });

  it("NFR-14 an entry that matches nothing is reported as stale", () => {
    assert.deepEqual(
      result.staleAllowlist.map((s) => `${s.key} ${s.missingKey}`),
      ["removedKey true"],
    );
  });

  it("NFR-14 entries apply only to their locales", () => {
    const id = '{ "@@locale": "id", "safetyPanelStillSaved": "Hasil disimpan anyway" }';
    const r = checkFiles({ "x_id.arb": id }, list, entries);
    assert.deepEqual(
      r.violations.map((v) => v.term),
      ["anyway"],
    );
  });

  it("NFR-14 entries need an allowlistable rule, words and a reason", () => {
    const check = (entry) => () =>
      validateAllowlist({ schema: "keluargamakan.safety-words-allowlist/1", entries: [entry] });
    const ok = {
      key: "settingsSafeModeTitle",
      rule: "state-word-outside-cek-aman",
      terms: ["safe"],
      reason: "Android device mode name, not a verdict",
    };
    assert.doesNotThrow(check(ok));
    assert.throws(check({ ...ok, reason: undefined }), /reason is required/);
    assert.throws(check({ ...ok, reason: "ok" }), /reason is required/);
    assert.throws(check({ ...ok, rule: "softener-not-safe" }), /rule must be one of/);
    assert.throws(check({ ...ok, rule: "inflation-safe" }), /rule must be one of/);
    assert.throws(check({ ...ok, terms: [] }), /terms must list/);
    assert.throws(check({ ...ok, key: "settings.safeMode.title" }), /ARB key/);
    assert.throws(check({ ...ok, everything: true }), /unexpected fields/);
    assert.throws(() => validateAllowlist({ entries: [] }), /schema must be/);
  });

  it("NFR-14 the committed allowlist is valid", () => {
    assert.doesNotThrow(() => validateAllowlist(JSON.parse(readFileSync(ALLOWLIST_PATH, "utf8"))));
  });
});

describe("NFR-14 command line", () => {
  it("NFR-14 the app's current ARB files pass", () => {
    const r = run();
    assert.equal(r.status, 0, r.stderr);
    assert.match(r.stdout, /Safety word check passed: \d+ strings in 2 ARB files/);
  });

  it("NFR-14 banned wording exits 1 with readable errors", () => {
    const r = run(join(FIXTURES, "fail_en.arb"));
    assert.equal(r.status, 1);
    assert.match(
      r.stderr,
      /fail_en\.arb:5 key "settingsPrivacyBody": \[state-word-outside-cek-aman\] word "safe"/,
    );
    assert.match(r.stderr, /safety-badges\.md section 5/);
  });

  it("NFR-14 a folder with no ARB files fails closed", () => {
    const empty = mkdtempSync(join(tmpdir(), "safety-words-"));
    try {
      const r = run(empty);
      assert.equal(r.status, 1);
      assert.match(r.stderr, /no ARB files found/);
    } finally {
      rmSync(empty, { recursive: true, force: true });
    }
  });
});
