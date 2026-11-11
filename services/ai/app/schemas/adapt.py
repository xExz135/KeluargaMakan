"""Schemas for /adapt/recipe (LIB-06, LIB-07, AI-02, AI-06; INT-07)."""

from __future__ import annotations

from typing import Annotated, Literal

from pydantic import Field, StringConstraints

from app.schemas.common import (
    AbstractConstraints,
    Confidence,
    IngredientName,
    IngredientRef,
    ReferenceId,
    RequestContext,
    ResponseMeta,
    ShortText,
    StrictModel,
)

StepText = Annotated[str, StringConstraints(min_length=1, max_length=600)]
Unit = Annotated[str, StringConstraints(min_length=1, max_length=24)]
RecipeVersion = Annotated[str, StringConstraints(pattern=r"^[A-Za-z0-9_.-]{1,40}$")]
AdaptationKind = Literal["scale", "substitute", "simplify"]


class RecipeIngredient(StrictModel):
    ingredient_id: ReferenceId | None = None
    raw_name: IngredientName
    quantity: float | None = Field(default=None, gt=0)
    unit: Unit | None = None


class RecipeStep(StrictModel):
    index: int = Field(ge=1)
    text: StepText
    timer_seconds: int | None = Field(default=None, gt=0)


class LibraryRecipe(StrictModel):
    """A tested library recipe (LIB-01). The AI adapts it, it never replaces it."""

    recipe_id: ReferenceId
    version: RecipeVersion
    title: Annotated[str, StringConstraints(min_length=1, max_length=120)]
    cuisine: ReferenceId
    servings: int = Field(ge=1, le=50)
    total_time_minutes: int | None = Field(default=None, gt=0)
    ingredients: list[RecipeIngredient] = Field(min_length=1, max_length=100)
    steps: list[RecipeStep] = Field(min_length=1, max_length=80)


class AdaptRecipeRequest(RequestContext):
    library_recipe: LibraryRecipe
    available_ingredients: list[IngredientRef] = Field(default_factory=list, max_length=1000)
    constraints: AbstractConstraints = Field(default_factory=AbstractConstraints)
    adaptations: list[AdaptationKind] = Field(min_length=1, max_length=3)
    target_servings: int | None = Field(default=None, ge=1, le=50)
    max_time_minutes: int | None = Field(default=None, gt=0)


class AdaptedIngredient(RecipeIngredient):
    changed: bool = False


class AdaptationChange(StrictModel):
    kind: Literal["scale", "substitute", "simplify", "remove"]
    note: ShortText


class BasedOn(StrictModel):
    recipe_id: ReferenceId
    version: RecipeVersion


class AdaptedRecipe(StrictModel):
    based_on: BasedOn
    title: Annotated[str, StringConstraints(min_length=1, max_length=120)]
    servings: int = Field(ge=1, le=50)
    total_time_minutes: int | None = Field(default=None, gt=0)
    ingredients: list[AdaptedIngredient] = Field(min_length=1, max_length=100)
    steps: list[RecipeStep] = Field(min_length=1, max_length=80)
    changes: list[AdaptationChange] = Field(max_length=20)
    # One sentence shown as the "adapted" note (tone guide 8.1).
    note: ShortText | None = None


class AdaptRecipeResponse(ResponseMeta):
    status: Literal["ok", "needs_clarification"]
    # LIB-06: always labeled adapted. LIB-07, AI-02: adapted, not generated.
    adapted: Literal[True] = True
    generated: bool = False
    recipe: AdaptedRecipe | None
    questions: list[ShortText] = Field(max_length=3)
    rule_check_required: Literal[True] = True


# ---------- what the language model must return ----------


class AdaptationModelOutput(StrictModel):
    title: Annotated[str, StringConstraints(min_length=1, max_length=120)]
    servings: int = Field(ge=1, le=50)
    total_time_minutes: int | None = Field(default=None, gt=0)
    ingredients: list[AdaptedIngredient] = Field(min_length=1, max_length=100)
    steps: list[RecipeStep] = Field(min_length=1, max_length=80)
    changes: list[AdaptationChange] = Field(default_factory=list, max_length=20)
    note: ShortText | None = None
    questions: list[ShortText] = Field(default_factory=list, max_length=3)
    confidence: Confidence
