"""Errors the service returns, and handlers that keep user content out of them.

AI-08: when a provider is down, slow or returns something unusable, the service
answers with an error that names the fallback the API should use. It never
returns a made-up or default result in its place.
"""

from __future__ import annotations

from enum import StrEnum

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from pydantic import BaseModel, ConfigDict
from pydantic.alias_generators import to_camel
from starlette.exceptions import HTTPException as StarletteHTTPException


class Feature(StrEnum):
    RECOGNITION = "recognition"
    ADAPTATION = "adaptation"
    TWEAK = "tweak"
    SPEECH_TO_TEXT = "speech_to_text"
    TEXT_TO_SPEECH = "text_to_speech"


class Fallback(StrEnum):
    """What the API shows instead (SRS 17, INT-06 to INT-08)."""

    MANUAL_ENTRY = "manual_entry"
    LIBRARY_RECIPE = "library_recipe"
    CURATED_FIXES = "curated_fixes"
    TOUCH_CONTROLS = "touch_controls"
    # Text-to-speech runs on the phone (DECISIONS 2026-11-11).
    DEVICE_TEXT_TO_SPEECH = "device_text_to_speech"


FALLBACK_FOR: dict[Feature, Fallback] = {
    Feature.RECOGNITION: Fallback.MANUAL_ENTRY,
    Feature.ADAPTATION: Fallback.LIBRARY_RECIPE,
    Feature.TWEAK: Fallback.CURATED_FIXES,
    Feature.SPEECH_TO_TEXT: Fallback.TOUCH_CONTROLS,
    Feature.TEXT_TO_SPEECH: Fallback.DEVICE_TEXT_TO_SPEECH,
}


class ErrorCode(StrEnum):
    AI_UNAVAILABLE = "ai_unavailable"
    AI_OUTPUT_REJECTED = "ai_output_rejected"
    AI_OPT_IN_REQUIRED = "ai_opt_in_required"
    UNAUTHORIZED = "unauthorized"
    INVALID_REQUEST = "invalid_request"
    UNSUPPORTED_MEDIA = "unsupported_media"
    PAYLOAD_TOO_LARGE = "payload_too_large"
    NOT_FOUND = "not_found"


class ErrorBody(BaseModel):
    """Error response. Carries no result fields, so it cannot be mistaken for one."""

    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True, extra="forbid")

    code: ErrorCode
    feature: Feature | None = None
    fallback: Fallback | None = None
    retryable: bool = False
    # Field locations and error types only; never the submitted values.
    fields: list[str] | None = None


class ServiceError(Exception):
    status_code = 500

    def __init__(self, body: ErrorBody) -> None:
        super().__init__(body.code.value)
        self.body = body


class AIUnavailableError(ServiceError):
    """Provider down, timed out, out of quota (HTTP 429) or disabled (AI-08)."""

    status_code = 503

    def __init__(self, feature: Feature) -> None:
        super().__init__(
            ErrorBody(
                code=ErrorCode.AI_UNAVAILABLE,
                feature=feature,
                fallback=FALLBACK_FOR[feature],
                retryable=True,
            )
        )


class AIOptInRequiredError(ServiceError):
    """SET-09, AI-12: every configured provider may train on inputs and this
    household has not opted in, so nothing was sent."""

    status_code = 403

    def __init__(self, feature: Feature) -> None:
        super().__init__(
            ErrorBody(
                code=ErrorCode.AI_OPT_IN_REQUIRED,
                feature=feature,
                fallback=FALLBACK_FOR[feature],
                retryable=False,
            )
        )


class AIOutputRejectedError(ServiceError):
    """Provider answered, but the output failed its schema or a guard."""

    status_code = 502

    def __init__(self, feature: Feature) -> None:
        super().__init__(
            ErrorBody(
                code=ErrorCode.AI_OUTPUT_REJECTED,
                feature=feature,
                fallback=FALLBACK_FOR[feature],
                retryable=False,
            )
        )


class RequestRejectedError(ServiceError):
    def __init__(self, status_code: int, code: ErrorCode, fields: list[str] | None = None) -> None:
        super().__init__(ErrorBody(code=code, fields=fields))
        self.status_code = status_code


def _json(status_code: int, body: ErrorBody, headers: dict[str, str] | None = None) -> JSONResponse:
    return JSONResponse(
        status_code=status_code,
        content=body.model_dump(mode="json", by_alias=True, exclude_none=True),
        headers=headers,
    )


def install_error_handlers(app: FastAPI) -> None:
    @app.exception_handler(ServiceError)
    async def _service_error(_: Request, exc: ServiceError) -> JSONResponse:
        headers = (
            {"WWW-Authenticate": "Bearer"} if exc.body.code is ErrorCode.UNAUTHORIZED else None
        )
        return _json(exc.status_code, exc.body, headers)

    @app.exception_handler(RequestValidationError)
    async def _validation_error(_: Request, exc: RequestValidationError) -> JSONResponse:
        # FastAPI's default echoes the submitted input, which could carry user text.
        fields = sorted(
            {
                ".".join(str(part) for part in error.get("loc", ())) + ":" + str(error.get("type"))
                for error in exc.errors()
            }
        )
        return _json(422, ErrorBody(code=ErrorCode.INVALID_REQUEST, fields=fields))

    @app.exception_handler(StarletteHTTPException)
    async def _http_error(_: Request, exc: StarletteHTTPException) -> JSONResponse:
        code = ErrorCode.NOT_FOUND if exc.status_code == 404 else ErrorCode.INVALID_REQUEST
        return _json(exc.status_code, ErrorBody(code=code))
