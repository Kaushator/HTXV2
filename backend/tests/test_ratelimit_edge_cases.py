"""
Enhanced tests for rate limiting edge cases.

Tests cover:
- Redis vs in-memory fallback behavior
- Serial requests under limit
- Window reset timing
- Edge cases with 0 limits
- Multiple keys and scoping
- Redis connection failures
"""
import time
import pytest
from unittest.mock import AsyncMock, patch
from fastapi.testclient import TestClient


class TestRateLimitingEdgeCases:
    """Test edge cases for rate limiting functionality."""

    @pytest.fixture
    def mock_htx_client(self, monkeypatch):
        """Mock HTX client for predictable responses."""
        async def fake_get_ticker(symbol: str):
            return {
                "provider": "HTX",
                "pair": "btcusdt", 
                "price": 60000.0,
                "timestamp": int(time.time() * 1000)
            }

        from app.clients import htx as htx_client
        monkeypatch.setattr(htx_client, "get_ticker", fake_get_ticker)

    def test_in_memory_rate_limit_zero_max(self, monkeypatch, client: TestClient, mock_htx_client):
        """Test rate limiter with max_calls=0 (should block all requests)."""
        from app import config as cfg
        
        # Force in-memory and set limit to 0
        monkeypatch.setattr(cfg.settings, "redis_url", None)
        monkeypatch.setattr(cfg.settings, "htx_rate_limit_max", 0)
        monkeypatch.setattr(cfg.settings, "htx_rate_limit_window", 60)

        # First request should be blocked (0 max calls)
        response = client.get("/api/data/htx/ticker/BTC")
        assert response.status_code == 429

    def test_in_memory_rate_limit_large_window(self, monkeypatch, client: TestClient, mock_htx_client):
        """Test rate limiter with very large window."""
        from app import config as cfg
        
        monkeypatch.setattr(cfg.settings, "redis_url", None)
        monkeypatch.setattr(cfg.settings, "htx_rate_limit_max", 2)
        monkeypatch.setattr(cfg.settings, "htx_rate_limit_window", 86400)  # 24 hours

        # Should allow up to max within large window
        response1 = client.get("/api/data/htx/ticker/BTC")
        assert response1.status_code == 200
        
        response2 = client.get("/api/data/htx/ticker/BTC")
        assert response2.status_code == 200
        
        response3 = client.get("/api/data/htx/ticker/BTC")
        assert response3.status_code == 429

    def test_in_memory_rate_limit_window_reset(self, monkeypatch, client: TestClient, mock_htx_client):
        """Test rate limit window reset behavior."""
        from app import config as cfg
        
        monkeypatch.setattr(cfg.settings, "redis_url", None)
        monkeypatch.setattr(cfg.settings, "htx_rate_limit_max", 1)
        monkeypatch.setattr(cfg.settings, "htx_rate_limit_window", 1)  # 1 second window

        # First request allowed
        response1 = client.get("/api/data/htx/ticker/BTC")
        assert response1.status_code == 200
        
        # Second request blocked (same window)
        response2 = client.get("/api/data/htx/ticker/BTC")
        assert response2.status_code == 429
        
        # Wait for window reset
        time.sleep(1.1)
        
        # Should be allowed again after window reset
        response3 = client.get("/api/data/htx/ticker/BTC")
        assert response3.status_code == 200

    def test_serial_requests_under_limit(self, monkeypatch, client: TestClient, mock_htx_client):
        """Test serial requests staying under rate limit."""
        from app import config as cfg
        
        monkeypatch.setattr(cfg.settings, "redis_url", None)
        monkeypatch.setattr(cfg.settings, "htx_rate_limit_max", 5)
        monkeypatch.setattr(cfg.settings, "htx_rate_limit_window", 60)

        # Make 5 serial requests (all should pass)
        for i in range(5):
            response = client.get("/api/data/htx/ticker/BTC")
            assert response.status_code == 200, f"Request {i+1} failed"
            
        # 6th request should be blocked
        response = client.get("/api/data/htx/ticker/BTC")
        assert response.status_code == 429

    def test_rate_limit_different_symbols_same_scope(self, monkeypatch, client: TestClient, mock_htx_client):
        """Test rate limiting applies across different symbols for same scope."""
        from app import config as cfg
        
        monkeypatch.setattr(cfg.settings, "redis_url", None)
        monkeypatch.setattr(cfg.settings, "htx_rate_limit_max", 2)
        monkeypatch.setattr(cfg.settings, "htx_rate_limit_window", 60)

        # Request different symbols but same scope (no api_key)
        response1 = client.get("/api/data/htx/ticker/BTC")
        assert response1.status_code == 200
        
        response2 = client.get("/api/data/htx/ticker/ETH")
        assert response2.status_code == 200
        
        # Third request (different symbol) should be blocked
        response3 = client.get("/api/data/htx/ticker/LTC")
        assert response3.status_code == 429

    def test_rate_limit_api_key_isolation(self, monkeypatch, client: TestClient, mock_htx_client):
        """Test API keys create isolated rate limit buckets."""
        from app import config as cfg
        
        monkeypatch.setattr(cfg.settings, "redis_url", None)
        monkeypatch.setattr(cfg.settings, "htx_rate_limit_max", 1)
        monkeypatch.setattr(cfg.settings, "htx_rate_limit_window", 60)

        # Use up limit for key1
        response1 = client.get("/api/data/htx/ticker/BTC?api_key=key1")
        assert response1.status_code == 200
        
        response2 = client.get("/api/data/htx/ticker/BTC?api_key=key1")
        assert response2.status_code == 429
        
        # key2 should have separate bucket
        response3 = client.get("/api/data/htx/ticker/BTC?api_key=key2")
        assert response3.status_code == 200
        
        response4 = client.get("/api/data/htx/ticker/BTC?api_key=key2")
        assert response4.status_code == 429
        
        # key3 should also have separate bucket
        response5 = client.get("/api/data/htx/ticker/BTC?api_key=key3")
        assert response5.status_code == 200

    @patch('app.utils.ratelimit.aioredis.from_url')
    def test_redis_fallback_on_connection_error(self, mock_redis, monkeypatch, client: TestClient, mock_htx_client):
        """Test fallback to in-memory when Redis connection fails."""
        from app import config as cfg
        
        # Mock Redis to raise connection error
        mock_redis.side_effect = Exception("Redis connection failed")
        
        monkeypatch.setattr(cfg.settings, "redis_url", "redis://localhost:6379")
        monkeypatch.setattr(cfg.settings, "htx_rate_limit_max", 1)
        monkeypatch.setattr(cfg.settings, "htx_rate_limit_window", 60)

        # Should fallback to in-memory rate limiting
        response1 = client.get("/api/data/htx/ticker/BTC")
        assert response1.status_code == 200
        
        response2 = client.get("/api/data/htx/ticker/BTC")
        assert response2.status_code == 429

    @patch('app.utils.ratelimit.aioredis.from_url')
    def test_redis_incr_expire_behavior(self, mock_redis, monkeypatch, client: TestClient, mock_htx_client):
        """Test Redis incr and expire behavior for rate limiting."""
        from app import config as cfg
        
        # Mock Redis instance
        mock_redis_instance = AsyncMock()
        mock_redis_instance.incr.return_value = 1  # First increment
        mock_redis_instance.expire.return_value = True
        mock_redis.return_value = mock_redis_instance
        
        monkeypatch.setattr(cfg.settings, "redis_url", "redis://localhost:6379")
        monkeypatch.setattr(cfg.settings, "htx_rate_limit_max", 2)
        monkeypatch.setattr(cfg.settings, "htx_rate_limit_window", 30)

        response = client.get("/api/data/htx/ticker/BTC")
        assert response.status_code == 200
        
        # Verify Redis was called correctly
        mock_redis_instance.incr.assert_called_once()
        mock_redis_instance.expire.assert_called_once()
        
        # Check expire was called with correct window
        expire_call = mock_redis_instance.expire.call_args[0]
        assert expire_call[1] == 30  # window_sec

    @patch('app.utils.ratelimit.aioredis.from_url')
    def test_redis_second_increment_no_expire(self, mock_redis, monkeypatch, client: TestClient, mock_htx_client):
        """Test Redis doesn't call expire on subsequent increments."""
        from app import config as cfg
        
        mock_redis_instance = AsyncMock()
        mock_redis_instance.incr.return_value = 2  # Second increment
        mock_redis.return_value = mock_redis_instance
        
        monkeypatch.setattr(cfg.settings, "redis_url", "redis://localhost:6379")
        monkeypatch.setattr(cfg.settings, "htx_rate_limit_max", 3)

        response = client.get("/api/data/htx/ticker/BTC")
        assert response.status_code == 200
        
        # Expire should not be called for second increment
        mock_redis_instance.expire.assert_not_called()

    @patch('app.utils.ratelimit.aioredis.from_url')
    def test_redis_rate_limit_exceeded(self, mock_redis, monkeypatch, client: TestClient, mock_htx_client):
        """Test Redis rate limit exceeded scenario."""
        from app import config as cfg
        
        mock_redis_instance = AsyncMock()
        mock_redis_instance.incr.return_value = 3  # Exceeds limit of 2
        mock_redis.return_value = mock_redis_instance
        
        monkeypatch.setattr(cfg.settings, "redis_url", "redis://localhost:6379")
        monkeypatch.setattr(cfg.settings, "htx_rate_limit_max", 2)

        response = client.get("/api/data/htx/ticker/BTC")
        assert response.status_code == 429

    def test_in_memory_concurrent_requests_same_key(self, monkeypatch, client: TestClient, mock_htx_client):
        """Test in-memory rate limiter with rapid requests to same key."""
        from app import config as cfg
        
        monkeypatch.setattr(cfg.settings, "redis_url", None)
        monkeypatch.setattr(cfg.settings, "htx_rate_limit_max", 3)
        monkeypatch.setattr(cfg.settings, "htx_rate_limit_window", 60)

        # Make rapid successive requests
        responses = []
        for i in range(5):
            response = client.get("/api/data/htx/ticker/BTC")
            responses.append(response.status_code)
        
        # First 3 should pass, last 2 should be rate limited
        assert responses == [200, 200, 200, 429, 429]

    def test_memory_store_cleanup_expired_keys(self, monkeypatch, client: TestClient, mock_htx_client):
        """Test in-memory store handles expired keys correctly."""
        from app import config as cfg
        from app.utils.ratelimit import RateLimiter
        
        monkeypatch.setattr(cfg.settings, "redis_url", None)
        monkeypatch.setattr(cfg.settings, "htx_rate_limit_max", 1)
        monkeypatch.setattr(cfg.settings, "htx_rate_limit_window", 1)  # 1 second

        # First request uses up the limit
        response1 = client.get("/api/data/htx/ticker/BTC")
        assert response1.status_code == 200
        
        # Wait for window to expire
        time.sleep(1.1)
        
        # Next request should reset the window and be allowed
        response2 = client.get("/api/data/htx/ticker/BTC")
        assert response2.status_code == 200

    def test_edge_case_empty_api_key(self, monkeypatch, client: TestClient, mock_htx_client):
        """Test rate limiting with empty api_key parameter."""
        from app import config as cfg
        
        monkeypatch.setattr(cfg.settings, "redis_url", None)
        monkeypatch.setattr(cfg.settings, "htx_rate_limit_max", 1)
        monkeypatch.setattr(cfg.settings, "htx_rate_limit_window", 60)

        # Empty api_key should use global scope
        response1 = client.get("/api/data/htx/ticker/BTC?api_key=")
        assert response1.status_code == 200
        
        response2 = client.get("/api/data/htx/ticker/BTC")  # No api_key
        assert response2.status_code == 429  # Should share same scope

    def test_rate_limit_key_generation(self, monkeypatch, client: TestClient, mock_htx_client):
        """Test rate limit key generation for different scenarios."""
        from app import config as cfg
        
        monkeypatch.setattr(cfg.settings, "redis_url", None)
        monkeypatch.setattr(cfg.settings, "htx_rate_limit_max", 1)
        monkeypatch.setattr(cfg.settings, "htx_rate_limit_window", 60)

        # Test with special characters in api_key
        response1 = client.get("/api/data/htx/ticker/BTC?api_key=test@domain.com")
        assert response1.status_code == 200
        
        response2 = client.get("/api/data/htx/ticker/BTC?api_key=test@domain.com")
        assert response2.status_code == 429
        
        # Different special character key should work
        response3 = client.get("/api/data/htx/ticker/BTC?api_key=test-123_ABC")
        assert response3.status_code == 200
