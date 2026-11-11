"""Manual live smoke test for the real AI provider slots (INT-06 to INT-08).

FOR THE OWNER TO RUN LOCALLY. Not run in CI and not run by agents: it calls
Google (Gemini API) and Groq with your real keys.

What it sends: one tiny synthetic request per configured Gemini or Groq slot.
A generated test image (coloured shapes, no people, no metadata), an invented
Taste & Tweak question about a made-up recipe, and one second of a generated
tone. No personal data. On free tiers Google and Groq may use requests to
improve their products, so running this counts as opting in for this test data.

What it prints: per slot, PASS or FAIL, the provider's model ID, the latency
and, on failure, the error class name only. It never prints keys, prompts or
model output.

Usage (from services/ai, with the service venv):
    .venv/Scripts/python scripts/smoke_live.py            (Windows)
    .venv/bin/python scripts/smoke_live.py                (macOS, Linux)
    .venv/Scripts/python scripts/smoke_live.py --env-file path/to/.env

Keys and model IDs come from services/ai/.env (see .env.example):
VISION_*, LANGUAGE_*, LANGUAGE_BACKUP_*, SPEECH_TO_TEXT_*. Variables already set
in the environment take precedence over the file. Exit code 0 when every
configured real slot passed, 1 otherwise, 2 when no real slot is configured.
"""

from __future__ import annotations

import argparse
import asyncio
import math
import os
import struct
import sys
import time
import zlib
from collections.abc import Awaitable, Callable, Mapping
from pathlib import Path

SERVICE_ROOT = Path(__file__).resolve().parent.parent
if str(SERVICE_ROOT) not in sys.path:
    sys.path.insert(0, str(SERVICE_ROOT))

from pydantic import BaseModel  # noqa: E402

from app.config import (  # noqa: E402
    REMOTE_PROVIDERS,
    Capability,
    ConfigError,
    ProviderConfig,
    ProviderName,
    load_settings,
)
from app.privacy.photo_metadata import strip_metadata  # noqa: E402
from app.prompt_registry import PromptRegistry  # noqa: E402
from app.providers.base import (  # noqa: E402
    AudioInput,
    CallOptions,
    ImageInput,
    LanguageProvider,
    ModelOutput,
    Transcription,
)
from app.providers.gemini import GeminiProvider  # noqa: E402
from app.providers.groq import GroqProvider  # noqa: E402
from app.schemas.recognize import RecognitionModelOutput  # noqa: E402
from app.schemas.tweak import TweakModelOutput  # noqa: E402

SLOT_PREFIXES = ("VISION_", "LANGUAGE_", "SPEECH_TO_TEXT_")
TIME_BUDGET_SECONDS = 30.0
# A throwaway token: the smoke test builds adapters directly and starts no server.
DUMMY_SERVICE_TOKEN = "smoke-test-only-not-a-service-token-000000"  # noqa: S105


def read_env_file(path: Path) -> dict[str, str]:
    """KEY=VALUE lines; # comments and blank lines skipped; surrounding quotes removed."""
    values: dict[str, str] = {}
    if not path.is_file():
        return values
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, value = line.partition("=")
        key = key.strip().removeprefix("export ").strip()
        value = value.strip()
        if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
            value = value[1:-1]
        values[key] = value
    return values


def synthetic_png(size: int = 128) -> bytes:
    """A generated picture: a red circle and a green bar on white. No people."""
    rows = bytearray()
    centre, radius = size * 0.35, size * 0.22
    for y in range(size):
        rows.append(0)  # filter type: none
        for x in range(size):
            if (x - centre) ** 2 + (y - centre) ** 2 <= radius**2:
                pixel = (200, 30, 30)
            elif size * 0.55 < x < size * 0.9 and size * 0.6 < y < size * 0.75:
                pixel = (40, 160, 60)
            else:
                pixel = (250, 250, 250)
            rows.extend(pixel)

    def chunk(kind: bytes, data: bytes) -> bytes:
        crc = zlib.crc32(kind + data) & 0xFFFFFFFF
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", crc)

    header = struct.pack(">IIBBBBB", size, size, 8, 2, 0, 0, 0)
    return (
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", header)
        + chunk(b"IDAT", zlib.compress(bytes(rows)))
        + chunk(b"IEND", b"")
    )


def synthetic_wav(seconds: float = 1.0, rate: int = 16000) -> bytes:
    """One second of a quiet 440 Hz tone, 16-bit mono PCM."""
    samples = int(seconds * rate)
    data = b"".join(
        struct.pack("<h", int(3000 * math.sin(2 * math.pi * 440 * i / rate)))
        for i in range(samples)
    )
    header = b"RIFF" + struct.pack("<I", 36 + len(data)) + b"WAVEfmt "
    header += struct.pack("<IHHIIHH", 16, 1, 1, rate, rate * 2, 2, 16)
    return header + b"data" + struct.pack("<I", len(data)) + data


TWEAK_PAYLOAD: Mapping[str, object] = {
    "recipe": {
        "recipeId": "smoke_test_recipe",
        "title": "Sayur bening contoh",
        "cuisine": "indonesian",
        "currentStep": {"index": 2, "text": "Masukkan bayam dan aduk sebentar."},
        "ingredients": [{"ingredientId": None, "rawName": "bayam"}],
    },
    "problem": {"button": "bland", "text": None},
    "constraints": {"avoid": [], "dislikes": [], "lessSalt": True},
    "availableIngredients": [{"ingredientId": None, "rawName": "jeruk nipis"}],
}


def _validated(model: type[BaseModel]) -> Callable[[ModelOutput], str]:
    def check(result: ModelOutput) -> str:
        model.model_validate(result.data)
        return result.model_id

    return check


def _transcribed(result: Transcription) -> str:
    if not 0.0 <= result.confidence <= 1.0:
        raise ValueError("confidence out of range")
    return result.model_id


async def _timed[T](
    call: Callable[[CallOptions], Awaitable[T]], check: Callable[[T], str]
) -> tuple[str, float]:
    loop = asyncio.get_running_loop()
    options = CallOptions(
        language="id", allow_training=True, deadline=loop.time() + TIME_BUDGET_SECONDS
    )
    start = time.perf_counter()
    try:
        result = await asyncio.wait_for(call(options), TIME_BUDGET_SECONDS)
    finally:
        latency = (time.perf_counter() - start) * 1000
    return check(result), latency


async def smoke(config: ProviderConfig, prompts: PromptRegistry) -> tuple[str, float]:
    if config.capability is Capability.VISION:
        gemini = GeminiProvider(config)
        prompt = prompts.active("recognize.ingredients").render(
            {"photoCount": 1, "savedIngredients": []}, "id"
        )
        clean, mime = strip_metadata(synthetic_png())
        image = ImageInput(data=clean, mime_type=mime)
        return await _timed(
            lambda options: gemini.analyze(prompt, [image], options),
            _validated(RecognitionModelOutput),
        )
    if config.capability is Capability.LANGUAGE:
        adapter: LanguageProvider = (
            GeminiProvider(config)
            if config.provider is ProviderName.GEMINI
            else GroqProvider(config)
        )
        prompt = prompts.active("tweak.advice").render(TWEAK_PAYLOAD, "id")
        return await _timed(
            lambda options: adapter.complete(prompt, options), _validated(TweakModelOutput)
        )
    if config.capability is Capability.SPEECH_TO_TEXT:
        groq = GroqProvider(config)
        prompt = prompts.active("speech.transcribe").render({}, "id")
        audio = AudioInput(data=synthetic_wav(), mime_type="audio/wav")
        return await _timed(lambda options: groq.transcribe(audio, prompt, options), _transcribed)
    raise ConfigError("no smoke test for this capability")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("--env-file", type=Path, default=SERVICE_ROOT / ".env")
    args = parser.parse_args(argv)

    file_values = read_env_file(args.env_file)
    env = {k: v for k, v in file_values.items() if k.startswith(SLOT_PREFIXES)}
    env.update({k: v for k, v in os.environ.items() if k.startswith(SLOT_PREFIXES)})
    env.update({"AI_ENV": "local", "AI_SERVICE_AUTH_TOKEN": DUMMY_SERVICE_TOKEN})
    try:
        settings = load_settings(env)
    except ConfigError as exc:
        # Config errors name the variable, never its value.
        print(f"FAIL configuration: {exc}")
        return 1
    prompts = PromptRegistry.load()

    slots = [
        config
        for chain in settings.providers.values()
        for config in chain
        if config.provider in REMOTE_PROVIDERS
    ]
    if not slots:
        print("No Gemini or Groq slot configured; nothing to test.")
        return 2
    print("Sending one synthetic request per slot to Google and Groq (no personal data).")
    failures = 0
    for config in slots:
        label = f"{config.slot:<16} {config.provider.value:<7}"
        try:
            model_id, latency = asyncio.run(smoke(config, prompts))
        except Exception as exc:
            failures += 1
            print(f"FAIL {label} model={config.model_id} error={type(exc).__name__}")
            continue
        print(f"PASS {label} model={model_id} latency={latency:.0f}ms")
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
