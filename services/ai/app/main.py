"""FastAPI entry point.

Run with `uvicorn --factory app.main:create_app_from_env`. Settings come from the
environment (services/ai/.env.example); the service refuses to start on invalid
configuration.

The AI service never returns a safety verdict. Every output that names an
ingredient or recipe carries `ruleCheckRequired: true`, and the API runs it
through Cek Aman before anything reaches a user (AI-01, SAF-02).
"""

from __future__ import annotations

from pathlib import Path

from fastapi import Depends, FastAPI

from app.auth import require_internal_token
from app.config import PhotoSourceName, Settings, load_settings
from app.errors import install_error_handlers
from app.guards import InputGuard, KeywordInputGuard
from app.photos import DisabledPhotoSource, PhotoSource, local_photo_source
from app.pipeline import ServiceContext
from app.prompt_registry import PromptRegistry
from app.providers.base import Providers
from app.providers.registry import build_providers, check_training_controls
from app.routes import adapt, recognize, speech, tweak
from app.telemetry import LogUsageSink, UsageSink, configure_logging


def create_app(
    settings: Settings,
    *,
    providers: Providers | None = None,
    photo_source: PhotoSource | None = None,
    usage_sink: UsageSink | None = None,
    input_guard: InputGuard | None = None,
    prompts: PromptRegistry | None = None,
) -> FastAPI:
    if providers is None:
        providers = build_providers(settings)
    else:
        check_training_controls(providers)
    if photo_source is None:
        photo_source = (
            local_photo_source()
            if settings.photo_source is PhotoSourceName.MOCK
            else DisabledPhotoSource()
        )
    prompts_dir = Path(settings.prompts_dir) if settings.prompts_dir else None
    ctx = ServiceContext(
        settings=settings,
        providers=providers,
        prompts=prompts or PromptRegistry.load(prompts_dir),
        photo_source=photo_source,
        usage_sink=usage_sink or LogUsageSink(),
        input_guard=input_guard or KeywordInputGuard(),
    )

    # Interactive docs only where the mock may run; internal service elsewhere.
    docs = settings.environment.allows_mock
    app = FastAPI(
        title="KeluargaMakan AI service",
        version="0.1.0",
        docs_url="/docs" if docs else None,
        redoc_url=None,
        openapi_url="/openapi.json" if docs else None,
    )
    app.state.settings = settings
    app.state.ctx = ctx
    install_error_handlers(app)

    @app.get("/health")
    def health() -> dict[str, str]:
        """Liveness probe. Reports nothing about providers or user data."""
        return {"status": "ok"}

    protected = [Depends(require_internal_token)]
    for module in (recognize, adapt, tweak, speech):
        app.include_router(module.router, dependencies=protected)
    return app


def create_app_from_env() -> FastAPI:
    configure_logging()
    return create_app(load_settings())
