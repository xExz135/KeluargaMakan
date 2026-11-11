"""The one path every provider call takes.

1. Choose eligible slots. A slot whose provider may train on inputs (every free
   tier) is used only when the request carries the household's opt-in (SET-09,
   AI-12). If no slot is eligible, nothing is sent: "opt-in required".
2. Call the primary, then the backup if there is one, within one time budget.
   Timeouts, outages and quota refusals (HTTP 429) all become "AI unavailable"
   with the feature's fallback, never a default result (AI-08).
3. Parse and check the output. Output that is not a JSON object, or that fails
   its schema or a guard, becomes "output rejected" with the same fallback.
4. Log each attempt with prompt ID, version, hash and model ID (AI-11) and record
   usage for the household pseudonym (AI-09). Neither holds any content.
"""

from __future__ import annotations

import asyncio
import uuid
from collections.abc import Awaitable, Callable, Sequence
from dataclasses import dataclass
from typing import Protocol

from pydantic import ValidationError

from app.config import Settings
from app.errors import AIOptInRequiredError, AIOutputRejectedError, AIUnavailableError, Feature
from app.guards import InputGuard
from app.photos import PhotoSource
from app.prompt_registry import PromptRegistry
from app.providers.base import (
    CallOptions,
    Provider,
    ProviderOutputError,
    ProviderQuotaExceededError,
    Providers,
    ProviderTimeoutError,
    RenderedPrompt,
    Slot,
    Usage,
)
from app.schemas.common import RequestContext
from app.telemetry import CallRecord, Outcome, Stopwatch, UsageRecord, UsageSink, log_call


class RejectedOutputError(Exception):
    """Raised by a parser when the output breaks a guard. Message is a rule name only."""


@dataclass(frozen=True)
class ServiceContext:
    settings: Settings
    providers: Providers
    prompts: PromptRegistry
    photo_source: PhotoSource
    usage_sink: UsageSink
    input_guard: InputGuard


class ProviderResult(Protocol):
    @property
    def model_id(self) -> str: ...

    @property
    def usage(self) -> Usage: ...


@dataclass(frozen=True)
class CallResult[R]:
    value: R
    model_id: str


def eligible_slots[P: Provider](slots: Sequence[Slot[P]], request: RequestContext) -> list[Slot[P]]:
    """AI-12: providers that may train on inputs only for opted-in households."""
    opted_in = request.data_use.ai_improvement_opt_in
    return [slot for slot in slots if opted_in or not slot.config.trains_on_inputs]


def call_options[P: Provider](
    slot: Slot[P], request: RequestContext, deadline: float | None = None
) -> CallOptions:
    allow = slot.config.trains_on_inputs and request.data_use.ai_improvement_opt_in
    return CallOptions(language=request.language, allow_training=allow, deadline=deadline)


class _Attempt:
    """Logs one provider attempt and records its usage, whatever the outcome."""

    def __init__(
        self,
        ctx: ServiceContext,
        feature: Feature,
        prompt: RenderedPrompt,
        request: RequestContext,
        slot: Slot[Provider] | None,
    ) -> None:
        self.ctx = ctx
        self.feature = feature
        self.prompt = prompt
        self.request = request
        self.slot = slot
        self.watch = Stopwatch()
        self.model_id = f"{slot.adapter.name if slot else 'none'}:unknown"
        self.usage = Usage()

    def finish(self, outcome: Outcome, *, training_allowed: bool = False) -> None:
        slot = self.slot
        call = CallRecord(
            request_id=uuid.uuid4().hex,
            feature=self.feature.value,
            prompt_id=self.prompt.prompt_id,
            prompt_version=self.prompt.version,
            prompt_sha256=self.prompt.template_sha256,
            model_id=self.model_id,
            provider=slot.adapter.name if slot else "none",
            slot=slot.config.slot if slot else "none",
            tier=slot.config.tier.value if slot else "none",
            outcome=outcome,
            latency_ms=self.watch.elapsed_ms(),
            training_allowed=training_allowed,
        )
        log_call(call)
        self.ctx.usage_sink.record(
            UsageRecord.build(household_ref=self.request.household_ref, call=call, usage=self.usage)
        )


async def run_call[P: Provider, T: ProviderResult, R](
    ctx: ServiceContext,
    *,
    feature: Feature,
    slots: Sequence[Slot[P]],
    prompt: RenderedPrompt,
    request: RequestContext,
    timeout: float,
    invoke: Callable[[P, CallOptions], Awaitable[T]],
    parse: Callable[[T], R],
) -> CallResult[R]:
    if not slots:
        _Attempt(ctx, feature, prompt, request, None).finish(Outcome.UNAVAILABLE)
        raise AIUnavailableError(feature)
    usable = eligible_slots(slots, request)
    if not usable:
        _Attempt(ctx, feature, prompt, request, None).finish(Outcome.OPT_IN_REQUIRED)
        raise AIOptInRequiredError(feature)

    loop = asyncio.get_running_loop()
    deadline = loop.time() + timeout
    for slot in usable:
        remaining = deadline - loop.time()
        if remaining <= 0:
            break
        options = call_options(slot, request, deadline)
        attempt = _Attempt(ctx, feature, prompt, request, slot)
        try:
            raw = await asyncio.wait_for(invoke(slot.adapter, options), remaining)
        except (TimeoutError, ProviderTimeoutError):
            attempt.finish(Outcome.TIMEOUT, training_allowed=options.allow_training)
            continue
        except ProviderQuotaExceededError:
            attempt.finish(Outcome.QUOTA_EXCEEDED, training_allowed=options.allow_training)
            continue
        except ProviderOutputError:
            # The provider answered with unusable output: rejected, like a schema
            # failure, never repaired or replaced (AI-08).
            attempt.finish(Outcome.INVALID_OUTPUT, training_allowed=options.allow_training)
            raise AIOutputRejectedError(feature) from None
        except Exception:
            # Any other failure, including an adapter bug, means unavailable.
            attempt.finish(Outcome.UNAVAILABLE, training_allowed=options.allow_training)
            continue
        attempt.model_id, attempt.usage = raw.model_id, raw.usage
        try:
            value = parse(raw)
        except ValidationError:
            attempt.finish(Outcome.INVALID_OUTPUT, training_allowed=options.allow_training)
            raise AIOutputRejectedError(feature) from None
        except RejectedOutputError:
            attempt.finish(Outcome.GUARDED, training_allowed=options.allow_training)
            raise AIOutputRejectedError(feature) from None
        attempt.finish(Outcome.OK, training_allowed=options.allow_training)
        return CallResult(value, raw.model_id)
    raise AIUnavailableError(feature)
