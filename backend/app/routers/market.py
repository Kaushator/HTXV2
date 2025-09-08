from fastapi import APIRouter, HTTPException, Request
from fastapi.responses import JSONResponse
import httpx

from ..clients import htx as htx_client
from ..utils.ratelimit import RateLimiter
from ..config import settings

router = APIRouter(prefix="/api/data", tags=["market-data"])


_rl = RateLimiter(settings.redis_url)


@router.get("/htx/ticker/{symbol}")
async def htx_ticker(request: Request, symbol: str, ttl: int | None = None):
    """HTX market ticker for a symbol or pair (e.g., BTC or BTCUSDT)."""
    # Basic rate limit: per-IP per route
    client_ip = request.client.host if request.client else "unknown"
    key = f"rl:htx:ticker:{client_ip}"
    allowed = await _rl.allow(key, settings.htx_rate_limit_max, settings.htx_rate_limit_window)
    if not allowed:
        raise HTTPException(status_code=429, detail="Rate limit exceeded. Please slow down.")
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
    """CoinGecko market data (pending integration)."""
    return JSONResponse(
        status_code=501,
        content={
            "status": "not_implemented",
            "provider": "CoinGecko",
            "endpoint": "coin",
            "id": coin_id,
            "todo": "Integrate CoinGecko client with caching",
        },
    )


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
