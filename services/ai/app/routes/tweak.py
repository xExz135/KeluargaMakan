"""POST /tweak, Taste & Tweak advice (skeleton; T-061 adds the real advice).

Guard points, in order:
1. Input guard on the typed problem: medical -> referral (AI-04); unsafe
   handling -> refused (AI-05, TNT-09); "is this safe/halal" -> refused, Cek
   Aman answers that (AI-01); off-topic -> refused (AI-13). No provider call.
2. Provider call with abstract constraints only (AI-03, TNT-03).
3. Output guard drops any fix with a safety, health or unsafe-handling claim.
4. TNT-06: with less-salt or less-sugar, salt or sugar fixes give way to others.
5. AI-06: low confidence returns a question, never a guess.
Every fix that names an ingredient must still pass Cek Aman in the API (TNT-05).
"""

from __future__ import annotations

import uuid
from dataclasses import dataclass
from typing import Literal

from fastapi import APIRouter, Request

from app.errors import Feature
from app.guards import GuardResult, InputCategory, output_violation
from app.pipeline import RejectedOutputError, ServiceContext, run_call
from app.privacy.redact import redact
from app.providers.base import ModelOutput
from app.schemas.common import AbstractConstraints
from app.schemas.tweak import (
    MessageKey,
    RefusalReason,
    TweakFix,
    TweakModelOutput,
    TweakRequest,
    TweakResponse,
)
from app.telemetry import CallRecord, Outcome, log_call

router = APIRouter()
PROMPT_ID = "tweak.advice"

_REFUSALS: dict[InputCategory, tuple[str, RefusalReason, MessageKey]] = {
    InputCategory.MEDICAL: ("referral", "medical", "ai.medicalReferral"),
    InputCategory.UNSAFE_HANDLING: ("refused", "food_handling", "ai.foodHandling"),
    InputCategory.FOOD_RULE_QUESTION: ("refused", "food_rule_question", "ai.foodRuleQuestion"),
    InputCategory.OFF_TOPIC: ("refused", "off_topic", "ai.offTopic"),
}


@dataclass(frozen=True)
class _Advice:
    status: Literal["ok", "needs_clarification"]
    fixes: list[TweakFix]
    question: str | None
    confidence: float


@router.post("/tweak", response_model=TweakResponse)
async def tweak(body: TweakRequest, request: Request) -> TweakResponse:
    ctx: ServiceContext = request.app.state.ctx

    if body.problem.text is not None:
        guarded = ctx.input_guard.classify(body.problem.text)
        if guarded.category is not InputCategory.COOKING:
            return _refusal(guarded)

    payload: dict[str, object] = {
        "recipe": body.recipe.model_dump(mode="json"),
        "problem": {
            "button": body.problem.button,
            "text": redact(body.problem.text) if body.problem.text else None,
        },
        "constraints": body.constraints.model_dump(mode="json"),
        "availableIngredients": [
            {"ingredientId": item.ingredient_id, "rawName": redact(item.raw_name)}
            for item in body.available_ingredients
        ],
    }
    prompt = ctx.prompts.active(PROMPT_ID).render(payload, body.language)
    allowed_ids = frozenset(
        [i.ingredient_id for i in body.recipe.ingredients if i.ingredient_id]
        + [i.ingredient_id for i in body.available_ingredients if i.ingredient_id]
    )
    threshold = ctx.settings.confidence.tweak

    def parse(raw: ModelOutput) -> _Advice:
        output = TweakModelOutput.model_validate(raw.data)
        fixes = [_restrict_id(fix, allowed_ids) for fix in output.fixes if _fix_is_clean(fix)]
        fixes = prefer_for_constraints(fixes, body.constraints)
        question = output.question
        if question is not None and output_violation(question):
            question = None
        if output.confidence < threshold or not fixes:
            if question is None:
                # Nothing usable to show: the API uses curated fixes (TNT-07).
                raise RejectedOutputError("no_usable_fix")
            return _Advice("needs_clarification", [], question, output.confidence)
        return _Advice("ok", fixes, None, output.confidence)

    result = await run_call(
        ctx,
        feature=Feature.TWEAK,
        prompt=prompt,
        request=body,
        timeout=ctx.settings.timeouts.tweak,
        slots=ctx.providers.language,
        invoke=lambda adapter, options: adapter.complete(prompt, options),
        parse=parse,
    )
    advice = result.value
    return TweakResponse(
        prompt_id=prompt.prompt_id,
        prompt_version=prompt.version,
        model_id=result.model_id,
        confidence=advice.confidence,
        status=advice.status,
        fixes=advice.fixes,
        question=advice.question,
    )


def _refusal(guarded: GuardResult) -> TweakResponse:
    status, reason, message_key = _REFUSALS[guarded.category]
    log_call(
        CallRecord(
            request_id=uuid.uuid4().hex,
            feature=Feature.TWEAK.value,
            prompt_id=guarded.guard_id,
            prompt_version=guarded.guard_version,
            prompt_sha256="",
            model_id=guarded.guard_id,
            provider="none",
            slot="none",
            tier="none",
            outcome=Outcome.GUARDED,
            latency_ms=0.0,
            training_allowed=False,
        )
    )
    return TweakResponse.model_validate(
        {
            "promptId": guarded.guard_id,
            "promptVersion": guarded.guard_version,
            "modelId": guarded.guard_id,
            "confidence": None,
            "status": status,
            "reason": reason,
            "messageKey": message_key,
            "fixes": [],
        }
    )


def _fix_is_clean(fix: TweakFix) -> bool:
    texts = [fix.action, fix.timing, fix.amount.text if fix.amount else ""]
    return not any(output_violation(text) for text in texts)


def _restrict_id(fix: TweakFix, allowed_ids: frozenset[str]) -> TweakFix:
    ingredient = fix.ingredient
    if ingredient is None or ingredient.ingredient_id in (None, *allowed_ids):
        return fix
    return fix.model_copy(
        update={"ingredient": ingredient.model_copy(update={"ingredient_id": None})}
    )


def prefer_for_constraints(
    fixes: list[TweakFix], constraints: AbstractConstraints
) -> list[TweakFix]:
    """TNT-06: with less salt or sugar, drop salt or sugar fixes when another fix exists."""
    avoided = set()
    if constraints.less_salt:
        avoided.add("salt")
    if constraints.less_sugar:
        avoided.add("sugar")
    preferred = [fix for fix in fixes if fix.kind not in avoided]
    return preferred if preferred else fixes
