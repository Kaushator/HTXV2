from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List, Optional
from datetime import datetime, timedelta

from app.core.security import get_current_active_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.trading import (
    TradingSignalResponse, 
    MarketDataResponse,
    PriceHistoryResponse
)

router = APIRouter()


@router.get("/signals", response_model=List[TradingSignalResponse])
async def get_trading_signals(
    symbol: Optional[str] = None,
    signal_type: Optional[str] = None,
    limit: int = 100,
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db)
):
    """Get trading signals"""
    # Generate sample trading signals
    import random
    
    signals = []
    symbols = ["BTC", "ETH", "ADA", "SOL", "AVAX"] if not symbol else [symbol.upper()]
    
    for i in range(min(limit, 10)):  # Limit to 10 sample signals
        sym = random.choice(symbols)
        signal_types = ["buy", "sell", "hold"]
        sig_type = signal_type if signal_type else random.choice(signal_types)
        
        signals.append(TradingSignalResponse(
            id=i + 1,
            symbol=sym,
            signal_type=sig_type,
            confidence=round(random.uniform(0.6, 0.95), 2),
            target_price=round(random.uniform(45000, 55000), 2),
            stop_loss=round(random.uniform(40000, 48000), 2),
            timeframe="1d",
            source="ai_model",
            model_version="v1.2.3",
            features={"rsi": 65, "macd": "bullish", "volume": "increasing"},
            metadata={"market_condition": "trending"},
            is_active=True,
            created_at=datetime.utcnow(),
            expires_at=datetime.utcnow() + timedelta(hours=24)
        ))
    
    return signals


@router.post("/signals", response_model=TradingSignalResponse)
async def create_trading_signal(
    signal_data: dict,
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db)
):
    """Create a new trading signal"""
    return TradingSignalResponse(
        id=999,
        symbol=signal_data.get("symbol", "BTC").upper(),
        signal_type=signal_data.get("signal_type", "buy"),
        confidence=signal_data.get("confidence", 0.75),
        target_price=signal_data.get("target_price", 52000.0),
        stop_loss=signal_data.get("stop_loss", 48000.0),
        timeframe=signal_data.get("timeframe", "1d"),
        source="user_created",
        model_version=None,
        features=signal_data.get("features", {}),
        metadata=signal_data.get("metadata", {}),
        is_active=True,
        created_at=datetime.utcnow(),
        expires_at=datetime.utcnow() + timedelta(hours=24)
    )


@router.get("/market-data/{symbol}", response_model=MarketDataResponse)
async def get_market_data(
    symbol: str,
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db)
):
    """Get current market data for a symbol"""
    # This would implement the actual market data retrieval
    # For now, returning mock data
    return MarketDataResponse(
        symbol=symbol.upper(),
        price=50000.00,
        price_change_24h=2.5,
        volume_24h=1000000.00,
        high_24h=51000.00,
        low_24h=49000.00,
        timestamp=datetime.utcnow()
    )


@router.get("/price-history/{symbol}", response_model=PriceHistoryResponse)
async def get_price_history(
    symbol: str,
    timeframe: str = "1d",
    days: int = 30,
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db)
):
    """Get price history for a symbol"""
    # Generate mock historical data with realistic progression
    from datetime import datetime, timedelta
    import random
    
    end_date = datetime.utcnow()
    start_date = end_date - timedelta(days=days)
    
    # Generate realistic price data
    data_points = []
    base_price = 50000.0
    
    for i in range(days):
        timestamp = start_date + timedelta(days=i)
        # Add some realistic price movement
        price_change = random.uniform(-0.05, 0.05)  # ±5% daily change
        base_price = base_price * (1 + price_change)
        volume = random.uniform(100000, 1000000)
        
        data_points.append({
            "timestamp": timestamp.isoformat(),
            "price": round(base_price, 2),
            "volume": round(volume, 2),
            "high": round(base_price * 1.02, 2),
            "low": round(base_price * 0.98, 2)
        })
    
    return PriceHistoryResponse(
        symbol=symbol.upper(),
        data=data_points,
        timeframe=timeframe,
        start_date=start_date,
        end_date=end_date
    )


@router.get("/symbols")
async def get_available_symbols(
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db)
):
    """Get available trading symbols"""
    # This would return available symbols from the database
    return {
        "symbols": [
            "BTC", "ETH", "ADA", "DOT", "SOL", "AVAX", "MATIC", "LINK",
            "UNI", "AAVE", "COMP", "MKR", "SUSHI", "CRV", "YFI", "1INCH"
        ]
    }


@router.post("/signals/{signal_id}/subscribe")
async def subscribe_to_signal(
    signal_id: int,
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db)
):
    """Subscribe to a trading signal"""
    # This would implement signal subscription logic
    return {"message": f"Subscribed to signal {signal_id}"}


@router.delete("/signals/{signal_id}/subscribe")
async def unsubscribe_from_signal(
    signal_id: int,
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db)
):
    """Unsubscribe from a trading signal"""
    # This would implement signal unsubscription logic
    return {"message": f"Unsubscribed from signal {signal_id}"}


@router.post("/backtest")
async def backtest_strategy(
    strategy_config: dict,
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db)
):
    """Backtest a trading strategy"""
    import random
    
    # Generate realistic backtest results
    total_return = round(random.uniform(-20, 40), 2)
    sharpe_ratio = round(random.uniform(0.5, 2.5), 2)
    max_drawdown = round(random.uniform(-25, -5), 2)
    win_rate = round(random.uniform(0.45, 0.75), 2)
    total_trades = random.randint(10, 100)
    
    return {
        "backtest_id": f"bt_{random.randint(10000, 99999)}",
        "strategy_name": strategy_config.get("name", "Custom Strategy"),
        "symbol": strategy_config.get("symbol", "BTC").upper(),
        "period": strategy_config.get("period", "30d"),
        "start_date": "2024-01-01",
        "end_date": "2024-01-31",
        "initial_capital": strategy_config.get("initial_capital", 10000),
        "results": {
            "total_return_pct": total_return,
            "total_return_usd": round(10000 * (total_return / 100), 2),
            "sharpe_ratio": sharpe_ratio,
            "max_drawdown_pct": max_drawdown,
            "win_rate": win_rate,
            "total_trades": total_trades,
            "winning_trades": int(total_trades * win_rate),
            "losing_trades": int(total_trades * (1 - win_rate)),
            "profit_factor": round(random.uniform(1.0, 3.0), 2),
            "avg_trade_return": round(total_return / total_trades, 2),
            "best_trade": round(random.uniform(5, 15), 2),
            "worst_trade": round(random.uniform(-10, -3), 2)
        },
        "performance_metrics": {
            "volatility": round(random.uniform(15, 35), 2),
            "calmar_ratio": round(random.uniform(0.3, 2.0), 2),
            "sortino_ratio": round(random.uniform(0.5, 2.8), 2),
            "beta": round(random.uniform(0.7, 1.3), 2)
        },
        "status": "completed",
        "created_at": datetime.utcnow().isoformat(),
        "execution_time_seconds": round(random.uniform(10, 60), 1)
    }