from fastapi import APIRouter
from fastapi.responses import JSONResponse

router = APIRouter(prefix="/api/data", tags=["market-data"])


@router.get("/htx/ticker/{symbol}")
async def htx_ticker(symbol: str):
    """HTX market data (pending integration)."""
    return JSONResponse(
        status_code=501,
        content={
            "status": "not_implemented",
            "provider": "HTX",
            "endpoint": "ticker",
            "symbol": symbol,
            "todo": "Integrate HTX API client and rate limiting",
        },
    )


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

