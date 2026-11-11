"""A provider that is switched off. Every call is "AI unavailable" (AI-08).

Used in staging and production until a real provider is chosen (QUESTIONS #8),
so the API exercises its fallbacks instead of receiving made-up output.
"""

from __future__ import annotations

from collections.abc import Sequence

from app.providers.base import (
    AudioInput,
    CallOptions,
    ImageInput,
    ModelOutput,
    ProviderUnavailableError,
    RenderedPrompt,
    SynthesizedSpeech,
    Transcription,
)


class DisabledProvider:
    @property
    def name(self) -> str:
        return "disabled"

    @property
    def can_disable_training(self) -> bool:
        return True

    async def analyze(
        self, prompt: RenderedPrompt, images: Sequence[ImageInput], options: CallOptions
    ) -> ModelOutput:
        raise ProviderUnavailableError("provider disabled")

    async def complete(self, prompt: RenderedPrompt, options: CallOptions) -> ModelOutput:
        raise ProviderUnavailableError("provider disabled")

    async def transcribe(
        self, audio: AudioInput, prompt: RenderedPrompt, options: CallOptions
    ) -> Transcription:
        raise ProviderUnavailableError("provider disabled")

    async def synthesize(
        self, text: str, prompt: RenderedPrompt, options: CallOptions
    ) -> SynthesizedSpeech:
        raise ProviderUnavailableError("provider disabled")
