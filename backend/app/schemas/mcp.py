from datetime import datetime
from enum import Enum
from typing import Any, Dict, List, Optional

from pydantic import BaseModel


class HealthStatus(str, Enum):
    """Health status enumeration"""

    HEALTHY = "healthy"
    UNHEALTHY = "unhealthy"
    DEGRADED = "degraded"


class ServiceHealth(BaseModel):
    """Individual service health schema"""

    name: str
    status: HealthStatus
    response_time_ms: Optional[float] = None
    details: Optional[Dict[str, Any]] = None
    last_checked: datetime


class SystemHealth(BaseModel):
    """Overall system health schema"""

    status: HealthStatus
    services: List[ServiceHealth]
    timestamp: datetime


class TaskStatus(str, Enum):
    """Task status enumeration"""

    PENDING = "pending"
    RUNNING = "running"
    SUCCESS = "success"
    FAILURE = "failure"
    RETRYING = "retrying"


class TaskInfo(BaseModel):
    """Task information schema"""

    task_id: str
    name: str
    status: TaskStatus
    created_at: datetime
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    result: Optional[Dict[str, Any]] = None
    error: Optional[str] = None


class MarketDataUpdate(BaseModel):
    """Market data update schema"""

    symbol: str
    price: float
    volume: float
    change_24h: float
    timestamp: datetime


class TradingSignalUpdate(BaseModel):
    """Trading signal update schema"""

    signal_id: str
    symbol: str
    action: str  # buy, sell, hold
    confidence: float
    price_target: Optional[float] = None
    stop_loss: Optional[float] = None
    timestamp: datetime


class PortfolioUpdate(BaseModel):
    """Portfolio update schema"""

    user_id: int
    portfolio_id: str
    total_value: float
    positions: List[Dict[str, Any]]
    timestamp: datetime


class WebSocketMessage(BaseModel):
    """WebSocket message schema"""

    type: str  # market_data, trading_signal, portfolio_update, task_status
    data: Dict[str, Any]
    timestamp: datetime
    user_id: Optional[int] = None  # For user-specific messages


class TaskRequest(BaseModel):
    """Task request schema"""

    task_name: str
    parameters: Optional[Dict[str, Any]] = None
    priority: Optional[int] = 1


class TaskResponse(BaseModel):
    """Task response schema"""

    task_id: str
    status: TaskStatus
    message: str
