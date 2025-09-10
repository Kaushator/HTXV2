from fastapi.testclient import TestClient


def test_htx_ratelimit_in_memory(monkeypatch, client: TestClient):
    # Force in-memory limiter by unsetting redis_url in settings
    from app import config as cfg

    monkeypatch.setattr(cfg.settings, "redis_url", None, raising=False)
    # Patch HTX client to be fast
    from app.clients import htx as htx_client

    async def fake_get_ticker(symbol: str):
        return {"provider": "HTX", "pair": "btcusdt", "price": 1.0}

    monkeypatch.setattr(htx_client, "get_ticker", fake_get_ticker)

    # hit a few times under limit
    for _ in range(3):
        r = client.get("/api/data/htx/ticker/BTC")
        assert r.status_code == 200

    # simulate small limit by patching settings
    monkeypatch.setattr(cfg.settings, "htx_rate_limit_max", 2, raising=False)
    monkeypatch.setattr(cfg.settings, "htx_rate_limit_window", 60, raising=False)

    # Two allowed on same scope
    client.get("/api/data/htx/ticker/BTC")
    client.get("/api/data/htx/ticker/BTC")
    # Third should be 429
    r = client.get("/api/data/htx/ticker/BTC")
    assert r.status_code == 429


def test_htx_ratelimit_api_key_scoping(monkeypatch, client: TestClient):
    from app import config as cfg

    monkeypatch.setattr(cfg.settings, "redis_url", None, raising=False)
    monkeypatch.setattr(cfg.settings, "htx_rate_limit_max", 1, raising=False)
    monkeypatch.setattr(cfg.settings, "htx_rate_limit_window", 60, raising=False)

    from app.clients import htx as htx_client

    async def fake_get_ticker(symbol: str):
        return {"provider": "HTX", "pair": "btcusdt", "price": 1.0}

    monkeypatch.setattr(htx_client, "get_ticker", fake_get_ticker)

    # First request with key A allowed
    r1 = client.get("/api/data/htx/ticker/BTC?api_key=A")
    assert r1.status_code == 200
    # Second with same key A should be rate-limited
    r2 = client.get("/api/data/htx/ticker/BTC?api_key=A")
    assert r2.status_code == 429
    # But with different key B allowed again (separate bucket)
    r3 = client.get("/api/data/htx/ticker/BTC?api_key=B")
    assert r3.status_code == 200
