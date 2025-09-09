"""
Tests for Redis fallback scenarios and in-memory behavior.

Tests cover:
- Behavior when Redis is unavailable
- Graceful degradation to in-memory storage
- Cache miss/hit scenarios
- Redis connection timeouts
- Invalid Redis URLs
"""
import json
import pytest
from unittest.mock import AsyncMock, patch, MagicMock
from fastapi.testclient import TestClient


class TestRedisFailoverScenarios:
    """Test Redis failover and in-memory fallback scenarios."""

    @pytest.fixture
    def mock_htx_response(self):
        """Standard HTX API response."""
        return {
            "status": "ok",
            "tick": {
                "close": 45000.0,
                "bid": [44990.0, 1.2],
                "ask": [45010.0, 0.8],
                "high": 46000.0,
                "low": 44000.0,
                "amount": 2345.67,
            },
            "ts": 1700000001000
        }

    @pytest.fixture  
    def mock_htx_client(self, monkeypatch, mock_htx_response):
        """Mock HTX client."""
        async def fake_fetch_ticker_http(pair: str):
            return mock_htx_response

        from app.clients import htx as htx_client
        monkeypatch.setattr(htx_client, "_fetch_ticker_http", fake_fetch_ticker_http)

    def test_redis_url_none_uses_memory_cache(self, monkeypatch, client: TestClient, mock_htx_client):
        """Test that redis_url=None forces in-memory caching."""
        from app import config as cfg
        
        monkeypatch.setattr(cfg.settings, "redis_url", None)
        monkeypatch.setattr(cfg.settings, "htx_ticker_ttl", 30)

        # First request should fetch from upstream
        response1 = client.get("/api/data/htx/ticker/BTC")
        assert response1.status_code == 200
        data1 = response1.json()
        assert data1["price"] == 45000.0

        # Since we're using in-memory and no caching mechanism in get_ticker
        # without Redis, second request will also fetch from upstream
        response2 = client.get("/api/data/htx/ticker/BTC")
        assert response2.status_code == 200
        data2 = response2.json()
        assert data2["price"] == 45000.0

    @patch('app.clients.htx.aioredis.from_url')
    def test_redis_import_error_fallback(self, mock_redis_from_url, monkeypatch, client: TestClient, mock_htx_client):
        """Test behavior when aioredis import fails."""
        from app import config as cfg
        
        # Mock Redis connection to raise import-like error
        mock_redis_from_url.side_effect = ImportError("No module named 'redis'")
        
        monkeypatch.setattr(cfg.settings, "redis_url", "redis://localhost:6379")

        response = client.get("/api/data/htx/ticker/BTC")
        assert response.status_code == 200
        
        data = response.json()
        assert data["provider"] == "HTX"
        assert data["price"] == 45000.0

    @patch('app.clients.htx.aioredis.from_url')
    def test_redis_connection_timeout(self, mock_redis_from_url, monkeypatch, client: TestClient, mock_htx_client):
        """Test Redis connection timeout scenario."""
        from app import config as cfg
        
        # Mock Redis to raise timeout error
        mock_redis_from_url.side_effect = TimeoutError("Redis connection timeout")
        
        monkeypatch.setattr(cfg.settings, "redis_url", "redis://localhost:6379")

        response = client.get("/api/data/htx/ticker/BTC")
        assert response.status_code == 200
        
        # Should still work by fetching from upstream
        data = response.json()
        assert data["provider"] == "HTX"

    @patch('app.clients.htx.aioredis.from_url')
    def test_redis_get_operation_fails(self, mock_redis_from_url, monkeypatch, client: TestClient, mock_htx_client):
        """Test when Redis GET operation fails but connection succeeds."""
        from app import config as cfg
        
        # Mock Redis instance where get() fails but connection works
        mock_redis_instance = AsyncMock()
        mock_redis_instance.get.side_effect = Exception("Redis GET failed")
        mock_redis_instance.set.return_value = True
        mock_redis_from_url.return_value = mock_redis_instance
        
        monkeypatch.setattr(cfg.settings, "redis_url", "redis://localhost:6379")

        response = client.get("/api/data/htx/ticker/BTC")
        assert response.status_code == 200
        
        # Should fetch from upstream and try to cache
        data = response.json()
        assert data["provider"] == "HTX"
        
        # Verify Redis operations were attempted
        mock_redis_instance.get.assert_called_once()

    @patch('app.clients.htx.aioredis.from_url')
    def test_redis_set_operation_fails(self, mock_redis_from_url, monkeypatch, client: TestClient, mock_htx_client):
        """Test when Redis SET operation fails after successful GET."""
        from app import config as cfg
        
        # Mock Redis instance where set() fails
        mock_redis_instance = AsyncMock()
        mock_redis_instance.get.return_value = None  # Cache miss
        mock_redis_instance.set.side_effect = Exception("Redis SET failed")
        mock_redis_from_url.return_value = mock_redis_instance
        
        monkeypatch.setattr(cfg.settings, "redis_url", "redis://localhost:6379")

        response = client.get("/api/data/htx/ticker/BTC")
        assert response.status_code == 200
        
        # Should still return data even if caching fails
        data = response.json()
        assert data["provider"] == "HTX"
        assert data["price"] == 45000.0

    @patch('app.clients.htx.aioredis.from_url')
    def test_redis_invalid_cached_json(self, mock_redis_from_url, monkeypatch, client: TestClient, mock_htx_client):
        """Test behavior with corrupted JSON in Redis cache."""
        from app import config as cfg
        
        # Mock Redis to return invalid JSON
        mock_redis_instance = AsyncMock()
        mock_redis_instance.get.return_value = "invalid json data {"
        mock_redis_from_url.return_value = mock_redis_instance
        
        monkeypatch.setattr(cfg.settings, "redis_url", "redis://localhost:6379")

        response = client.get("/api/data/htx/ticker/BTC")
        assert response.status_code == 200
        
        # Should fall back to upstream despite bad cache data
        data = response.json()
        assert data["provider"] == "HTX"

    @patch('app.clients.htx.aioredis.from_url')
    def test_redis_cache_hit_valid_data(self, mock_redis_from_url, monkeypatch, client: TestClient):
        """Test successful Redis cache hit with valid data."""
        from app import config as cfg
        
        cached_data = {
            "provider": "HTX",
            "pair": "btcusdt",
            "price": 50000.0,
            "cached": True,
            "timestamp": 1700000002000
        }
        
        mock_redis_instance = AsyncMock()
        mock_redis_instance.get.return_value = json.dumps(cached_data)
        mock_redis_from_url.return_value = mock_redis_instance
        
        monkeypatch.setattr(cfg.settings, "redis_url", "redis://localhost:6379")

        response = client.get("/api/data/htx/ticker/BTC")
        assert response.status_code == 200
        
        data = response.json()
        assert data["cached"] is True
        assert data["price"] == 50000.0
        assert data["provider"] == "HTX"

    @patch('app.clients.htx.aioredis')
    def test_redis_module_not_available(self, mock_aioredis, monkeypatch, client: TestClient, mock_htx_client):
        """Test behavior when Redis module is not available."""
        from app import config as cfg
        
        # Simulate aioredis being None (not installed)
        mock_aioredis = None
        
        with patch('app.clients.htx.aioredis', None):
            monkeypatch.setattr(cfg.settings, "redis_url", "redis://localhost:6379")
            
            response = client.get("/api/data/htx/ticker/BTC")
            assert response.status_code == 200
            
            data = response.json()
            assert data["provider"] == "HTX"

    @patch('app.clients.htx.aioredis.from_url')
    def test_redis_auth_error(self, mock_redis_from_url, monkeypatch, client: TestClient, mock_htx_client):
        """Test Redis authentication error handling."""
        from app import config as cfg
        
        # Mock authentication error
        mock_redis_from_url.side_effect = Exception("NOAUTH Authentication required")
        
        monkeypatch.setattr(cfg.settings, "redis_url", "redis://localhost:6379")

        response = client.get("/api/data/htx/ticker/BTC")
        assert response.status_code == 200
        
        # Should work without Redis
        data = response.json()
        assert data["provider"] == "HTX"

    @patch('app.clients.htx.aioredis.from_url')
    def test_multiple_redis_operations_mixed_success(self, mock_redis_from_url, monkeypatch, client: TestClient, mock_htx_client):
        """Test scenario where some Redis operations succeed and others fail."""
        from app import config as cfg
        
        mock_redis_instance = AsyncMock()
        # First call: get() succeeds but returns None, set() fails
        mock_redis_instance.get.return_value = None
        mock_redis_instance.set.side_effect = Exception("Redis SET failed")
        mock_redis_from_url.return_value = mock_redis_instance
        
        monkeypatch.setattr(cfg.settings, "redis_url", "redis://localhost:6379")

        response = client.get("/api/data/htx/ticker/BTC")
        assert response.status_code == 200
        
        data = response.json()
        assert data["provider"] == "HTX"
        
        # Both operations should have been attempted
        mock_redis_instance.get.assert_called_once()
        mock_redis_instance.set.assert_called_once()

    def test_rate_limiter_without_redis_module(self, monkeypatch, client: TestClient, mock_htx_client):
        """Test rate limiter behavior when Redis module is unavailable."""
        from app import config as cfg
        from app.utils.ratelimit import RateLimiter
        
        # Patch aioredis to be None globally
        with patch('app.utils.ratelimit.aioredis', None):
            monkeypatch.setattr(cfg.settings, "redis_url", "redis://localhost:6379")
            monkeypatch.setattr(cfg.settings, "htx_rate_limit_max", 1)
            monkeypatch.setattr(cfg.settings, "htx_rate_limit_window", 60)

            # Should fallback to in-memory limiting
            response1 = client.get("/api/data/htx/ticker/BTC")
            assert response1.status_code == 200
            
            response2 = client.get("/api/data/htx/ticker/BTC")
            assert response2.status_code == 429

    @patch('app.utils.ratelimit.aioredis.from_url')
    def test_rate_limiter_redis_intermittent_failures(self, mock_redis_from_url, monkeypatch, client: TestClient, mock_htx_client):
        """Test rate limiter with intermittent Redis failures."""
        from app import config as cfg
        
        # First call succeeds, second fails
        call_count = 0
        def side_effect(*args, **kwargs):
            nonlocal call_count
            call_count += 1
            if call_count == 1:
                mock_instance = AsyncMock()
                mock_instance.incr.return_value = 1
                mock_instance.expire.return_value = True
                return mock_instance
            else:
                raise Exception("Redis temporarily unavailable")
        
        mock_redis_from_url.side_effect = side_effect
        
        monkeypatch.setattr(cfg.settings, "redis_url", "redis://localhost:6379")
        monkeypatch.setattr(cfg.settings, "htx_rate_limit_max", 2)
        monkeypatch.setattr(cfg.settings, "htx_rate_limit_window", 60)

        # First request uses Redis
        response1 = client.get("/api/data/htx/ticker/BTC")
        assert response1.status_code == 200
        
        # Second request falls back to memory
        response2 = client.get("/api/data/htx/ticker/BTC")
        assert response2.status_code == 200  # Should work with memory fallback

    def test_cache_key_consistency_across_failures(self, monkeypatch, client: TestClient, mock_htx_client):
        """Test that cache keys remain consistent even with Redis failures."""
        from app import config as cfg
        
        # Test with different symbols to ensure key generation is consistent
        monkeypatch.setattr(cfg.settings, "redis_url", None)
        
        symbols = ["BTC", "ETH", "btc", "eth", "BTC-USDT", "eth-usdt"]
        
        for symbol in symbols:
            response = client.get(f"/api/data/htx/ticker/{symbol}")
            assert response.status_code == 200
            
            data = response.json()
            assert data["provider"] == "HTX"
            # All should normalize to same pair format
            if symbol.lower().startswith('btc'):
                assert data["pair"] == "btcusdt"
            elif symbol.lower().startswith('eth'):
                assert data["pair"] == "ethusdt"
