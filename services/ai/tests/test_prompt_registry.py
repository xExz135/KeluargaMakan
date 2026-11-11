"""AI-11: prompts are versioned in a registry, and each call logs promptVersion and modelId."""

from __future__ import annotations

import json
import logging
import shutil
from pathlib import Path

import pytest

from app.config import ConfigError
from app.prompt_registry import DEFAULT_PROMPTS_DIR, PromptRegistry, canonical_sha256
from app.telemetry import CALL_LOGGER
from tests.support import AUTH, harness, tweak_body

FEATURE_PROMPTS = {
    "recognize.ingredients",
    "adapt.recipe",
    "tweak.advice",
    "speech.transcribe",
    "speech.synthesize",
}


def _copy(tmp_path: Path) -> Path:
    target = tmp_path / "prompts"
    shutil.copytree(DEFAULT_PROMPTS_DIR, target)
    return target


def test_ai11_registry_loads_with_an_active_version_per_feature() -> None:
    registry = PromptRegistry.load()
    assert set(registry.active_versions) == FEATURE_PROMPTS
    for template in registry.all_templates():
        assert template.requirement_ids, template.prompt_id


def test_ai11_editing_a_template_without_a_new_version_is_refused(tmp_path: Path) -> None:
    root = _copy(tmp_path)
    path = root / "tweak.advice" / "0.1.0.json"
    document = json.loads(path.read_text(encoding="utf-8"))
    document["system"] += " Extra instruction."
    path.write_text(json.dumps(document), encoding="utf-8")
    with pytest.raises(ConfigError, match="changed without a registry update"):
        PromptRegistry.load(root)


def test_ai11_whitespace_and_line_endings_do_not_change_the_hash(tmp_path: Path) -> None:
    root = _copy(tmp_path)
    path = root / "tweak.advice" / "0.1.0.json"
    document = json.loads(path.read_text(encoding="utf-8"))
    path.write_bytes(json.dumps(document, indent=8).replace("\n", "\r\n").encode())
    PromptRegistry.load(root)


def test_ai11_new_version_is_added_and_selected_through_the_registry(tmp_path: Path) -> None:
    root = _copy(tmp_path)
    old = json.loads((root / "tweak.advice" / "0.1.0.json").read_text(encoding="utf-8"))
    new = {**old, "version": "0.2.0", "system": old["system"] + " v2"}
    (root / "tweak.advice" / "0.2.0.json").write_text(json.dumps(new), encoding="utf-8")
    index = json.loads((root / "registry.json").read_text(encoding="utf-8"))
    for entry in index["prompts"]:
        if entry["id"] == "tweak.advice":
            entry["active"] = False
    index["prompts"].append(
        {"id": "tweak.advice", "version": "0.2.0", "sha256": canonical_sha256(new), "active": True}
    )
    (root / "registry.json").write_text(json.dumps(index), encoding="utf-8")
    registry = PromptRegistry.load(root)
    assert registry.active("tweak.advice").version == "0.2.0"


def test_ai11_unlisted_template_is_refused(tmp_path: Path) -> None:
    root = _copy(tmp_path)
    shutil.copy(root / "tweak.advice" / "0.1.0.json", root / "tweak.advice" / "9.9.9.json")
    with pytest.raises(ConfigError, match="missing from registry"):
        PromptRegistry.load(root)


def test_ai11_unknown_placeholder_is_refused(tmp_path: Path) -> None:
    root = _copy(tmp_path)
    path = root / "tweak.advice" / "0.1.0.json"
    document = json.loads(path.read_text(encoding="utf-8"))
    document["user"] = "Member: $memberName"
    path.write_text(json.dumps(document), encoding="utf-8")
    index = json.loads((root / "registry.json").read_text(encoding="utf-8"))
    for entry in index["prompts"]:
        if entry["id"] == "tweak.advice":
            entry["sha256"] = canonical_sha256(document)
    (root / "registry.json").write_text(json.dumps(index), encoding="utf-8")
    with pytest.raises(ConfigError, match="unknown placeholders"):
        PromptRegistry.load(root)


def test_ai11_response_and_call_log_carry_prompt_version_and_model_id(
    caplog: pytest.LogCaptureFixture,
) -> None:
    h = harness()
    with caplog.at_level(logging.INFO, logger=CALL_LOGGER):
        body = h.client.post("/tweak", json=tweak_body(), headers=AUTH).json()
    active = PromptRegistry.load().active("tweak.advice")
    assert body["promptId"] == "tweak.advice"
    assert body["promptVersion"] == active.version
    assert body["modelId"] == "mock-language-1"
    (record,) = [r for r in caplog.records if r.name == CALL_LOGGER]
    fields = record.fields  # type: ignore[attr-defined]
    assert fields["prompt_version"] == active.version
    assert fields["model_id"] == "mock-language-1"
    assert fields["prompt_sha256"] == active.sha256
    assert fields["outcome"] == "ok"


def test_ai11_each_feature_prompt_targets_the_capability_its_route_calls() -> None:
    registry = PromptRegistry.load()
    expected = {
        "recognize.ingredients": "vision",
        "adapt.recipe": "language",
        "tweak.advice": "language",
        "speech.transcribe": "speech_to_text",
        "speech.synthesize": "text_to_speech",
    }
    for prompt_id, capability in expected.items():
        assert registry.active(prompt_id).capability.value == capability
