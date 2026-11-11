"""POST /adapt/recipe (skeleton; T-046 adds the real adaptation).

LIB-06 adapted recipes are labeled `adapted: true`; LIB-07 and AI-02 they are
based on a library recipe and never generated; AI-06 low confidence asks
instead of guessing. Ingredient IDs come only from the library recipe or the
household's available ingredients; anything else stays a raw name.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Literal

from fastapi import APIRouter, Request

from app.errors import Feature
from app.guards import output_violation
from app.pipeline import RejectedOutputError, ServiceContext, run_call
from app.privacy.redact import redact
from app.providers.base import ModelOutput
from app.schemas.adapt import (
    AdaptationModelOutput,
    AdaptedRecipe,
    AdaptRecipeRequest,
    AdaptRecipeResponse,
    BasedOn,
    LibraryRecipe,
)

router = APIRouter()
PROMPT_ID = "adapt.recipe"


@dataclass(frozen=True)
class _Adaptation:
    status: Literal["ok", "needs_clarification"]
    recipe: AdaptedRecipe | None
    questions: list[str]
    confidence: float


@router.post("/adapt/recipe", response_model=AdaptRecipeResponse)
async def adapt_recipe(body: AdaptRecipeRequest, request: Request) -> AdaptRecipeResponse:
    ctx: ServiceContext = request.app.state.ctx
    recipe = body.library_recipe
    payload: dict[str, object] = {
        "libraryRecipe": recipe.model_dump(mode="json"),
        "availableIngredients": [
            {"ingredientId": item.ingredient_id, "rawName": redact(item.raw_name)}
            for item in body.available_ingredients
        ],
        "constraints": body.constraints.model_dump(mode="json"),
        "adaptations": list(body.adaptations),
        "targetServings": body.target_servings,
        "maxTimeMinutes": body.max_time_minutes,
    }
    prompt = ctx.prompts.active(PROMPT_ID).render(payload, body.language)
    allowed_ids = frozenset(
        [i.ingredient_id for i in recipe.ingredients if i.ingredient_id]
        + [i.ingredient_id for i in body.available_ingredients if i.ingredient_id]
    )
    threshold = ctx.settings.confidence.adaptation

    def parse(raw: ModelOutput) -> _Adaptation:
        output = AdaptationModelOutput.model_validate(raw.data)
        _guard_texts(output)
        if output.confidence < threshold:
            if not output.questions:
                raise RejectedOutputError("low_confidence_without_question")
            return _Adaptation("needs_clarification", None, output.questions, output.confidence)
        adapted = _adapted(recipe, output, allowed_ids)
        return _Adaptation("ok", adapted, output.questions, output.confidence)

    result = await run_call(
        ctx,
        feature=Feature.ADAPTATION,
        prompt=prompt,
        request=body,
        timeout=ctx.settings.timeouts.adaptation,
        slots=ctx.providers.language,
        invoke=lambda adapter, options: adapter.complete(prompt, options),
        parse=parse,
    )
    adaptation = result.value
    return AdaptRecipeResponse(
        prompt_id=prompt.prompt_id,
        prompt_version=prompt.version,
        model_id=result.model_id,
        confidence=adaptation.confidence,
        status=adaptation.status,
        recipe=adaptation.recipe,
        questions=adaptation.questions,
    )


def _adapted(
    recipe: LibraryRecipe, output: AdaptationModelOutput, allowed_ids: frozenset[str]
) -> AdaptedRecipe:
    return AdaptedRecipe(
        # Taken from the request, never from the model.
        based_on=BasedOn(recipe_id=recipe.recipe_id, version=recipe.version),
        title=output.title,
        servings=output.servings,
        total_time_minutes=output.total_time_minutes,
        ingredients=[
            item
            if item.ingredient_id is None or item.ingredient_id in allowed_ids
            else item.model_copy(update={"ingredient_id": None})
            for item in output.ingredients
        ],
        steps=output.steps,
        changes=output.changes,
        note=output.note,
    )


def _guard_texts(output: AdaptationModelOutput) -> None:
    """A recipe cannot lose a step safely, so any violation rejects the whole output."""
    texts = [output.title, output.note or "", *output.questions]
    texts += [step.text for step in output.steps]
    texts += [change.note for change in output.changes]
    for text in texts:
        violation = output_violation(text)
        if violation:
            raise RejectedOutputError(violation)
