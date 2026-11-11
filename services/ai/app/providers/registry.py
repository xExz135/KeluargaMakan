"""Build the configured provider slots and check them against AI-12 before startup.

To add Gemini or Groq: add the name to `config.ProviderName`, write an adapter
class that takes its `ProviderConfig` (and its API key from the secret manager)
and implements the capability protocols in `base.py`, and add it to `_ADAPTERS`.
"""

from __future__ import annotations

from collections.abc import Callable

from app.config import Capability, ConfigError, ProviderConfig, ProviderName, Settings
from app.providers.base import Provider, Providers, Slot
from app.providers.disabled import DisabledProvider
from app.providers.mock import MockProvider

type Adapter = MockProvider | DisabledProvider

_ADAPTERS: dict[ProviderName, Callable[[ProviderConfig], Adapter]] = {
    ProviderName.MOCK: lambda config: MockProvider(),
    ProviderName.DISABLED: lambda config: DisabledProvider(),
}


def _slots(settings: Settings, capability: Capability) -> tuple[Slot[Adapter], ...]:
    return tuple(
        Slot(config=config, adapter=_ADAPTERS[config.provider](config))
        for config in settings.providers.get(capability, ())
    )


def build_providers(settings: Settings) -> Providers:
    providers = Providers(
        vision=_slots(settings, Capability.VISION),
        language=_slots(settings, Capability.LANGUAGE),
        speech_to_text=_slots(settings, Capability.SPEECH_TO_TEXT),
        text_to_speech=_slots(settings, Capability.TEXT_TO_SPEECH),
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
