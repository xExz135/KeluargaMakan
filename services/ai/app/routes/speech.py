"""POST /speech/transcribe and /speech/synthesize (skeleton; T-065 adds real speech).

INT-08, VOI-04: audio is read into memory for this request only and never
stored or logged. Speech goes through the API and this service (DECISIONS
2026-11-11, QUESTIONS #18). Text-to-speech runs on the phone; the synthesize
endpoint is an optional slot that answers "AI unavailable" with the
device fallback when no provider is configured.

Transcription metadata comes in headers, not the query string, so it stays out
of access logs: X-Household-Ref, X-Language (id or en) and
X-AI-Improvement-Opt-In (true or false).
"""

from __future__ import annotations

import base64

from fastapi import APIRouter, Request
from pydantic import ValidationError

from app.errors import ErrorCode, Feature, RequestRejectedError
from app.pipeline import RejectedOutputError, ServiceContext, run_call
from app.privacy.redact import redact
from app.providers.base import AudioInput, SynthesizedSpeech, Transcription
from app.schemas.common import RequestContext
from app.schemas.speech import (
    AUDIO_MIME_TYPES,
    SynthesisRequest,
    SynthesisResponse,
    TranscriptionResponse,
)

router = APIRouter()
TRANSCRIBE_PROMPT_ID = "speech.transcribe"
SYNTHESIZE_PROMPT_ID = "speech.synthesize"


@router.post("/speech/transcribe", response_model=TranscriptionResponse)
async def transcribe(request: Request) -> TranscriptionResponse:
    ctx: ServiceContext = request.app.state.ctx
    context = _context_from_headers(request)
    mime = request.headers.get("content-type", "").split(";")[0].strip().lower()
    if mime not in AUDIO_MIME_TYPES:
        raise RequestRejectedError(415, ErrorCode.UNSUPPORTED_MEDIA)
    audio = await _read_limited(request, ctx.settings.limits.max_audio_bytes)
    if not audio:
        raise RequestRejectedError(422, ErrorCode.INVALID_REQUEST, ["body:empty"])
    prompt = ctx.prompts.active(TRANSCRIBE_PROMPT_ID).render({}, context.language)
    # VOI-04: the audio lives only in this request's memory; nothing keeps it.
    audio_input = AudioInput(data=audio, mime_type=mime)
    threshold = ctx.settings.confidence.speech_to_text
    result = await run_call(
        ctx,
        feature=Feature.SPEECH_TO_TEXT,
        slots=ctx.providers.speech_to_text,
        prompt=prompt,
        request=context,
        timeout=ctx.settings.timeouts.speech_to_text,
        invoke=lambda adapter, options: adapter.transcribe(audio_input, prompt, options),
        parse=lambda raw: _transcript(raw),
    )
    transcript = result.value
    return TranscriptionResponse(
        prompt_id=prompt.prompt_id,
        prompt_version=prompt.version,
        model_id=result.model_id,
        confidence=transcript.confidence,
        # AI-06, VOI-05: low confidence is flagged; the app shows what it heard.
        status="ok" if transcript.confidence >= threshold else "needs_clarification",
        transcript=transcript.text,
        language=context.language,
    )


@router.post("/speech/synthesize", response_model=SynthesisResponse)
async def synthesize(body: SynthesisRequest, request: Request) -> SynthesisResponse:
    ctx: ServiceContext = request.app.state.ctx
    prompt = ctx.prompts.active(SYNTHESIZE_PROMPT_ID).render({}, body.language)
    text = redact(body.text)
    result = await run_call(
        ctx,
        feature=Feature.TEXT_TO_SPEECH,
        slots=ctx.providers.text_to_speech,
        prompt=prompt,
        request=body,
        timeout=ctx.settings.timeouts.text_to_speech,
        invoke=lambda adapter, options: adapter.synthesize(text, prompt, options),
        parse=lambda raw: _speech(raw),
    )
    speech = result.value
    return SynthesisResponse(
        prompt_id=prompt.prompt_id,
        prompt_version=prompt.version,
        model_id=result.model_id,
        confidence=None,
        audio_base64=base64.b64encode(speech.audio).decode("ascii"),
        mime_type=speech.mime_type,
    )


def _transcript(raw: Transcription) -> Transcription:
    if not 0.0 <= raw.confidence <= 1.0:
        raise RejectedOutputError("confidence_out_of_range")
    return raw


def _speech(raw: SynthesizedSpeech) -> SynthesizedSpeech:
    return raw


def _context_from_headers(request: Request) -> RequestContext:
    opt_in = request.headers.get("x-ai-improvement-opt-in", "false").strip().lower()
    if opt_in not in ("true", "false"):
        raise RequestRejectedError(422, ErrorCode.INVALID_REQUEST, ["x-ai-improvement-opt-in"])
    try:
        return RequestContext.model_validate(
            {
                "householdRef": request.headers.get("x-household-ref", ""),
                "language": request.headers.get("x-language", "id"),
                "dataUse": {"aiImprovementOptIn": opt_in == "true"},
            }
        )
    except ValidationError as exc:
        fields = sorted({".".join(str(p) for p in e["loc"]) for e in exc.errors()})
        raise RequestRejectedError(422, ErrorCode.INVALID_REQUEST, fields) from None


async def _read_limited(request: Request, max_bytes: int) -> bytes:
    declared = request.headers.get("content-length")
    if declared and declared.isdigit() and int(declared) > max_bytes:
        raise RequestRejectedError(413, ErrorCode.PAYLOAD_TOO_LARGE)
    buffer = bytearray()
    async for chunk in request.stream():
        buffer += chunk
        if len(buffer) > max_bytes:
            buffer.clear()
            raise RequestRejectedError(413, ErrorCode.PAYLOAD_TOO_LARGE)
    return bytes(buffer)
