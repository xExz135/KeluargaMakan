"""Schemas for /speech/* (INT-08; VOI-01 to VOI-05 support). Audio is never stored."""

from __future__ import annotations

from typing import Annotated, Literal

from pydantic import StringConstraints

from app.schemas.common import Language, RequestContext, ResponseMeta

SpeechMode = Literal["command", "question"]
AUDIO_MIME_TYPES = frozenset(
    {"audio/wav", "audio/x-wav", "audio/ogg", "audio/webm", "audio/mpeg", "audio/mp4", "audio/flac"}
)


class TranscriptionResponse(ResponseMeta):
    # needs_clarification: low confidence; the app shows what it heard and the
    # available commands (VOI-05, AI-06).
    status: Literal["ok", "needs_clarification"]
    transcript: str
    language: Language


class SynthesisRequest(RequestContext):
    text: Annotated[str, StringConstraints(min_length=1, max_length=2000)]


class SynthesisResponse(ResponseMeta):
    audio_base64: str
    mime_type: str
