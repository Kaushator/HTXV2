from fastapi.testclient import TestClient


def test_ws_ticker_basic(monkeypatch, client: TestClient):
    # Patch HTX client to avoid real HTTP
    from app.clients import htx as htx_client

    async def fake_get_ticker(symbol: str, ttl_override=None):
        return {"provider": "HTX", "pair": "btcusdt", "price": 1.0}

    monkeypatch.setattr(htx_client, "get_ticker", fake_get_ticker)

    with client.websocket_connect("/ws/ticker?symbols=BTC,ETH&interval_ms=200") as ws:
        data = ws.receive_json()
        assert data["type"] == "ticker_batch"
        assert "BTC" in data["data"]
        assert "ETH" in data["data"]

