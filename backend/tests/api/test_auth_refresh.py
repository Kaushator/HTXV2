import json
from fastapi.testclient import TestClient

from app.core.security import create_refresh_token
from app.main import app


def test_refresh_token_invalid_returns_401(client: TestClient):
    response = client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": "not-a-valid-token"},
    )
    assert response.status_code == 401


def test_refresh_token_success_with_mock_user(monkeypatch):
    test_client = TestClient(app)

    class FakeUser:
        id = 1
        is_active = True

    class FakeUserService:
        def __init__(self, *args, **kwargs):
            pass

        async def get_user(self, user_id: int):
            return FakeUser()

    # Patch UserService used inside endpoint implementation
    import app.api.api_v1.endpoints.auth as auth_module

    monkeypatch.setattr(auth_module, "UserService", FakeUserService)

    token = create_refresh_token({"sub": "1"})
    resp = test_client.post("/api/v1/auth/refresh", json={"refresh_token": token})
    assert resp.status_code == 200
    data = resp.json()
    assert "access_token" in data and data["access_token"]
    assert "refresh_token" in data and data["refresh_token"]
    assert data["token_type"] == "bearer"

