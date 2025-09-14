"""
Master Control Program (MCP) module

This module provides the core functionality for the MCP server including:
- Task orchestration and scheduling
- Real-time data processing and broadcasting
- System health monitoring
- WebSocket communication
"""

from app.schemas.mcp import (HealthStatus, MarketDataUpdate, PortfolioUpdate,
                             ServiceHealth, SystemHealth, TaskInfo, TaskStatus,
                             TradingSignalUpdate, WebSocketMessage)
from app.services.mcp_service import MCPService

__all__ = [
    "MCPService",
    "HealthStatus",
    "ServiceHealth",
    "SystemHealth",
    "TaskStatus",
    "TaskInfo",
    "WebSocketMessage",
    "MarketDataUpdate",
    "TradingSignalUpdate",
    "PortfolioUpdate",
]
