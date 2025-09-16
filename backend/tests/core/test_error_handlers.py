from fastapi.testclient import TestClient

from app.main import app


def test_validation_error_shape():
    client = TestClient(app)
    # Missing required payload (expects object with refresh_token for this route)
    resp = client.post("/api/v1/auth/refresh", json={})
    assert resp.status_code == 422
    data = resp.json()
    # Unified error fields
    assert set(["error", "message", "details", "request_id", "timestamp"]).issubset(
        data.keys()
    )
    assert data["error"] == "validation_error"
    assert isinstance(data["details"].get("errors", []), list)
