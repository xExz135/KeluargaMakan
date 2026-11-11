"""Guard points in the AI pipeline (AI-01, AI-04, AI-05, AI-13, TNT-09).

Input guard: runs on the user's free text before any provider call.
  - medical question            -> referral to a doctor or nutritionist (AI-04)
  - unsafe food handling        -> refused (AI-05, TNT-09)
  - asks whether food is safe,
    halal or free of an allergen -> refused; only Cek Aman answers that (AI-01)
  - not about cooking           -> refused (AI-13)

Output guard: runs on every text the model produced. An item that makes a
safety, halal, allergen, health, calorie or "tested" claim, or suggests unsafe
handling, is removed. It is never rewritten into something else.

The classifiers here are keyword MOCKS so the pipeline and its tests exist.
T-061 replaces `KeywordInputGuard` with a reviewed classifier behind the same
`InputGuard` protocol; the output guard stays as a deterministic backstop.
"""

from __future__ import annotations

import re
from dataclasses import dataclass
from enum import StrEnum
from typing import Protocol


class InputCategory(StrEnum):
    COOKING = "cooking"
    MEDICAL = "medical"
    UNSAFE_HANDLING = "unsafe_handling"
    FOOD_RULE_QUESTION = "food_rule_question"
    OFF_TOPIC = "off_topic"


@dataclass(frozen=True)
class GuardResult:
    category: InputCategory
    guard_id: str
    guard_version: str


class InputGuard(Protocol):
    def classify(self, text: str) -> GuardResult: ...


def _words(*patterns: str) -> re.Pattern[str]:
    return re.compile(r"\b(?:" + "|".join(patterns) + r")", re.IGNORECASE)


_MEDICAL = _words(
    r"diabet",
    r"gula darah",
    r"darah tinggi",
    r"hipertensi",
    r"hypertension",
    r"blood (?:sugar|pressure)",
    r"kolesterol",
    r"cholesterol",
    r"asam urat",
    r"gout",
    r"obat",
    r"medicine",
    r"medication",
    r"dosis",
    r"dose\b",
    r"diagnos",
    r"gejala",
    r"symptom",
    r"penyakit",
    r"disease",
    r"hamil",
    r"pregnan",
    r"menyusui",
    r"breastfeed",
    r"sembuh",
    r"cure\b",
    r"turun(?:kan)? berat",
    r"lose weight",
    r"diet",
)
_UNSAFE_HANDLING = _words(
    r"setengah matang",
    r"tidak (?:usah|perlu) (?:sampai )?matang",
    r"kurang matang",
    r"undercook",
    r"half[- ]cooked",
    r"rare chicken",
    r"ayam mentah",
    r"raw chicken",
    r"daging mentah",
    r"telur mentah",
    r"raw eggs?",
    r"semalam(?:an)? di (?:suhu ruang|luar)",
    r"overnight (?:at room temperature|on the counter)",
    r"basi\b",
    r"spoiled",
    r"berjamur",
    r"mouldy",
    r"moldy",
    r"canning",
    r"pengalengan",
)
_FOOD_RULE_QUESTION = _words(
    r"aman (?:untuk|buat|bagi|dimakan)",
    r"apakah aman",
    r"masih aman",
    r"(?:is|it'?s) (?:it )?safe",
    r"safe (?:for|to eat)",
    r"halal",
    r"haram",
    r"alergi",
    r"allerg",
    r"bebas (?:gluten|susu|kacang|udang)",
    r"(?:gluten|dairy|nut)[- ]free",
)
_OFF_TOPIC = _words(
    r"puisi",
    r"poem",
    r"politik",
    r"politic",
    r"pemilu",
    r"election",
    r"saham",
    r"stock market",
    r"crypto",
    r"kripto",
    r"pekerjaan rumah",
    r"homework",
    r"matematika",
    r"\bmath",
    r"lelucon",
    r"joke",
    r"kode program",
    r"write (?:me )?(?:a|an|some) (?:code|essay|story)",
    r"cerita(?:kan)? dongeng",
    r"ramal",
    r"horoscope",
)


class KeywordInputGuard:
    """MOCK classifier. Order matters: medical and unsafe checks win over the rest."""

    guard_id = "guard.keywords"
    guard_version = "0.1.0"

    def classify(self, text: str) -> GuardResult:
        for category, pattern in (
            (InputCategory.MEDICAL, _MEDICAL),
            (InputCategory.UNSAFE_HANDLING, _UNSAFE_HANDLING),
            (InputCategory.FOOD_RULE_QUESTION, _FOOD_RULE_QUESTION),
            (InputCategory.OFF_TOPIC, _OFF_TOPIC),
        ):
            if pattern.search(text):
                return GuardResult(category, self.guard_id, self.guard_version)
        return GuardResult(InputCategory.COOKING, self.guard_id, self.guard_version)


# ---------- output guard ----------

_SAFETY_CLAIM = _words(
    r"aman\b",
    r"tidak aman",
    r"halal",
    r"haram",
    r"bebas \w+",
    r"tanpa alergen",
    r"safe\b",
    r"safety",
    r"allergen",
    r"\w+[- ]free\b",
    r"suitable for",
    r"cocok untuk (?:alergi|penderita)",
)
_HEALTH_CLAIM = _words(
    r"baik untuk (?:kesehatan|diabetes|jantung|darah)",
    r"menurunkan (?:kolesterol|gula|tekanan|berat)",
    r"sehat untuk",
    r"good for your",
    r"lowers? (?:cholesterol|blood|weight)",
    r"kalori",
    r"calorie",
    r"kkal",
    r"kcal",
    r"diet",
)
_TESTED_CLAIM = _words(r"teruji", r"sudah diuji", r"tested", r"terbukti", r"proven")


def output_violation(text: str) -> str | None:
    """Name of the first rule `text` breaks, or None. The name is safe to log."""
    for name, pattern in (
        ("safety_claim", _SAFETY_CLAIM),
        ("health_claim", _HEALTH_CLAIM),
        ("tested_claim", _TESTED_CLAIM),
        ("unsafe_handling", _UNSAFE_HANDLING),
        ("medical", _MEDICAL),
    ):
        if pattern.search(text):
            return name
    return None
