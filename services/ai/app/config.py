"""Service configuration, read from environment variables and validated at startup.

Validation fails closed: an unknown value, a missing secret or a data-use
setting that the provider's terms do not support stops the service from
starting, rather than running with a guessed default.

Providers (DECISIONS 2026-11-11, QUESTIONS #8): free tiers of Gemini (vision,
language), Groq (backup language) and Groq Whisper (speech-to-text); text-to-
speech runs on the phone, so the service's text-to-speech slot is optional.
Model names and limits are configuration, not code.

Values marked (target) in the SRS, and thresholds proposed here that still need
a human decision, are configuration so they can change without a code change.
"""

from __future__ import annotations

import os
from collections.abc import Mapping
from dataclasses import dataclass, field
from enum import StrEnum

MIN_AUTH_TOKEN_LENGTH = 32


class ConfigError(ValueError):
    """Raised when the configuration is missing, malformed or not allowed."""


class Environment(StrEnum):
    LOCAL = "local"
    TEST = "test"
    STAGING = "staging"
    PRODUCTION = "production"

    @property
    def allows_mock(self) -> bool:
        """The mock provider returns canned output, so it never runs where users are."""
        return self in (Environment.LOCAL, Environment.TEST)


class Capability(StrEnum):
    """Provider capabilities (INT-06 vision, INT-07 language, INT-08 speech)."""

    VISION = "vision"
    LANGUAGE = "language"
    SPEECH_TO_TEXT = "speech_to_text"
    TEXT_TO_SPEECH = "text_to_speech"


# Text-to-speech runs on the phone (DECISIONS 2026-11-11); the slot is optional.
OPTIONAL_CAPABILITIES = frozenset({Capability.TEXT_TO_SPEECH})


class ProviderName(StrEnum):
    """Adapters that exist. Gemini and Groq adapters are added in the follow-up task."""

    MOCK = "mock"
    # Always answers "AI unavailable". Lets an environment run without a provider.
    DISABLED = "disabled"


class Tier(StrEnum):
    FREE = "free"
    PAID = "paid"


class PhotoSourceName(StrEnum):
    MOCK = "mock"
    DISABLED = "disabled"


@dataclass(frozen=True)
class RateLimitHints:
    """The provider's published limits, for pacing and alerts (AI-09). Not enforced here:
    a provider's own quota response (HTTP 429) is what the service reacts to."""

    requests_per_minute: int | None = None
    requests_per_day: int | None = None
    tokens_per_minute: int | None = None


@dataclass(frozen=True)
class ProviderConfig:
    """One provider slot: the primary or the backup for a capability.

    AI-12 and SET-09: `trains_on_inputs` records whether the provider's terms let
    it use requests to improve its products. Free tiers may, so a free-tier slot
    must say so. A slot that trains on inputs is only ever called for a request
    that carries the household's opt-in; without it no data is sent. The default
    assumes the provider trains, so forgetting the setting keeps data back.
    """

    capability: Capability
    slot: str
    provider: ProviderName
    model_id: str | None = None
    tier: Tier = Tier.FREE
    trains_on_inputs: bool = True
    rate_limits: RateLimitHints = field(default_factory=RateLimitHints)

    def __post_init__(self) -> None:
        if self.tier is Tier.FREE and not self.trains_on_inputs:
            raise ConfigError(
                f"{self.slot}: free-tier providers may use requests to improve their "
                "products; trains_on_inputs must be true (AI-12)"
            )
        for name, value in vars(self.rate_limits).items():
            if value is not None and value <= 0:
                raise ConfigError(f"{self.slot}: {name} must be positive")


@dataclass(frozen=True)
class Timeouts:
    """Seconds to wait for a provider before answering "AI unavailable" (AI-08).

    The budget covers the primary and, if needed, the backup provider together.
    """

    recognition: float = 10.0  # REC-08 (target)
    adaptation: float = 8.0
    tweak: float = 4.0  # TNT-07 (target)
    speech_to_text: float = 5.0
    text_to_speech: float = 5.0


@dataclass(frozen=True)
class ConfidenceThresholds:
    """Below these, the service asks instead of guessing (AI-06, REC-03).

    Proposed defaults; the agreed values need a human decision (QUESTIONS #22).
    """

    recognition: float = 0.6
    adaptation: float = 0.6
    tweak: float = 0.6
    speech_to_text: float = 0.6


@dataclass(frozen=True)
class Limits:
    max_photos_per_request: int = 5  # REC-01 (target)
    max_photo_bytes: int = 4 * 1024 * 1024
    max_audio_bytes: int = 2 * 1024 * 1024


@dataclass(frozen=True)
class Settings:
    environment: Environment
    auth_tokens: tuple[str, ...]
    # Per capability: primary first, then an optional backup.
    providers: Mapping[Capability, tuple[ProviderConfig, ...]]
    photo_source: PhotoSourceName
    photo_allowed_hosts: frozenset[str]
    prompts_dir: str | None = None
    timeouts: Timeouts = field(default_factory=Timeouts)
    confidence: ConfidenceThresholds = field(default_factory=ConfidenceThresholds)
    limits: Limits = field(default_factory=Limits)

    def __post_init__(self) -> None:
        if not self.auth_tokens:
            raise ConfigError("AI_SERVICE_AUTH_TOKEN is required")
        for token in self.auth_tokens:
            if len(token) < MIN_AUTH_TOKEN_LENGTH:
                raise ConfigError(
                    f"auth tokens must be at least {MIN_AUTH_TOKEN_LENGTH} characters"
                )
        for capability in Capability:
            chain = self.providers.get(capability, ())
            if not chain and capability not in OPTIONAL_CAPABILITIES:
                raise ConfigError(f"no provider configured for {capability.value}")
            if len(chain) > 2:
                raise ConfigError(f"{capability.value}: at most a primary and a backup")
            if any(slot.capability is not capability for slot in chain):
                raise ConfigError(f"{capability.value}: slot configured for another capability")
        if not self.environment.allows_mock:
            for chain in self.providers.values():
                for slot in chain:
                    if slot.provider is ProviderName.MOCK:
                        raise ConfigError(
                            f"{slot.slot}: the mock provider is only allowed in local and test"
                        )
            if self.photo_source is PhotoSourceName.MOCK:
                raise ConfigError("the mock photo source is only allowed in local and test")
        for host in self.photo_allowed_hosts:
            if not host or host != host.strip().lower() or "/" in host:
                raise ConfigError(f"invalid photo host: {host!r}")
        _require_positive(self.timeouts)
        _require_positive(self.limits)
        for name, value in vars(self.confidence).items():
            if not 0.0 < value < 1.0:
                raise ConfigError(f"confidence threshold {name} must be between 0 and 1")


def _require_positive(group: object) -> None:
    for name, value in vars(group).items():
        if not value > 0:
            raise ConfigError(f"{type(group).__name__}.{name} must be positive")


# ---------- environment parsing ----------

_ENV_PREFIX = {
    Capability.VISION: "VISION",
    Capability.LANGUAGE: "LANGUAGE",
    Capability.SPEECH_TO_TEXT: "SPEECH_TO_TEXT",
    Capability.TEXT_TO_SPEECH: "TEXT_TO_SPEECH",
}


def load_settings(env: Mapping[str, str] | None = None) -> Settings:
    """Build settings from environment variables (see services/ai/.env.example)."""
    source = os.environ if env is None else env

    environment = _enum(source, "AI_ENV", Environment, default=None)
    tokens = tuple(
        value
        for value in (
            source.get("AI_SERVICE_AUTH_TOKEN", "").strip(),
            source.get("AI_SERVICE_AUTH_TOKEN_PREVIOUS", "").strip(),
        )
        if value
    )
    providers = {
        capability: _chain(source, capability, prefix, environment)
        for capability, prefix in _ENV_PREFIX.items()
    }
    default_photo_source = (
        PhotoSourceName.MOCK if environment.allows_mock else PhotoSourceName.DISABLED
    )
    hosts = frozenset(
        host.strip() for host in source.get("PHOTO_URL_ALLOWED_HOSTS", "").split(",") if host
    )
    defaults_t, defaults_c, defaults_l = Timeouts(), ConfidenceThresholds(), Limits()
    return Settings(
        environment=environment,
        auth_tokens=tokens,
        providers=providers,
        photo_source=_enum(source, "PHOTO_SOURCE", PhotoSourceName, default=default_photo_source),
        photo_allowed_hosts=hosts,
        prompts_dir=source.get("PROMPTS_DIR") or None,
        timeouts=Timeouts(
            **{
                name: _float(source, f"{name.upper()}_TIMEOUT_SECONDS", value)
                for name, value in vars(defaults_t).items()
            }
        ),
        confidence=ConfidenceThresholds(
            **{
                name: _float(source, f"{name.upper()}_MIN_CONFIDENCE", value)
                for name, value in vars(defaults_c).items()
            }
        ),
        limits=Limits(
            **{name: _int(source, name.upper(), value) for name, value in vars(defaults_l).items()}
        ),
    )


def _chain(
    source: Mapping[str, str], capability: Capability, prefix: str, environment: Environment
) -> tuple[ProviderConfig, ...]:
    if capability in OPTIONAL_CAPABILITIES:
        primary_default = None
    else:
        primary_default = ProviderName.MOCK if environment.allows_mock else None
    chain = []
    for slot_prefix, default, required in (
        (prefix, primary_default, capability not in OPTIONAL_CAPABILITIES),
        (f"{prefix}_BACKUP", None, False),
    ):
        raw = source.get(f"{slot_prefix}_PROVIDER", "").strip()
        if not raw and default is None:
            if required:
                raise ConfigError(f"{slot_prefix}_PROVIDER is required")
            continue
        chain.append(_slot(source, capability, slot_prefix, default))
    return tuple(chain)


def _slot(
    source: Mapping[str, str],
    capability: Capability,
    prefix: str,
    default: ProviderName | None,
) -> ProviderConfig:
    return ProviderConfig(
        capability=capability,
        slot=prefix.lower(),
        provider=_enum(source, f"{prefix}_PROVIDER", ProviderName, default=default),
        model_id=source.get(f"{prefix}_MODEL_ID", "").strip() or None,
        tier=_enum(source, f"{prefix}_TIER", Tier, default=Tier.FREE),
        trains_on_inputs=_bool(source, f"{prefix}_TRAINS_ON_INPUTS", default=True),
        rate_limits=RateLimitHints(
            requests_per_minute=_optional_int(source, f"{prefix}_RPM"),
            requests_per_day=_optional_int(source, f"{prefix}_RPD"),
            tokens_per_minute=_optional_int(source, f"{prefix}_TPM"),
        ),
    )


def _enum[E: StrEnum](
    source: Mapping[str, str], key: str, kind: type[E], *, default: E | None
) -> E:
    raw = source.get(key, "").strip()
    if not raw:
        if default is None:
            raise ConfigError(f"{key} is required")
        return default
    try:
        return kind(raw)
    except ValueError:
        allowed = ", ".join(member.value for member in kind)
        raise ConfigError(f"{key} must be one of: {allowed}") from None


def _bool(source: Mapping[str, str], key: str, *, default: bool) -> bool:
    """Strict: only "true" or "false"; anything else is an error."""
    raw = source.get(key, "").strip().lower()
    if not raw:
        return default
    if raw in ("true", "false"):
        return raw == "true"
    raise ConfigError(f"{key} must be true or false")


def _float(source: Mapping[str, str], key: str, default: float) -> float:
    raw = source.get(key, "").strip()
    if not raw:
        return default
    try:
        return float(raw)
    except ValueError:
        raise ConfigError(f"{key} must be a number") from None


def _int(source: Mapping[str, str], key: str, default: int) -> int:
    value = _optional_int(source, key)
    return default if value is None else value


def _optional_int(source: Mapping[str, str], key: str) -> int | None:
    raw = source.get(key, "").strip()
    if not raw:
        return None
    try:
        return int(raw)
    except ValueError:
        raise ConfigError(f"{key} must be a whole number") from None
