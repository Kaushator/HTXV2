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
from app.schemas.mcp import (
    HealthStatus, ServiceHealth, SystemHealth,
    TaskStatus, TaskInfo, WebSocketMessage,
    MarketDataUpdate, TradingSignalUpdate, PortfolioUpdate,
    TaskRequest, TaskResponse
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
    "MarketDataResponse", "PriceHistoryResponse",
    # MCP schemas
    "HealthStatus", "ServiceHealth", "SystemHealth",
    "TaskStatus", "TaskInfo", "WebSocketMessage",
    "MarketDataUpdate", "TradingSignalUpdate", "PortfolioUpdate",
    "TaskRequest", "TaskResponse"
]