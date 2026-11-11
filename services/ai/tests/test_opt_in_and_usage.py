"""AI-12, SET-09: free-tier providers may train on inputs, so nothing is sent for a
household that has not opted in. AI-09: usage is recorded per household pseudonym."""

from __future__ import annotations

import dataclasses

import pytest

from app.config import Capability, ConfigError
from app.main import create_app
from app.providers.base import Providers, Slot
from app.providers.mock import MockProvider
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


def test_ai12_set09_no_opt_in_means_no_provider_call_on_any_feature() -> None:
    h = harness()
    responses = {
        "recognition": h.client.post(
            "/recognize/ingredients", json=recognize_body(opt_in=False), headers=AUTH
        ),
        "adaptation": h.client.post("/adapt/recipe", json=adapt_body(opt_in=False), headers=AUTH),
        "tweak": h.client.post("/tweak", json=tweak_body(opt_in=False), headers=AUTH),
        "speech_to_text": h.client.post(
            "/speech/transcribe", content=b"\x00", headers=speech_headers(opt_in=False)
        ),
        "text_to_speech": h.client.post(
            "/speech/synthesize",
            json={"householdRef": HOUSEHOLD_REF, "text": "Langkah 1."},
            headers=AUTH,
        ),
    }
    for feature, response in responses.items():
        assert response.status_code == 403, feature
        assert response.json()["code"] == "ai_opt_in_required"
        assert response.json()["feature"] == feature
    assert not h.mock.calls
    assert {r.outcome for r in h.usage.records} == {Outcome.OPT_IN_REQUIRED}


def test_ai12_opt_in_is_off_by_default() -> None:
    h = harness()
    body = tweak_body()
    del body["dataUse"]
    assert h.client.post("/tweak", json=body, headers=AUTH).status_code == 403
    assert not h.mock.calls


def test_ai12_opted_in_call_to_a_free_tier_is_marked_as_training_allowed() -> None:
    h = harness()
    assert h.client.post("/tweak", json=tweak_body(), headers=AUTH).status_code == 200
    (call,) = h.mock.calls
    assert call.options.allow_training is True
    assert h.usage.records[0].tier == "free"


def test_ai12_paid_no_training_slot_serves_households_without_opt_in() -> None:
    h = harness(LANGUAGE_TIER="paid", LANGUAGE_TRAINS_ON_INPUTS="false")
    assert h.client.post("/tweak", json=tweak_body(opt_in=False), headers=AUTH).status_code == 200
    (call,) = h.mock.calls
    assert call.options.allow_training is False
    # Even with opt-in, a no-training slot is never told it may train.
    h.client.post("/tweak", json=tweak_body(opt_in=True), headers=AUTH)
    assert h.mock.calls[-1].options.allow_training is False


def test_ai12_without_opt_in_only_the_no_training_backup_is_used() -> None:
    s = settings(
        LANGUAGE_BACKUP_PROVIDER="mock",
        LANGUAGE_BACKUP_TIER="paid",
        LANGUAGE_BACKUP_TRAINS_ON_INPUTS="false",
    )
    free, paid = MockProvider(), MockProvider()
    base = mock_providers(s, free)
    primary_cfg, backup_cfg = s.providers[Capability.LANGUAGE]
    providers = Providers(
        vision=base.vision,
        language=(Slot(primary_cfg, free), Slot(backup_cfg, paid)),
        speech_to_text=base.speech_to_text,
        text_to_speech=base.text_to_speech,
    )
    app = create_app(s, providers=providers)
    from fastapi.testclient import TestClient

    response = TestClient(app).post("/tweak", json=tweak_body(opt_in=False), headers=AUTH)
    assert response.status_code == 200
    assert not free.calls
    assert len(paid.calls) == 1


@dataclasses.dataclass
class _CannotDisableTraining(MockProvider):
    @property
    def can_disable_training(self) -> bool:
        return False


def test_ai12_no_training_slot_needs_an_adapter_that_can_switch_training_off() -> None:
    s = settings(LANGUAGE_TIER="paid", LANGUAGE_TRAINS_ON_INPUTS="false")
    base = mock_providers(s, MockProvider())
    (cfg,) = s.providers[Capability.LANGUAGE]
    providers = dataclasses.replace(base, language=(Slot(cfg, _CannotDisableTraining()),))
    with pytest.raises(ConfigError, match="AI-12"):
        create_app(s, providers=providers)


def test_ai09_usage_is_recorded_per_household_pseudonym_and_month() -> None:
    h = harness()
    h.client.post("/recognize/ingredients", json=recognize_body(photos=2), headers=AUTH)
    h.client.post("/tweak", json=tweak_body(), headers=AUTH)
    vision, language = h.usage.records
    assert vision.household_ref == HOUSEHOLD_REF
    assert vision.feature == "recognition"
    assert vision.images == 2
    assert vision.input_tokens > 0
    assert len(vision.month) == 7
    assert language.feature == "tweak"
    assert language.output_tokens > 0
    assert language.model_id == "mock-language-1"
    assert language.prompt_version == "0.1.0"
    fields = {f.name for f in dataclasses.fields(vision)}
    assert not fields & {"prompt", "text", "transcript", "photo", "audio", "name"}


def test_ai09_speech_usage_counts_audio_seconds_and_characters() -> None:
    h = harness()
    h.client.post("/speech/transcribe", content=b"\x00" * 32000, headers=speech_headers())
    h.client.post(
        "/speech/synthesize",
        json={
            "householdRef": HOUSEHOLD_REF,
            "dataUse": {"aiImprovementOptIn": True},
            "text": "Langkah 1.",
        },
        headers=AUTH,
    )
    stt, tts = h.usage.records
    assert stt.audio_seconds == 1.0
    assert tts.characters == len("Langkah 1.")


def test_set09_photos_are_not_fetched_without_opt_in() -> None:
    from app.photos import DisabledPhotoSource

    s = settings()
    # A photo source that fails if touched proves nothing was fetched.
    app = create_app(
        s, providers=mock_providers(s, MockProvider()), photo_source=DisabledPhotoSource()
    )
    from fastapi.testclient import TestClient

    response = TestClient(app).post(
        "/recognize/ingredients", json=recognize_body(opt_in=False), headers=AUTH
    )
    assert response.status_code == 403
