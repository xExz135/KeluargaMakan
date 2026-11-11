"""Fake Gemini and Groq REST APIs on an httpx2.MockTransport. No test reaches the network.

TEST FIXTURE: the keys below are made-up placeholders, not real credentials, and
the model answers are invented test data, not recognition, recipe or Taste &
Tweak content.
"""

from __future__ import annotations

import json
from collections.abc import Callable, Mapping, Sequence
from dataclasses import dataclass, field
from typing import Any

import httpx2
from fastapi.testclient import TestClient

from app.config import Settings
from app.main import create_app
from app.photos import InMemoryPhotoSource
from app.providers.registry import build_providers
from app.telemetry import InMemoryUsageSink
from tests.support import EXIF_JPEG, library_recipe, settings

# Distinct fake keys per slot, so a leak can be traced to its slot.
VISION_KEY = "fake-vision-key-test-only-1111111111"
LANGUAGE_KEY = "fake-language-key-test-only-2222222222"
BACKUP_KEY = "fake-backup-key-test-only-3333333333"
SPEECH_KEY = "fake-speech-key-test-only-4444444444"
ALL_KEYS = (VISION_KEY, LANGUAGE_KEY, BACKUP_KEY, SPEECH_KEY)

GEMINI_VISION_MODEL = "gemini-test-flash"
GEMINI_LANGUAGE_MODEL = "gemini-test-flash-lite"
GROQ_CHAT_MODEL = "test-org/groq-test-chat"
GROQ_STT_MODEL = "whisper-large-v3-turbo"

REAL_ENV = {
    "VISION_PROVIDER": "gemini",
    "VISION_MODEL_ID": GEMINI_VISION_MODEL,
    "VISION_API_KEY": VISION_KEY,
    "LANGUAGE_PROVIDER": "gemini",
    "LANGUAGE_MODEL_ID": GEMINI_LANGUAGE_MODEL,
    "LANGUAGE_API_KEY": LANGUAGE_KEY,
    "LANGUAGE_BACKUP_PROVIDER": "groq",
    "LANGUAGE_BACKUP_MODEL_ID": GROQ_CHAT_MODEL,
    "LANGUAGE_BACKUP_API_KEY": BACKUP_KEY,
    "SPEECH_TO_TEXT_PROVIDER": "groq",
    "SPEECH_TO_TEXT_MODEL_ID": GROQ_STT_MODEL,
    "SPEECH_TO_TEXT_API_KEY": SPEECH_KEY,
}

GEMINI_HOST = "generativelanguage.googleapis.com"
GROQ_HOST = "api.groq.com"

type Reply = httpx2.Response | Callable[[httpx2.Request], httpx2.Response]


@dataclass
class FakeApis:
    """Routes: "gemini", "groq_chat", "groq_stt". Each holds a queue of replies; the
    last reply repeats once the queue is down to one."""

    routes: dict[str, list[Reply]] = field(default_factory=dict)
    requests: list[httpx2.Request] = field(default_factory=list)

    def on(self, route: str, *replies: Reply) -> FakeApis:
        self.routes[route] = list(replies)
        return self

    def transport(self) -> httpx2.MockTransport:
        return httpx2.MockTransport(self._handle)

    def sent(self, route: str) -> list[httpx2.Request]:
        return [r for r in self.requests if route_of(r) == route]

    def _handle(self, request: httpx2.Request) -> httpx2.Response:
        self.requests.append(request)
        route = route_of(request)
        queue = self.routes.get(route)
        if not queue:
            return httpx2.Response(404, json={"error": {"message": "no fake route"}})
        reply = queue.pop(0) if len(queue) > 1 else queue[0]
        return reply(request) if callable(reply) else reply


def route_of(request: httpx2.Request) -> str:
    if request.url.host == GEMINI_HOST and request.url.path.endswith(":generateContent"):
        return "gemini"
    if request.url.host == GROQ_HOST and request.url.path == "/openai/v1/chat/completions":
        return "groq_chat"
    if request.url.host == GROQ_HOST and request.url.path == "/openai/v1/audio/transcriptions":
        return "groq_stt"
    return "unknown"


# ---------- provider replies ----------


def gemini_ok(
    output: object,
    *,
    finish: str = "STOP",
    model_version: str = "gemini-test-flash-001",
    text: str | None = None,
) -> httpx2.Response:
    return httpx2.Response(
        200,
        json={
            "candidates": [
                {
                    "content": {
                        "role": "model",
                        "parts": [{"text": json.dumps(output) if text is None else text}],
                    },
                    "finishReason": finish,
                    "index": 0,
                }
            ],
            "usageMetadata": {
                "promptTokenCount": 120,
                "candidatesTokenCount": 30,
                "thoughtsTokenCount": 10,
                "totalTokenCount": 160,
            },
            "modelVersion": model_version,
        },
    )


def groq_chat_ok(
    output: object, *, finish: str = "stop", text: str | None = None
) -> httpx2.Response:
    return httpx2.Response(
        200,
        json={
            "id": "chatcmpl-test",
            "object": "chat.completion",
            "model": GROQ_CHAT_MODEL,
            "choices": [
                {
                    "index": 0,
                    "message": {
                        "role": "assistant",
                        "content": json.dumps(output) if text is None else text,
                    },
                    "finish_reason": finish,
                }
            ],
            "usage": {"prompt_tokens": 80, "completion_tokens": 20, "total_tokens": 100},
            "x_groq": {"id": "req_test"},
        },
    )


def groq_stt_ok(
    text: str = "lanjut",
    *,
    segments: Sequence[Mapping[str, Any]] | None = None,
    duration: float = 1.5,
) -> httpx2.Response:
    if segments is None:
        segments = [
            {
                "id": 0,
                "start": 0.0,
                "end": 1.5,
                "text": text,
                "avg_logprob": -0.05,
                "no_speech_prob": 0.01,
                "compression_ratio": 1.0,
            },
        ]
    return httpx2.Response(
        200,
        json={"text": text, "duration": duration, "language": "id", "segments": segments},
    )


def quota(retry_after: str | None = None) -> httpx2.Response:
    headers = {"retry-after": retry_after} if retry_after else {}
    return httpx2.Response(
        429,
        headers=headers,
        json={"error": {"code": 429, "message": "quota", "status": "RESOURCE_EXHAUSTED"}},
    )


def status(code: int) -> httpx2.Response:
    return httpx2.Response(code, json={"error": {"code": code, "message": "fake failure"}})


def timeout(request: httpx2.Request) -> httpx2.Response:
    raise httpx2.ReadTimeout("fake timeout", request=request)


def connect_error(request: httpx2.Request) -> httpx2.Response:
    raise httpx2.ConnectError("fake connection failure", request=request)


# ---------- valid model outputs for each prompt (invented test data) ----------


def recognition_output() -> dict[str, Any]:
    return {
        "candidates": [
            {"rawName": "tempe", "confidence": 0.92, "photoIndex": 0},
            {
                "rawName": "tahu",
                "confidence": 0.4,
                "photoIndex": 0,
                "alternatives": [{"rawName": "tempe"}],
                "question": "[TEST] Ini tahu atau tempe?",
            },
        ],
        "confidence": 0.8,
    }


def tweak_output() -> dict[str, Any]:
    return {
        "fixes": [
            {
                "action": "[TEST] Kecilkan api dan masak 2 menit lagi.",
                "kind": "technique",
                "timing": "sekarang",
            }
        ],
        "confidence": 0.9,
    }


def adaptation_output() -> dict[str, Any]:
    recipe = library_recipe()
    return {
        "title": recipe["title"],
        "servings": 4,
        "totalTimeMinutes": recipe["totalTimeMinutes"],
        "ingredients": [
            {**item, "quantity": item["quantity"] * 2, "changed": True}
            for item in recipe["ingredients"]
        ],
        "steps": recipe["steps"],
        "changes": [{"kind": "scale", "note": "[TEST] Porsi disesuaikan."}],
        "note": "[TEST] Disesuaikan: porsi diubah.",
        "confidence": 0.85,
    }


# ---------- app harness with the real adapters ----------


@dataclass
class RealHarness:
    client: TestClient
    apis: FakeApis
    usage: InMemoryUsageSink
    settings: Settings


def real_settings(**env: str) -> Settings:
    return settings(**{**REAL_ENV, **env})


def real_harness(apis: FakeApis, **env: str) -> RealHarness:
    """The full service with the real Gemini and Groq adapters on the fake APIs."""
    s = real_settings(**env)
    usage = InMemoryUsageSink()
    app = create_app(
        s,
        providers=build_providers(s, transport=apis.transport()),
        photo_source=InMemoryPhotoSource(photos={}, default=EXIF_JPEG),
        usage_sink=usage,
    )
    return RealHarness(TestClient(app), apis, usage, s)
