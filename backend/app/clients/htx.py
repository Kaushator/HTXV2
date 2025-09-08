import asyncio
from typing import Any, Dict, Optional
import time

import httpx
from redis import asyncio as aioredis

from ..config import settings


def _normalize_symbol(symbol: str) -> str:
    s = symbol.strip().lower()
    # Accept 'btc', 'btc-usdt', 'btcusdt'; default quote: first allowed quote
    s = s.replace("-", "")
    quotes = settings.htx_allowed_quotes
    for q in quotes:
        if s.endswith(q):
            base = s[: -len(q)]
            if not base or not base.isalpha():
                raise ValueError("invalid base symbol")
            return f"{base}{q}"
    # no known quote found -> assume first allowed quote if looks like base
    if s.isalpha():
        return f"{s}{quotes[0]}"
    raise ValueError("unsupported symbol/quote")


async def _fetch_ticker_http(pair: str) -> Dict[str, Any]:
    base = settings.htx_api_base.rstrip('/')
    url = f"{base}/market/detail/merged"
    async with httpx.AsyncClient(timeout=5.0) as client:
        r = await client.get(url, params={"symbol": pair})
        r.raise_for_status()
        data = r.json()
        return data


def _map_response(pair: str, data: Dict[str, Any]) -> Dict[str, Any]:
    # Expected Huobi/HTX format: { status, tick: { close, bid, ask, high, low, amount, vol, ... }, ts }
    tick = (data or {}).get('tick') or {}
    return {
        "provider": "HTX",
        "pair": pair,
        "price": tick.get("close"),
        "bid": (tick.get("bid") or [None, None])[0],
        "ask": (tick.get("ask") or [None, None])[0],
        "high": tick.get("high"),
        "low": tick.get("low"),
        "volume": tick.get("amount"),  # base amount
        "raw": {k: v for k, v in data.items() if k != 'tick'},
        "timestamp": data.get("ts"),
    }


async def get_ticker(symbol: str, ttl_override: Optional[int] = None) -> Dict[str, Any]:
    """Fetch ticker from HTX with optional Redis caching.

    - Normalizes symbol to HTX pair (e.g., BTC -> btcusdt).
    - Uses Redis if configured to cache for a short TTL (default 5s).
    """
    pair = _normalize_symbol(symbol)
    cache_key = f"htx:ticker:{pair}"
    ttl = settings.htx_ticker_ttl
    if ttl_override is not None:
        try:
            ttl = max(1, min(int(ttl_override), settings.htx_ticker_ttl_max))
        except Exception:
            ttl = settings.htx_ticker_ttl

    # Try Redis cache first
    if settings.redis_url:
        try:
            r = aioredis.from_url(settings.redis_url, decode_responses=True)
            cached = await r.get(cache_key)
            if cached:
                import json
                return json.loads(cached)
        except Exception:
            pass

    # Fetch from upstream
    data = await _fetch_ticker_http(pair)
    mapped = _map_response(pair, data)

    # Store cache
    if settings.redis_url:
        try:
            import json
            r = aioredis.from_url(settings.redis_url, decode_responses=True)
            await r.set(cache_key, json.dumps(mapped), ex=ttl)
        except Exception:
            pass

    return mapped
