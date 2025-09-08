from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import os
from datetime import datetime

app = FastAPI(
    title="HTX Interface v2 API",
    description="Backend API for HTX cryptocurrency trading platform with ML analytics",
    version="0.1.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://localhost:3001"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def root():
    return {
        "message": "HTX Interface v2 API",
        "version": "0.1.0",
        "timestamp": datetime.now().isoformat(),
        "status": "running"
    }

@app.get("/health")
@app.get("/healthz")
async def health():
    return {
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "version": "0.1.0",
        "services": {
            "api": "running",
            "database": "pending",  # TODO: Add database health check
            "redis": "pending",     # TODO: Add Redis health check
            "fingpt": "pending"     # TODO: Add FinGPT health check
        }
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
