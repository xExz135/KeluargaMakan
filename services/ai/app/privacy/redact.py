"""Remove contact details and personal names from free text (AI-03).

Structured fields cannot carry personal data: request schemas forbid unknown
fields and hold only abstract constraints. Free text (a typed Taste & Tweak
problem, a cooking question, text to read aloud) can, so it passes through
`redact` before it reaches a provider.

What this catches: email addresses, phone numbers (Indonesian formats such as
0812-3456-7890, +62 812 3456 7890, 62812..., (021) 555-1234, and other
international numbers), long digit runs such as an NIK, and a name that follows
an honorific or kinship word ("Bu Siti", "Pak Budi", "Adik Rara") or "nama
saya ...". A bare first name with no such cue cannot be detected here; the API
removes the household's own member names before it calls this service.
"""

from __future__ import annotations

import re

EMAIL_PLACEHOLDER = "[email]"
PHONE_PLACEHOLDER = "[telepon]"
NUMBER_PLACEHOLDER = "[nomor]"
NAME_PLACEHOLDER = "[nama]"

EMAIL_RE = re.compile(r"[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}")

# Indonesian mobile and landline numbers, with or without +62 / 62, and with
# spaces, dots, dashes or brackets between groups. At least 8 digits in total.
INDONESIAN_PHONE_RE = re.compile(
    r"(?<![\w+])(?:\+62|62|0)[\s.-]?\(?\d{1,4}\)?(?:[\s.-]?\d{2,5}){1,4}(?![\w])"
)
INTERNATIONAL_PHONE_RE = re.compile(r"(?<![\w+])\+\d{1,3}(?:[\s.-]?\(?\d{1,5}\)?){2,6}(?![\w])")
# NIK, account numbers and anything else that is a long number.
LONG_NUMBER_RE = re.compile(r"(?<!\w)\d(?:[\s.-]?\d){9,}(?!\w)")

_HONORIFICS = (
    "pak|bapak|bu|ibu|mbak|mba|mas|kak|kakak|dik|adik|dek|om|tante|oma|opa|nenek|"
    "kakek|eyang|mbah|bang|abang|teh|teteh|aa|uda|uni|bunda|mama|papa|ayah|bude|"
    "pakde|bulek|paklek|cik|koh|ci|ko|mr|mrs|ms|miss|aunt|auntie|uncle|grandma|grandpa"
)
_NAME = r"[A-Z][a-zA-Z'-]+(?:\s+[A-Z][a-zA-Z'-]+)?"
HONORIFIC_NAME_RE = re.compile(rf"\b((?i:{_HONORIFICS})\.?\s+)({_NAME})")
SELF_NAME_RE = re.compile(
    rf"\b((?i:nama\s+(?:saya|aku|anak\s+saya|suami\s+saya|istri\s+saya)|my\s+name\s+is|"
    rf"i\s+am|i'm)\s+)({_NAME})"
)


def _digit_count(text: str) -> int:
    return sum(char.isdigit() for char in text)


def _phone_sub(match: re.Match[str]) -> str:
    return PHONE_PLACEHOLDER if 8 <= _digit_count(match.group(0)) <= 15 else match.group(0)


def redact(text: str) -> str:
    """Return `text` with contact details and cue-detected names replaced."""
    text = EMAIL_RE.sub(EMAIL_PLACEHOLDER, text)
    text = INTERNATIONAL_PHONE_RE.sub(_phone_sub, text)
    text = INDONESIAN_PHONE_RE.sub(_phone_sub, text)
    text = LONG_NUMBER_RE.sub(NUMBER_PLACEHOLDER, text)
    text = HONORIFIC_NAME_RE.sub(lambda m: m.group(1) + NAME_PLACEHOLDER, text)
    text = SELF_NAME_RE.sub(lambda m: m.group(1) + NAME_PLACEHOLDER, text)
    return text


def find_contact_details(text: str) -> list[str]:
    """Every email address or phone-like number in `text`. Used by log scans."""
    found = EMAIL_RE.findall(text)
    for pattern in (INTERNATIONAL_PHONE_RE, INDONESIAN_PHONE_RE, LONG_NUMBER_RE):
        found.extend(
            match.group(0) for match in pattern.finditer(text) if _digit_count(match.group(0)) >= 8
        )
    return found
