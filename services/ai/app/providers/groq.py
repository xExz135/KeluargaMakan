"""Groq adapter: backup language (INT-07) and Whisper speech-to-text (INT-08).

Calls Groq's OpenAI-compatible REST API over HTTPS:

- `POST /openai/v1/chat/completions` with `response_format` type `json_schema`
  (best effort, `strict: false`: strict mode needs every property required,
  which the service's output models do not follow). The answer is parsed here
  and validated again by the route. A cut-off, non-JSON or schema-refused answer
  is rejected.
- `POST /openai/v1/audio/transcriptions` (multipart) with `verbose_json`, so a
  confidence can be derived from the segment log-probabilities and the
  no-speech probability. Audio is sent from memory and never stored.

The API key goes in the `Authorization: Bearer` header, never in the URL.
Groq's chat API does not support `store`, and no per-call training switch is
documented, so this adapter never claims it can switch training off: Groq slots
stay `trains_on_inputs=true` and are only called for opted-in households.

Model names and limits come from configuration (LANGUAGE_BACKUP_*, SPEECH_TO_TEXT_*).
"""

from __future__ import annotations

import asyncio
import math
import re
import time
from collections.abc import Mapping
from typing import Any

import httpx2

from app.config import ConfigError, ProviderConfig, SecretKey
from app.providers.base import (
    AudioInput,
    CallOptions,
    ModelOutput,
    ProviderOutputError,
    RenderedPrompt,
    Transcription,
    Usage,
)
from app.providers.remote import (
    Clock,
    LocalBudget,
    RemoteClient,
    Sleep,
    estimate_tokens,
    output_schema,
    parse_json_object,
    response_json,
)

GROQ_BASE_URL = "https://api.groq.com/openai/v1"
NAME = "groq"
# Groq bills every transcription as at least 10 seconds; the local audio budget
# counts it the same way.
MIN_BILLED_AUDIO_SECONDS = 10.0
# Whisper accepts a prompt of at most 224 tokens; keep the hint well under it.
MAX_SPEECH_HINT_CHARS = 600
MAX_TRANSCRIPT_CHARS = 2000

_MODEL_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._/-]{0,99}$")
_SCHEMA_NAME_RE = re.compile(r"[^A-Za-z0-9_-]")

AUDIO_EXTENSIONS: Mapping[str, str] = {
    "audio/wav": "wav",
    "audio/x-wav": "wav",
    "audio/ogg": "ogg",
    "audio/webm": "webm",
    "audio/mpeg": "mp3",
    "audio/mp4": "m4a",
    "audio/flac": "flac",
}


class GroqProvider:
    def __init__(
        self,
        config: ProviderConfig,
        *,
        transport: httpx2.AsyncBaseTransport | None = None,
        clock: Clock = time.monotonic,
        sleep: Sleep = asyncio.sleep,
    ) -> None:
        key, model = config.api_key, config.model_id
        if key is None or not model:
            raise ConfigError(f"{config.slot}: groq needs a model ID and an API key")
        if not _MODEL_RE.match(model):
            raise ConfigError(f"{config.slot.upper()}_MODEL_ID is not a valid Groq model name")
        self._config = config
        self._key: SecretKey = key
        self._model: str = model
        self._budget = LocalBudget(NAME, config.rate_limits, clock)
        self._http = RemoteClient(NAME, config, self._budget, transport=transport, sleep=sleep)

    @property
    def name(self) -> str:
        return NAME

    @property
    def can_disable_training(self) -> bool:
        # No documented per-call or per-tier switch was verified (open question).
        return False

    def __repr__(self) -> str:
        return f"GroqProvider(slot={self._config.slot!r}, model={self._model!r})"

    def _headers(self) -> dict[str, str]:
        return {"Authorization": f"Bearer {self._key.reveal()}"}

    # ---------- language ----------

    async def complete(self, prompt: RenderedPrompt, options: CallOptions) -> ModelOutput:
        body = {
            "model": self._model,
            "messages": [
                {"role": "system", "content": prompt.system},
                {"role": "user", "content": prompt.user},
            ],
            "response_format": {
                "type": "json_schema",
                "json_schema": {
                    "name": _SCHEMA_NAME_RE.sub("_", prompt.prompt_id),
                    "strict": False,
                    "schema": output_schema(NAME, prompt.prompt_id),
                },
            },
            "max_completion_tokens": self._config.max_output_tokens,
        }
        reservation = self._budget.reserve(tokens=estimate_tokens(prompt.system, prompt.user))
        response = await self._http.post(
            f"{GROQ_BASE_URL}/chat/completions",
            headers=self._headers(),
            json_body=body,
            deadline=options.deadline,
            classify=_schema_refusal,
        )
        envelope = response_json(NAME, response)
        usage = _chat_usage(envelope.get("usage"))
        self._budget.settle(reservation, tokens=usage.input_tokens + usage.output_tokens)
        text = _chat_text(envelope)
        return ModelOutput(
            data=parse_json_object(NAME, text),
            model_id=self._model_id(envelope.get("model")),
            usage=usage,
        )

    # ---------- speech-to-text ----------

    async def transcribe(
        self, audio: AudioInput, prompt: RenderedPrompt, options: CallOptions
    ) -> Transcription:
        extension = AUDIO_EXTENSIONS.get(audio.mime_type)
        if extension is None:
            raise ProviderOutputError(f"{NAME}: unsupported audio type")
        form = {
            "model": self._model,
            "response_format": "verbose_json",
            "temperature": "0",
            "language": options.language,
        }
        hint = prompt.system.strip()[:MAX_SPEECH_HINT_CHARS]
        if hint:
            form["prompt"] = hint
        reservation = self._budget.reserve(audio_seconds=MIN_BILLED_AUDIO_SECONDS)
        response = await self._http.post(
            f"{GROQ_BASE_URL}/audio/transcriptions",
            headers=self._headers(),
            files={"file": (f"audio.{extension}", audio.data, audio.mime_type)},
            data=form,
            deadline=options.deadline,
        )
        envelope = response_json(NAME, response)
        text = envelope.get("text")
        if not isinstance(text, str):
            raise ProviderOutputError(f"{NAME}: transcription has no text")
        text = text.strip()
        if len(text) > MAX_TRANSCRIPT_CHARS:
            raise ProviderOutputError(f"{NAME}: transcription too long")
        segments = envelope.get("segments")
        segments = segments if isinstance(segments, list) else []
        duration = _duration(envelope.get("duration"), segments)
        self._budget.settle(reservation, audio_seconds=max(MIN_BILLED_AUDIO_SECONDS, duration))
        return Transcription(
            text=text,
            confidence=_confidence(segments) if text else 0.0,
            model_id=self._model,
            usage=Usage(audio_seconds=round(duration, 3)),
        )

    def _model_id(self, reported: object) -> str:
        if isinstance(reported, str) and _MODEL_RE.match(reported):
            return reported
        return self._model


def _schema_refusal(response: httpx2.Response) -> Exception | None:
    """Groq answers 400 when the generated JSON does not match the schema: that is
    unusable output (rejected), not an outage. Any other 400 is an outage."""
    if response.status_code != 400:
        return None
    try:
        body = response.json()
    except ValueError:
        return None
    error = body.get("error") if isinstance(body, dict) else None
    if not isinstance(error, dict):
        return None
    code = error.get("code")
    message = error.get("message")
    if code == "json_validate_failed" or (
        isinstance(message, str) and "does not match the expected schema" in message
    ):
        return ProviderOutputError(f"{NAME}: output did not match the schema")
    return None


def _chat_text(envelope: Mapping[str, Any]) -> str:
    choices = envelope.get("choices")
    if not isinstance(choices, list) or not choices or not isinstance(choices[0], dict):
        raise ProviderOutputError(f"{NAME}: no answer")
    choice = choices[0]
    if choice.get("finish_reason") != "stop":
        # "length" would be cut-off JSON; anything else is not a finished answer.
        raise ProviderOutputError(f"{NAME}: answer not finished")
    message = choice.get("message")
    content = message.get("content") if isinstance(message, dict) else None
    if not isinstance(content, str) or not content.strip():
        raise ProviderOutputError(f"{NAME}: answer has no text")
    return content


def _chat_usage(usage: object) -> Usage:
    values = usage if isinstance(usage, dict) else {}

    def count(key: str) -> int:
        value = values.get(key)
        return value if isinstance(value, int) and value >= 0 else 0

    return Usage(input_tokens=count("prompt_tokens"), output_tokens=count("completion_tokens"))


def _duration(reported: object, segments: list[Any]) -> float:
    if isinstance(reported, int | float) and math.isfinite(reported) and reported >= 0:
        return float(reported)
    ends = [
        seg["end"]
        for seg in segments
        if isinstance(seg, dict) and isinstance(seg.get("end"), int | float)
    ]
    return float(max(ends)) if ends else 0.0


def _confidence(segments: list[Any]) -> float:
    """Duration-weighted mean of exp(avg_logprob) * (1 - no_speech_prob).

    A heuristic, not a calibrated probability: it only decides whether the app
    shows "needs clarification" (AI-06, VOI-05). No segments means no evidence,
    so confidence is 0 and the app asks again.
    """
    total_weight = 0.0
    total = 0.0
    for seg in segments:
        if not isinstance(seg, dict):
            continue
        logprob = seg.get("avg_logprob")
        no_speech = seg.get("no_speech_prob", 0.0)
        if not isinstance(logprob, int | float) or not isinstance(no_speech, int | float):
            continue
        if not (math.isfinite(logprob) and math.isfinite(no_speech)):
            continue
        start, end = seg.get("start"), seg.get("end")
        weight = (
            float(end) - float(start)
            if isinstance(start, int | float) and isinstance(end, int | float) and end > start
            else 1.0
        )
        score = math.exp(min(0.0, float(logprob))) * (1.0 - min(1.0, max(0.0, float(no_speech))))
        total += score * weight
        total_weight += weight
    if total_weight <= 0:
        return 0.0
    return round(min(1.0, max(0.0, total / total_weight)), 3)
