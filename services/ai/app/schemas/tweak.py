"""Schemas for /tweak, Taste & Tweak advice (TNT-02 to TNT-06, TNT-09, AI-04 to AI-06, AI-13)."""

from __future__ import annotations

from typing import Annotated, Literal, Self

from pydantic import Field, StringConstraints, model_validator

from app.schemas.adapt import RecipeStep, Unit
from app.schemas.common import (
    AbstractConstraints,
    Confidence,
    IngredientRef,
    ReferenceId,
    RequestContext,
    ResponseMeta,
    ShortText,
    StrictModel,
)

# TNT-01 quick-fix buttons, named as in the copy deck (tweak.fix.*).
QuickFixButton = Literal[
    "tooSalty", "tooSour", "tooSweet", "tooSpicy", "bland", "tooWatery", "tooThick", "tooOily"
]
FixKind = Literal[
    "acid", "aromatic", "herb", "salt", "sugar", "liquid", "fat", "thickener", "technique", "other"
]
RefusalReason = Literal["medical", "food_handling", "off_topic", "food_rule_question"]
# Copy-deck keys the app shows for a referral or refusal. The service sends the
# key, never the text, so the reviewed wording is used.
MessageKey = Literal["ai.medicalReferral", "ai.offTopic", "ai.foodHandling", "ai.foodRuleQuestion"]
FixText = Annotated[str, StringConstraints(min_length=1, max_length=160)]


class TweakRecipeContext(StrictModel):
    recipe_id: ReferenceId
    title: Annotated[str, StringConstraints(min_length=1, max_length=120)]
    cuisine: ReferenceId
    current_step: RecipeStep
    ingredients: list[IngredientRef] = Field(min_length=1, max_length=100)


class TweakProblem(StrictModel):
    """A quick-fix button, a typed or spoken description (TNT-02), or both."""

    button: QuickFixButton | None = None
    text: ShortText | None = None

    @model_validator(mode="after")
    def _one_of(self) -> Self:
        if self.button is None and self.text is None:
            raise ValueError("give a quick-fix button or a description")
        return self


class TweakRequest(RequestContext):
    recipe: TweakRecipeContext
    problem: TweakProblem
    constraints: AbstractConstraints = Field(default_factory=AbstractConstraints)
    available_ingredients: list[IngredientRef] = Field(default_factory=list, max_length=1000)


class FixAmount(StrictModel):
    quantity: float | None = Field(default=None, gt=0)
    unit: Unit | None = None
    text: Annotated[str, StringConstraints(min_length=1, max_length=40)]


class TweakFix(StrictModel):
    """TNT-04: imperative action, ingredient, amount and when to do it."""

    action: FixText
    kind: FixKind
    ingredient: IngredientRef | None = None
    amount: FixAmount | None = None
    timing: Annotated[str, StringConstraints(min_length=1, max_length=80)]

    @model_validator(mode="after")
    def _amount_with_ingredient(self) -> Self:
        if self.ingredient is not None and self.amount is None:
            raise ValueError("a fix that adds an ingredient needs an amount (TNT-04)")
        return self


class TweakResponse(ResponseMeta):
    status: Literal["ok", "needs_clarification", "referral", "refused"]
    reason: RefusalReason | None = None
    message_key: MessageKey | None = None
    fixes: list[TweakFix] = Field(max_length=3)
    question: ShortText | None = None
    rule_check_required: Literal[True] = True


# ---------- what the language model must return ----------


class TweakModelOutput(StrictModel):
    fixes: list[TweakFix] = Field(default_factory=list, max_length=3)
    question: ShortText | None = None
    confidence: Confidence
