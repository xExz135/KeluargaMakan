"""Schemas for /recognize/ingredients (REC-02, REC-03, REC-05, AI-06; INT-06)."""

from __future__ import annotations

from typing import Annotated, Literal

from pydantic import Field, StringConstraints

from app.schemas.common import (
    Confidence,
    IngredientName,
    IngredientRef,
    ReferenceId,
    RequestContext,
    ResponseMeta,
    ShortText,
    StrictModel,
)

PhotoUrl = Annotated[str, StringConstraints(min_length=8, max_length=2048)]


class PhotoRef(StrictModel):
    """A short-lived URL to a photo the API already stripped of metadata (T-035)."""

    url: PhotoUrl


class SavedIngredient(StrictModel):
    """An ingredient already in the household's kitchen, preferred as a match (REC-05)."""

    ingredient_id: ReferenceId
    name: IngredientName


class RecognizeIngredientsRequest(RequestContext):
    # The per-request maximum is configuration (REC-01 target), checked in the route.
    photos: list[PhotoRef] = Field(min_length=1, max_length=20)
    saved_ingredients: list[SavedIngredient] = Field(default_factory=list, max_length=1000)


class RecognizedIngredient(StrictModel):
    ingredient_id: ReferenceId | None
    raw_name: IngredientName
    confidence: Confidence
    photo_index: int = Field(ge=0)


class IngredientQuestion(StrictModel):
    """REC-03, AI-06: a low-confidence item, asked instead of guessed."""

    # One short question in the request language, or null for the app's own copy.
    text: ShortText | None
    options: list[IngredientRef] = Field(min_length=1, max_length=4)
    confidence: Confidence
    photo_index: int = Field(ge=0)


class RecognizeIngredientsResponse(ResponseMeta):
    candidates: list[RecognizedIngredient]
    questions: list[IngredientQuestion]
    # REC-04: nothing is saved until the user confirms the checklist.
    confirmation_required: Literal[True] = True
    rule_check_required: Literal[True] = True


# ---------- what the vision model must return ----------


class VisionCandidate(StrictModel):
    raw_name: IngredientName
    ingredient_id: ReferenceId | None = None
    confidence: Confidence
    photo_index: int = Field(ge=0)
    alternatives: list[IngredientRef] = Field(default_factory=list, max_length=3)
    question: ShortText | None = None


class RecognitionModelOutput(StrictModel):
    candidates: list[VisionCandidate] = Field(max_length=200)
    confidence: Confidence | None = None
