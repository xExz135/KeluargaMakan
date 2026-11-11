"""REC-07, SET-05, AI-03: photo metadata is stripped and photos never touch disk or logs."""

from __future__ import annotations

import builtins
import hashlib
import logging
import os
import struct
import tempfile
import zlib
from typing import Any

import pytest

from app.privacy.photo_metadata import UnsupportedPhotoError, strip_metadata
from tests.support import AUTH, EXIF_JPEG, PHOTO_HOST, harness, recognize_body


def _png_chunk(kind: bytes, data: bytes) -> bytes:
    return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data))


PNG = (
    b"\x89PNG\r\n\x1a\n"
    + _png_chunk(b"IHDR", struct.pack(">IIBBBBB", 1, 1, 8, 2, 0, 0, 0))
    + _png_chunk(b"eXIf", b"GPS-6.2000,106.8166")
    + _png_chunk(b"tEXt", b"Author\x00Siti")
    + _png_chunk(b"IDAT", zlib.compress(b"\x00\x00\x00\x00"))
    + _png_chunk(b"IEND", b"")
)


def _webp_chunk(kind: bytes, data: bytes) -> bytes:
    return kind + struct.pack("<I", len(data)) + data + (b"\x00" if len(data) % 2 else b"")


_WEBP_BODY = (
    _webp_chunk(b"VP8X", bytes([0x0C, 0, 0, 0, 0, 0, 0, 0, 0, 0]))
    + _webp_chunk(b"VP8L", b"\x2f\x00\x00\x00\x00")
    + _webp_chunk(b"EXIF", b"GPS-6.2000,106.8166")
    + _webp_chunk(b"XMP ", b"<x>Siti</x>")
)
WEBP = b"RIFF" + struct.pack("<I", 4 + len(_WEBP_BODY)) + b"WEBP" + _WEBP_BODY


@pytest.mark.parametrize(
    ("photo", "mime"), [(EXIF_JPEG, "image/jpeg"), (PNG, "image/png"), (WEBP, "image/webp")]
)
def test_ai03_metadata_is_stripped(photo: bytes, mime: str) -> None:
    clean, detected = strip_metadata(photo)
    assert detected == mime
    for marker in (b"GPS", b"Exif", b"CAMERA", b"Siti", b"eXIf", b"tEXt", b"XMP "):
        assert marker not in clean
    assert len(clean) < len(photo)


def test_ai03_jpeg_image_data_is_kept() -> None:
    clean, _ = strip_metadata(EXIF_JPEG)
    assert clean.startswith(b"\xff\xd8\xff\xe0")
    assert b"\xff\xdb" in clean
    assert clean.endswith(b"\x12\x34\x56\xff\xd9")


def test_ai03_webp_metadata_flags_are_cleared() -> None:
    clean, _ = strip_metadata(WEBP)
    assert clean[12:16] == b"VP8X"
    assert clean[20] & 0x0C == 0
    assert struct.unpack("<I", clean[4:8])[0] == len(clean) - 8


@pytest.mark.parametrize(
    "data", [b"GIF89a....", b"\xff\xd8\xff\xe1\x00", b"", b"\x89PNG\r\n\x1a\n"]
)
def test_ai03_unknown_or_malformed_photos_are_refused(data: bytes) -> None:
    with pytest.raises(UnsupportedPhotoError):
        strip_metadata(data)


def test_ai03_provider_receives_only_the_stripped_photo() -> None:
    h = harness()
    response = h.client.post("/recognize/ingredients", json=recognize_body(), headers=AUTH)
    assert response.status_code == 200
    (call,) = h.mock.calls
    stripped, _ = strip_metadata(EXIF_JPEG)
    assert call.media_sha256 == (hashlib.sha256(stripped).hexdigest(),)


def test_ai03_unsupported_photo_is_refused_before_any_provider_call() -> None:
    url = f"https://{PHOTO_HOST}/upload/p0.jpg"
    h = harness(photos={url: b"GIF89a not a photo we can clean"})
    response = h.client.post("/recognize/ingredients", json=recognize_body(), headers=AUTH)
    assert response.status_code == 415
    assert not h.mock.calls


@pytest.mark.parametrize(
    "url",
    [
        "http://photos.example.test/p.jpg",
        "https://elsewhere.example.test/p.jpg",
        "https://user:pw@photos.example.test/p.jpg",
        "file:///etc/passwd",
    ],
)
def test_photo_urls_must_be_https_on_an_allowed_host(url: str) -> None:
    h = harness()
    body = {**recognize_body(), "photos": [{"url": url}]}
    response = h.client.post("/recognize/ingredients", json=body, headers=AUTH)
    assert response.status_code == 422
    assert url not in response.text
    assert not h.mock.calls


def test_rec01_photo_count_limit_comes_from_config() -> None:
    h = harness(MAX_PHOTOS_PER_REQUEST="2")
    ok = h.client.post("/recognize/ingredients", json=recognize_body(photos=2), headers=AUTH)
    too_many = h.client.post("/recognize/ingredients", json=recognize_body(photos=3), headers=AUTH)
    assert ok.status_code == 200
    assert too_many.status_code == 422


def test_photo_size_limit_comes_from_config() -> None:
    h = harness(MAX_PHOTO_BYTES="16")
    response = h.client.post("/recognize/ingredients", json=recognize_body(), headers=AUTH)
    assert response.status_code == 413


def test_rec07_recognition_writes_nothing_to_disk_or_logs(
    monkeypatch: pytest.MonkeyPatch, caplog: pytest.LogCaptureFixture
) -> None:
    h = harness()
    real_open = builtins.open

    def no_write_open(file: Any, mode: str = "r", *args: Any, **kwargs: Any) -> Any:
        if any(flag in mode for flag in "wax+"):
            raise AssertionError(f"file opened for writing: {file}")
        return real_open(file, mode, *args, **kwargs)

    def forbidden(*args: Any, **kwargs: Any) -> Any:
        raise AssertionError("temporary file created")

    monkeypatch.setattr(builtins, "open", no_write_open)
    for name in ("TemporaryFile", "NamedTemporaryFile", "SpooledTemporaryFile", "mkstemp"):
        monkeypatch.setattr(tempfile, name, forbidden)
    real_os_open = os.open

    def no_write_os_open(path: Any, flags: int, *args: Any, **kwargs: Any) -> int:
        if flags & (os.O_WRONLY | os.O_RDWR | os.O_CREAT):
            raise AssertionError(f"os.open for writing: {path}")
        return real_os_open(path, flags, *args, **kwargs)

    monkeypatch.setattr(os, "open", no_write_os_open)
    with caplog.at_level(logging.DEBUG):
        response = h.client.post("/recognize/ingredients", json=recognize_body(), headers=AUTH)
    assert response.status_code == 200
    logged = "\n".join(r.getMessage() + str(getattr(r, "fields", "")) for r in caplog.records)
    assert "GPS" not in logged
    assert "p0.jpg" not in logged
