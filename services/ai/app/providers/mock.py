"""Deterministic mock provider for tests and local development.

MOCK OUTPUT ONLY. Nothing here is recognition, recipe or Taste & Tweak content:
the texts are placeholders marked "[MOCK]" and no reviewed cook wrote them. The
mock is refused outside local and test environments (config.Settings).

Behaviour is chosen with `MockMode`, and tests can replace the output for a
prompt ID with `responses`. Each call is recorded (prompt, options, media
digests, never the media bytes) so tests can check what a provider would have
received.
"""

from __future__ import annotations

import asyncio
import hashlib
import struct
from collections import deque
from collections.abc import Mapping, Sequence
from dataclasses import dataclass, field
from enum import StrEnum

from app.providers.base import (
    AudioInput,
    CallOptions,
    ImageInput,
    ModelOutput,
    ProviderQuotaExceededError,
    ProviderUnavailableError,
    RenderedPrompt,
    SynthesizedSpeech,
    Transcription,
    Usage,
)

MOCK_PREFIX = "[MOCK] "
MOCK_HANG_SECONDS = 60.0


class MockMode(StrEnum):
    NORMAL = "normal"
    LOW_CONFIDENCE = "low_confidence"
    ERROR = "error"
    QUOTA_EXCEEDED = "quota_exceeded"
    TIMEOUT = "timeout"
    INVALID_OUTPUT = "invalid_output"


@dataclass(frozen=True)
class RecordedCall:
    method: str
    prompt: RenderedPrompt
    options: CallOptions
    media_sha256: tuple[str, ...] = ()
    text: str | None = None


@dataclass
class MockProvider:
    mode: MockMode = MockMode.NORMAL
    responses: dict[str, Mapping[str, object]] = field(default_factory=dict)
    calls: deque[RecordedCall] = field(default_factory=lambda: deque(maxlen=100))

    @property
    def name(self) -> str:
        return "mock"

    @property
    def can_disable_training(self) -> bool:
        return True

    def model_id(self, method: str) -> str:
        return f"mock-{method}-1"

    async def _misbehave(self) -> None:
        if self.mode is MockMode.ERROR:
            raise ProviderUnavailableError("mock provider error")
        if self.mode is MockMode.QUOTA_EXCEEDED:
            # What an adapter raises for HTTP 429 or an exhausted free-tier quota.
            raise ProviderQuotaExceededError("mock quota exceeded")
        if self.mode is MockMode.TIMEOUT:
            await asyncio.sleep(MOCK_HANG_SECONDS)
            raise ProviderUnavailableError("mock provider hung")

    def _output(
        self, prompt: RenderedPrompt, default: Mapping[str, object]
    ) -> Mapping[str, object]:
        if self.mode is MockMode.INVALID_OUTPUT:
            return {"unexpected": "shape"}
        return self.responses.get(prompt.prompt_id, default)

    # ---------- vision ----------

    async def analyze(
        self, prompt: RenderedPrompt, images: Sequence[ImageInput], options: CallOptions
    ) -> ModelOutput:
        digests = tuple(hashlib.sha256(image.data).hexdigest() for image in images)
        self.calls.append(RecordedCall("analyze", prompt, options, digests))
        await self._misbehave()
        return ModelOutput(
            data=self._output(prompt, self._recognition(prompt, len(images))),
            model_id=self.model_id("vision"),
            usage=Usage(input_tokens=_tokens(prompt), output_tokens=40, images=len(images)),
        )

    def _recognition(self, prompt: RenderedPrompt, image_count: int) -> Mapping[str, object]:
        low = self.mode is MockMode.LOW_CONFIDENCE
        candidates: list[dict[str, object]] = []
        saved = prompt.payload.get("savedIngredients")
        if isinstance(saved, list) and saved and isinstance(saved[0], dict):
            first = saved[0]
            candidates.append(
                {
                    "rawName": first.get("name"),
                    "ingredientId": first.get("ingredientId"),
                    "confidence": 0.4 if low else 0.95,
                    "photoIndex": 0,
                }
            )
        candidates.append(
            {"rawName": "tempe", "confidence": 0.4 if low else 0.9, "photoIndex": image_count - 1}
        )
        candidates.append(
            {
                "rawName": "tahu",
                "confidence": 0.45,
                "photoIndex": 0,
                "alternatives": [{"rawName": "tempe"}],
                "question": MOCK_PREFIX + "Ini tahu atau tempe?",
            }
        )
        return {"candidates": candidates, "confidence": 0.4 if low else 0.8}

    # ---------- language ----------

    async def complete(self, prompt: RenderedPrompt, options: CallOptions) -> ModelOutput:
        self.calls.append(RecordedCall("complete", prompt, options))
        await self._misbehave()
        if prompt.prompt_id == "adapt.recipe":
            default = self._adaptation(prompt)
        elif prompt.prompt_id == "tweak.advice":
            default = self._tweak(prompt)
        elif prompt.prompt_id in self.responses:
            default = {}
        else:
            raise ProviderUnavailableError("mock has no output for this prompt")
        return ModelOutput(
            data=self._output(prompt, default),
            model_id=self.model_id("language"),
            usage=Usage(input_tokens=_tokens(prompt), output_tokens=120),
        )

    def _confidence(self) -> float:
        return 0.3 if self.mode is MockMode.LOW_CONFIDENCE else 0.85

    def _adaptation(self, prompt: RenderedPrompt) -> Mapping[str, object]:
        recipe = prompt.payload.get("libraryRecipe")
        if not isinstance(recipe, dict):
            raise ProviderUnavailableError("mock needs a library recipe")
        servings = recipe.get("servings")
        target = prompt.payload.get("targetServings") or servings
        factor = target / servings if isinstance(target, int) and isinstance(servings, int) else 1
        ingredients = []
        for item in recipe.get("ingredients", []):
            scaled = dict(item)
            quantity = item.get("quantity")
            if isinstance(quantity, int | float) and factor != 1:
                scaled["quantity"] = round(quantity * factor, 2)
                scaled["changed"] = True
            ingredients.append(scaled)
        output: dict[str, object] = {
            "title": recipe.get("title"),
            "servings": target,
            "totalTimeMinutes": recipe.get("totalTimeMinutes"),
            "ingredients": ingredients,
            "steps": recipe.get("steps"),
            "changes": [{"kind": "scale", "note": MOCK_PREFIX + "Porsi disesuaikan."}],
            "note": MOCK_PREFIX + "Disesuaikan: porsi diubah.",
            "confidence": self._confidence(),
        }
        if self.mode is MockMode.LOW_CONFIDENCE:
            output["questions"] = [MOCK_PREFIX + "Mau pakai tempe atau tahu?"]
        return output

    def _tweak(self, prompt: RenderedPrompt) -> Mapping[str, object]:
        problem = prompt.payload.get("problem")
        button = problem.get("button") if isinstance(problem, dict) else None
        key = button if isinstance(button, str) else None
        fixes = _MOCK_FIXES.get(key, _MOCK_FIXES[None])
        output: dict[str, object] = {"fixes": fixes, "confidence": self._confidence()}
        if self.mode is MockMode.LOW_CONFIDENCE:
            output = {
                "fixes": [],
                "question": MOCK_PREFIX + "Terlalu asin atau terlalu pedas?",
                "confidence": 0.3,
            }
        return output

    # ---------- speech ----------

    async def transcribe(
        self, audio: AudioInput, prompt: RenderedPrompt, options: CallOptions
    ) -> Transcription:
        digest = (hashlib.sha256(audio.data).hexdigest(),)
        self.calls.append(RecordedCall("transcribe", prompt, options, digest))
        await self._misbehave()
        text = "lanjut" if options.language == "id" else "next"
        return Transcription(
            text=MOCK_PREFIX + text,
            confidence=self._confidence(),
            model_id=self.model_id("stt"),
            usage=Usage(audio_seconds=round(len(audio.data) / 32000, 3)),
        )

    async def synthesize(
        self, text: str, prompt: RenderedPrompt, options: CallOptions
    ) -> SynthesizedSpeech:
        self.calls.append(RecordedCall("synthesize", prompt, options, text=text))
        await self._misbehave()
        return SynthesizedSpeech(
            audio=_silent_wav(),
            mime_type="audio/wav",
            model_id=self.model_id("tts"),
            usage=Usage(characters=len(text)),
        )


def _tokens(prompt: RenderedPrompt) -> int:
    """Rough token estimate so metering has a number to record."""
    return (len(prompt.system) + len(prompt.user)) // 4


def _silent_wav(samples: int = 160, rate: int = 16000) -> bytes:
    data = b"\x00\x00" * samples
    header = b"RIFF" + struct.pack("<I", 36 + len(data)) + b"WAVEfmt "
    header += struct.pack("<IHHIIHH", 16, 1, 1, rate, rate * 2, 2, 16)
    return header + b"data" + struct.pack("<I", len(data)) + data


def _fix(action: str, kind: str, timing: str, **extra: object) -> dict[str, object]:
    return {"action": MOCK_PREFIX + action, "kind": kind, "timing": timing, **extra}


_MOCK_FIXES: dict[str | None, list[dict[str, object]]] = {
    None: [_fix("Kecilkan api dan masak 2 menit lagi.", "technique", "sekarang")],
    "tooSalty": [_fix("Tambahkan air panas sedikit demi sedikit.", "liquid", "sekarang")],
    "bland": [
        _fix(
            "Tambahkan garam sedikit.",
            "salt",
            "sekarang",
            ingredient={"rawName": "garam"},
            amount={"quantity": 0.25, "unit": "sdt", "text": "¼ sdt"},
        ),
        _fix(
            "Tambahkan air jeruk nipis.",
            "acid",
            "di akhir",
            ingredient={"rawName": "jeruk nipis"},
            amount={"quantity": 1, "unit": "sdt", "text": "1 sdt"},
        ),
    ],
}
