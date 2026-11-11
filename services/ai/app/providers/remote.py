"""Shared plumbing for adapters that call a provider's REST API (INT-06 to INT-08).

- `RemoteClient` sends one HTTPS request with a per-attempt timeout inside the
  feature's time budget, and maps failures to the provider errors in `base.py`:
  timeout -> ProviderTimeoutError, HTTP 429 -> ProviderQuotaExceededError,
  anything else -> ProviderUnavailableError. It retries only a 5xx or a
  connection error, a bounded number of times, and only while the retry still
  fits before the deadline; never a 429 and never a timeout (AI-08).
- `LocalBudget` keeps the free-tier limits from configuration (RPM, RPD, TPM,
  audio seconds) in process and refuses early with a quota error when they are
  spent, so the service does not call a provider it knows will refuse (AI-09).
- `parse_json_object` turns model text into a JSON object or raises
  `ProviderOutputError`; nothing is repaired or defaulted.
- `output_schema` gives the JSON Schema each prompt's answer must match, built
  from the pydantic output models, so the provider is asked for exactly the
  shape the service validates afterwards.

Error messages hold the provider name and an HTTP status at most: never the API
key, the URL's query, the prompt, the photo or the provider's response text.
Exceptions from the HTTP client are dropped (`from None`) because they carry
the request, and the request carries the key header.
"""

from __future__ import annotations

import asyncio
import functools
import json
import logging
import math
import ssl
import time
from collections import deque
from collections.abc import Callable, Mapping
from dataclasses import dataclass
from typing import Any

import httpx2
from pydantic import BaseModel

from app.config import ProviderConfig, RateLimitHints
from app.providers.base import (
    ProviderOutputError,
    ProviderQuotaExceededError,
    ProviderTimeoutError,
    ProviderUnavailableError,
)
from app.schemas.adapt import AdaptationModelOutput
from app.schemas.recognize import RecognitionModelOutput
from app.schemas.tweak import TweakModelOutput

PROVIDER_LOGGER = "app.providers"

# Seconds for one attempt when the slot sets no request timeout. The feature's
# time budget (config.Timeouts) is the real cap.
DEFAULT_REQUEST_TIMEOUT = 30.0
# A retry is only started when at least this much time is left after the backoff.
MIN_ATTEMPT_SECONDS = 0.5
RETRY_BACKOFF_SECONDS = 0.25
RETRYABLE_STATUS = frozenset({500, 502, 503, 504})
MAX_RESPONSE_BYTES = 2 * 1024 * 1024
# The longest a provider's "retry after" is honoured locally before trying again.
MAX_BLOCK_SECONDS = 3600.0

MINUTE = 60.0
HOUR = 3600.0
DAY = 86400.0

type Clock = Callable[[], float]
type Sleep = Callable[[float], Any]


# ---------- local free-tier budget ----------


@dataclass
class Reservation:
    """One request counted against the budget; `settle` replaces the estimates."""

    at: float
    tokens: int
    audio_seconds: float


class LocalBudget:
    """In-process sliding-window limits for one provider slot (AI-09).

    Windows are rolling (last 60 seconds, last hour, last 24 hours), which is at
    least as strict as a provider's calendar-day reset for a steady load. A 429
    with a retry hint blocks the slot locally for that long (capped).
    """

    def __init__(self, provider: str, limits: RateLimitHints, clock: Clock = time.monotonic):
        self._provider = provider
        self._limits = limits
        self._clock = clock
        self._entries: deque[Reservation] = deque()
        self._blocked_until = 0.0
        self._horizon = (
            DAY
            if limits.requests_per_day or limits.audio_seconds_per_day
            else HOUR
            if limits.audio_seconds_per_hour
            else MINUTE
        )

    def reserve(self, *, tokens: int = 0, audio_seconds: float = 0.0) -> Reservation:
        now = self._clock()
        while self._entries and now - self._entries[0].at >= self._horizon:
            self._entries.popleft()
        if now < self._blocked_until:
            raise self._refuse()
        limits = self._limits
        minute = [e for e in self._entries if now - e.at < MINUTE]
        if limits.requests_per_minute is not None and len(minute) >= limits.requests_per_minute:
            raise self._refuse()
        if limits.requests_per_day is not None and len(self._entries) >= limits.requests_per_day:
            raise self._refuse()
        if limits.tokens_per_minute is not None:
            used = sum(e.tokens for e in minute)
            # A single request bigger than the whole minute budget is still tried
            # once the window is empty; the provider decides.
            if minute and used + tokens > limits.tokens_per_minute:
                raise self._refuse()
        if limits.audio_seconds_per_hour is not None:
            hour = sum(e.audio_seconds for e in self._entries if now - e.at < HOUR)
            if hour + audio_seconds > limits.audio_seconds_per_hour:
                raise self._refuse()
        if limits.audio_seconds_per_day is not None:
            day = sum(e.audio_seconds for e in self._entries)
            if day + audio_seconds > limits.audio_seconds_per_day:
                raise self._refuse()
        reservation = Reservation(at=now, tokens=tokens, audio_seconds=audio_seconds)
        self._entries.append(reservation)
        return reservation

    def settle(
        self,
        reservation: Reservation,
        *,
        tokens: int | None = None,
        audio_seconds: float | None = None,
    ) -> None:
        if tokens is not None:
            reservation.tokens = tokens
        if audio_seconds is not None:
            reservation.audio_seconds = audio_seconds

    def block_for(self, seconds: float) -> None:
        if seconds > 0:
            until = self._clock() + min(seconds, MAX_BLOCK_SECONDS)
            self._blocked_until = max(self._blocked_until, until)

    def _refuse(self) -> ProviderQuotaExceededError:
        return ProviderQuotaExceededError(f"{self._provider}: local free-tier budget spent")


# ---------- HTTP ----------


@functools.cache
def _ssl_context() -> ssl.SSLContext:
    # Built once: the system trust store, certificate and hostname checks on.
    return httpx2.create_ssl_context(trust_env=False)


type Classifier = Callable[[httpx2.Response], Exception | None]


class RemoteClient:
    """Sends requests for one slot. A fresh connection per call keeps the client
    independent of the event loop that serves the request."""

    def __init__(
        self,
        provider: str,
        config: ProviderConfig,
        budget: LocalBudget,
        *,
        transport: httpx2.AsyncBaseTransport | None = None,
        sleep: Sleep = asyncio.sleep,
    ) -> None:
        self._provider = provider
        self._config = config
        self._budget = budget
        self._transport = transport
        self._sleep = sleep

    async def post(
        self,
        url: str,
        *,
        headers: Mapping[str, str],
        deadline: float | None,
        json_body: object | None = None,
        files: Mapping[str, tuple[str, bytes, str]] | None = None,
        data: Mapping[str, str] | None = None,
        classify: Classifier | None = None,
    ) -> httpx2.Response:
        attempts = 1 + self._config.max_retries
        for attempt in range(attempts):
            timeout = self._attempt_timeout(deadline)
            if timeout <= 0:
                raise ProviderTimeoutError(f"{self._provider}: no time left")
            # The client's exceptions hold the request, and the request holds the
            # key header. Errors are raised after the except block so that no
            # client exception stays attached as __context__.
            response: httpx2.Response | None = None
            timed_out = False
            try:
                response = await self._send(url, headers, timeout, json_body, files, data)
            except httpx2.TimeoutException:
                timed_out = True
            except httpx2.HTTPError:
                pass
            if timed_out:
                raise ProviderTimeoutError(f"{self._provider}: timed out")
            if response is None:
                error = ProviderUnavailableError(f"{self._provider}: connection failed")
            else:
                status = response.status_code
                if 200 <= status < 300:
                    if len(response.content) > MAX_RESPONSE_BYTES:
                        raise ProviderOutputError(f"{self._provider}: response too large")
                    return response
                self._log_status(status)
                if status == 429:
                    self._budget.block_for(retry_after_seconds(response))
                    raise ProviderQuotaExceededError(f"{self._provider}: http 429")
                specific = classify(response) if classify else None
                if specific is not None:
                    raise specific
                error = ProviderUnavailableError(f"{self._provider}: http {status}")
                if status not in RETRYABLE_STATUS:
                    raise error
            backoff = RETRY_BACKOFF_SECONDS * (attempt + 1)
            if attempt + 1 < attempts and self._fits(deadline, backoff + MIN_ATTEMPT_SECONDS):
                await self._sleep(backoff)
                continue
            raise error
        raise ProviderUnavailableError(f"{self._provider}: no attempt made")  # pragma: no cover

    async def _send(
        self,
        url: str,
        headers: Mapping[str, str],
        timeout: float,
        json_body: object | None,
        files: Mapping[str, tuple[str, bytes, str]] | None,
        data: Mapping[str, str] | None,
    ) -> httpx2.Response:
        async with httpx2.AsyncClient(
            transport=self._transport,
            verify=_ssl_context() if self._transport is None else True,
            timeout=httpx2.Timeout(timeout),
            follow_redirects=False,
            trust_env=False,
        ) as client:
            if files is not None:
                return await client.post(url, headers=dict(headers), files=files, data=data)
            return await client.post(url, headers=dict(headers), json=json_body)

    def _attempt_timeout(self, deadline: float | None) -> float:
        timeout = self._config.request_timeout or DEFAULT_REQUEST_TIMEOUT
        if deadline is None:
            return timeout
        return min(timeout, deadline - asyncio.get_running_loop().time())

    def _fits(self, deadline: float | None, needed: float) -> bool:
        if deadline is None:
            return True
        return deadline - asyncio.get_running_loop().time() >= needed

    def _log_status(self, status: int) -> None:
        # Status code only; the body can echo the request.
        logging.getLogger(PROVIDER_LOGGER).warning(
            "provider_http_error",
            extra={
                "fields": {"provider": self._provider, "slot": self._config.slot, "status": status}
            },
        )


def retry_after_seconds(response: httpx2.Response) -> float:
    """The provider's wait hint for a 429: the Retry-After header, or Google's
    RetryInfo detail ("retryDelay": "17s"). Zero when there is none."""
    header = response.headers.get("retry-after", "").strip()
    if header:
        try:
            value = float(header)
        except ValueError:
            value = 0.0
        if math.isfinite(value) and value > 0:
            return value
    try:
        body = response.json()
    except ValueError:
        return 0.0
    details = body.get("error", {}).get("details", []) if isinstance(body, dict) else []
    for detail in details if isinstance(details, list) else []:
        delay = detail.get("retryDelay") if isinstance(detail, dict) else None
        if isinstance(delay, str) and delay.endswith("s"):
            try:
                value = float(delay[:-1])
            except ValueError:
                continue
            if math.isfinite(value) and value > 0:
                return value
    return 0.0


def response_json(provider: str, response: httpx2.Response) -> Mapping[str, Any]:
    """The provider's JSON envelope. A 2xx that is not a JSON object is unusable output."""
    try:
        body = response.json()
    except ValueError:
        raise ProviderOutputError(f"{provider}: response is not JSON") from None
    if not isinstance(body, dict):
        raise ProviderOutputError(f"{provider}: response is not a JSON object")
    return body


def parse_json_object(provider: str, text: str) -> Mapping[str, object]:
    """Model text to a JSON object. Anything else is rejected, never repaired."""
    try:
        value = json.loads(text)
    except ValueError:
        raise ProviderOutputError(f"{provider}: output is not JSON") from None
    if not isinstance(value, dict):
        raise ProviderOutputError(f"{provider}: output is not a JSON object")
    return value


def estimate_tokens(*texts: str) -> int:
    """Rough count (about 4 characters a token) for the local TPM budget only."""
    return sum(len(text) for text in texts) // 4 + 1


# ---------- requested output shape ----------

# Prompt ID -> the pydantic model its answer is validated against in the route.
OUTPUT_MODELS: Mapping[str, type[BaseModel]] = {
    "recognize.ingredients": RecognitionModelOutput,
    "adapt.recipe": AdaptationModelOutput,
    "tweak.advice": TweakModelOutput,
}

# JSON Schema keywords both providers accept. Everything else (patterns, string
# lengths, exclusive bounds, defaults, titles) is dropped from the request and
# still enforced by pydantic on the answer.
_PORTABLE_KEYWORDS = frozenset(
    {
        "type",
        "properties",
        "required",
        "items",
        "enum",
        "anyOf",
        "additionalProperties",
        "minimum",
        "maximum",
        "minItems",
        "maxItems",
        "description",
    }
)


def output_schema(provider: str, prompt_id: str) -> dict[str, Any]:
    try:
        model = OUTPUT_MODELS[prompt_id]
    except KeyError:
        raise ProviderUnavailableError(f"{provider}: no output schema for this prompt") from None
    return _portable_schema(model)


@functools.cache
def _portable_schema_json(model: type[BaseModel]) -> str:
    schema = model.model_json_schema(by_alias=True, mode="validation")
    definitions = schema.pop("$defs", {})

    def walk(node: Any, depth: int = 0) -> Any:
        if depth > 32:
            raise ValueError("output schema is too deep")
        if isinstance(node, list):
            return [walk(item, depth + 1) for item in node]
        if not isinstance(node, dict):
            return node
        if "$ref" in node:
            return walk(definitions[node["$ref"].rsplit("/", 1)[-1]], depth + 1)
        out: dict[str, Any] = {}
        if "const" in node:
            out["enum"] = [node["const"]]
        for key, value in node.items():
            if key == "properties":
                out[key] = {name: walk(sub, depth + 1) for name, sub in value.items()}
            elif key in ("items", "anyOf") or (
                key == "additionalProperties" and isinstance(value, dict)
            ):
                out[key] = walk(value, depth + 1)
            elif key in _PORTABLE_KEYWORDS:
                out[key] = value
        return out

    return json.dumps(walk(schema), sort_keys=True)


def _portable_schema(model: type[BaseModel]) -> dict[str, Any]:
    # A fresh copy each time, so no caller can change the cached schema.
    result: dict[str, Any] = json.loads(_portable_schema_json(model))
    return result
