"""Shared helpers for AI service tests.

TEST FIXTURE: not real safety or nutrition data. Ingredient names, recipe text
and personal details below are invented for tests only.
"""

from __future__ import annotations

from collections.abc import Mapping
from dataclasses import dataclass
from typing import Any

from fastapi.testclient import TestClient

from app.config import Capability, Settings, load_settings
from app.main import create_app
from app.photos import InMemoryPhotoSource
from app.providers.base import Providers, Slot
from app.providers.mock import MockProvider
from app.telemetry import InMemoryUsageSink

TOKEN = "test-only-internal-token-0000000000000000"
AUTH = {"Authorization": f"Bearer {TOKEN}"}
PHOTO_HOST = "photos.example.test"
HOUSEHOLD_REF = "hh_test_pseudonym_0001"

BASE_ENV = {
    "AI_ENV": "test",
    "AI_SERVICE_AUTH_TOKEN": TOKEN,
    "PHOTO_URL_ALLOWED_HOSTS": PHOTO_HOST,
    "TEXT_TO_SPEECH_PROVIDER": "mock",
}


def _jpeg_segment(marker: int, data: bytes) -> bytes:
    return bytes((0xFF, marker)) + (len(data) + 2).to_bytes(2, "big") + data


# A JPEG carrying an EXIF APP1 segment with a fake GPS marker, and a comment.
EXIF_JPEG = (
    b"\xff\xd8"
    + _jpeg_segment(0xE0, b"JFIF\x00\x01\x01\x00\x00\x01\x00\x01\x00\x00")
    + _jpeg_segment(0xE1, b"Exif\x00\x00GPS-6.2000,106.8166")
    + _jpeg_segment(0xFE, b"CAMERA-XYZ")
    + _jpeg_segment(0xDB, b"\x00\x01\x02")
    + _jpeg_segment(0xDA, b"\x00\x00")
    + b"\x12\x34\x56"
    + b"\xff\xd9"
)


def settings(**env: str) -> Settings:
    return load_settings({**BASE_ENV, **env})


@dataclass
class Harness:
    client: TestClient
    mock: MockProvider
    usage: InMemoryUsageSink
    settings: Settings


def mock_providers(settings_: Settings, mock: MockProvider) -> Providers:
    def chain(capability: Capability) -> tuple[Slot[MockProvider], ...]:
        return tuple(Slot(config, mock) for config in settings_.providers.get(capability, ()))

    return Providers(
        vision=chain(Capability.VISION),
        language=chain(Capability.LANGUAGE),
        speech_to_text=chain(Capability.SPEECH_TO_TEXT),
        text_to_speech=chain(Capability.TEXT_TO_SPEECH),
    )


def harness(
    *,
    mock: MockProvider | None = None,
    photos: Mapping[str, bytes] | None = None,
    providers: Providers | None = None,
    env: Mapping[str, str] | None = None,
    **more_env: str,
) -> Harness:
    s = settings(**{**(env or {}), **more_env})
    mock = mock or MockProvider()
    usage = InMemoryUsageSink()
    app = create_app(
        s,
        providers=providers or mock_providers(s, mock),
        photo_source=InMemoryPhotoSource(photos=photos or {}, default=EXIF_JPEG),
        usage_sink=usage,
    )
    return Harness(TestClient(app), mock, usage, s)


def context(opt_in: bool = True) -> dict[str, Any]:
    return {
        "householdRef": HOUSEHOLD_REF,
        "language": "id",
        "dataUse": {"aiImprovementOptIn": opt_in},
    }


def recognize_body(opt_in: bool = True, photos: int = 1) -> dict[str, Any]:
    return {
        **context(opt_in),
        "photos": [{"url": f"https://{PHOTO_HOST}/upload/p{i}.jpg"} for i in range(photos)],
        "savedIngredients": [{"ingredientId": "fixture_bayam", "name": "bayam"}],
    }


def library_recipe() -> dict[str, Any]:
    return {
        "recipeId": "fixture_recipe_tumis",
        "version": "1",
        "title": "Tumis contoh",
        "cuisine": "indonesian",
        "servings": 2,
        "totalTimeMinutes": 20,
        "ingredients": [
            {"ingredientId": "fixture_bayam", "rawName": "bayam", "quantity": 200, "unit": "gram"},
            {
                "ingredientId": "fixture_bawang_putih",
                "rawName": "bawang putih",
                "quantity": 2,
                "unit": "siung",
            },
        ],
        "steps": [{"index": 1, "text": "Tumis bawang putih sampai harum."}],
    }


def adapt_body(opt_in: bool = True) -> dict[str, Any]:
    return {
        **context(opt_in),
        "libraryRecipe": library_recipe(),
        "availableIngredients": [{"ingredientId": "fixture_tempe", "rawName": "tempe"}],
        "constraints": {"avoid": ["shellfish"], "lessSalt": True},
        "adaptations": ["scale"],
        "targetServings": 4,
    }


def tweak_body(
    *,
    button: str | None = "bland",
    text: str | None = None,
    opt_in: bool = True,
    **constraints: Any,
) -> dict[str, Any]:
    problem: dict[str, Any] = {}
    if button:
        problem["button"] = button
    if text:
        problem["text"] = text
    return {
        **context(opt_in),
        "recipe": {
            "recipeId": "fixture_recipe_sayur",
            "title": "Sayur contoh",
            "cuisine": "indonesian",
            "currentStep": {"index": 3, "text": "Masukkan sayur dan aduk."},
            "ingredients": [{"ingredientId": "fixture_bayam", "rawName": "bayam"}],
        },
        "problem": problem,
        "constraints": constraints,
        "availableIngredients": [],
    }


def speech_headers(opt_in: bool = True, mime: str = "audio/wav") -> dict[str, str]:
    return {
        **AUTH,
        "Content-Type": mime,
        "X-Household-Ref": HOUSEHOLD_REF,
        "X-Language": "id",
        "X-AI-Improvement-Opt-In": "true" if opt_in else "false",
    }
