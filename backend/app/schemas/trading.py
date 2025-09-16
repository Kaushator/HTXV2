from datetime import datetime
from decimal import Decimal
from typing import List, Optional

from pydantic import BaseModel


class CryptoPriceDataBase(BaseModel):
    """Base crypto price data schema"""

    symbol: str
    exchange: str
    price: Decimal
    volume_24h: Optional[Decimal] = None
    market_cap: Optional[Decimal] = None
    price_change_24h: Optional[Decimal] = None
    high_24h: Optional[Decimal] = None
    low_24h: Optional[Decimal] = None
    circulating_supply: Optional[Decimal] = None
    total_supply: Optional[Decimal] = None
    data_source: str


class CryptoPriceDataCreate(CryptoPriceDataBase):
    """Crypto price data creation schema"""

    timestamp: datetime
    metadata: Optional[dict] = None


class CryptoPriceDataResponse(CryptoPriceDataBase):
    """Crypto price data response schema"""

    id: int
    timestamp: datetime
    metadata: Optional[dict] = None
    created_at: datetime

    class Config:
        from_attributes = True


class TradingSignalBase(BaseModel):
    """Base trading signal schema"""

    symbol: str
    signal_type: str  # buy, sell, hold
    confidence: Decimal
    target_price: Optional[Decimal] = None
    stop_loss: Optional[Decimal] = None
    timeframe: str
    source: str


class TradingSignalCreate(TradingSignalBase):
    """Trading signal creation schema"""

    model_version: Optional[str] = None
    features: Optional[dict] = None
    metadata: Optional[dict] = None
    expires_at: Optional[datetime] = None


class TradingSignalResponse(TradingSignalBase):
    """Trading signal response schema"""

    id: int
    model_version: Optional[str] = None
    features: Optional[dict] = None
    metadata: Optional[dict] = None
    is_active: bool
    created_at: datetime
    expires_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class PortfolioBase(BaseModel):
    """Base portfolio schema"""

    name: str
    description: Optional[str] = None
    base_currency: str = "USD"
    risk_tolerance: str = "medium"


class PortfolioCreate(PortfolioBase):
    """Portfolio creation schema"""

    pass


class PortfolioUpdate(BaseModel):
    """Portfolio update schema"""

    name: Optional[str] = None
    description: Optional[str] = None
    base_currency: Optional[str] = None
    risk_tolerance: Optional[str] = None


class PortfolioResponse(PortfolioBase):
    """Portfolio response schema"""

    id: int
    user_id: int
    is_active: bool
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class PositionBase(BaseModel):
    """Base position schema"""

    symbol: str
    quantity: Decimal
    average_price: Decimal
    position_type: str = "long"


class PositionCreate(PositionBase):
    """Position creation schema"""

    portfolio_id: int


class PositionUpdate(BaseModel):
    """Position update schema"""

    quantity: Optional[Decimal] = None
    average_price: Optional[Decimal] = None
    current_price: Optional[Decimal] = None


class PositionResponse(PositionBase):
    """Position response schema"""

    id: int
    portfolio_id: int
    current_price: Optional[Decimal] = None
    unrealized_pnl: Optional[Decimal] = None
    realized_pnl: Decimal
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class MarketDataResponse(BaseModel):
    """Market data response schema"""

    symbol: str
    price: Decimal
    price_change_24h: Optional[Decimal] = None
    volume_24h: Optional[Decimal] = None
    high_24h: Optional[Decimal] = None
    low_24h: Optional[Decimal] = None
    timestamp: datetime


class PriceHistoryResponse(BaseModel):
    """Price history response schema"""

    symbol: str
    data: List[dict]  # List of {timestamp, price, volume} objects
    timeframe: str
    start_date: datetime
    end_date: datetime
