# Import all schemas for easy access
from app.schemas.auth import Token, TokenData
from app.schemas.mcp import (HealthStatus, MarketDataUpdate, PortfolioUpdate,
                             ServiceHealth, SystemHealth, TaskInfo,
                             TaskRequest, TaskResponse, TaskStatus,
                             TradingSignalUpdate, WebSocketMessage)
from app.schemas.trading import (CryptoPriceDataBase, CryptoPriceDataCreate,
                                 CryptoPriceDataResponse, MarketDataResponse,
                                 PortfolioBase, PortfolioCreate,
                                 PortfolioResponse, PortfolioUpdate,
                                 PositionBase, PositionCreate,
                                 PositionResponse, PositionUpdate,
                                 PriceHistoryResponse, TradingSignalBase,
                                 TradingSignalCreate, TradingSignalResponse)
from app.schemas.user import (UserBase, UserCreate, UserLogin, UserResponse,
                              UserUpdate)

__all__ = [
    # User schemas
    "UserBase",
    "UserCreate",
    "UserUpdate",
    "UserLogin",
    "UserResponse",
    # Auth schemas
    "Token",
    "TokenData",
    # Trading schemas
    "CryptoPriceDataBase",
    "CryptoPriceDataCreate",
    "CryptoPriceDataResponse",
    "TradingSignalBase",
    "TradingSignalCreate",
    "TradingSignalResponse",
    "PortfolioBase",
    "PortfolioCreate",
    "PortfolioUpdate",
    "PortfolioResponse",
    "PositionBase",
    "PositionCreate",
    "PositionUpdate",
    "PositionResponse",
    "MarketDataResponse",
    "PriceHistoryResponse",
    # MCP schemas
    "HealthStatus",
    "ServiceHealth",
    "SystemHealth",
    "TaskStatus",
    "TaskInfo",
    "WebSocketMessage",
    "MarketDataUpdate",
    "TradingSignalUpdate",
    "PortfolioUpdate",
    "TaskRequest",
    "TaskResponse",
]
