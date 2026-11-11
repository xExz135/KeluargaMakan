"""The owner's live smoke test (scripts/smoke_live.py) without the network.

Only the offline parts run here: env-file parsing, the generated test media and
the "nothing configured" exit. The live run is manual (INT-06 to INT-08).
"""

from __future__ import annotations

import importlib.util
import os
import sys
from pathlib import Path
from types import ModuleType

import pytest

from app.privacy.photo_metadata import strip_metadata

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
