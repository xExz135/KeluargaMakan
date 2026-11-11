"""Configuration validation: AI-12, INT-06 to INT-08, AI-08 (fail closed)."""

from __future__ import annotations

import pytest

from app.config import Capability, ConfigError, ProviderName, Tier, load_settings
from tests.support import BASE_ENV, TOKEN, settings


def test_ai12_slots_assume_training_on_inputs_by_default() -> None:
    s = settings()
    for chain in s.providers.values():
        for slot in chain:
            assert slot.tier is Tier.FREE
            assert slot.trains_on_inputs is True


def test_ai12_free_tier_cannot_claim_no_training() -> None:
    with pytest.raises(ConfigError, match="AI-12"):
        settings(LANGUAGE_TRAINS_ON_INPUTS="false")


def test_ai12_paid_tier_may_declare_no_training() -> None:
    s = settings(LANGUAGE_TIER="paid", LANGUAGE_TRAINS_ON_INPUTS="false")
    (slot,) = s.providers[Capability.LANGUAGE]
    assert slot.tier is Tier.PAID
    assert slot.trains_on_inputs is False


def test_ai12_boolean_settings_are_strict() -> None:
    with pytest.raises(ConfigError, match="true or false"):
        settings(LANGUAGE_TRAINS_ON_INPUTS="no")


def test_int07_backup_language_slot_with_model_and_rate_limit_hints() -> None:
    s = settings(
        LANGUAGE_MODEL_ID="primary-model",
        LANGUAGE_RPM="15",
        LANGUAGE_RPD="1000",
        LANGUAGE_BACKUP_PROVIDER="mock",
        LANGUAGE_BACKUP_MODEL_ID="backup-model",
        LANGUAGE_BACKUP_TPM="6000",
    )
    primary, backup = s.providers[Capability.LANGUAGE]
    assert (primary.slot, primary.model_id) == ("language", "primary-model")
    assert primary.rate_limits.requests_per_minute == 15
    assert primary.rate_limits.requests_per_day == 1000
    assert (backup.slot, backup.model_id) == ("language_backup", "backup-model")
    assert backup.rate_limits.tokens_per_minute == 6000


def test_rate_limit_hints_must_be_positive() -> None:
    with pytest.raises(ConfigError):
        settings(VISION_RPM="0")


def test_int08_text_to_speech_slot_is_optional() -> None:
    env = {k: v for k, v in BASE_ENV.items() if k != "TEXT_TO_SPEECH_PROVIDER"}
    s = load_settings(env)
    assert s.providers[Capability.TEXT_TO_SPEECH] == ()
    assert s.providers[Capability.VISION][0].provider is ProviderName.MOCK


def test_mock_provider_is_refused_outside_local_and_test() -> None:
    env = {"AI_ENV": "production", "AI_SERVICE_AUTH_TOKEN": TOKEN}
    with pytest.raises(ConfigError, match="VISION_PROVIDER is required"):
        load_settings(env)
    for capability in ("VISION", "LANGUAGE", "SPEECH_TO_TEXT"):
        env[f"{capability}_PROVIDER"] = "mock"
    with pytest.raises(ConfigError, match="mock"):
        load_settings(env)


def test_staging_runs_with_disabled_providers_and_no_photo_source() -> None:
    env = {"AI_ENV": "staging", "AI_SERVICE_AUTH_TOKEN": TOKEN}
    for capability in ("VISION", "LANGUAGE", "SPEECH_TO_TEXT"):
        env[f"{capability}_PROVIDER"] = "disabled"
    s = load_settings(env)
    assert s.photo_source.value == "disabled"


def test_unknown_provider_name_is_refused() -> None:
    with pytest.raises(ConfigError, match="must be one of"):
        settings(VISION_PROVIDER="some-vendor")


def test_auth_token_is_required_and_long() -> None:
    with pytest.raises(ConfigError, match="required"):
        settings(AI_SERVICE_AUTH_TOKEN="")
    with pytest.raises(ConfigError, match="at least"):
        settings(AI_SERVICE_AUTH_TOKEN="short")


def test_targets_are_configuration() -> None:
    s = settings(
        MAX_PHOTOS_PER_REQUEST="3", RECOGNITION_TIMEOUT_SECONDS="7", TWEAK_MIN_CONFIDENCE="0.7"
    )
    assert s.limits.max_photos_per_request == 3
    assert s.timeouts.recognition == 7.0
    assert s.confidence.tweak == 0.7
    with pytest.raises(ConfigError):
        settings(TWEAK_MIN_CONFIDENCE="1.5")
