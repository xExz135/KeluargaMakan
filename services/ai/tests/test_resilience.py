"""AI-08: provider down, slow, out of quota (HTTP 429) or disabled gives a clear
"AI unavailable" error with the fallback, never a fake or default result."""

from __future__ import annotations

from typing import Any

import pytest

from app.config import Capability
from app.photos import DisabledPhotoSource
from app.providers.base import Providers, Slot
from app.providers.disabled import DisabledProvider
from app.providers.mock import MockMode, MockProvider
from app.telemetry import Outcome
from tests.support import (
    AUTH,
    HOUSEHOLD_REF,
    adapt_body,
    harness,
    mock_providers,
    recognize_body,
    settings,
    speech_headers,
    tweak_body,
)

RESULT_FIELDS = {"candidates", "questions", "recipe", "fixes", "transcript", "audioBase64"}


def _calls(h: Any) -> dict[str, Any]:
    return {
        "recognition": h.client.post("/recognize/ingredients", json=recognize_body(), headers=AUTH),
        "adaptation": h.client.post("/adapt/recipe", json=adapt_body(), headers=AUTH),
        "tweak": h.client.post("/tweak", json=tweak_body(), headers=AUTH),
        "speech_to_text": h.client.post(
            "/speech/transcribe", content=b"\x00" * 10, headers=speech_headers()
        ),
        "text_to_speech": h.client.post(
            "/speech/synthesize",
            json={
                "householdRef": HOUSEHOLD_REF,
                "dataUse": {"aiImprovementOptIn": True},
                "text": "Langkah 1.",
            },
            headers=AUTH,
        ),
    }


FALLBACKS = {
    "recognition": "manual_entry",
    "adaptation": "library_recipe",
    "tweak": "curated_fixes",
    "speech_to_text": "touch_controls",
    "text_to_speech": "device_text_to_speech",
}


@pytest.mark.parametrize("mode", [MockMode.ERROR, MockMode.TIMEOUT, MockMode.QUOTA_EXCEEDED])
def test_ai08_every_feature_answers_ai_unavailable_with_its_fallback(mode: MockMode) -> None:
    timeouts = {
        f"{name.upper()}_TIMEOUT_SECONDS": "0.05"
        for name in ("recognition", "adaptation", "tweak", "speech_to_text", "text_to_speech")
    }
    h = harness(mock=MockProvider(mode=mode), env=timeouts)
    for feature, response in _calls(h).items():
        assert response.status_code == 503, feature
        body = response.json()
        assert body == {
            "code": "ai_unavailable",
            "feature": feature,
            "fallback": FALLBACKS[feature],
            "retryable": True,
        }
        assert not RESULT_FIELDS & set(body)


def test_ai08_quota_exceeded_is_logged_as_such() -> None:
    h = harness(mock=MockProvider(mode=MockMode.QUOTA_EXCEEDED))
    h.client.post("/tweak", json=tweak_body(), headers=AUTH)
    (record,) = h.usage.records
    assert record.outcome is Outcome.QUOTA_EXCEEDED


def test_int07_backup_language_provider_answers_when_the_primary_hits_its_quota() -> None:
    s = settings(LANGUAGE_BACKUP_PROVIDER="mock")
    primary, backup = MockProvider(mode=MockMode.QUOTA_EXCEEDED), MockProvider()
    base = mock_providers(s, backup)
    primary_cfg, backup_cfg = s.providers[Capability.LANGUAGE]
    providers = Providers(
        vision=base.vision,
        language=(Slot(primary_cfg, primary), Slot(backup_cfg, backup)),
        speech_to_text=base.speech_to_text,
        text_to_speech=base.text_to_speech,
    )
    h = harness(providers=providers, LANGUAGE_BACKUP_PROVIDER="mock")
    response = h.client.post("/tweak", json=tweak_body(), headers=AUTH)
    assert response.status_code == 200
    assert len(primary.calls) == 1
    assert len(backup.calls) == 1
    outcomes = [(r.slot, r.outcome) for r in h.usage.records]
    assert outcomes == [("language", Outcome.QUOTA_EXCEEDED), ("language_backup", Outcome.OK)]


def test_ai08_invalid_provider_output_is_rejected_not_defaulted() -> None:
    h = harness(mock=MockProvider(mode=MockMode.INVALID_OUTPUT))
    for feature in ("recognition", "adaptation", "tweak"):
        response = _calls(h)[feature]
        assert response.status_code == 502
        assert response.json()["code"] == "ai_output_rejected"
        assert response.json()["fallback"] == FALLBACKS[feature]


def test_ai08_disabled_provider_answers_ai_unavailable() -> None:
    s = settings()
    disabled = DisabledProvider()
    providers = Providers(
        vision=tuple(Slot(c, disabled) for c in s.providers[Capability.VISION]),
        language=tuple(Slot(c, disabled) for c in s.providers[Capability.LANGUAGE]),
        speech_to_text=tuple(Slot(c, disabled) for c in s.providers[Capability.SPEECH_TO_TEXT]),
    )
    h = harness(providers=providers)
    assert h.client.post("/tweak", json=tweak_body(), headers=AUTH).status_code == 503


def test_ai08_photo_source_down_means_manual_entry() -> None:
    from app.main import create_app

    s = settings()
    app = create_app(
        s, providers=mock_providers(s, MockProvider()), photo_source=DisabledPhotoSource()
    )
    from fastapi.testclient import TestClient

    response = TestClient(app).post("/recognize/ingredients", json=recognize_body(), headers=AUTH)
    assert response.status_code == 503
    assert response.json()["fallback"] == "manual_entry"


def test_ai08_guard_refusals_still_work_when_the_provider_is_down() -> None:
    h = harness(mock=MockProvider(mode=MockMode.ERROR))
    body = h.client.post(
        "/tweak", json=tweak_body(button=None, text="Untuk diabetes boleh?"), headers=AUTH
    ).json()
    assert body["status"] == "referral"
