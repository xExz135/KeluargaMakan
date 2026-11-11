"""The provider adapter interface (INT-06 vision, INT-07 language, INT-08 speech).

Every external AI provider sits behind one of these protocols. Feature code only
talks to the protocols, so a provider can be added or swapped without touching
the endpoints (QUESTIONS #8: no provider is chosen yet).

Contract for every adapter:

- Receives only the rendered, privacy-minimized prompt and the in-memory media
  for this call. Never writes media or prompt text to disk or logs.
- Sends the call with training on user content switched off unless
  `CallOptions.allow_training` is true (AI-12).
- Returns parsed JSON (vision and language) for the caller to validate, and the
  provider's own model ID and usage for tracing and metering (AI-09, AI-11).
- Raises `ProviderUnavailableError` on any failure: `ProviderTimeoutError` for a
  timeout, `ProviderQuotaExceededError` for HTTP 429 or an exhausted free-tier
  quota. It never substitutes a default answer.
- Is built from its `ProviderConfig` (model ID, tier, `trains_on_inputs`, rate
  limit hints). Whether a call may be sent at all is decided by the pipeline:
  a slot that trains on inputs is only used for an opted-in household.
"""

from __future__ import annotations

from collections.abc import Mapping, Sequence
from dataclasses import dataclass
from typing import Protocol, runtime_checkable

from app.config import Capability, ProviderConfig


class ProviderUnavailableError(Exception):
    """The provider could not answer. Message must not contain user content."""


class ProviderTimeoutError(ProviderUnavailableError):
    pass


class ProviderQuotaExceededError(ProviderUnavailableError):
    """The provider refused for quota or rate limit (HTTP 429). Same as an outage
    for the caller: "AI unavailable" with the feature's fallback (AI-08)."""


@dataclass(frozen=True)
class CallOptions:
    language: str
    # AI-12: true only when the slot's provider may train on inputs AND this
    # request carries the household's opt-in (SET-09). Otherwise the call must
    # go out with training off, and a provider that cannot do that is refused.
    allow_training: bool = False


@dataclass(frozen=True)
class Usage:
    """Metering units for AI-09. Counts only, never content."""

    input_tokens: int = 0
    output_tokens: int = 0
    images: int = 0
    audio_seconds: float = 0.0
    characters: int = 0


@dataclass(frozen=True)
class RenderedPrompt:
    prompt_id: str
    version: str
    template_sha256: str
    capability: Capability
    system: str
    user: str
    # The minimized payload the user text was rendered from, for adapters that
    # send structured input. Holds no household reference or opt-in flags.
    payload: Mapping[str, object]


@dataclass(frozen=True)
class ImageInput:
    """Photo bytes with metadata already stripped. In memory only."""

    data: bytes
    mime_type: str


@dataclass(frozen=True)
class AudioInput:
    data: bytes
    mime_type: str


@dataclass(frozen=True)
class ModelOutput:
    data: Mapping[str, object]
    model_id: str
    usage: Usage


@dataclass(frozen=True)
class Transcription:
    text: str
    confidence: float
    model_id: str
    usage: Usage


@dataclass(frozen=True)
class SynthesizedSpeech:
    audio: bytes
    mime_type: str
    model_id: str
    usage: Usage


@runtime_checkable
class Provider(Protocol):
    @property
    def name(self) -> str: ...

    @property
    def can_disable_training(self) -> bool:
        """True when the provider honours a per-call no-training setting or contract.

        A provider that cannot keep user content out of training is refused at
        startup (AI-12).
        """
        ...


class VisionProvider(Provider, Protocol):
    async def analyze(
        self, prompt: RenderedPrompt, images: Sequence[ImageInput], options: CallOptions
    ) -> ModelOutput: ...


class LanguageProvider(Provider, Protocol):
    async def complete(self, prompt: RenderedPrompt, options: CallOptions) -> ModelOutput: ...


class SpeechToTextProvider(Provider, Protocol):
    async def transcribe(
        self, audio: AudioInput, prompt: RenderedPrompt, options: CallOptions
    ) -> Transcription: ...


class TextToSpeechProvider(Provider, Protocol):
    async def synthesize(
        self, text: str, prompt: RenderedPrompt, options: CallOptions
    ) -> SynthesizedSpeech: ...


@dataclass(frozen=True)
class Slot[P: Provider]:
    """A configured adapter: the primary or the backup for one capability."""

    config: ProviderConfig
    adapter: P


@dataclass(frozen=True)
class Providers:
    """Adapters per capability, primary first. Text-to-speech may be empty: it runs
    on the phone (DECISIONS 2026-11-11)."""

    vision: tuple[Slot[VisionProvider], ...]
    language: tuple[Slot[LanguageProvider], ...]
    speech_to_text: tuple[Slot[SpeechToTextProvider], ...]
    text_to_speech: tuple[Slot[TextToSpeechProvider], ...] = ()

    def all_slots(self) -> list[Slot[Provider]]:
        return [*self.vision, *self.language, *self.speech_to_text, *self.text_to_speech]
