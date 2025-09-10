"""
Simplified test runner for edge cases without database dependencies.
"""
import asyncio
import json
import time
from unittest.mock import AsyncMock, patch, MagicMock
import sys
import os

# Add app to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from app.utils.ratelimit import RateLimiter
from app.clients.htx import get_ticker, _normalize_symbol, _map_response
from app.config import settings


class TestRunner:
    def __init__(self):
        self.tests_passed = 0
        self.tests_failed = 0
        self.failures = []

    def assert_equal(self, actual, expected, message=""):
        if actual != expected:
            error_msg = f"Expected {expected}, got {actual}. {message}"
            self.failures.append(error_msg)
            self.tests_failed += 1
            print(f"❌ FAIL: {error_msg}")
            return False
        else:
            self.tests_passed += 1
            print(f"✅ PASS: {message or 'Assertion passed'}")
            return True

    def assert_true(self, condition, message=""):
        return self.assert_equal(condition, True, message)

    def run_test(self, test_func, test_name):
        print(f"\n🧪 Running {test_name}...")
        try:
            test_func()
            print(f"✅ {test_name} completed")
        except Exception as e:
            self.tests_failed += 1
            self.failures.append(f"{test_name}: {str(e)}")
            print(f"❌ {test_name} failed: {e}")

    def summary(self):
        total = self.tests_passed + self.tests_failed
        print(f"\n📊 Test Summary:")
        print(f"Total tests: {total}")
        print(f"Passed: {self.tests_passed}")
        print(f"Failed: {self.tests_failed}")
        
        if self.failures:
            print(f"\n❌ Failures:")
            for failure in self.failures:
                print(f"  - {failure}")
        
        return self.tests_failed == 0


def test_symbol_normalization(runner: TestRunner):
    """Test HTX symbol normalization edge cases."""
    
    # Test basic symbols
    runner.assert_equal(_normalize_symbol("BTC"), "btcusdt", "BTC -> btcusdt")
    runner.assert_equal(_normalize_symbol("ETH"), "ethusdt", "ETH -> ethusdt")
    
    # Test with quotes
    runner.assert_equal(_normalize_symbol("BTC-USDT"), "btcusdt", "BTC-USDT -> btcusdt")
    runner.assert_equal(_normalize_symbol("btcusdt"), "btcusdt", "btcusdt -> btcusdt")
    
    # Test case insensitive
    runner.assert_equal(_normalize_symbol("btc"), "btcusdt", "btc -> btcusdt")
    runner.assert_equal(_normalize_symbol("BTC"), "btcusdt", "BTC -> btcusdt")
    
    # Test invalid symbols
    try:
        _normalize_symbol("")
        runner.assert_true(False, "Empty symbol should raise ValueError")
    except ValueError:
        runner.assert_true(True, "Empty symbol correctly raises ValueError")
    
    try:
        _normalize_symbol("123")
        runner.assert_true(False, "Numeric symbol should raise ValueError")
    except ValueError:
        runner.assert_true(True, "Numeric symbol correctly raises ValueError")


def test_rate_limiter_in_memory(runner: TestRunner):
    """Test in-memory rate limiter edge cases."""
    
    limiter = RateLimiter(redis_url=None)
    
    # Test basic functionality
    async def run_rate_limit_tests():
        # Test allow under limit
        result1 = await limiter.allow("test_key", max_calls=2, window_sec=60)
        runner.assert_true(result1, "First request should be allowed")
        
        result2 = await limiter.allow("test_key", max_calls=2, window_sec=60)
        runner.assert_true(result2, "Second request should be allowed")
        
        result3 = await limiter.allow("test_key", max_calls=2, window_sec=60)
        runner.assert_true(not result3, "Third request should be blocked")
        
        # Test different key
        result4 = await limiter.allow("other_key", max_calls=2, window_sec=60)
        runner.assert_true(result4, "Different key should be allowed")
        
        # Test zero limit
        result5 = await limiter.allow("zero_key", max_calls=0, window_sec=60)
        runner.assert_true(not result5, "Zero limit should block all requests")
        
        # Test window reset
        result6 = await limiter.allow("short_window", max_calls=1, window_sec=1)
        runner.assert_true(result6, "First request in short window should be allowed")
        
        result7 = await limiter.allow("short_window", max_calls=1, window_sec=1)
        runner.assert_true(not result7, "Second request in short window should be blocked")
        
        # Wait for window reset
        await asyncio.sleep(1.1)
        
        result8 = await limiter.allow("short_window", max_calls=1, window_sec=1)
        runner.assert_true(result8, "Request after window reset should be allowed")
    
    asyncio.run(run_rate_limit_tests())


def test_htx_response_mapping(runner: TestRunner):
    """Test HTX response mapping edge cases."""
    
    # Test valid response
    valid_response = {
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
    
    mapped = _map_response("btcusdt", valid_response)
    runner.assert_equal(mapped["provider"], "HTX", "Provider should be HTX")
    runner.assert_equal(mapped["pair"], "btcusdt", "Pair should be btcusdt")
    runner.assert_equal(mapped["price"], 60000.0, "Price should be mapped correctly")
    runner.assert_equal(mapped["bid"], 59990.0, "Bid should be first element of bid array")
    runner.assert_equal(mapped["ask"], 60010.0, "Ask should be first element of ask array")
    
    # Test empty response
    empty_response = {}
    mapped_empty = _map_response("btcusdt", empty_response)
    runner.assert_equal(mapped_empty["provider"], "HTX", "Provider should still be HTX")
    runner.assert_equal(mapped_empty["pair"], "btcusdt", "Pair should still be btcusdt")
    runner.assert_equal(mapped_empty["price"], None, "Price should be None for empty response")
    
    # Test malformed tick
    malformed_response = {
        "status": "ok",
        "tick": {
            "close": "invalid",
            "bid": [],
            "ask": None,
        },
        "ts": 1700000000000
    }
    
    mapped_malformed = _map_response("btcusdt", malformed_response)
    runner.assert_equal(mapped_malformed["price"], "invalid", "Invalid price should be passed through")
    runner.assert_equal(mapped_malformed["bid"], None, "Empty bid array should return None")
    runner.assert_equal(mapped_malformed["ask"], None, "None ask should return None")


async def test_htx_ticker_with_mocks(runner: TestRunner):
    """Test HTX ticker with mocked HTTP calls."""
    
    mock_response = {
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
    
    # Mock the HTTP fetch function
    from app.clients import htx as htx_client
    original_fetch = htx_client._fetch_ticker_http
    try:
        async def mock_fetch(pair: str):
            return mock_response
        
        htx_client._fetch_ticker_http = mock_fetch
        
        # Test with no Redis
        original_redis_url = settings.redis_url
        settings.redis_url = None
        
        result = await get_ticker("BTC")
        runner.assert_equal(result["provider"], "HTX", "Provider should be HTX")
        runner.assert_equal(result["price"], 45000.0, "Price should be from mock")
        runner.assert_equal(result["pair"], "btcusdt", "Pair should be normalized")
        
        # Test TTL override
        result_ttl = await get_ticker("BTC", ttl_override=10)
        runner.assert_equal(result_ttl["price"], 45000.0, "TTL override should not affect result")
        
        # Test invalid TTL
        result_invalid_ttl = await get_ticker("BTC", ttl_override=-5)
        runner.assert_equal(result_invalid_ttl["price"], 45000.0, "Invalid TTL should fallback")
        
        # Restore settings
        settings.redis_url = original_redis_url
        
    finally:
        htx_client._fetch_ticker_http = original_fetch


def main():
    """Run all edge case tests."""
    runner = TestRunner()
    
    print("🚀 Running HTX Ticker and Rate Limiting Edge Case Tests")
    print("=" * 60)
    
    # Run sync tests
    runner.run_test(lambda: test_symbol_normalization(runner), "Symbol Normalization")
    runner.run_test(lambda: test_rate_limiter_in_memory(runner), "Rate Limiter In-Memory")
    runner.run_test(lambda: test_htx_response_mapping(runner), "HTX Response Mapping")
    
    # Run async tests  
    runner.run_test(lambda: asyncio.run(test_htx_ticker_with_mocks(runner)), "HTX Ticker with Mocks")
    
    # Summary
    success = runner.summary()
    
    if success:
        print("\n🎉 All tests passed!")
        return 0
    else:
        print("\n💥 Some tests failed!")
        return 1


if __name__ == "__main__":
    exit_code = main()
    exit(exit_code)
