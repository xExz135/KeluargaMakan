"""Strip EXIF, GPS, XMP and text metadata from photos before a provider sees them.

The API strips metadata when the photo is uploaded (T-035). This is the second
line: the AI service removes it again from the in-memory bytes, and refuses any
format it cannot clean rather than passing it through (AI-03, fail closed).

Supported: JPEG, PNG and WebP. Works on bytes only; nothing touches the disk.
"""

from __future__ import annotations

import struct

JPEG_MIME = "image/jpeg"
PNG_MIME = "image/png"
WEBP_MIME = "image/webp"

_PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"
# Ancillary PNG chunks that can carry camera, location, time or free text.
_PNG_DROP = {b"eXIf", b"tEXt", b"zTXt", b"iTXt", b"tIME"}
# JPEG markers kept: APP0 (JFIF), APP2 (ICC colour profile), APP14 (Adobe colour
# transform). Every other APPn (APP1 is EXIF and XMP) and comments are removed.
_JPEG_KEEP_APP = {0xE0, 0xE2, 0xEE}
_WEBP_DROP = {b"EXIF", b"XMP "}


class UnsupportedPhotoError(ValueError):
    """The bytes are not a photo format we can clean, or are malformed."""


def detect_mime(data: bytes) -> str:
    if data.startswith(b"\xff\xd8\xff"):
        return JPEG_MIME
    if data.startswith(_PNG_SIGNATURE):
        return PNG_MIME
    if len(data) >= 12 and data[:4] == b"RIFF" and data[8:12] == b"WEBP":
        return WEBP_MIME
    raise UnsupportedPhotoError("unsupported photo format")


def strip_metadata(data: bytes) -> tuple[bytes, str]:
    """Return (clean bytes, MIME type)."""
    mime = detect_mime(data)
    try:
        if mime == JPEG_MIME:
            return _strip_jpeg(data), mime
        if mime == PNG_MIME:
            return _strip_png(data), mime
        return _strip_webp(data), mime
    except (IndexError, struct.error) as exc:
        raise UnsupportedPhotoError("malformed photo") from exc


def _strip_jpeg(data: bytes) -> bytes:
    out = bytearray(b"\xff\xd8")
    pos = 2
    while pos < len(data):
        if data[pos] != 0xFF:
            raise UnsupportedPhotoError("malformed JPEG")
        # Fill bytes: any number of 0xFF before a marker.
        while data[pos] == 0xFF:
            pos += 1
        marker = data[pos]
        pos += 1
        if marker == 0xD9:  # EOI
            out += b"\xff\xd9"
            return bytes(out)
        if marker == 0x01 or 0xD0 <= marker <= 0xD7:  # standalone markers
            out += bytes((0xFF, marker))
            continue
        (length,) = struct.unpack(">H", data[pos : pos + 2])
        if length < 2 or pos + length > len(data):
            raise UnsupportedPhotoError("malformed JPEG segment")
        segment = data[pos : pos + length]
        if marker == 0xDA:  # SOS: entropy-coded data follows, up to EOI
            out += bytes((0xFF, marker)) + data[pos:]
            return bytes(out)
        is_app = 0xE0 <= marker <= 0xEF
        if marker == 0xFE or (is_app and marker not in _JPEG_KEEP_APP):
            pos += length
            continue
        out += bytes((0xFF, marker)) + segment
        pos += length
    raise UnsupportedPhotoError("JPEG ended without image data")


def _strip_png(data: bytes) -> bytes:
    out = bytearray(_PNG_SIGNATURE)
    pos = len(_PNG_SIGNATURE)
    while pos < len(data):
        (length,) = struct.unpack(">I", data[pos : pos + 4])
        kind = data[pos + 4 : pos + 8]
        end = pos + 12 + length
        if len(kind) != 4 or end > len(data):
            raise UnsupportedPhotoError("malformed PNG chunk")
        if kind not in _PNG_DROP:
            out += data[pos:end]
        pos = end
        if kind == b"IEND":
            return bytes(out)
    raise UnsupportedPhotoError("PNG ended without IEND")


def _strip_webp(data: bytes) -> bytes:
    (riff_size,) = struct.unpack("<I", data[4:8])
    end = min(len(data), 8 + riff_size)
    chunks = bytearray()
    pos = 12
    while pos + 8 <= end:
        kind = data[pos : pos + 4]
        (size,) = struct.unpack("<I", data[pos + 4 : pos + 8])
        padded = size + (size & 1)
        if pos + 8 + size > end:
            raise UnsupportedPhotoError("malformed WebP chunk")
        chunk = bytearray(data[pos : pos + 8 + padded])
        if kind == b"VP8X" and size >= 1:
            # Clear the EXIF (0x08) and XMP (0x04) flags for the removed chunks.
            chunk[8] &= ~0x0C & 0xFF
        if kind not in _WEBP_DROP:
            chunks += chunk
        pos += 8 + padded
    return b"RIFF" + struct.pack("<I", 4 + len(chunks)) + b"WEBP" + bytes(chunks)
