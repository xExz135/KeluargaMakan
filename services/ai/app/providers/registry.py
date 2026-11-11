"""Build the configured provider slots and check them against AI-12 before startup.

Each capability has its own builder, so a provider can only be put in a slot for
a capability it implements (Gemini: vision and language; Groq: language and
speech-to-text; DECISIONS 2026-11-11). To add a provider: add its name to
`config.ProviderName` and `config.PROVIDER_CAPABILITIES`, write an adapter that
takes its `ProviderConfig` and implements the protocols in `base.py`, and add it
to the builders below.

`transport` replaces the HTTP transport of every real adapter. Tests pass an
`httpx2.MockTransport`, so no test reaches the network.
"""

from __future__ import annotations

from collections.abc import Callable

import httpx2

from app.config import Capability, ConfigError, ProviderConfig, ProviderName, Settings
from app.providers.base import (
    LanguageProvider,
    Provider,
    Providers,
    Slot,
    SpeechToTextProvider,
    TextToSpeechProvider,
    VisionProvider,
)
from app.providers.disabled import DisabledProvider
from app.providers.gemini import GeminiProvider
from app.providers.groq import GroqProvider
from app.providers.mock import MockProvider

type Transport = httpx2.AsyncBaseTransport | None


def _unsupported(config: ProviderConfig) -> ConfigError:
    return ConfigError(
        f"{config.slot.upper()}_PROVIDER: {config.provider.value!r} does not serve "
        f"{config.capability.value}"
    )


def _vision(config: ProviderConfig, transport: Transport) -> VisionProvider:
    match config.provider:
        case ProviderName.MOCK:
            return MockProvider()
        case ProviderName.DISABLED:
            return DisabledProvider()
        case ProviderName.GEMINI:
            return GeminiProvider(config, transport=transport)
        case _:
            raise _unsupported(config)


def _language(config: ProviderConfig, transport: Transport) -> LanguageProvider:
    match config.provider:
        case ProviderName.MOCK:
            return MockProvider()
        case ProviderName.DISABLED:
            return DisabledProvider()
        case ProviderName.GEMINI:
            return GeminiProvider(config, transport=transport)
        case ProviderName.GROQ:
            return GroqProvider(config, transport=transport)
        case _:
            raise _unsupported(config)


def _speech_to_text(config: ProviderConfig, transport: Transport) -> SpeechToTextProvider:
    match config.provider:
        case ProviderName.MOCK:
            return MockProvider()
        case ProviderName.DISABLED:
            return DisabledProvider()
        case ProviderName.GROQ:
            return GroqProvider(config, transport=transport)
        case _:
            raise _unsupported(config)


def _text_to_speech(config: ProviderConfig, transport: Transport) -> TextToSpeechProvider:
    # Text-to-speech runs on the phone (DECISIONS 2026-11-11); no real adapter.
    match config.provider:
        case ProviderName.MOCK:
            return MockProvider()
        case ProviderName.DISABLED:
            return DisabledProvider()
        case _:
            raise _unsupported(config)


def _slots[P: Provider](
    settings: Settings,
    capability: Capability,
    build: Callable[[ProviderConfig, Transport], P],
    transport: Transport,
) -> tuple[Slot[P], ...]:
    return tuple(
        Slot(config=config, adapter=build(config, transport))
        for config in settings.providers.get(capability, ())
    )


def build_providers(settings: Settings, *, transport: Transport = None) -> Providers:
    providers = Providers(
        vision=_slots(settings, Capability.VISION, _vision, transport),
        language=_slots(settings, Capability.LANGUAGE, _language, transport),
        speech_to_text=_slots(settings, Capability.SPEECH_TO_TEXT, _speech_to_text, transport),
        text_to_speech=_slots(settings, Capability.TEXT_TO_SPEECH, _text_to_speech, transport),
    )
    check_training_controls(providers)
    return providers


def check_training_controls(providers: Providers) -> None:
    """AI-12: a slot configured as not training must use an adapter that can keep
    user content out of training. Slots that do train are gated per request on
    the household's opt-in (pipeline.eligible_slots)."""
    for slot in providers.all_slots():
        adapter: Provider = slot.adapter
        if not slot.config.trains_on_inputs and not adapter.can_disable_training:
            raise ConfigError(
                f"{slot.config.slot}: provider {adapter.name!r} cannot switch off training "
                "on user content (AI-12)"
            )
