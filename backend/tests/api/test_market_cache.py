from fastapi.testclient import TestClient


def test_market_data_uses_cache_when_available(monkeypatch):
    from app.main import app
    import app.api.api_v1.endpoints.trading as trading_module
    import app.core.cache as cache
    import app.core.security as sec

    client = TestClient(app)

    # mock auth to bypass DB
    def _fake_verify_token(token: str):
        return {"sub": "1", "type": "access"}

    class FakeUser:
        id = 1
        is_active = True

    class FakeUserService:
        def __init__(self, *args, **kwargs):
            pass

        async def get_user(self, user_id: int):
            return FakeUser()

    monkeypatch.setattr(sec, "verify_token", _fake_verify_token)
    monkeypatch.setattr(trading_module, "UserService", FakeUserService)

    cached = {
        "symbol": "BTC",
        "price": 123.45,
        "price_change_24h": 1.23,
        "volume_24h": 1000.0,
        "high_24h": 130.0,
        "low_24h": 120.0,
        "timestamp": "2025-01-01T00:00:00Z",
    }

    async def _fake_get_json(key: str):
        return cached

    async def _fake_set_json(key: str, value: dict, ttl_seconds: int):
        return None

    monkeypatch.setattr(cache, "get_json", _fake_get_json)
    monkeypatch.setattr(cache, "set_json", _fake_set_json)

    headers = {"Authorization": "Bearer token"}
    resp = client.get("/api/v1/trading/market-data/BTC", headers=headers)
    assert resp.status_code == 200
    data = resp.json()
    assert data["symbol"] == "BTC"
    assert data["price"] == 123.45


def test_market_data_sets_cache_when_missing(monkeypatch):
    from app.main import app
    import app.api.api_v1.endpoints.trading as trading_module
    import app.core.cache as cache
    import app.core.security as sec

    client = TestClient(app)

    def _fake_verify_token(token: str):
        return {"sub": "1", "type": "access"}

    class FakeUser:
        id = 1
        is_active = True

    class FakeUserService:
        def __init__(self, *args, **kwargs):
            pass

        async def get_user(self, user_id: int):
            return FakeUser()

    monkeypatch.setattr(sec, "verify_token", _fake_verify_token)
    monkeypatch.setattr(trading_module, "UserService", FakeUserService)

    calls = {"set": 0}

    async def _fake_get_json_none(key: str):
        return None

    async def _fake_set_json_record(key: str, value: dict, ttl_seconds: int):
        calls["set"] += 1
        # Ensure minimal expected structure present
        assert "symbol" in value and value["symbol"] == "BTC"

    monkeypatch.setattr(cache, "get_json", _fake_get_json_none)
    monkeypatch.setattr(cache, "set_json", _fake_set_json_record)

    headers = {"Authorization": "Bearer token"}
    resp = client.get("/api/v1/trading/market-data/BTC", headers=headers)
    assert resp.status_code == 200
    assert calls["set"] == 1

