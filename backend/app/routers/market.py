from fastapi import APIRouter, HTTPException, Request
import httpx

from ..clients import htx as htx_client
from ..clients import coingecko as cg_client
from ..utils.ratelimit import RateLimiter
from ..utils.api_keys import extract_api_key
from ..config import settings

router = APIRouter(prefix="/api/data", tags=["market-data"])


_rl = RateLimiter(settings.redis_url)


@router.get("/htx/ticker/{symbol}")
async def htx_ticker(request: Request, symbol: str, ttl: int | None = None, api_key: str | None = None):
    """HTX market ticker for a symbol or pair (e.g., BTC or BTCUSDT)."""
    # Basic rate limit: per-IP per route
    # Prefer API key (header or query) to scope rate limiting; fallback to IP
    header_key = request.headers.get("X-API-Key")
    effective_key = api_key or header_key
    if not effective_key:
        # unified extractor (covers query/header)
        k, _ = extract_api_key(request)
        effective_key = effective_key or k
    if effective_key:
        key = f"rl:htx:ticker:key:{effective_key}"
    else:
        client_ip = request.client.host if request.client else "unknown"
        key = f"rl:htx:ticker:ip:{client_ip}"
    # Load per-key quota if available (placeholder for future DAO)
    max_calls = settings.htx_rate_limit_max
    window = settings.htx_rate_limit_window
    try:
        from ..services.quotas import get_rate_limit_for_api_key  # lazy import
        if effective_key:
            q = await get_rate_limit_for_api_key(effective_key)
            if q:
                max_calls, window = q
    except Exception:
        pass
    allowed = await _rl.allow(key, max_calls, window)
    if not allowed:
        raise HTTPException(status_code=429, detail="Rate limit exceeded. Please slow down.")
    # Usage tracking now handled globally by ApiKeyUsageMiddleware
    try:
        data = await htx_client.get_ticker(symbol, ttl_override=ttl)
        return data
    except httpx.HTTPStatusError as e:
        raise HTTPException(status_code=502, detail=f"HTX upstream error: {e.response.status_code}")
    except ValueError as e:
        raise HTTPException(status_code=422, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"HTX upstream unavailable: {e}")


@router.get("/coingecko/coin/{coin_id}")
async def coingecko_coin(coin_id: str):
    """CoinGecko market data for a given coin id."""
    try:
        return await cg_client.get_coin(coin_id)
    except httpx.HTTPStatusError as e:
        if e.response is not None and e.response.status_code == 404:
            raise HTTPException(status_code=404, detail="Coin not found")
        raise HTTPException(status_code=502, detail=f"CoinGecko upstream error: {e.response.status_code if e.response else 'unknown'}")
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"CoinGecko upstream unavailable: {e}")


@router.get("/sources")
async def data_sources():
    return {
        "sources": ["HTX", "CoinGecko", "CSV Upload", "CryptoPanic"],
        "implemented": ["coins (mock)", "analysis (mock)", "health"],
        "pending": [
            "htx ticker",
            "coingecko coin",
            "csv/xlsx signed url",
            "cryptopanic news",
            "llm predict via FinGPT",
        ],
    }
