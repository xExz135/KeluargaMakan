"""AI-03: minimum data to providers, and no personal data in prompt or response logs.

Fictional personal details below are test data only.
"""

from __future__ import annotations

import json
import logging
from typing import Any

import pytest

from app.privacy.redact import find_contact_details, redact
from app.providers.mock import MockProvider
from tests.support import (
    AUTH,
    HOUSEHOLD_REF,
    adapt_body,
    harness,
    recognize_body,
    speech_headers,
    tweak_body,
)

INDONESIAN_PHONES = [
    "0812-3456-7890",
    "081234567890",
    "0812 3456 7890",
    "+62 812 3456 7890",
    "+6281234567890",
    "6281234567890",
    "(021) 555-1234",
    "021-5551234",
    "+62 21 5551234",
]
OTHER_CONTACTS = ["+1 415 555 0100", "siti.rahma@example.com", "budi_s+food@mail.example.id"]
NAMES = ["Siti Rahmawati", "Budi", "Rara"]
PII_TEXT = (
    "Bu Siti Rahmawati bilang rasanya hambar, hubungi 0812-3456-7890 atau "
    "siti.rahma@example.com. Pak Budi minta, kata Adik Rara juga, +62 21 5551234."
)


@pytest.mark.parametrize("phone", INDONESIAN_PHONES + OTHER_CONTACTS)
def test_ai03_redact_removes_contact_details(phone: str) -> None:
    cleaned = redact(f"Telepon saya {phone} ya")
    assert phone not in cleaned
    assert find_contact_details(cleaned) == []
    assert find_contact_details(f"Telepon saya {phone} ya")


def test_ai03_redact_removes_names_after_honorifics_and_keeps_cooking_text() -> None:
    cleaned = redact("Bu Siti suka pedas, Pak Budi tidak. Nama saya Rara. Tambah 100 ml air.")
    for name in [*NAMES[1:], "Siti"]:
        assert name not in cleaned
    assert "Tambah 100 ml air." in cleaned
    assert redact("Tumis 2 siung bawang putih 5 menit.") == "Tumis 2 siung bawang putih 5 menit."


def test_ai03_redact_removes_long_id_numbers() -> None:
    assert "3174012345678901" not in redact("NIK 3174012345678901")


@pytest.mark.parametrize(
    "extra",
    [
        {"memberName": "Siti"},
        {"memberIds": ["m_1"]},
        {"phone": "081234567890"},
        {"members": [{"name": "Budi", "rules": ["shellfish"]}]},
        {"healthConditions": ["diabetes"]},
    ],
)
def test_ai03_requests_reject_personal_fields(extra: dict[str, Any]) -> None:
    h = harness()
    response = h.client.post("/tweak", json={**tweak_body(), **extra}, headers=AUTH)
    assert response.status_code == 422
    assert not h.mock.calls


@pytest.mark.parametrize("tag", ["diabetes", "hipertensi", "darah_tinggi", "celiac", "hamil"])
def test_ai03_constraint_tags_cannot_name_health_conditions(tag: str) -> None:
    h = harness()
    body = tweak_body(avoid=[tag])
    response = h.client.post("/tweak", json=body, headers=AUTH)
    assert response.status_code == 422
    assert not h.mock.calls


@pytest.mark.parametrize("ref", ["siti.rahma@example.com", "081234567890123456", "short"])
def test_ai03_household_ref_must_be_an_opaque_pseudonym(ref: str) -> None:
    h = harness()
    response = h.client.post("/tweak", json={**tweak_body(), "householdRef": ref}, headers=AUTH)
    assert response.status_code == 422


def test_ai03_validation_errors_do_not_echo_submitted_values() -> None:
    h = harness()
    body = {**tweak_body(), "memberName": "Siti Rahmawati", "phone": "081234567890"}
    response = h.client.post("/tweak", json=body, headers=AUTH)
    assert response.status_code == 422
    text = response.text
    assert "Siti" not in text
    assert "081234567890" not in text


def _prompt_text(mock: MockProvider) -> str:
    return "\n".join(
        call.prompt.system + call.prompt.user + json.dumps(call.prompt.payload) + (call.text or "")
        for call in mock.calls
    )


def _run_everything(h: Any) -> list[Any]:
    """Call every endpoint with personal details in every free-text field."""
    tweak = tweak_body(button=None, text=PII_TEXT)
    tweak["availableIngredients"] = [{"rawName": "sambal Bu Siti 0812-3456-7890"}]
    recognize = recognize_body()
    recognize["savedIngredients"] = [{"ingredientId": "fixture_x", "name": "kue Pak Budi"}]
    adapt = adapt_body()
    adapt["availableIngredients"] = [{"rawName": "rendang Bu Siti siti.rahma@example.com"}]
    return [
        h.client.post("/tweak", json=tweak, headers=AUTH),
        h.client.post("/recognize/ingredients", json=recognize, headers=AUTH),
        h.client.post("/adapt/recipe", json=adapt, headers=AUTH),
        h.client.post("/speech/transcribe", content=b"\x00" * 64, headers=speech_headers()),
        h.client.post(
            "/speech/synthesize",
            json={
                "householdRef": HOUSEHOLD_REF,
                "dataUse": {"aiImprovementOptIn": True},
                "text": PII_TEXT,
            },
            headers=AUTH,
        ),
    ]


def test_ai03_prompts_sent_to_providers_carry_no_contact_details_or_cued_names() -> None:
    h = harness()
    responses = _run_everything(h)
    assert [r.status_code for r in responses] == [200] * 5
    sent = _prompt_text(h.mock)
    assert find_contact_details(sent) == []
    for name in ("Siti", "Rahmawati", "Budi", "Rara"):
        assert name not in sent
    # The household pseudonym is for metering only and never reaches a provider.
    assert HOUSEHOLD_REF not in sent


def test_ai03_prompt_and_response_logs_contain_no_personal_data(
    caplog: pytest.LogCaptureFixture,
) -> None:
    h = harness()
    with caplog.at_level(logging.DEBUG):
        _run_everything(h)
        # Failure paths log too.
        h.mock.mode = h.mock.mode.ERROR
        _run_everything(h)
    logged = "\n".join(
        record.getMessage() + json.dumps(getattr(record, "fields", {}), default=str)
        for record in caplog.records
    )
    assert any(r.name == "app.ai_calls" for r in caplog.records)
    assert find_contact_details(logged) == []
    for secret in ("Siti", "Rahmawati", "Budi", "Rara", "hambar", "sambal", "rendang", "kue"):
        assert secret not in logged
    usage = json.dumps([vars(record) for record in h.usage.records], default=str)
    assert find_contact_details(usage) == []
    for secret in ("Siti", "Budi", "Rara", "hambar"):
        assert secret not in usage


def test_ai03_redacting_log_filter_scrubs_stray_contact_details() -> None:
    from app.telemetry import JsonFormatter, RedactingFilter

    record = logging.LogRecord(
        "app.x", logging.INFO, __file__, 1, "call %s", ("0812-3456-7890",), None
    )
    record.fields = {"note": "siti.rahma@example.com"}
    RedactingFilter().filter(record)
    line = JsonFormatter().format(record)
    assert find_contact_details(line) == []
