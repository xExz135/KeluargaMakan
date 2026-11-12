"""The owner's live smoke test (scripts/smoke_live.py) without the network.

Only the offline parts run here: env-file parsing, the generated test media and
the "nothing configured" exit. The live run is manual (INT-06 to INT-08).
"""

from __future__ import annotations

import importlib.util
import json
import os
import sys
from pathlib import Path
from types import ModuleType
from typing import Any

import httpx2
import pytest

from app.privacy.photo_metadata import strip_metadata
from tests.fake_apis import (
    ALL_KEYS,
    GEMINI_VISION_MODEL,
    REAL_ENV,
    VISION_KEY,
    FakeApis,
    adaptation_output,
    gemini_ok,
    groq_chat_ok,
    groq_stt_ok,
    recognition_output,
    tweak_output,
)

SCRIPT = Path(__file__).resolve().parent.parent / "scripts" / "smoke_live.py"


def _load() -> ModuleType:
    spec = importlib.util.spec_from_file_location("smoke_live", SCRIPT)
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    sys.modules["smoke_live"] = module
    spec.loader.exec_module(module)
    return module


def test_int06_smoke_image_is_a_valid_png_without_metadata() -> None:
    smoke = _load()
    png = smoke.synthetic_png()
    clean, mime = strip_metadata(png)
    assert mime == "image/png"
    assert clean == png


def test_int08_smoke_audio_is_a_one_second_wav() -> None:
    smoke = _load()
    wav = smoke.synthetic_wav()
    assert wav[:4] == b"RIFF" and wav[8:12] == b"WAVE"
    assert len(wav) == 44 + 16000 * 2


def test_smoke_env_file_parsing(tmp_path: Path) -> None:
    smoke = _load()
    env_file = tmp_path / "smoke.env"
    env_file.write_text(
        "# comment\n\nVISION_PROVIDER=gemini\nexport LANGUAGE_MODEL_ID='m-1'\n"
        'SPEECH_TO_TEXT_API_KEY="fake-test-only"\nnot a line\n',
        encoding="utf-8",
    )
    assert smoke.read_env_file(env_file) == {
        "VISION_PROVIDER": "gemini",
        "LANGUAGE_MODEL_ID": "m-1",
        "SPEECH_TO_TEXT_API_KEY": "fake-test-only",
    }
    assert smoke.read_env_file(tmp_path / "missing.env") == {}


def test_smoke_without_real_slots_calls_nothing(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch, capsys: pytest.CaptureFixture[str]
) -> None:
    smoke = _load()
    for key in list(os.environ):
        if key.startswith(smoke.SLOT_PREFIXES):
            monkeypatch.delenv(key)
    empty = tmp_path / "empty.env"
    empty.write_text("", encoding="utf-8")
    assert smoke.main(["--env-file", str(empty)]) == 2
    assert "nothing to test" in capsys.readouterr().out


def test_smoke_config_error_names_the_variable_not_the_value(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch, capsys: pytest.CaptureFixture[str]
) -> None:
    smoke = _load()
    for key in list(os.environ):
        if key.startswith(smoke.SLOT_PREFIXES):
            monkeypatch.delenv(key)
    env_file = tmp_path / "bad.env"
    env_file.write_text(
        "VISION_PROVIDER=gemini\nVISION_API_KEY=fake-secret-test-only-9999\n", encoding="utf-8"
    )
    assert smoke.main(["--env-file", str(env_file)]) == 1
    out = capsys.readouterr().out
    assert "VISION_MODEL_ID" in out
    assert "fake-secret-test-only-9999" not in out


# ---------- the whole script against the fake provider APIs ----------


def _answer_for(schema: object) -> dict[str, Any]:
    """Pick the invented answer whose schema the request asked for."""
    from app.providers.remote import output_schema

    outputs = {
        "recognize.ingredients": recognition_output,
        "adapt.recipe": adaptation_output,
        "tweak.advice": tweak_output,
    }
    for prompt_id, build in outputs.items():
        if schema == output_schema("gemini", prompt_id):
            return build()
    raise AssertionError("unexpected schema")


def _gemini(request: httpx2.Request) -> httpx2.Response:
    schema = json.loads(request.content)["generationConfig"]["responseJsonSchema"]
    return gemini_ok(_answer_for(schema))


def _groq(request: httpx2.Request) -> httpx2.Response:
    schema = json.loads(request.content)["response_format"]["json_schema"]["schema"]
    return groq_chat_ok(_answer_for(schema))


def _run_smoke(tmp_path: Path, monkeypatch: pytest.MonkeyPatch, apis: FakeApis) -> int:
    smoke = _load()
    for key in list(os.environ):
        if key.startswith(smoke.SLOT_PREFIXES):
            monkeypatch.delenv(key)
    env_file = tmp_path / "fake.env"
    env_file.write_text("".join(f"{k}={v}\n" for k, v in REAL_ENV.items()), encoding="utf-8")
    code: int = smoke.main(["--env-file", str(env_file)], transport=apis.transport())
    return code


def test_int06_smoke_passes_every_check_on_healthy_apis(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch, capsys: pytest.CaptureFixture[str]
) -> None:
    apis = FakeApis().on("gemini", _gemini).on("groq_chat", _groq).on("groq_stt", groq_stt_ok())
    code = _run_smoke(tmp_path, monkeypatch, apis)
    lines = [line for line in capsys.readouterr().out.splitlines() if line[:4] in ("PASS", "FAIL")]
    assert code == 0
    assert [line.split()[:4] for line in lines] == [
        ["PASS", "vision", "gemini", "recognize"],
        ["PASS", "language", "gemini", "tweak"],
        ["PASS", "language", "gemini", "adapt"],
        ["PASS", "language_backup", "groq", "tweak"],
        ["PASS", "language_backup", "groq", "adapt"],
        ["PASS", "speech_to_text", "groq", "transcribe"],
    ]


def test_ai03_smoke_failure_prints_http_status_and_error_code_only(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch, capsys: pytest.CaptureFixture[str]
) -> None:
    echoed = "Invalid JSON payload received. Unknown name rawName tempe 0812-3456-7890"
    rejected = httpx2.Response(
        400,
        headers={"x-echo": VISION_KEY},
        json={
            "error": {
                "code": 400,
                "message": f"{echoed} {VISION_KEY}",
                "status": "INVALID_ARGUMENT",
            }
        },
    )

    def gemini(request: httpx2.Request) -> httpx2.Response:
        if json.loads(request.content)["contents"][0]["parts"][-1].get("inlineData"):
            return rejected
        return _gemini(request)

    apis = FakeApis().on("gemini", gemini).on("groq_chat", _groq).on("groq_stt", groq_stt_ok())
    code = _run_smoke(tmp_path, monkeypatch, apis)
    captured = capsys.readouterr()
    out = captured.out + captured.err
    assert code == 1
    (fail,) = [line for line in out.splitlines() if line.startswith("FAIL")]
    assert fail.split() == [
        "FAIL",
        "vision",
        "gemini",
        "recognize",
        f"model={GEMINI_VISION_MODEL}",
        "error=ProviderUnavailableError",
        "http=400",
        "reason=INVALID_ARGUMENT",
    ]
    for leaked in (echoed, "rawName", "tempe", "0812", *ALL_KEYS):
        assert leaked not in out
