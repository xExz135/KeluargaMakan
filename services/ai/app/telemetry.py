"""Call logs (AI-11) and usage records (AI-09 groundwork), without personal data.

Logs and usage records are built from typed metadata only: prompt ID, version
and hash, model ID, outcome, latency and counts. There is no field for prompt
text, response text, transcripts, photos or audio, so they cannot be logged by
accident. A filter on the service's log handler also redacts any email address
or phone number that reaches a log line from elsewhere (AI-03).
"""

from __future__ import annotations

import json
import logging
import time
from collections import deque
from dataclasses import asdict, dataclass
from datetime import UTC, datetime
from enum import StrEnum
from typing import Protocol

from app.privacy.redact import redact
from app.providers.base import Usage

CALL_LOGGER = "app.ai_calls"
USAGE_LOGGER = "app.usage"


class Outcome(StrEnum):
    OK = "ok"
    TIMEOUT = "timeout"
    QUOTA_EXCEEDED = "quota_exceeded"
    UNAVAILABLE = "unavailable"
    OPT_IN_REQUIRED = "opt_in_required"
    INVALID_OUTPUT = "invalid_output"
    GUARDED = "guarded"


@dataclass(frozen=True)
class CallRecord:
    request_id: str
    feature: str
    prompt_id: str
    prompt_version: str
    prompt_sha256: str
    model_id: str
    provider: str
    slot: str
    tier: str
    outcome: Outcome
    latency_ms: float
    training_allowed: bool


@dataclass(frozen=True)
class UsageRecord:
    """One AI call's usage for a household pseudonym, bucketed by month (AI-09)."""

    month: str
    household_ref: str
    feature: str
    provider: str
    slot: str
    tier: str
    model_id: str
    prompt_id: str
    prompt_version: str
    outcome: Outcome
    input_tokens: int
    output_tokens: int
    images: int
    audio_seconds: float
    characters: int

    @classmethod
    def build(
        cls,
        *,
        household_ref: str,
        call: CallRecord,
        usage: Usage,
        now: datetime | None = None,
    ) -> UsageRecord:
        moment = now or datetime.now(UTC)
        return cls(
            month=moment.strftime("%Y-%m"),
            household_ref=household_ref,
            feature=call.feature,
            provider=call.provider,
            slot=call.slot,
            tier=call.tier,
            model_id=call.model_id,
            prompt_id=call.prompt_id,
            prompt_version=call.prompt_version,
            outcome=call.outcome,
            input_tokens=usage.input_tokens,
            output_tokens=usage.output_tokens,
            images=usage.images,
            audio_seconds=usage.audio_seconds,
            characters=usage.characters,
        )


class UsageSink(Protocol):
    def record(self, usage: UsageRecord) -> None: ...


class LogUsageSink:
    """Writes usage records as structured log lines until T-068 adds storage."""

    def record(self, usage: UsageRecord) -> None:
        logging.getLogger(USAGE_LOGGER).info("ai_usage", extra={"fields": _jsonable(asdict(usage))})


class InMemoryUsageSink:
    def __init__(self, maxlen: int = 10_000) -> None:
        self.records: deque[UsageRecord] = deque(maxlen=maxlen)

    def record(self, usage: UsageRecord) -> None:
        self.records.append(usage)


def log_call(call: CallRecord) -> None:
    logging.getLogger(CALL_LOGGER).info("ai_call", extra={"fields": _jsonable(asdict(call))})


def _jsonable(values: dict[str, object]) -> dict[str, object]:
    return {
        key: value.value if isinstance(value, StrEnum) else value for key, value in values.items()
    }


class Stopwatch:
    def __init__(self) -> None:
        self._start = time.perf_counter()

    def elapsed_ms(self) -> float:
        return round((time.perf_counter() - self._start) * 1000, 1)


# ---------- log formatting ----------


class RedactingFilter(logging.Filter):
    """Last line of defence: redact contact details in any record on our handler."""

    def filter(self, record: logging.LogRecord) -> bool:
        record.msg = redact(record.getMessage())
        record.args = None
        fields = getattr(record, "fields", None)
        if isinstance(fields, dict):
            record.fields = {
                key: redact(value) if isinstance(value, str) else value
                for key, value in fields.items()
            }
        return True


class JsonFormatter(logging.Formatter):
    def format(self, record: logging.LogRecord) -> str:
        entry: dict[str, object] = {
            "time": datetime.fromtimestamp(record.created, UTC).isoformat(timespec="seconds"),
            "level": record.levelname,
            "logger": record.name,
            "event": record.getMessage(),
        }
        fields = getattr(record, "fields", None)
        if isinstance(fields, dict):
            entry.update(fields)
        if record.exc_info and record.exc_info[0] is not None:
            # Exception type only: messages and tracebacks can hold user content.
            entry["error"] = record.exc_info[0].__name__
        return json.dumps(entry, ensure_ascii=False)


def configure_logging(level: str = "INFO") -> None:
    handler = logging.StreamHandler()
    handler.addFilter(RedactingFilter())
    handler.setFormatter(JsonFormatter())
    root = logging.getLogger("app")
    root.handlers[:] = [handler]
    root.setLevel(level)
    root.propagate = False
    # The HTTP client logs each request URL at INFO. URLs carry no key or content,
    # but nothing from the client needs to reach the logs below a warning.
    for name in ("httpx2", "httpcore2"):
        logging.getLogger(name).setLevel(logging.WARNING)
