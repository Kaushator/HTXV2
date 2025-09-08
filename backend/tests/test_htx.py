from fastapi.testclient import TestClient


def test_htx_ticker_endpoint(monkeypatch, client: TestClient):
    async def fake_get_ticker(symbol: str):
        return {
            "provider": "HTX",
            "pair": "btcusdt",
            "price": 60000.0,
            "bid": 59990.0,
            "ask": 60010.0,
            "high": 60500.0,
            "low": 59500.0,
            "volume": 1234.56,
            "timestamp": 1700000000000,
        }

    # Patch client function
    from app.clients import htx as htx_client

    monkeypatch.setattr(htx_client, "get_ticker", fake_get_ticker)

    r = client.get("/api/data/htx/ticker/BTC")
    assert r.status_code == 200
    data = r.json()
    assert data["provider"] == "HTX"
    assert data["pair"] == "btcusdt"
    assert "price" in data and isinstance(data["price"], (int, float))

