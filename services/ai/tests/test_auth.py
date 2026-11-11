"""Calls between the API and the AI service are authenticated (T-036)."""

from __future__ import annotations

from tests.support import AUTH, harness, tweak_body

PREVIOUS = "test-only-previous-token-111111111111111"


def test_missing_token_is_rejected_and_no_provider_call() -> None:
    h = harness()
    response = h.client.post("/tweak", json=tweak_body())
    assert response.status_code == 401
    assert response.json() == {"code": "unauthorized", "retryable": False}
    assert not h.mock.calls


def test_wrong_token_and_wrong_scheme_are_rejected() -> None:
    h = harness()
    for header in ("Bearer not-the-token", f"Basic {AUTH['Authorization'].split()[1]}"):
        response = h.client.post("/tweak", json=tweak_body(), headers={"Authorization": header})
        assert response.status_code == 401
    assert not h.mock.calls


def test_previous_token_is_accepted_during_rotation() -> None:
    h = harness(AI_SERVICE_AUTH_TOKEN_PREVIOUS=PREVIOUS)
    response = h.client.post(
        "/tweak", json=tweak_body(), headers={"Authorization": f"Bearer {PREVIOUS}"}
    )
    assert response.status_code == 200


def test_every_feature_route_requires_the_token() -> None:
    h = harness()
    paths = h.client.app.openapi()["paths"]  # type: ignore[attr-defined]
    feature_paths = [path for path, methods in paths.items() if "post" in methods]
    assert set(feature_paths) == {
        "/recognize/ingredients",
        "/adapt/recipe",
        "/tweak",
        "/speech/transcribe",
        "/speech/synthesize",
    }
    for path in feature_paths:
        assert h.client.post(path, json={}).status_code == 401
