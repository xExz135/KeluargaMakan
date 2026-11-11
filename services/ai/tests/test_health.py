from tests.support import harness


def test_health_returns_ok_without_auth() -> None:
    response = harness().client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}
