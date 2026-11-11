"""The full service with the real Gemini and Groq adapters on fake APIs.

INT-06 to INT-08, AI-08 (fallbacks), AI-12 and SET-09 (opt-in gate), AI-01 (no
verdict slips through), and that API keys never reach logs, responses or errors.
No test reaches the network; the keys are fake (tests/fake_apis.py).
"""

from __future__ import annotations

import json
import logging
from typing import Any

import pytest

from app.config import Capability, ConfigError
from app.providers.registry import build_providers
from app.telemetry import JsonFormatter, Outcome, RedactingFilter
from tests.fake_apis import (
    ALL_KEYS,
    REAL_ENV,
    FakeApis,
    RealHarness,
    adaptation_output,
    connect_error,
    gemini_ok,
    groq_chat_ok,
    groq_stt_ok,
    quota,
    real_harness,
    real_settings,
    recognition_output,
    status,
    timeout,
    tweak_output,
)
from tests.support import (
    AUTH,
    adapt_body,
    recognize_body,
    settings,
    speech_headers,
    tweak_body,
)


def _healthy() -> FakeApis:
    """Gemini answers recognition and the language prompts; Groq answers both."""

    def gemini(request: Any) -> Any:
        text = json.loads(request.content)["systemInstruction"]["parts"][0]["text"]
        if "kitchen" in text:
            return gemini_ok(recognition_output())
        if "adapt" in text.lower() or "recipe" in text.lower():
            return gemini_ok(adaptation_output())
        return gemini_ok(tweak_output())

    return (
        FakeApis()
        .on("gemini", gemini)
        .on("groq_chat", groq_chat_ok(tweak_output()))
        .on("groq_stt", groq_stt_ok("lanjut"))
    )


def _post_all(h: RealHarness, opt_in: bool = True) -> dict[str, Any]:
    c = h.client
    return {
        "recognition": c.post(
            "/recognize/ingredients", json=recognize_body(opt_in=opt_in), headers=AUTH
        ),
        "adaptation": c.post("/adapt/recipe", json=adapt_body(opt_in=opt_in), headers=AUTH),
        "tweak": c.post("/tweak", json=tweak_body(opt_in=opt_in), headers=AUTH),
        "speech_to_text": c.post(
            "/speech/transcribe", content=b"\x00" * 64, headers=speech_headers(opt_in=opt_in)
        ),
    }


def _outcomes(h: RealHarness) -> list[tuple[str, str, Outcome]]:
    return [(r.feature, r.provider, r.outcome) for r in h.usage.records]


# ---------- AI-12, SET-09: opt-in gate ----------


def test_ai12_set09_free_tier_real_providers_get_nothing_without_opt_in() -> None:
    h = real_harness(_healthy())
    responses = _post_all(h, opt_in=False)
    for feature, response in responses.items():
        assert response.status_code == 403, feature
        assert response.json()["code"] == "ai_opt_in_required"
    assert h.apis.requests == []


def test_ai12_real_free_tier_slots_are_marked_as_training() -> None:
    providers = build_providers(real_settings(), transport=FakeApis().transport())
    for slot in providers.all_slots():
        if slot.adapter.name in ("gemini", "groq"):
            assert slot.config.trains_on_inputs is True
            assert slot.adapter.can_disable_training is False


def test_ai12_paid_gemini_may_be_configured_as_not_training() -> None:
    s = real_settings(VISION_TIER="paid", VISION_TRAINS_ON_INPUTS="false")
    providers = build_providers(s, transport=FakeApis().transport())
    assert providers.vision[0].adapter.can_disable_training is True


def test_ai12_groq_cannot_be_configured_as_not_training_even_on_paid() -> None:
    s = real_settings(LANGUAGE_BACKUP_TIER="paid", LANGUAGE_BACKUP_TRAINS_ON_INPUTS="false")
    with pytest.raises(ConfigError, match="cannot switch off training"):
        build_providers(s, transport=FakeApis().transport())


def test_ai12_paid_no_training_gemini_serves_households_without_opt_in() -> None:
    apis = _healthy()
    h = real_harness(apis, VISION_TIER="paid", VISION_TRAINS_ON_INPUTS="false")
    response = h.client.post(
        "/recognize/ingredients", json=recognize_body(opt_in=False), headers=AUTH
    )
    assert response.status_code == 200
    assert len(apis.sent("gemini")) == 1
    (record,) = h.usage.records
    assert record.outcome is Outcome.OK


# ---------- success through the real adapters ----------


def test_int06_to_int08_every_feature_works_through_the_real_adapters() -> None:
    h = real_harness(_healthy())
    responses = _post_all(h)
    for feature, response in responses.items():
        assert response.status_code == 200, (feature, response.json())
    assert responses["recognition"].json()["modelId"] == "gemini-test-flash-001"
    assert responses["recognition"].json()["ruleCheckRequired"] is True
    assert responses["tweak"].json()["modelId"] == "gemini-test-flash-001"
    assert responses["speech_to_text"].json()["modelId"] == "whisper-large-v3-turbo"
    assert responses["speech_to_text"].json()["transcript"] == "lanjut"
    assert responses["speech_to_text"].json()["promptVersion"] == "0.2.0"
    # Groq chat is only the backup; it was not needed.
    assert h.apis.sent("groq_chat") == []
    assert {o for _, _, o in _outcomes(h)} == {Outcome.OK}
    usage = {r.feature: r for r in h.usage.records}
    assert usage["recognition"].images == 1
    assert usage["recognition"].input_tokens == 120
    assert usage["speech_to_text"].audio_seconds == 1.5


# ---------- INT-07: primary -> backup ----------


@pytest.mark.parametrize(
    ("failure", "outcome"),
    [
        (quota(), Outcome.QUOTA_EXCEEDED),
        (timeout, Outcome.TIMEOUT),
        (status(503), Outcome.UNAVAILABLE),
        (connect_error, Outcome.UNAVAILABLE),
    ],
)
def test_int07_language_falls_back_from_gemini_to_groq(failure: Any, outcome: Outcome) -> None:
    apis = FakeApis().on("gemini", failure).on("groq_chat", groq_chat_ok(tweak_output()))
    h = real_harness(apis)
    response = h.client.post("/tweak", json=tweak_body(), headers=AUTH)
    assert response.status_code == 200, response.json()
    assert response.json()["modelId"] == "test-org/groq-test-chat"
    assert len(apis.sent("groq_chat")) == 1
    assert _outcomes(h) == [("tweak", "gemini", outcome), ("tweak", "groq", Outcome.OK)]


def test_int07_gemini_local_budget_spent_goes_straight_to_groq() -> None:
    apis = (
        FakeApis()
        .on("gemini", gemini_ok(tweak_output()))
        .on("groq_chat", groq_chat_ok(tweak_output()))
    )
    h = real_harness(apis, LANGUAGE_RPM="1")
    for _ in range(2):
        assert h.client.post("/tweak", json=tweak_body(), headers=AUTH).status_code == 200
    assert len(apis.sent("gemini")) == 1
    assert len(apis.sent("groq_chat")) == 1
    assert _outcomes(h)[1:] == [
        ("tweak", "gemini", Outcome.QUOTA_EXCEEDED),
        ("tweak", "groq", Outcome.OK),
    ]


@pytest.mark.parametrize("path", ["/tweak", "/adapt/recipe"])
def test_ai08_both_language_providers_down_is_ai_unavailable_with_fallback(path: str) -> None:
    apis = FakeApis().on("gemini", quota()).on("groq_chat", status(503))
    h = real_harness(apis)
    body = tweak_body() if path == "/tweak" else adapt_body()
    response = h.client.post(path, json=body, headers=AUTH)
    assert response.status_code == 503
    expected = "curated_fixes" if path == "/tweak" else "library_recipe"
    assert response.json() == {
        "code": "ai_unavailable",
        "feature": "tweak" if path == "/tweak" else "adaptation",
        "fallback": expected,
        "retryable": True,
    }


def test_ai08_vision_429_is_ai_unavailable_with_manual_entry() -> None:
    apis = FakeApis().on("gemini", quota())
    h = real_harness(apis)
    response = h.client.post("/recognize/ingredients", json=recognize_body(), headers=AUTH)
    assert response.status_code == 503
    assert response.json()["fallback"] == "manual_entry"
    assert len(apis.requests) == 1


def test_ai08_speech_timeout_is_ai_unavailable_with_touch_controls() -> None:
    apis = FakeApis().on("groq_stt", timeout)
    h = real_harness(apis)
    response = h.client.post("/speech/transcribe", content=b"\x00" * 64, headers=speech_headers())
    assert response.status_code == 503
    assert response.json()["fallback"] == "touch_controls"


# ---------- rejected output ----------


@pytest.mark.parametrize(
    "reply",
    [
        gemini_ok(None, text="not json at all"),
        gemini_ok(tweak_output(), finish="MAX_TOKENS"),
        # Valid JSON in the wrong shape.
        gemini_ok({"fixes": "add salt", "confidence": 2}),
        # AI-01: a verdict field is not in the schema, so the answer is refused.
        gemini_ok({**tweak_output(), "safe": True}),
    ],
)
def test_ai08_unusable_language_output_is_rejected_without_trying_backup(reply: Any) -> None:
    apis = FakeApis().on("gemini", reply).on("groq_chat", groq_chat_ok(tweak_output()))
    h = real_harness(apis)
    response = h.client.post("/tweak", json=tweak_body(), headers=AUTH)
    assert response.status_code == 502
    assert response.json() == {
        "code": "ai_output_rejected",
        "feature": "tweak",
        "fallback": "curated_fixes",
        "retryable": False,
    }
    assert apis.sent("groq_chat") == []
    assert _outcomes(h) == [("tweak", "gemini", Outcome.INVALID_OUTPUT)]


def test_ai01_recognition_output_with_a_verdict_field_is_rejected() -> None:
    output = recognition_output()
    output["candidates"][0]["halal"] = True
    apis = FakeApis().on("gemini", gemini_ok(output))
    h = real_harness(apis)
    response = h.client.post("/recognize/ingredients", json=recognize_body(), headers=AUTH)
    assert response.status_code == 502
    assert response.json()["code"] == "ai_output_rejected"


def test_ai01_requested_schemas_hold_no_safety_words() -> None:
    from app.providers.remote import OUTPUT_MODELS, output_schema
    from tests.test_no_safety_verdict import FORBIDDEN_WORDS, _names, _words

    for prompt_id in OUTPUT_MODELS:
        schema = output_schema("gemini", prompt_id)
        words = set().union(*(_words(name) for name in _names(schema)))
        assert not words & FORBIDDEN_WORDS, prompt_id


# ---------- configuration ----------


@pytest.mark.parametrize("missing", ["VISION_API_KEY", "VISION_MODEL_ID"])
def test_int06_real_provider_needs_a_key_and_a_model(missing: str) -> None:
    with pytest.raises(ConfigError, match=missing):
        settings(**{**REAL_ENV, missing: ""})


@pytest.mark.parametrize(
    "env",
    [
        {"SPEECH_TO_TEXT_PROVIDER": "gemini", "SPEECH_TO_TEXT_MODEL_ID": "m"},
        {"VISION_PROVIDER": "groq"},
        {
            "TEXT_TO_SPEECH_PROVIDER": "groq",
            "TEXT_TO_SPEECH_MODEL_ID": "m",
            "TEXT_TO_SPEECH_API_KEY": "fake-tts-key-test-only",
        },
    ],
)
def test_int06_provider_must_serve_the_slot_capability(env: dict[str, str]) -> None:
    with pytest.raises(ConfigError, match="does not serve"):
        settings(**{**REAL_ENV, **env})


def test_int06_slot_tuning_is_configuration() -> None:
    s = real_settings(
        LANGUAGE_REQUEST_TIMEOUT_SECONDS="2.5",
        LANGUAGE_MAX_RETRIES="0",
        LANGUAGE_MAX_OUTPUT_TOKENS="512",
        SPEECH_TO_TEXT_ASH="7200",
        SPEECH_TO_TEXT_ASD="28800",
    )
    slot = s.providers[Capability.LANGUAGE][0]
    assert (slot.request_timeout, slot.max_retries, slot.max_output_tokens) == (2.5, 0, 512)
    stt = s.providers[Capability.SPEECH_TO_TEXT][0]
    assert stt.rate_limits.audio_seconds_per_hour == 7200
    assert stt.rate_limits.audio_seconds_per_day == 28800
    # The feature budget keeps its own name: no clash with the slot's request timeout.
    assert s.timeouts.speech_to_text == 5.0


@pytest.mark.parametrize(
    "env",
    [
        {"LANGUAGE_MAX_RETRIES": "9"},
        {"LANGUAGE_REQUEST_TIMEOUT_SECONDS": "0"},
        {"LANGUAGE_MAX_OUTPUT_TOKENS": "0"},
        {"SPEECH_TO_TEXT_ASH": "-1"},
        {"VISION_MODEL_ID": "../../other"},
    ],
)
def test_int06_bad_slot_tuning_is_refused(env: dict[str, str]) -> None:
    with pytest.raises(ConfigError):
        build_providers(real_settings(**env), transport=FakeApis().transport())


# ---------- keys never leak ----------


def _scenario_apis() -> list[FakeApis]:
    return [
        _healthy(),
        FakeApis().on("gemini", quota("5")).on("groq_chat", status(500)).on("groq_stt", quota()),
        FakeApis().on("gemini", timeout).on("groq_chat", connect_error).on("groq_stt", timeout),
        FakeApis()
        .on("gemini", gemini_ok(None, text="nope"))
        .on("groq_chat", status(401))
        .on("groq_stt", status(400)),
    ]


def test_ai03_api_keys_never_reach_logs_responses_errors_or_reprs(
    caplog: pytest.LogCaptureFixture,
) -> None:
    formatter = JsonFormatter()
    redactor = RedactingFilter()
    bodies: list[str] = []
    with caplog.at_level(logging.DEBUG):
        for apis in _scenario_apis():
            h = real_harness(apis)
            for response in _post_all(h).values():
                bodies.append(response.text + json.dumps(dict(response.headers)))
            bodies.append(json.dumps([vars(r) for r in h.usage.records], default=str))
            bodies.append(repr(h.settings) + str(h.settings))
            providers = build_providers(h.settings, transport=apis.transport())
            bodies.append(repr(providers))
    lines = []
    for record in caplog.records:
        redactor.filter(record)
        lines.append(formatter.format(record))
    everything = "\n".join(bodies + lines + [caplog.text])
    assert any(r.name == "app.providers" for r in caplog.records)
    for key in ALL_KEYS:
        assert key not in everything


def test_ai03_keys_are_sent_only_in_headers() -> None:
    apis = _healthy()
    h = real_harness(apis)
    _post_all(h)
    assert apis.requests
    for request in apis.requests:
        assert request.url.scheme == "https"
        assert request.url.query == b""
        for key in ALL_KEYS:
            assert key not in str(request.url)
            assert key.encode() not in request.content
