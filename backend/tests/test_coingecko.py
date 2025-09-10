from fastapi.testclient import TestClient


def test_coingecko_coin_success(monkeypatch, client: TestClient):
    from app.clients import coingecko as cg

    async def fake_get_coin(coin_id: str):
        return {"provider": "CoinGecko", "id": "bitcoin", "symbol": "btc", "name": "Bitcoin", "price_usd": 123.45}

    monkeypatch.setattr(cg, "get_coin", fake_get_coin)

    r = client.get("/api/data/coingecko/coin/bitcoin")
    assert r.status_code == 200
    j = r.json()
    assert j["id"] == "bitcoin"
    assert j["provider"] == "CoinGecko"


def test_coingecko_coin_not_found(monkeypatch, client: TestClient):
    import httpx
    from app.clients import coingecko as cg

    async def fake_get_coin(coin_id: str):
        # simulate HTTPStatusError with response 404
        resp = httpx.Response(404, request=httpx.Request("GET", "http://test"))
        raise httpx.HTTPStatusError("not found", request=resp.request, response=resp)

    monkeypatch.setattr(cg, "get_coin", fake_get_coin)

    r = client.get("/api/data/coingecko/coin/nope")
    assert r.status_code == 404
    assert r.json()["status"] == "error"


def test_coingecko_coin_upstream_error(monkeypatch, client: TestClient):
    import httpx
    from app.clients import coingecko as cg

    async def fake_get_coin(coin_id: str):
        resp = httpx.Response(500, request=httpx.Request("GET", "http://test"))
        raise httpx.HTTPStatusError("boom", request=resp.request, response=resp)

    monkeypatch.setattr(cg, "get_coin", fake_get_coin)

    r = client.get("/api/data/coingecko/coin/eth")
    assert r.status_code == 502

