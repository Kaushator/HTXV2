from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from datetime import datetime
import asyncio
import contextlib

import httpx
import asyncpg
from redis import asyncio as aioredis

from .config import settings

app = FastAPI(
    title=settings.app_name,
    description="Backend API for HTX cryptocurrency trading platform with ML analytics",
    version=settings.version,
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def root():
    return {
        "message": settings.app_name,
        "version": settings.version,
        "timestamp": datetime.now().isoformat(),
        "status": "running"
    }

@app.get("/health")
@app.get("/healthz")
async def health():
    services: dict[str, str] = {"api": "running"}

    async def check_db() -> str:
        if not settings.database_url:
            return "skipped"
        try:
            conn = await asyncpg.connect(settings.database_url, timeout=2.0)
            await conn.close()
            return "ok"
        except Exception:
            return "unavailable"

    async def check_redis() -> str:
        if not settings.redis_url:
            return "skipped"
        try:
            client = aioredis.from_url(settings.redis_url, decode_responses=True)
            pong = await client.ping()
            with contextlib.suppress(Exception):
                await client.close()
            return "ok" if pong else "unavailable"
        except Exception:
            return "unavailable"

    async def check_fingpt() -> str:
        base = settings.fingpt_base
        if not base:
            return "skipped"
        try:
            async with httpx.AsyncClient(timeout=2.0) as client:
                # Try /health, fallback to base
                for path in ("/health", ""):
                    url = base.rstrip("/") + path
                    try:
                        r = await client.get(url)
                        if r.status_code < 500:
                            return "ok"
                    except Exception:
                        continue
            return "unavailable"
        except Exception:
            return "unavailable"

    # run checks concurrently with overall timeout buffer
    db_task = asyncio.create_task(check_db())
    redis_task = asyncio.create_task(check_redis())
    fingpt_task = asyncio.create_task(check_fingpt())

    try:
        db_status, redis_status, fingpt_status = await asyncio.wait_for(
            asyncio.gather(db_task, redis_task, fingpt_task), timeout=3.0
        )
    except asyncio.TimeoutError:
        db_status = db_task.result() if db_task.done() else "timeout"
        redis_status = redis_task.result() if redis_task.done() else "timeout"
        fingpt_status = fingpt_task.result() if fingpt_task.done() else "timeout"

    services.update(
        {
            "database": db_status,
            "redis": redis_status,
            "fingpt": fingpt_status,
        }
    )

    return {
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "version": settings.version,
        "services": services,
    }

@app.get("/api/coins")
async def get_coins():
    """Get list of available coins (mock data for now)"""
    return {
        "coins": [
            {"symbol": "BTC", "name": "Bitcoin", "source": "HTX"},
            {"symbol": "ETH", "name": "Ethereum", "source": "HTX"},
            {"symbol": "USDT", "name": "Tether", "source": "HTX"},
        ],
        "total": 3,
        "sources": ["HTX", "CoinGecko", "CSV Upload"]
    }

@app.post("/api/coins")
async def add_coin(coin_data: dict):
    """Add new coin manually"""
    return {
        "message": "Coin added successfully",
        "coin": coin_data,
        "timestamp": datetime.now().isoformat()
    }

@app.delete("/api/coins/{symbol}")
async def remove_coin(symbol: str):
    """Remove coin from list"""
    return {
        "message": f"Coin {symbol} removed successfully",
        "timestamp": datetime.now().isoformat()
    }

@app.get("/api/analysis/{symbol}")
async def get_analysis(symbol: str):
    """Get ML analysis for a symbol"""
    return {
        "symbol": symbol,
        "analysis": f"Mock analysis for {symbol}",
        "confidence": 0.85,
        "signals": [
            {"type": "technical", "value": "bullish", "confidence": 0.8},
            {"type": "sentiment", "value": "neutral", "confidence": 0.7}
        ],
        "timestamp": datetime.now().isoformat()
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
