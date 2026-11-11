"""Building blocks shared by every request and response schema.

Two rules shape these types:

- AI-03: requests carry only abstract constraints. Every model forbids unknown
  fields, so a name, member ID, contact detail or health condition cannot ride
  along in an extra field, and constraint tags reject health-condition words.
- AI-01, SAF-01: no field reads as a safety verdict. Outputs that name
  ingredients or recipes carry `ruleCheckRequired: true`, telling the API the
  result has not been checked and must go through Cek Aman before display.
"""

from __future__ import annotations

from typing import Annotated, Literal

from pydantic import AfterValidator, BaseModel, ConfigDict, Field, StringConstraints
from pydantic.alias_generators import to_camel

Language = Literal["id", "en"]


class StrictModel(BaseModel):
    """camelCase on the wire, no unknown fields, immutable."""

    model_config = ConfigDict(
        alias_generator=to_camel,
        validate_by_name=True,
        validate_by_alias=True,
        serialize_by_alias=True,
        extra="forbid",
        frozen=True,
        str_strip_whitespace=True,
    )


# Same pattern as data/schema/common.schema.json#/$defs/id.
ReferenceId = Annotated[str, StringConstraints(pattern=r"^[a-z0-9][a-z0-9_.-]{0,99}$")]

# Words that would name a health condition instead of an abstract constraint.
# The API sends what to avoid ("gluten", "added_sugar"), never why (AI-03).
HEALTH_CONDITION_WORDS = (
    "diabet",
    "hipertensi",
    "hypertens",
    "darah_tinggi",
    "kolesterol",
    "cholesterol",
    "asam_urat",
    "asamurat",
    "gout",
    "ginjal",
    "kidney",
    "jantung",
    "cardiac",
    "hamil",
    "pregnan",
    "kanker",
    "cancer",
    "maag",
    "gerd",
    "celiac",
    "coeliac",
    "seliak",
    "autis",
    "adhd",
    "epilep",
    "asma",
    "asthma",
    "stroke",
    "obesit",
    "anemia",
    "hepatit",
    "dokter",
    "doctor",
    "medis",
    "medical",
    "obat",
    "medication",
)


def _no_health_condition(tag: str) -> str:
    folded = tag.replace("-", "_").replace(".", "_")
    if any(word in folded for word in HEALTH_CONDITION_WORDS):
        raise ValueError("constraint tags name what to avoid, never a health condition")
    return tag


ConstraintTag = Annotated[ReferenceId, AfterValidator(_no_health_condition)]


def _pseudonym(value: str) -> str:
    if not any(char.isalpha() for char in value):
        raise ValueError("household reference must be an opaque pseudonym")
    return value


# Opaque pseudonym from the API for usage metering (AI-09). It is never sent to a
# provider. The pattern rules out email addresses; requiring a letter rules out
# phone numbers.
HouseholdRef = Annotated[
    str, StringConstraints(pattern=r"^[A-Za-z0-9_-]{16,128}$"), AfterValidator(_pseudonym)
]

IngredientName = Annotated[str, StringConstraints(min_length=1, max_length=80)]
ShortText = Annotated[str, StringConstraints(min_length=1, max_length=300)]
Confidence = Annotated[float, Field(ge=0.0, le=1.0)]
SpiceLevel = Literal["none", "mild", "medium", "hot"]


class AbstractConstraints(StrictModel):
    """Selected members' rules and preferences, merged and anonymized by the API.

    Example: {"avoid": ["shellfish", "alcohol"], "lessSalt": true}. There is no
    per-member structure and no reason for a rule.
    """

    avoid: list[ConstraintTag] = Field(default_factory=list, max_length=200)
    dislikes: list[ConstraintTag] = Field(default_factory=list, max_length=200)
    less_salt: bool = False
    less_sugar: bool = False
    less_oil: bool = False
    spice_level: SpiceLevel | None = None


class DataUse(StrictModel):
    """SET-09: the household's AI-improvement choice. Off unless the user opted in."""

    ai_improvement_opt_in: bool = False


class RequestContext(StrictModel):
    household_ref: HouseholdRef
    language: Language = "id"
    data_use: DataUse = Field(default_factory=DataUse)


class IngredientRef(StrictModel):
    """An ingredient by reference ID, or by raw name when it is not mapped.

    Unmapped names stay unmapped (`ingredientId: null`); Cek Aman then returns
    "Check the label" for them (SAF-09).
    """

    ingredient_id: ReferenceId | None = None
    raw_name: IngredientName


class ResponseMeta(StrictModel):
    """Traceability on every response (AI-11)."""

    prompt_id: str
    prompt_version: str
    model_id: str
    # Null where it does not apply (for example text-to-speech or a refusal).
    confidence: Confidence | None
