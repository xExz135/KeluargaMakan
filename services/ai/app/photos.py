"""Fetch photos by short-lived URL into memory (REC-07, SET-05, AI-03).

Photos are held in memory for one request only: they are never written to disk
or logs, and the service keeps no reference after the response. URLs must be
HTTPS on a configured host, so the service cannot be pointed elsewhere.

No network fetcher exists yet (T-037 adds it with T-035's bucket). Until then
`DisabledPhotoSource` makes recognition answer "AI unavailable", and tests and
local development use the in-memory sources.
"""

from __future__ import annotations

from collections.abc import Mapping
from dataclasses import dataclass, field
from typing import Protocol
from urllib.parse import urlsplit

from app.providers.base import ProviderUnavailableError

# 1x1 JPEG with no metadata, for local development with the mock provider.
_TINY_JPEG = bytes.fromhex(
    "ffd8ffe000104a46494600010100000100010000ffdb004300080606070605080707070909080a0c140d0c0b0b0c"
    "1912130f141d1a1f1e1d1a1c1c20242e2720222c231c1c2837292c30313434341f27393d38323c2e333432ffc000"
    "0b080001000101011100ffc4001f0000010501010101010100000000000000000102030405060708090a0bffc400"
    "b5100002010303020403050504040000017d01020300041105122131410613516107227114328191a1082342b1c1"
    "1552d1f02433627282090a161718191a25262728292a3435363738393a434445464748494a535455565758595a63"
    "6465666768696a737475767778797a838485868788898a92939495969798999aa2a3a4a5a6a7a8a9aab2b3b4b5b6"
    "b7b8b9bac2c3c4c5c6c7c8c9cad2d3d4d5d6d7d8d9dae1e2e3e4e5e6e7e8e9eaf1f2f3f4f5f6f7f8f9faffda0008"
    "010100003f00fbd3ffd9"
)


class PhotoUrlError(ValueError):
    """The URL is not HTTPS on an allowed host."""


class PhotoTooLargeError(ValueError):
    pass


def check_photo_url(url: str, allowed_hosts: frozenset[str]) -> None:
    parts = urlsplit(url)
    if parts.scheme != "https" or not parts.hostname:
        raise PhotoUrlError("photo URLs must be HTTPS")
    if parts.username or parts.password:
        raise PhotoUrlError("photo URLs must not carry credentials")
    if parts.hostname.lower() not in allowed_hosts:
        raise PhotoUrlError("photo host is not allowed")


class PhotoSource(Protocol):
    async def fetch(self, url: str, max_bytes: int) -> bytes: ...


class DisabledPhotoSource:
    async def fetch(self, url: str, max_bytes: int) -> bytes:
        raise ProviderUnavailableError("photo fetching is not configured")


@dataclass
class InMemoryPhotoSource:
    """Serves bytes from a mapping (tests) or one tiny JPEG for any URL (local)."""

    photos: Mapping[str, bytes] = field(default_factory=dict)
    default: bytes | None = None

    async def fetch(self, url: str, max_bytes: int) -> bytes:
        data = self.photos.get(url, self.default)
        if data is None:
            raise ProviderUnavailableError("photo not found")
        if len(data) > max_bytes:
            raise PhotoTooLargeError("photo is too large")
        return data


def local_photo_source() -> InMemoryPhotoSource:
    return InMemoryPhotoSource(default=_TINY_JPEG)
