from fastapi.testclient import TestClient

from app.main import app


def test_healthz_returns_200_and_exact_body() -> None:
    response = TestClient(app).get("/healthz")

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}
    assert response.content == b'{"status":"ok"}'
