"""Versioned prompt registry (AI-11).

Templates live in services/ai/prompts/<prompt id>/<version>.json, and
services/ai/prompts/registry.json lists every version with the SHA-256 of its
canonical JSON and which version is active. At startup the registry refuses to
load if a template changed without its registry entry changing too, so every
change to a prompt is a visible, reviewable version change. Changes under
services/ai/prompts/ also trigger the AI eval CI stage (AI-10).

Every call logs the prompt ID, version and template hash with the model ID.
"""

from __future__ import annotations

import hashlib
import json
import re
from collections.abc import Mapping
from dataclasses import dataclass
from pathlib import Path
from string import Template

from app.config import Capability, ConfigError
from app.providers.base import RenderedPrompt

DEFAULT_PROMPTS_DIR = Path(__file__).resolve().parent.parent / "prompts"
ALLOWED_PLACEHOLDERS = frozenset({"payload", "language"})
LANGUAGE_NAMES = {"id": "Bahasa Indonesia", "en": "English"}

_VERSION_RE = re.compile(r"^\d+\.\d+\.\d+$")
_ID_RE = re.compile(r"^[a-z]+(?:\.[a-z]+)+$")


@dataclass(frozen=True)
class PromptTemplate:
    prompt_id: str
    version: str
    capability: Capability
    requirement_ids: tuple[str, ...]
    system: Template
    user: Template
    sha256: str

    def render(self, payload: Mapping[str, object], language: str) -> RenderedPrompt:
        if language not in LANGUAGE_NAMES:
            raise ValueError("unsupported language")
        values = {
            "payload": json.dumps(payload, ensure_ascii=False, sort_keys=True),
            "language": LANGUAGE_NAMES[language],
        }
        return RenderedPrompt(
            prompt_id=self.prompt_id,
            version=self.version,
            template_sha256=self.sha256,
            capability=self.capability,
            system=self.system.substitute(values),
            user=self.user.substitute(values),
            payload=payload,
        )


def canonical_sha256(document: object) -> str:
    """Hash of the template's canonical JSON, so line endings and spacing don't matter."""
    canonical = json.dumps(document, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
    return hashlib.sha256(canonical.encode("utf-8")).hexdigest()


class PromptRegistry:
    def __init__(
        self, templates: Mapping[tuple[str, str], PromptTemplate], active: Mapping[str, str]
    ):
        self._templates = dict(templates)
        self._active = dict(active)

    @property
    def active_versions(self) -> dict[str, str]:
        return dict(self._active)

    def all_templates(self) -> list[PromptTemplate]:
        return list(self._templates.values())

    def active(self, prompt_id: str) -> PromptTemplate:
        try:
            return self._templates[(prompt_id, self._active[prompt_id])]
        except KeyError:
            raise ConfigError(f"no active prompt {prompt_id!r}") from None

    @classmethod
    def load(cls, directory: Path | None = None) -> PromptRegistry:
        root = directory or DEFAULT_PROMPTS_DIR
        registry_path = root / "registry.json"
        try:
            index = json.loads(registry_path.read_text(encoding="utf-8"))
        except (OSError, ValueError) as exc:
            raise ConfigError(f"cannot read prompt registry: {registry_path}") from exc

        templates: dict[tuple[str, str], PromptTemplate] = {}
        active: dict[str, str] = {}
        for entry in index.get("prompts", []):
            template = _load_entry(root, entry)
            key = (template.prompt_id, template.version)
            if key in templates:
                raise ConfigError(f"duplicate prompt version {key}")
            templates[key] = template
            if entry.get("active") is True:
                if template.prompt_id in active:
                    raise ConfigError(f"more than one active version of {template.prompt_id!r}")
                active[template.prompt_id] = template.version

        listed = {root / f"{pid}/{version}.json" for pid, version in templates}
        unlisted = {path for path in root.glob("*/*.json")} - listed
        if unlisted:
            names = ", ".join(sorted(p.relative_to(root).as_posix() for p in unlisted))
            raise ConfigError(f"prompt templates missing from registry.json: {names}")
        missing_active = {pid for pid, _ in templates} - set(active)
        if missing_active:
            raise ConfigError(f"no active version for: {', '.join(sorted(missing_active))}")
        return cls(templates, active)


def _load_entry(root: Path, entry: Mapping[str, object]) -> PromptTemplate:
    prompt_id = entry.get("id")
    version = entry.get("version")
    expected_hash = entry.get("sha256")
    if not (isinstance(prompt_id, str) and _ID_RE.match(prompt_id)):
        raise ConfigError(f"invalid prompt id: {prompt_id!r}")
    if not (isinstance(version, str) and _VERSION_RE.match(version)):
        raise ConfigError(f"{prompt_id}: version must be semantic (x.y.z)")
    path = root / prompt_id / f"{version}.json"
    try:
        document = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError) as exc:
        raise ConfigError(f"cannot read prompt template {prompt_id}@{version}") from exc

    actual_hash = canonical_sha256(document)
    if actual_hash != expected_hash:
        raise ConfigError(
            f"{prompt_id}@{version} changed without a registry update; add a new version "
            f"(sha256 {actual_hash})"
        )
    if document.get("id") != prompt_id or document.get("version") != version:
        raise ConfigError(f"{prompt_id}@{version}: id or version inside the file does not match")
    try:
        capability = Capability(document["capability"])
        system = document["system"]
        user = document["user"]
        requirement_ids = tuple(document.get("requirementIds", ()))
    except (KeyError, ValueError) as exc:
        raise ConfigError(f"{prompt_id}@{version}: malformed template") from exc
    if not isinstance(system, str) or not isinstance(user, str):
        raise ConfigError(f"{prompt_id}@{version}: system and user must be text")
    system_template, user_template = Template(system), Template(user)
    for part in (system_template, user_template):
        if not part.is_valid():
            raise ConfigError(f"{prompt_id}@{version}: invalid placeholder")
        unknown = set(part.get_identifiers()) - ALLOWED_PLACEHOLDERS
        if unknown:
            raise ConfigError(f"{prompt_id}@{version}: unknown placeholders {sorted(unknown)}")
    return PromptTemplate(
        prompt_id=prompt_id,
        version=version,
        capability=capability,
        requirement_ids=requirement_ids,
        system=system_template,
        user=user_template,
        sha256=actual_hash,
    )
