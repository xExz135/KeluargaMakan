"""INT-06, INT-07, INT-08: the Gemini and Groq REST adapters on fake APIs.

Covers the request shape (key in a header, JSON output requested with the
prompt's schema), parsing, usage, and every failure mode: 429, timeout, 5xx
with bounded retries, malformed and cut-off output, and the local free-tier
budget. No test reaches the network; the keys are fake (tests/fake_apis.py).
"""

from __future__ import annotations

import asyncio
import base64
import json
import traceback
from collections.abc import Awaitable, Callable
from typing import Any

import httpx2
import pytest

from app.config import Capability, ProviderConfig
from app.prompt_registry import PromptRegistry
from app.providers.base import (
    AudioInput,
    CallOptions,
    ImageInput,
    ProviderOutputError,
    ProviderQuotaExceededError,
    ProviderTimeoutError,
    ProviderUnavailableError,
    RenderedPrompt,
)
from app.providers.gemini import GEMINI_BASE_URL, GeminiProvider
from app.providers.groq import GROQ_BASE_URL, GroqProvider
from app.providers.remote import output_schema
from tests.fake_apis import (
    ALL_KEYS,
    BACKUP_KEY,
    GEMINI_LANGUAGE_MODEL,
    GEMINI_VISION_MODEL,
    GROQ_CHAT_MODEL,
    GROQ_STT_MODEL,
    LANGUAGE_KEY,
    SPEECH_KEY,
    VISION_KEY,
    FakeApis,
    connect_error,
    gemini_ok,
    groq_chat_ok,
    groq_stt_ok,
    quota,
    real_settings,
    recognition_output,
    status,
    timeout,
    tweak_output,
)

OPTIONS = CallOptions(language="id", allow_training=True)
IMAGE = ImageInput(data=b"\xff\xd8fake-jpeg-bytes\xff\xd9", mime_type="image/jpeg")
AUDIO = AudioInput(data=b"RIFF....WAVEfmt fake", mime_type="audio/wav")


class FakeClock:
    def __init__(self) -> None:
        self.now = 1000.0

    def __call__(self) -> float:
        return self.now


async def _no_sleep(_: float) -> None:
    return None


def _config(capability: Capability, env: dict[str, str], *, backup: bool = False) -> ProviderConfig:
    return real_settings(**env).providers[capability][1 if backup else 0]


def _vision(apis: FakeApis, clock: FakeClock | None = None, **env: str) -> GeminiProvider:
    return GeminiProvider(
        _config(Capability.VISION, env),
        transport=apis.transport(),
        clock=clock or FakeClock(),
        sleep=_no_sleep,
    )


def _gemini_language(apis: FakeApis, **env: str) -> GeminiProvider:
    return GeminiProvider(
        _config(Capability.LANGUAGE, env), transport=apis.transport(), sleep=_no_sleep
    )


def _groq_chat(apis: FakeApis, clock: FakeClock | None = None, **env: str) -> GroqProvider:
    return GroqProvider(
        _config(Capability.LANGUAGE, env, backup=True),
        transport=apis.transport(),
        clock=clock or FakeClock(),
        sleep=_no_sleep,
    )


def _groq_stt(apis: FakeApis, clock: FakeClock | None = None, **env: str) -> GroqProvider:
    return GroqProvider(
        _config(Capability.SPEECH_TO_TEXT, env),
        transport=apis.transport(),
        clock=clock or FakeClock(),
        sleep=_no_sleep,
    )


def _prompt(prompt_id: str, payload: dict[str, object] | None = None) -> RenderedPrompt:
    return PromptRegistry.load().active(prompt_id).render(payload or {}, "id")


def _run[T](coro: Awaitable[T]) -> T:
    async def main() -> T:
        return await coro

    return asyncio.run(main())


def _raises(coro: Awaitable[Any]) -> BaseException:
    try:
        _run(coro)
    except BaseException as exc:
        return exc
    raise AssertionError("expected an error")


def _no_key_in(exc: BaseException) -> None:
    text = "".join(traceback.format_exception(exc)) + repr(exc) + str(exc)
    for key in ALL_KEYS:
        assert key not in text
    # No HTTP client exception (which holds the request and its key header) rides
    # along for an error reporter that walks the exception chain.
    assert exc.__cause__ is None
    assert exc.__context__ is None


# ---------- request shape and success ----------


def test_int06_gemini_vision_sends_key_in_header_and_requests_schema_json() -> None:
    apis = FakeApis().on("gemini", gemini_ok(recognition_output()))
    adapter = _vision(apis)
    prompt = _prompt("recognize.ingredients", {"photoCount": 1, "savedIngredients": []})

    result = _run(adapter.analyze(prompt, [IMAGE], OPTIONS))

    (request,) = apis.requests
    assert str(request.url) == f"{GEMINI_BASE_URL}/models/{GEMINI_VISION_MODEL}:generateContent"
    assert request.url.scheme == "https"
    assert request.headers["x-goog-api-key"] == VISION_KEY
    assert VISION_KEY not in str(request.url)
    assert "authorization" not in request.headers
    body = json.loads(request.content)
    assert body["systemInstruction"] == {"parts": [{"text": prompt.system}]}
    parts = body["contents"][0]["parts"]
    assert parts[0] == {"text": prompt.user}
    assert parts[1]["inlineData"] == {
        "mimeType": "image/jpeg",
        "data": base64.b64encode(IMAGE.data).decode("ascii"),
    }
    config = body["generationConfig"]
    assert config["responseMimeType"] == "application/json"
    assert config["responseJsonSchema"] == output_schema("gemini", "recognize.ingredients")
    assert config["maxOutputTokens"] == 2048

    assert result.data == recognition_output()
    assert result.model_id == "gemini-test-flash-001"
    assert result.usage.input_tokens == 120
    assert result.usage.output_tokens == 40  # candidates + thoughts
    assert result.usage.images == 1


def test_int07_gemini_language_sends_text_only() -> None:
    apis = FakeApis().on("gemini", gemini_ok(tweak_output(), model_version=""))
    result = _run(_gemini_language(apis).complete(_prompt("tweak.advice"), OPTIONS))
    (request,) = apis.requests
    assert request.headers["x-goog-api-key"] == LANGUAGE_KEY
    assert GEMINI_LANGUAGE_MODEL in request.url.path
    parts = json.loads(request.content)["contents"][0]["parts"]
    assert all("inlineData" not in part for part in parts)
    assert result.data == tweak_output()
    # No usable modelVersion in the answer: the configured model is reported.
    assert result.model_id == GEMINI_LANGUAGE_MODEL


def test_int07_groq_chat_uses_bearer_header_and_json_schema() -> None:
    apis = FakeApis().on("groq_chat", groq_chat_ok(tweak_output()))
    prompt = _prompt("tweak.advice")
    result = _run(_groq_chat(apis).complete(prompt, OPTIONS))
    (request,) = apis.requests
    assert str(request.url) == f"{GROQ_BASE_URL}/chat/completions"
    assert request.headers["authorization"] == f"Bearer {BACKUP_KEY}"
    assert BACKUP_KEY not in str(request.url)
    body = json.loads(request.content)
    assert body["model"] == GROQ_CHAT_MODEL
    assert body["messages"] == [
        {"role": "system", "content": prompt.system},
        {"role": "user", "content": prompt.user},
    ]
    assert body["response_format"] == {
        "type": "json_schema",
        "json_schema": {
            "name": "tweak_advice",
            "strict": False,
            "schema": output_schema("groq", "tweak.advice"),
        },
    }
    assert result.data == tweak_output()
    assert result.model_id == GROQ_CHAT_MODEL
    assert (result.usage.input_tokens, result.usage.output_tokens) == (80, 20)


def test_int08_groq_whisper_transcribes_with_language_and_hint() -> None:
    apis = FakeApis().on("groq_stt", groq_stt_ok("lanjut"))
    prompt = _prompt("speech.transcribe")
    result = _run(_groq_stt(apis).transcribe(AUDIO, prompt, OPTIONS))
    (request,) = apis.requests
    assert str(request.url) == f"{GROQ_BASE_URL}/audio/transcriptions"
    assert request.headers["authorization"] == f"Bearer {SPEECH_KEY}"
    assert request.headers["content-type"].startswith("multipart/form-data")
    content = request.content
    for field, value in (
        ("model", GROQ_STT_MODEL),
        ("language", "id"),
        ("response_format", "verbose_json"),
        ("temperature", "0"),
        ("prompt", prompt.system),
    ):
        assert f'name="{field}"\r\n\r\n{value}\r\n'.encode() in content
    assert b'filename="audio.wav"' in content
    assert AUDIO.data in content
    assert result.text == "lanjut"
    assert result.model_id == GROQ_STT_MODEL
    assert 0.9 < result.confidence <= 1.0
    assert result.usage.audio_seconds == 1.5


def test_int08_whisper_confidence_is_low_for_silence_and_zero_without_segments() -> None:
    silent = [{"start": 0.0, "end": 1.0, "avg_logprob": -0.2, "no_speech_prob": 0.95}]
    apis = FakeApis().on(
        "groq_stt", groq_stt_ok("lanjut", segments=silent), groq_stt_ok("x", segments=[])
    )
    adapter = _groq_stt(apis)
    prompt = _prompt("speech.transcribe")
    assert _run(adapter.transcribe(AUDIO, prompt, OPTIONS)).confidence < 0.1
    assert _run(adapter.transcribe(AUDIO, prompt, OPTIONS)).confidence == 0.0


def test_int08_whisper_text_must_be_present_and_short() -> None:
    apis = FakeApis().on(
        "groq_stt",
        httpx2.Response(200, json={"segments": []}),
        groq_stt_ok("a" * 2001),
    )
    adapter = _groq_stt(apis)
    prompt = _prompt("speech.transcribe")
    for _ in range(2):
        assert isinstance(_raises(adapter.transcribe(AUDIO, prompt, OPTIONS)), ProviderOutputError)


# ---------- failures ----------


AdapterCall = Callable[[FakeApis], Awaitable[Any]]


def _gemini_call(apis: FakeApis) -> Awaitable[Any]:
    return _vision(apis).analyze(_prompt("recognize.ingredients"), [IMAGE], OPTIONS)


def _groq_chat_call(apis: FakeApis) -> Awaitable[Any]:
    return _groq_chat(apis).complete(_prompt("tweak.advice"), OPTIONS)


def _groq_stt_call(apis: FakeApis) -> Awaitable[Any]:
    return _groq_stt(apis).transcribe(AUDIO, _prompt("speech.transcribe"), OPTIONS)


CALLS: list[tuple[str, AdapterCall]] = [
    ("gemini", _gemini_call),
    ("groq_chat", _groq_chat_call),
    ("groq_stt", _groq_stt_call),
]


@pytest.mark.parametrize(("route", "call"), CALLS)
def test_ai08_http_429_is_quota_exceeded_without_retry(route: str, call: AdapterCall) -> None:
    apis = FakeApis().on(route, quota())
    exc = _raises(call(apis))
    assert type(exc) is ProviderQuotaExceededError
    assert len(apis.requests) == 1
    _no_key_in(exc)


@pytest.mark.parametrize(("route", "call"), CALLS)
def test_ai08_timeout_is_provider_timeout_without_retry(route: str, call: AdapterCall) -> None:
    apis = FakeApis().on(route, timeout)
    exc = _raises(call(apis))
    assert type(exc) is ProviderTimeoutError
    assert len(apis.requests) == 1
    _no_key_in(exc)


@pytest.mark.parametrize(("route", "call"), CALLS)
@pytest.mark.parametrize("code", [500, 502, 503, 504])
def test_ai08_5xx_is_retried_once_then_unavailable(
    route: str, call: AdapterCall, code: int
) -> None:
    apis = FakeApis().on(route, status(code))
    exc = _raises(call(apis))
    assert type(exc) is ProviderUnavailableError
    assert len(apis.requests) == 2  # default MAX_RETRIES=1
    _no_key_in(exc)


def test_ai08_connection_error_is_retried_then_unavailable() -> None:
    apis = FakeApis().on("gemini", connect_error)
    exc = _raises(_gemini_call(apis))
    assert type(exc) is ProviderUnavailableError
    assert len(apis.requests) == 2
    _no_key_in(exc)


def test_ai08_a_retry_that_succeeds_returns_the_answer() -> None:
    apis = FakeApis().on("gemini", status(503), gemini_ok(recognition_output()))
    assert _run(_gemini_call(apis)).data == recognition_output()
    assert len(apis.requests) == 2


@pytest.mark.parametrize("code", [400, 401, 403, 404])
def test_ai08_client_errors_are_unavailable_without_retry(code: int) -> None:
    apis = FakeApis().on("gemini", status(code))
    exc = _raises(_gemini_call(apis))
    assert type(exc) is ProviderUnavailableError
    assert str(exc) == f"gemini: http {code}"
    assert len(apis.requests) == 1


def test_ai08_retries_are_configurable_and_bounded() -> None:
    apis = FakeApis().on("gemini", status(503))
    _raises(
        _vision(apis, VISION_MAX_RETRIES="0").analyze(
            _prompt("recognize.ingredients"), [IMAGE], OPTIONS
        )
    )
    assert len(apis.requests) == 1


def test_ai08_no_retry_when_the_time_budget_would_be_exceeded() -> None:
    apis = FakeApis().on("gemini", status(503))
    adapter = _vision(apis)

    async def call() -> Any:
        deadline = asyncio.get_running_loop().time() + 0.3
        options = CallOptions(language="id", allow_training=True, deadline=deadline)
        return await adapter.analyze(_prompt("recognize.ingredients"), [IMAGE], options)

    assert type(_raises(call())) is ProviderUnavailableError
    assert len(apis.requests) == 1


def test_ai08_an_expired_budget_sends_nothing() -> None:
    apis = FakeApis().on("gemini", gemini_ok(recognition_output()))
    adapter = _vision(apis)

    async def call() -> Any:
        deadline = asyncio.get_running_loop().time() - 1
        options = CallOptions(language="id", allow_training=True, deadline=deadline)
        return await adapter.analyze(_prompt("recognize.ingredients"), [IMAGE], options)

    assert type(_raises(call())) is ProviderTimeoutError
    assert apis.requests == []


# ---------- malformed, cut-off and blocked output ----------


@pytest.mark.parametrize(
    "reply",
    [
        gemini_ok(None, text="this is not json"),
        gemini_ok(None, text='{"candidates": ['),
        gemini_ok(None, text="[1, 2, 3]"),
        gemini_ok(recognition_output(), finish="MAX_TOKENS"),
        gemini_ok(recognition_output(), finish="SAFETY"),
        gemini_ok(recognition_output(), finish="RECITATION"),
        httpx2.Response(200, json={"promptFeedback": {"blockReason": "SAFETY"}}),
        httpx2.Response(200, json={"candidates": []}),
        httpx2.Response(200, json={"candidates": [{"finishReason": "STOP", "content": {}}]}),
        httpx2.Response(200, content=b"<html>not json</html>"),
        httpx2.Response(200, json=["not", "an", "object"]),
    ],
)
def test_ai08_gemini_unusable_output_is_rejected(reply: httpx2.Response) -> None:
    apis = FakeApis().on("gemini", reply)
    exc = _raises(_gemini_call(apis))
    assert type(exc) is ProviderOutputError
    assert len(apis.requests) == 1


def test_ai08_gemini_thought_parts_are_not_part_of_the_answer() -> None:
    reply = httpx2.Response(
        200,
        json={
            "candidates": [
                {
                    "finishReason": "STOP",
                    "content": {
                        "parts": [
                            {"text": "thinking about it", "thought": True},
                            {"text": json.dumps(recognition_output())},
                        ]
                    },
                }
            ]
        },
    )
    apis = FakeApis().on("gemini", reply)
    assert _run(_gemini_call(apis)).data == recognition_output()


@pytest.mark.parametrize(
    "reply",
    [
        groq_chat_ok(None, text="not json"),
        groq_chat_ok(None, text='"a string"'),
        groq_chat_ok(tweak_output(), finish="length"),
        groq_chat_ok(None, text=""),
        httpx2.Response(200, json={"choices": []}),
        httpx2.Response(
            400,
            json={
                "error": {
                    "message": "Generated JSON does not match the expected schema. "
                    "Please adjust your prompt.",
                    "type": "invalid_request_error",
                    "code": "json_validate_failed",
                }
            },
        ),
    ],
)
def test_ai08_groq_unusable_output_is_rejected(reply: httpx2.Response) -> None:
    apis = FakeApis().on("groq_chat", reply)
    exc = _raises(_groq_chat_call(apis))
    assert type(exc) is ProviderOutputError
    assert len(apis.requests) == 1


def test_ai08_groq_other_400_is_an_outage_not_rejected_output() -> None:
    apis = FakeApis().on("groq_chat", status(400))
    assert type(_raises(_groq_chat_call(apis))) is ProviderUnavailableError


# ---------- local free-tier budget (AI-09) ----------


def test_ai09_rpm_budget_refuses_early_without_calling() -> None:
    apis = FakeApis().on("gemini", gemini_ok(recognition_output()))
    clock = FakeClock()
    adapter = _vision(apis, clock, VISION_RPM="2")
    prompt = _prompt("recognize.ingredients")
    _run(adapter.analyze(prompt, [IMAGE], OPTIONS))
    _run(adapter.analyze(prompt, [IMAGE], OPTIONS))
    exc = _raises(adapter.analyze(prompt, [IMAGE], OPTIONS))
    assert type(exc) is ProviderQuotaExceededError
    assert len(apis.requests) == 2
    clock.now += 61
    _run(adapter.analyze(prompt, [IMAGE], OPTIONS))
    assert len(apis.requests) == 3


def test_ai09_rpd_budget_refuses_until_a_day_has_passed() -> None:
    apis = FakeApis().on("groq_chat", groq_chat_ok(tweak_output()))
    clock = FakeClock()
    adapter = _groq_chat(apis, clock, LANGUAGE_BACKUP_RPD="1")
    prompt = _prompt("tweak.advice")
    _run(adapter.complete(prompt, OPTIONS))
    clock.now += 3600
    assert type(_raises(adapter.complete(prompt, OPTIONS))) is ProviderQuotaExceededError
    clock.now += 86400
    _run(adapter.complete(prompt, OPTIONS))
    assert len(apis.requests) == 2


def test_ai09_tpm_budget_counts_the_tokens_the_provider_reported() -> None:
    # Each answer reports 160 tokens (120 in, 30 out, 10 thinking).
    apis = FakeApis().on("gemini", gemini_ok(recognition_output()))
    clock = FakeClock()
    adapter = _vision(apis, clock, VISION_TPM="300")
    prompt = _prompt("recognize.ingredients")
    _run(adapter.analyze(prompt, [], OPTIONS))
    assert type(_raises(adapter.analyze(prompt, [], OPTIONS))) is ProviderQuotaExceededError
    assert len(apis.requests) == 1
    clock.now += 60
    _run(adapter.analyze(prompt, [], OPTIONS))


def test_ai09_audio_budget_counts_at_least_ten_billed_seconds() -> None:
    apis = FakeApis().on("groq_stt", groq_stt_ok("lanjut", duration=1.0))
    clock = FakeClock()
    adapter = _groq_stt(apis, clock, SPEECH_TO_TEXT_ASH="25")
    prompt = _prompt("speech.transcribe")
    _run(adapter.transcribe(AUDIO, prompt, OPTIONS))
    _run(adapter.transcribe(AUDIO, prompt, OPTIONS))
    # 2 x 10 billed seconds used; the next 10 would pass 25.
    assert type(_raises(adapter.transcribe(AUDIO, prompt, OPTIONS))) is ProviderQuotaExceededError
    assert len(apis.requests) == 2
    clock.now += 3601
    _run(adapter.transcribe(AUDIO, prompt, OPTIONS))


@pytest.mark.parametrize("hint", ["retry-after", "retry-info"])
def test_ai09_a_429_wait_hint_blocks_the_slot_locally(hint: str) -> None:
    if hint == "retry-after":
        first = quota(retry_after="30")
    else:
        first = httpx2.Response(
            429,
            json={
                "error": {
                    "code": 429,
                    "status": "RESOURCE_EXHAUSTED",
                    "details": [
                        {"@type": "type.googleapis.com/google.rpc.RetryInfo", "retryDelay": "30s"}
                    ],
                }
            },
        )
    apis = FakeApis().on("gemini", first, gemini_ok(recognition_output()))
    clock = FakeClock()
    adapter = _vision(apis, clock)
    prompt = _prompt("recognize.ingredients")
    assert type(_raises(adapter.analyze(prompt, [IMAGE], OPTIONS))) is ProviderQuotaExceededError
    clock.now += 10
    assert type(_raises(adapter.analyze(prompt, [IMAGE], OPTIONS))) is ProviderQuotaExceededError
    assert len(apis.requests) == 1
    clock.now += 21
    assert _run(adapter.analyze(prompt, [IMAGE], OPTIONS)).data == recognition_output()


# ---------- requested output schema ----------


@pytest.mark.parametrize("prompt_id", ["recognize.ingredients", "adapt.recipe", "tweak.advice"])
def test_int06_output_schema_is_portable_and_closed(prompt_id: str) -> None:
    schema = output_schema("gemini", prompt_id)

    def keywords(node: Any) -> set[str]:
        found: set[str] = set()
        if isinstance(node, list):
            for item in node:
                found |= keywords(item)
        elif isinstance(node, dict):
            for key, value in node.items():
                found.add(key)
                if key == "properties":
                    for sub in value.values():
                        found |= keywords(sub)
                else:
                    found |= keywords(value)
        return found

    used = keywords(schema)
    for keyword in ("$ref", "$defs", "pattern", "default", "title", "exclusiveMinimum", "const"):
        assert keyword not in used
    assert schema["type"] == "object"
    assert schema["additionalProperties"] is False
    # Each call gets its own copy.
    schema["properties"] = {}
    assert output_schema("gemini", prompt_id)["properties"]


def test_int06_unknown_prompt_has_no_schema_and_is_not_sent() -> None:
    apis = FakeApis().on("gemini", gemini_ok({}))
    prompt = _prompt("speech.synthesize")
    exc = _raises(_gemini_language(apis).complete(prompt, OPTIONS))
    assert type(exc) is ProviderUnavailableError
    assert apis.requests == []
