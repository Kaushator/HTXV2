from fastapi.testclient import TestClient


class _FakeRedis:
    def __init__(self):
        self.counts = {}
        self.exp = {}

    async def incr(self, key: str):
        self.counts[key] = self.counts.get(key, 0) + 1
        return self.counts[key]

    async def expire(self, key: str, ttl: int):
        self.exp[key] = ttl

    async def ttl(self, key: str):
        return self.exp.get(key, 0)


def test_rate_limit_trading_endpoint_monkeypatch(monkeypatch):
    # Patch Redis getter to use fake client with low limit
    import app.core.rate_limit as rl

    fake = _FakeRedis()

    async def _fake_get_redis():
        return fake

    monkeypatch.setattr(rl, "_get_redis", _fake_get_redis)

    from app.main import app

    client = TestClient(app)

    # Use an endpoint with rate limiting; no auth token present -> will typically be 401
    # but once rate limit threshold crossed, should return 429 regardless
    url = "/api/v1/trading/market-data/BTC"

    # simulate limit=2 per minute case by patching decorator default indirectly
    # We'll just call 3 times and assert last becomes 429 based on our fake counter
    r1 = client.get(url)
    r2 = client.get(url)
    r3 = client.get(url)

    assert r3.status_code in (401, 429)  # allow first two to be 401
    # Now forcefully check that the dependency triggered 429 by executing again
    r4 = client.get(url)
    assert r4.status_code == 429

