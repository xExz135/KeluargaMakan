"""Gemini API adapter: vision (INT-06) and language (INT-07).

Calls `models/{model}:generateContent` over HTTPS with plain REST. That method is
stateless (the newer Interactions API stores each interaction server-side by
default), which keeps photos and prompts off Google's servers beyond the call
itself, apart from what the free-tier terms allow (DECISIONS 2026-11-11).

- The API key goes in the `x-goog-api-key` header, never in the URL.
- The answer is requested as JSON matching the prompt's output schema
  (`responseMimeType` + `responseJsonSchema`), then parsed here and validated
  again by the route. Blocked, cut-off or non-JSON answers are rejected.
- Photos are sent inline (base64) from memory, already stripped of metadata.
- Free tier: Google may use the content to improve its products, so free-tier
  slots carry `trains_on_inputs=true` and are only called for opted-in
  households (pipeline.eligible_slots). The paid tier does not use content
  for that, so a paid slot can be configured as not training.

Model names and limits come from configuration (VISION_*, LANGUAGE_*).
"""

from __future__ import annotations

import asyncio
import base64
import re
import time
from collections.abc import Mapping, Sequence
from typing import Any

import httpx2

from app.config import ConfigError, ProviderConfig, SecretKey, Tier
from app.providers.base import (
    CallOptions,
    ImageInput,
    ModelOutput,
    ProviderOutputError,
    RenderedPrompt,
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

GEMINI_BASE_URL = "https://generativelanguage.googleapis.com/v1beta"
NAME = "gemini"
# Gemini counts an image as a few hundred tokens; used for the local TPM estimate.
IMAGE_TOKEN_ESTIMATE = 300

_MODEL_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]{0,99}$")
_REASON_RE = re.compile(r"^[A-Z_]{1,40}$")


class GeminiProvider:
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
            raise ConfigError(f"{config.slot}: gemini needs a model ID and an API key")
        if not _MODEL_RE.match(model):
            raise ConfigError(f"{config.slot.upper()}_MODEL_ID is not a valid Gemini model name")
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
        # Paid tier: "Used to improve our products: No" (Gemini API pricing page).
        return self._config.tier is Tier.PAID

    def __repr__(self) -> str:
        return f"GeminiProvider(slot={self._config.slot!r}, model={self._config.model_id!r})"

    async def analyze(
        self, prompt: RenderedPrompt, images: Sequence[ImageInput], options: CallOptions
    ) -> ModelOutput:
        parts: list[dict[str, object]] = [{"text": prompt.user}]
        for image in images:
            parts.append(
                {
                    "inlineData": {
                        "mimeType": image.mime_type,
                        "data": base64.b64encode(image.data).decode("ascii"),
                    }
                }
            )
        return await self._generate(prompt, parts, len(images), options)

    async def complete(self, prompt: RenderedPrompt, options: CallOptions) -> ModelOutput:
        return await self._generate(prompt, [{"text": prompt.user}], 0, options)

    async def _generate(
        self,
        prompt: RenderedPrompt,
        parts: list[dict[str, object]],
        image_count: int,
        options: CallOptions,
    ) -> ModelOutput:
        config = self._config
        body = {
            "systemInstruction": {"parts": [{"text": prompt.system}]},
            "contents": [{"role": "user", "parts": parts}],
            "generationConfig": {
                "candidateCount": 1,
                "maxOutputTokens": config.max_output_tokens,
                "responseMimeType": "application/json",
                "responseJsonSchema": output_schema(NAME, prompt.prompt_id),
            },
        }
        estimate = estimate_tokens(prompt.system, prompt.user) + IMAGE_TOKEN_ESTIMATE * image_count
        reservation = self._budget.reserve(tokens=estimate)
        response = await self._http.post(
            f"{GEMINI_BASE_URL}/models/{self._model}:generateContent",
            headers={"x-goog-api-key": self._key.reveal()},
            json_body=body,
            deadline=options.deadline,
        )
        envelope = response_json(NAME, response)
        usage = _usage(envelope.get("usageMetadata"), image_count)
        self._budget.settle(reservation, tokens=usage.input_tokens + usage.output_tokens)
        text = _answer_text(envelope)
        model_version = envelope.get("modelVersion")
        model_id = (
            model_version
            if isinstance(model_version, str) and _MODEL_RE.match(model_version)
            else self._model
        )
        return ModelOutput(data=parse_json_object(NAME, text), model_id=model_id, usage=usage)


def _answer_text(envelope: Mapping[str, Any]) -> str:
    feedback = envelope.get("promptFeedback")
    if isinstance(feedback, dict) and feedback.get("blockReason"):
        raise ProviderOutputError(f"{NAME}: request blocked ({_reason(feedback['blockReason'])})")
    candidates = envelope.get("candidates")
    if not isinstance(candidates, list) or not candidates or not isinstance(candidates[0], dict):
        raise ProviderOutputError(f"{NAME}: no answer")
    candidate = candidates[0]
    finish = candidate.get("finishReason")
    if finish != "STOP":
        # MAX_TOKENS would be cut-off JSON; SAFETY, RECITATION and others are
        # answers the provider withheld. None of them is used.
        raise ProviderOutputError(f"{NAME}: answer not finished ({_reason(finish)})")
    content = candidate.get("content")
    parts = content.get("parts") if isinstance(content, dict) else None
    if not isinstance(parts, list):
        raise ProviderOutputError(f"{NAME}: answer has no content")
    texts = [
        part["text"]
        for part in parts
        if isinstance(part, dict) and isinstance(part.get("text"), str) and not part.get("thought")
    ]
    if not texts:
        raise ProviderOutputError(f"{NAME}: answer has no text")
    return "".join(texts)


def _usage(metadata: object, image_count: int) -> Usage:
    values = metadata if isinstance(metadata, dict) else {}

    def count(key: str) -> int:
        value = values.get(key)
        return value if isinstance(value, int) and value >= 0 else 0

    return Usage(
        input_tokens=count("promptTokenCount"),
        output_tokens=count("candidatesTokenCount") + count("thoughtsTokenCount"),
        images=image_count,
    )


def _reason(value: object) -> str:
    return value if isinstance(value, str) and _REASON_RE.match(value) else "unknown"
