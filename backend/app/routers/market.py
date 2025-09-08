from fastapi import APIRouter, HTTPException
from fastapi.responses import JSONResponse
import httpx

from ..clients import htx as htx_client

router = APIRouter(prefix="/api/data", tags=["market-data"])


@router.get("/htx/ticker/{symbol}")
async def htx_ticker(symbol: str):
    """HTX market ticker for a symbol or pair (e.g., BTC or BTCUSDT)."""
    try:
        data = await htx_client.get_ticker(symbol)
        return data
    except httpx.HTTPStatusError as e:
        raise HTTPException(status_code=502, detail=f"HTX upstream error: {e.response.status_code}")
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
