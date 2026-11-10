"""FastAPI entry point.

Scaffold only: no provider adapters and no outbound calls. The AI service never
returns a safety verdict; the API runs every AI output through Cek Aman.
"""

from fastapi import FastAPI

app = FastAPI(title="KeluargaMakan AI service", version="0.0.0")


@app.get("/health")
def health() -> dict[str, str]:
    """Liveness probe. Reports nothing about providers or user data."""
    return {"status": "ok"}
