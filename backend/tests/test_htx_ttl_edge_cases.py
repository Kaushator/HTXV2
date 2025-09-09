"""
Enhanced tests for HTX ticker TTL override edge cases.

Tests cover:
- TTL boundary values (0, max, >max)
- Invalid TTL inputs
- Cache behavior with TTL overrides  
- Redis fallback scenarios
"""
import json
import pytest
from unittest.mock import AsyncMock, patch
from fastapi.testclient import TestClient


class TestHTXTickerTTLEdgeCases:
    """Test TTL override edge cases for HTX ticker endpoint."""

    @pytest.fixture
    def mock_htx_response(self):
        """Standard mock response for HTX API."""
        return {
            "status": "ok",
            "tick": {
                "close": 60000.0,
                "bid": [59990.0, 1.5],
                "ask": [60010.0, 2.0],
                "high": 61000.0,
                "low": 59000.0,
                "amount": 1234.56,
            },
            "ts": 1700000000000
        }

    @pytest.fixture
    def mock_htx_client(self, monkeypatch, mock_htx_response):
        """Mock HTX client to return predictable data."""
        async def fake_fetch_ticker_http(pair: str):
            return mock_htx_response

        from app.clients import htx as htx_client
        monkeypatch.setattr(htx_client, "_fetch_ticker_http", fake_fetch_ticker_http)
        return htx_client

    def test_ttl_override_zero_boundary(self, monkeypatch, client: TestClient, mock_htx_client):
        """Test TTL=0 should be converted to minimum TTL=1."""
        from app import config as cfg
        
        # Mock settings
        monkeypatch.setattr(cfg.settings, "redis_url", None)
        monkeypatch.setattr(cfg.settings, "htx_ticker_ttl", 5)
        monkeypatch.setattr(cfg.settings, "htx_ticker_ttl_max", 300)

        # TTL=0 should be treated as TTL=1 (minimum)
        response = client.get("/api/data/htx/ticker/BTC?ttl=0")
        assert response.status_code == 200
        
        data = response.json()
        assert data["provider"] == "HTX"
        assert data["pair"] == "btcusdt"

    def test_ttl_override_max_boundary(self, monkeypatch, client: TestClient, mock_htx_client):
        """Test TTL=max should be accepted."""
        from app import config as cfg
        
        monkeypatch.setattr(cfg.settings, "redis_url", None)
        monkeypatch.setattr(cfg.settings, "htx_ticker_ttl", 5)
        monkeypatch.setattr(cfg.settings, "htx_ticker_ttl_max", 300)

        # TTL=300 (max) should be accepted
        response = client.get("/api/data/htx/ticker/BTC?ttl=300")
        assert response.status_code == 200
        
        data = response.json()
        assert data["provider"] == "HTX"

    def test_ttl_override_above_max_boundary(self, monkeypatch, client: TestClient, mock_htx_client):
        """Test TTL>max should be clamped to max."""
        from app import config as cfg
        
        monkeypatch.setattr(cfg.settings, "redis_url", None)
        monkeypatch.setattr(cfg.settings, "htx_ticker_ttl", 5)
        monkeypatch.setattr(cfg.settings, "htx_ticker_ttl_max", 300)

        # TTL=999 (>max) should be clamped to 300
        response = client.get("/api/data/htx/ticker/BTC?ttl=999")
        assert response.status_code == 200
        
        data = response.json()
        assert data["provider"] == "HTX"

    def test_ttl_override_negative_value(self, monkeypatch, client: TestClient, mock_htx_client):
        """Test negative TTL should fall back to default."""
        from app import config as cfg
        
        monkeypatch.setattr(cfg.settings, "redis_url", None)
        monkeypatch.setattr(cfg.settings, "htx_ticker_ttl", 5)
        monkeypatch.setattr(cfg.settings, "htx_ticker_ttl_max", 300)

        # TTL=-5 should use default TTL
        response = client.get("/api/data/htx/ticker/BTC?ttl=-5")
        assert response.status_code == 200

    def test_ttl_override_invalid_string(self, monkeypatch, client: TestClient, mock_htx_client):
        """Test invalid TTL string should fall back to default."""
        from app import config as cfg
        
        monkeypatch.setattr(cfg.settings, "redis_url", None)
        monkeypatch.setattr(cfg.settings, "htx_ticker_ttl", 5)

        # TTL="invalid" should use default TTL
        response = client.get("/api/data/htx/ticker/BTC?ttl=invalid")
        assert response.status_code == 200

    def test_ttl_override_float_value(self, monkeypatch, client: TestClient, mock_htx_client):
        """Test float TTL should be converted to int."""
        from app import config as cfg
        
        monkeypatch.setattr(cfg.settings, "redis_url", None)
        monkeypatch.setattr(cfg.settings, "htx_ticker_ttl", 5)
        monkeypatch.setattr(cfg.settings, "htx_ticker_ttl_max", 300)

        # TTL=10.7 should be converted to 10
        response = client.get("/api/data/htx/ticker/BTC?ttl=10.7")
        assert response.status_code == 200

    @patch('app.clients.htx.aioredis.from_url')
    def test_ttl_override_with_redis_cache_miss(self, mock_redis, monkeypatch, client: TestClient, mock_htx_client):
        """Test TTL override with Redis cache miss."""
        from app import config as cfg
        
        # Mock Redis to return None (cache miss)
        mock_redis_instance = AsyncMock()
        mock_redis_instance.get.return_value = None
        mock_redis_instance.set.return_value = True
        mock_redis.return_value = mock_redis_instance
        
        monkeypatch.setattr(cfg.settings, "redis_url", "redis://localhost:6379")
        monkeypatch.setattr(cfg.settings, "htx_ticker_ttl", 5)
        monkeypatch.setattr(cfg.settings, "htx_ticker_ttl_max", 300)

        response = client.get("/api/data/htx/ticker/BTC?ttl=10")
        assert response.status_code == 200
        
        # Verify Redis was called with correct TTL
        mock_redis_instance.set.assert_called_once()
        call_args = mock_redis_instance.set.call_args
        assert "htx:ticker:btcusdt" in call_args[0]
        assert call_args[1]["ex"] == 10  # TTL override should be used

    @patch('app.clients.htx.aioredis.from_url')
    def test_ttl_override_with_redis_cache_hit(self, mock_redis, monkeypatch, client: TestClient):
        """Test TTL override with Redis cache hit."""
        from app import config as cfg
        
        # Mock cached response
        cached_data = {
            "provider": "HTX",
            "pair": "btcusdt", 
            "price": 58000.0,
            "cached": True
        }
        
        mock_redis_instance = AsyncMock()
        mock_redis_instance.get.return_value = json.dumps(cached_data)
        mock_redis.return_value = mock_redis_instance
        
        monkeypatch.setattr(cfg.settings, "redis_url", "redis://localhost:6379")

        response = client.get("/api/data/htx/ticker/BTC?ttl=10")
        assert response.status_code == 200
        
        data = response.json()
        assert data["cached"] is True  # Should return cached data
        assert data["price"] == 58000.0

    @patch('app.clients.htx.aioredis.from_url')
    def test_ttl_override_redis_connection_error(self, mock_redis, monkeypatch, client: TestClient, mock_htx_client):
        """Test TTL override when Redis connection fails."""
        from app import config as cfg
        
        # Mock Redis to raise connection error
        mock_redis.side_effect = Exception("Redis connection failed")
        
        monkeypatch.setattr(cfg.settings, "redis_url", "redis://localhost:6379")
        monkeypatch.setattr(cfg.settings, "htx_ticker_ttl", 5)

        # Should still work without Redis
        response = client.get("/api/data/htx/ticker/BTC?ttl=10")
        assert response.status_code == 200
        
        data = response.json()
        assert data["provider"] == "HTX"

    def test_ttl_override_extreme_values(self, monkeypatch, client: TestClient, mock_htx_client):
        """Test extreme TTL values."""
        from app import config as cfg
        
        monkeypatch.setattr(cfg.settings, "redis_url", None)
        monkeypatch.setattr(cfg.settings, "htx_ticker_ttl", 5)
        monkeypatch.setattr(cfg.settings, "htx_ticker_ttl_max", 300)

        # Test very large number
        response = client.get("/api/data/htx/ticker/BTC?ttl=999999999")
        assert response.status_code == 200

        # Test scientific notation  
        response = client.get("/api/data/htx/ticker/BTC?ttl=1e3")
        assert response.status_code == 200

    def test_ttl_override_multiple_parameters(self, monkeypatch, client: TestClient, mock_htx_client):
        """Test TTL override with other query parameters."""
        from app import config as cfg
        
        monkeypatch.setattr(cfg.settings, "redis_url", None)
        monkeypatch.setattr(cfg.settings, "htx_ticker_ttl", 5)

        # TTL with api_key parameter
        response = client.get("/api/data/htx/ticker/BTC?ttl=15&api_key=test123")
        assert response.status_code == 200
        
        data = response.json()
        assert data["provider"] == "HTX"

    def test_different_symbols_same_ttl_override(self, monkeypatch, client: TestClient, mock_htx_client):
        """Test TTL override works for different symbols."""
        from app import config as cfg
        
        monkeypatch.setattr(cfg.settings, "redis_url", None)
        monkeypatch.setattr(cfg.settings, "htx_ticker_ttl", 5)

        # Test BTC with TTL override
        response1 = client.get("/api/data/htx/ticker/BTC?ttl=20")
        assert response1.status_code == 200
        
        # Test ETH with same TTL override
        response2 = client.get("/api/data/htx/ticker/ETH?ttl=20")
        assert response2.status_code == 200
        
        # Both should work
        assert response1.json()["provider"] == "HTX"
        assert response2.json()["provider"] == "HTX"
