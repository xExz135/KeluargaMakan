"""AI-01, SAF-01: no AI response field can be read as a safety verdict.

Scans every schema in the service's OpenAPI document (requests, responses and
errors): property names and enum values are split into words, and none may be
a safety word. Outputs that name ingredients or recipes must carry
`ruleCheckRequired: true`, so the API knows Cek Aman has not run yet.
"""

from __future__ import annotations

import re
from collections.abc import Iterator
from typing import Any

from tests.support import harness

FORBIDDEN_WORDS = {
    "safe",
    "safely",
    "unsafe",
    "safety",
    "aman",
    "halal",
    "haram",
    "allergen",
    "allergens",
    "allergenfree",
    "verdict",
    "kosher",
    "vegan",
    "vegetarian",
    "certified",
    "suitable",
    "approved",
}

INGREDIENT_NAMING_RESPONSES = {
    "RecognizeIngredientsResponse",
    "AdaptRecipeResponse",
    "TweakResponse",
}


def _words(name: str) -> set[str]:
    spaced = re.sub(r"([a-z0-9])([A-Z])", r"\1 \2", name)
    return {word.lower() for word in re.split(r"[^A-Za-z0-9]+", spaced) if word}


def _names(node: Any) -> Iterator[str]:
    if isinstance(node, dict):
        for key, value in node.get("properties", {}).items():
            yield key
            yield from _names(value)
        for value in node.get("enum", []):
            if isinstance(value, str):
                yield value
        if isinstance(node.get("const"), str):
            yield node["const"]
        for key, value in node.items():
            if key != "properties":
                yield from _names(value)
    elif isinstance(node, list):
        for item in node:
            yield from _names(item)


def _schemas() -> dict[str, Any]:
    schemas: dict[str, Any] = harness().client.app.openapi()["components"]["schemas"]  # type: ignore[attr-defined]
    return schemas


def test_ai01_no_schema_field_or_enum_reads_as_a_safety_verdict() -> None:
    schemas = _schemas()
    assert set(schemas) >= INGREDIENT_NAMING_RESPONSES
    offenders = sorted(
        f"{schema_name}: {name}"
        for schema_name, schema in schemas.items()
        for name in _names(schema)
        if _words(name) & FORBIDDEN_WORDS
    )
    assert offenders == []


def test_ai01_scanner_catches_verdict_names() -> None:
    for name in ("safe", "isSafe", "allergenFree", "halal", "cekAmanResult", "safety_status"):
        assert _words(name) & FORBIDDEN_WORDS, name
    for name in ("ruleCheckRequired", "confidence", "ingredientId", "lessSalt"):
        assert not _words(name) & FORBIDDEN_WORDS, name


def test_ai01_ingredient_naming_outputs_require_a_downstream_rule_check() -> None:
    schemas = _schemas()
    for name in INGREDIENT_NAMING_RESPONSES:
        field = schemas[name]["properties"]["ruleCheckRequired"]
        assert field.get("const") is True or field.get("enum") == [True], name


def test_ai11_every_response_carries_prompt_version_model_id_and_confidence() -> None:
    schemas = _schemas()
    for name in (*INGREDIENT_NAMING_RESPONSES, "TranscriptionResponse", "SynthesisResponse"):
        assert {"promptId", "promptVersion", "modelId", "confidence"} <= set(
            schemas[name]["properties"]
        ), name
