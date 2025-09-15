import asyncio
import json
import logging
import uuid
from datetime import datetime
from typing import Dict, Set

from fastapi import (APIRouter, Depends, HTTPException, WebSocket,
                     WebSocketDisconnect, status)
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.rate_limit import websocket_rate_limit
from app.core.security import get_current_user_websocket
from app.db.session import get_db
from app.models.user import User
from app.schemas.mcp import MarketDataUpdate, WebSocketMessage

router = APIRouter()
logger = logging.getLogger(__name__)

# Active WebSocket connections per symbol
symbol_connections: Dict[str, Set[WebSocket]] = {}
# Connection metadata
connection_metadata: Dict[WebSocket, Dict] = {}


class WebSocketManager:
    """Manages WebSocket connections for real-time market data"""

    def __init__(self):
        self.connections: Set[WebSocket] = set()
        self.symbol_subscriptions: Dict[str, Set[WebSocket]] = {}

    async def connect(self, websocket: WebSocket, symbol: str, user: User):
        """Accept a new WebSocket connection"""
        await websocket.accept()
        self.connections.add(websocket)

        # Add to symbol subscriptions
        if symbol not in self.symbol_subscriptions:
            self.symbol_subscriptions[symbol] = set()
        self.symbol_subscriptions[symbol].add(websocket)

        # Store connection metadata
        connection_metadata[websocket] = {
            "user_id": user.id,
            "symbol": symbol,
            "connected_at": datetime.utcnow(),
            "last_ping": datetime.utcnow(),
        }

        logger.info(f"User {user.id} connected to WebSocket for symbol {symbol}")

    def disconnect(self, websocket: WebSocket):
        """Remove a WebSocket connection"""
        self.connections.discard(websocket)

        # Remove from symbol subscriptions
        metadata = connection_metadata.get(websocket)
        if metadata:
            symbol = metadata["symbol"]
            if symbol in self.symbol_subscriptions:
                self.symbol_subscriptions[symbol].discard(websocket)
                # Clean up empty symbol subscription
                if not self.symbol_subscriptions[symbol]:
                    del self.symbol_subscriptions[symbol]

        # Clean up metadata
        connection_metadata.pop(websocket, None)

        if metadata:
            logger.info(
                f"User {metadata['user_id']} disconnected from WebSocket for symbol {metadata['symbol']}"
            )

    async def send_to_symbol(self, symbol: str, message: dict):
        """Send message to all connections subscribed to a symbol"""
        if symbol not in self.symbol_subscriptions:
            return

        disconnected = set()
        for websocket in self.symbol_subscriptions[symbol]:
            try:
                await websocket.send_text(json.dumps(message))
            except Exception:
                disconnected.add(websocket)

        # Clean up disconnected connections
        for websocket in disconnected:
            self.disconnect(websocket)

    async def send_to_connection(self, websocket: WebSocket, message: dict):
        """Send message to a specific connection"""
        try:
            await websocket.send_text(json.dumps(message))
        except Exception:
            self.disconnect(websocket)

    async def broadcast(self, message: dict):
        """Broadcast message to all connections"""
        disconnected = set()
        for websocket in self.connections:
            try:
                await websocket.send_text(json.dumps(message))
            except Exception:
                disconnected.add(websocket)

        # Clean up disconnected connections
        for websocket in disconnected:
            self.disconnect(websocket)


# Global WebSocket manager instance
websocket_manager = WebSocketManager()


@router.websocket("/market-data/{symbol}")
async def market_data_websocket(websocket: WebSocket, symbol: str, token: str = None):
    """WebSocket endpoint for real-time market data updates"""

    # Authenticate the connection
    try:
        user = await get_current_user_websocket(token)
        if not user:
            await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
            return
    except Exception as e:
        logger.error(f"WebSocket authentication failed: {e}")
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
        return

    # Validate symbol format
    symbol = symbol.upper()
    if not symbol or len(symbol) < 3:
        await websocket.close(code=status.WS_1003_UNSUPPORTED_DATA)
        return

    await websocket_manager.connect(websocket, symbol, user)

    try:
        # Send initial connection confirmation
        await websocket_manager.send_to_connection(
            websocket,
            {
                "type": "connection_established",
                "symbol": symbol,
                "timestamp": datetime.utcnow().isoformat(),
                "message": f"Connected to {symbol} market data feed",
            },
        )

        # Send initial market data if available
        await send_current_market_data(websocket, symbol)

        # Keep connection alive and handle incoming messages
        while True:
            try:
                # Wait for messages with timeout for ping/pong
                message = await asyncio.wait_for(websocket.receive_text(), timeout=30.0)

                data = json.loads(message)
                await handle_websocket_message(websocket, data, symbol, user)

            except asyncio.TimeoutError:
                # Send ping to keep connection alive
                await websocket_manager.send_to_connection(
                    websocket,
                    {"type": "ping", "timestamp": datetime.utcnow().isoformat()},
                )

            except json.JSONDecodeError:
                await websocket_manager.send_to_connection(
                    websocket,
                    {
                        "type": "error",
                        "message": "Invalid JSON format",
                        "timestamp": datetime.utcnow().isoformat(),
                    },
                )

    except WebSocketDisconnect:
        logger.info(f"WebSocket disconnected for symbol {symbol}")
    except Exception as e:
        logger.error(f"WebSocket error for symbol {symbol}: {e}")
    finally:
        websocket_manager.disconnect(websocket)


async def handle_websocket_message(
    websocket: WebSocket, data: dict, symbol: str, user: User
):
    """Handle incoming WebSocket messages"""
    message_type = data.get("type")

    if message_type == "pong":
        # Update last ping time
        if websocket in connection_metadata:
            connection_metadata[websocket]["last_ping"] = datetime.utcnow()

    elif message_type == "subscribe_additional":
        # Handle subscription to additional symbols (future feature)
        await websocket_manager.send_to_connection(
            websocket,
            {
                "type": "error",
                "message": "Additional subscriptions not implemented yet",
                "timestamp": datetime.utcnow().isoformat(),
            },
        )

    elif message_type == "request_history":
        # Handle historical data request
        await send_price_history(websocket, symbol, data.get("timeframe", "1h"))

    else:
        await websocket_manager.send_to_connection(
            websocket,
            {
                "type": "error",
                "message": f"Unknown message type: {message_type}",
                "timestamp": datetime.utcnow().isoformat(),
            },
        )


async def send_current_market_data(websocket: WebSocket, symbol: str):
    """Send current market data for the symbol"""
    # This would fetch real market data from the database or external API
    # For now, sending mock data
    market_data = {
        "type": "market_data",
        "symbol": symbol,
        "price": 50000.00 if symbol == "BTCUSDT" else 3000.00,
        "change_24h": 2.5,
        "volume_24h": 1000000.00,
        "high_24h": 51000.00 if symbol == "BTCUSDT" else 3100.00,
        "low_24h": 49000.00 if symbol == "BTCUSDT" else 2900.00,
        "timestamp": datetime.utcnow().isoformat(),
    }

    await websocket_manager.send_to_connection(websocket, market_data)


async def send_price_history(websocket: WebSocket, symbol: str, timeframe: str):
    """Send price history data"""
    # This would fetch real historical data
    # For now, sending mock data
    history_data = {
        "type": "price_history",
        "symbol": symbol,
        "timeframe": timeframe,
        "data": [
            {
                "timestamp": datetime.utcnow().isoformat(),
                "price": 50000.00,
                "volume": 1000.0,
            }
        ],
        "timestamp": datetime.utcnow().isoformat(),
    }

    await websocket_manager.send_to_connection(websocket, history_data)


# Public function to broadcast market data updates
async def broadcast_market_data_update(symbol: str, market_data: MarketDataUpdate):
    """Broadcast market data update to all subscribers of a symbol"""
    message = {
        "type": "market_data_update",
        "symbol": symbol,
        "price": market_data.price,
        "volume": market_data.volume,
        "change_24h": market_data.change_24h,
        "timestamp": market_data.timestamp.isoformat(),
    }

    await websocket_manager.send_to_symbol(symbol, message)


@router.get("/connections")
async def get_active_connections(
    current_user: User = Depends(get_current_user_websocket),
):
    """Get information about active WebSocket connections (admin only)"""
    if not current_user.is_superuser:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only superusers can view connection information",
        )

    connections_info = []
    for websocket, metadata in connection_metadata.items():
        connections_info.append(
            {
                "user_id": metadata["user_id"],
                "symbol": metadata["symbol"],
                "connected_at": metadata["connected_at"].isoformat(),
                "last_ping": metadata["last_ping"].isoformat(),
            }
        )

    return {
        "total_connections": len(connection_metadata),
        "symbol_subscriptions": {
            symbol: len(connections)
            for symbol, connections in websocket_manager.symbol_subscriptions.items()
        },
        "connections": connections_info,
    }
