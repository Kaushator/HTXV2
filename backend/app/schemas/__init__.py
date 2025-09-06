# Import all schemas for easy access
from app.schemas.user import UserBase, UserCreate, UserUpdate, UserLogin, UserResponse
from app.schemas.auth import Token, TokenData
from app.schemas.trading import (
    CryptoPriceDataBase, CryptoPriceDataCreate, CryptoPriceDataResponse,
    TradingSignalBase, TradingSignalCreate, TradingSignalResponse,
    PortfolioBase, PortfolioCreate, PortfolioUpdate, PortfolioResponse,
    PositionBase, PositionCreate, PositionUpdate, PositionResponse,
    MarketDataResponse, PriceHistoryResponse
)

__all__ = [
    # User schemas
    "UserBase", "UserCreate", "UserUpdate", "UserLogin", "UserResponse",
    # Auth schemas
    "Token", "TokenData",
    # Trading schemas
    "CryptoPriceDataBase", "CryptoPriceDataCreate", "CryptoPriceDataResponse",
    "TradingSignalBase", "TradingSignalCreate", "TradingSignalResponse",
    "PortfolioBase", "PortfolioCreate", "PortfolioUpdate", "PortfolioResponse",
    "PositionBase", "PositionCreate", "PositionUpdate", "PositionResponse",
    "MarketDataResponse", "PriceHistoryResponse"
]