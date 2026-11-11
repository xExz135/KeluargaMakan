"""POST /recognize/ingredients (skeleton; T-037 adds real recognition).

REC-02 checklist with confidence, REC-03 and AI-06 questions for low confidence,
REC-05 saved-ingredient matches, REC-07 photos only in memory, AI-03 metadata
stripped and no personal data sent.
"""

from __future__ import annotations

from fastapi import APIRouter, Request

from app.errors import (
    AIOptInRequiredError,
    AIUnavailableError,
    ErrorCode,
    Feature,
    RequestRejectedError,
)
from app.guards import output_violation
from app.photos import PhotoTooLargeError, PhotoUrlError, check_photo_url
from app.pipeline import RejectedOutputError, ServiceContext, eligible_slots, run_call
from app.privacy.photo_metadata import UnsupportedPhotoError, strip_metadata
from app.privacy.redact import redact
from app.providers.base import ImageInput, ModelOutput, ProviderUnavailableError
from app.schemas.common import IngredientRef
from app.schemas.recognize import (
    IngredientQuestion,
    RecognitionModelOutput,
    RecognizedIngredient,
    RecognizeIngredientsRequest,
    RecognizeIngredientsResponse,
)

router = APIRouter()
PROMPT_ID = "recognize.ingredients"


@router.post("/recognize/ingredients", response_model=RecognizeIngredientsResponse)
async def recognize_ingredients(
    body: RecognizeIngredientsRequest, request: Request
) -> RecognizeIngredientsResponse:
    ctx: ServiceContext = request.app.state.ctx
    limits = ctx.settings.limits
    if len(body.photos) > limits.max_photos_per_request:
        raise RequestRejectedError(422, ErrorCode.INVALID_REQUEST, ["photos:too_many"])
    for index, photo in enumerate(body.photos):
        try:
            check_photo_url(photo.url, ctx.settings.photo_allowed_hosts)
        except PhotoUrlError:
            raise RequestRejectedError(
                422, ErrorCode.INVALID_REQUEST, [f"photos.{index}.url:not_allowed"]
            ) from None

    # SET-09: without an eligible provider, do not even load the photos.
    if not eligible_slots(ctx.providers.vision, body):
        raise AIOptInRequiredError(Feature.RECOGNITION)
    images = await _load_images(ctx, body)
    try:
        template = ctx.prompts.active(PROMPT_ID)
        payload: dict[str, object] = {
            "photoCount": len(images),
            "savedIngredients": [
                {"ingredientId": item.ingredient_id, "name": redact(item.name)}
                for item in body.saved_ingredients
            ],
        }
        prompt = template.render(payload, body.language)
        known_ids = frozenset(item.ingredient_id for item in body.saved_ingredients)
        threshold = ctx.settings.confidence.recognition

        def parse(raw: ModelOutput) -> tuple[list[RecognizedIngredient], list[IngredientQuestion]]:
            output = RecognitionModelOutput.model_validate(raw.data)
            return _checklist(output, known_ids, threshold, len(images))

        result = await run_call(
            ctx,
            feature=Feature.RECOGNITION,
            prompt=prompt,
            request=body,
            timeout=ctx.settings.timeouts.recognition,
            slots=ctx.providers.vision,
            invoke=lambda adapter, options: adapter.analyze(prompt, images, options),
            parse=parse,
        )
    finally:
        # REC-07: drop the photo bytes as soon as the call is over.
        images.clear()

    candidates, questions = result.value
    return RecognizeIngredientsResponse(
        prompt_id=prompt.prompt_id,
        prompt_version=prompt.version,
        model_id=result.model_id,
        confidence=_overall(candidates, questions),
        candidates=candidates,
        questions=questions,
    )


async def _load_images(ctx: ServiceContext, body: RecognizeIngredientsRequest) -> list[ImageInput]:
    images: list[ImageInput] = []
    for index, photo in enumerate(body.photos):
        try:
            data = await ctx.photo_source.fetch(photo.url, ctx.settings.limits.max_photo_bytes)
        except PhotoTooLargeError:
            raise RequestRejectedError(
                413, ErrorCode.PAYLOAD_TOO_LARGE, [f"photos.{index}"]
            ) from None
        except ProviderUnavailableError:
            raise AIUnavailableError(Feature.RECOGNITION) from None
        try:
            clean, mime = strip_metadata(data)
        except UnsupportedPhotoError:
            raise RequestRejectedError(
                415, ErrorCode.UNSUPPORTED_MEDIA, [f"photos.{index}"]
            ) from None
        images.append(ImageInput(data=clean, mime_type=mime))
    return images


def _checklist(
    output: RecognitionModelOutput, known_ids: frozenset[str], threshold: float, photo_count: int
) -> tuple[list[RecognizedIngredient], list[IngredientQuestion]]:
    candidates: list[RecognizedIngredient] = []
    questions: list[IngredientQuestion] = []
    for item in output.candidates:
        if item.photo_index >= photo_count:
            raise RejectedOutputError("photo_index")
        # Only IDs the household already has; anything else stays a raw name.
        ingredient_id = item.ingredient_id if item.ingredient_id in known_ids else None
        if item.confidence >= threshold:
            candidates.append(
                RecognizedIngredient(
                    ingredient_id=ingredient_id,
                    raw_name=item.raw_name,
                    confidence=item.confidence,
                    photo_index=item.photo_index,
                )
            )
            continue
        # AI-06: ask, never include a low-confidence guess silently.
        options = [IngredientRef(ingredient_id=ingredient_id, raw_name=item.raw_name)]
        for alternative in item.alternatives:
            alt_id = alternative.ingredient_id if alternative.ingredient_id in known_ids else None
            if all(option.raw_name != alternative.raw_name for option in options):
                options.append(IngredientRef(ingredient_id=alt_id, raw_name=alternative.raw_name))
        text = item.question if item.question and not output_violation(item.question) else None
        questions.append(
            IngredientQuestion(
                text=text,
                options=options[:4],
                confidence=item.confidence,
                photo_index=item.photo_index,
            )
        )
    return candidates, questions


def _overall(
    candidates: list[RecognizedIngredient], questions: list[IngredientQuestion]
) -> float | None:
    scores = [c.confidence for c in candidates] + [q.confidence for q in questions]
    return round(min(scores), 3) if scores else None
