from typing import Dict, Set
from fastapi import APIRouter, WebSocket, WebSocketDisconnect, HTTPException, Depends
from fastapi.responses import HTMLResponse
import asyncio
import json
import logging
from datetime import datetime
from app.services.api_key_service import ApiKeyService
from app.db.session import get_db
from sqlalchemy.orm import Session

logger = logging.getLogger(__name__)

router = APIRouter()

# Connection manager for WebSocket connections
class ConnectionManager:
    def __init__(self):
        self.active_connections: Dict[str, Set[WebSocket]] = {}
    
    async def connect(self, websocket: WebSocket, symbol: str = "all"):
        await websocket.accept()
        if symbol not in self.active_connections:
            self.active_connections[symbol] = set()
        self.active_connections[symbol].add(websocket)
        logger.info(f"WebSocket connected for symbol: {symbol}")
    
    def disconnect(self, websocket: WebSocket, symbol: str = "all"):
        if symbol in self.active_connections:
            self.active_connections[symbol].discard(websocket)
            if not self.active_connections[symbol]:
                del self.active_connections[symbol]
        logger.info(f"WebSocket disconnected for symbol: {symbol}")
    
    async def send_personal_message(self, message: str, websocket: WebSocket):
        await websocket.send_text(message)
    
    async def broadcast_to_symbol(self, message: str, symbol: str):
        if symbol in self.active_connections:
            disconnected = []
            for connection in self.active_connections[symbol]:
                try:
                    await connection.send_text(message)
                except:
                    disconnected.append(connection)
            
            # Remove disconnected connections
            for conn in disconnected:
                self.active_connections[symbol].discard(conn)

manager = ConnectionManager()

# Mock ticker data - in production this would come from real APIs
async def get_ticker_data(db: Session):
    """Get real ticker data from CoinGecko"""
    try:
        from app.services.coingecko_service import CoinGeckoService
        
        coingecko = CoinGeckoService(db)
        
        # Get prices for BTC and ETH
        symbols = ["bitcoin", "ethereum"]  # CoinGecko IDs
        ticker_data = await coingecko.get_price(symbols)
        
        # Transform to match our format
        tickers = {}
        symbol_mapping = {"bitcoin": "BTC", "ethereum": "ETH"}
        
        for cg_id, symbol in symbol_mapping.items():
            if cg_id in ticker_data:
                data = ticker_data[cg_id]
                tickers[symbol] = {
                    "symbol": symbol,
                    "price": data["price"],
                    "change_24h": data["change_24h"],
                    "volume_24h": 0,  # Would need separate API call for volume
                    "timestamp": data["timestamp"],
                    "source": data["source"]
                }
        
        return tickers
        
    except Exception as e:
        logger.error(f"Error getting real ticker data: {e}")
        # Fallback to mock data
        import random
        
        base_prices = {
            "BTC": 45000,
            "ETH": 3000,
        }
        
        tickers = {}
        for symbol, base_price in base_prices.items():
            # Simulate price movement
            change_percent = (random.random() - 0.5) * 0.02  # -1% to +1%
            new_price = base_price * (1 + change_percent)
            
            tickers[symbol] = {
                "symbol": symbol,
                "price": round(new_price, 2),
                "change_24h": round(change_percent * 100, 2),
                "volume_24h": random.randint(1000000, 10000000),
                "timestamp": datetime.utcnow().isoformat(),
                "source": "mock"
            }
        
        return tickers

async def ticker_broadcaster():
    """Background task to broadcast ticker updates"""
    from app.db.session import SessionLocal
    
    while True:
        db = None
        try:
            db = SessionLocal()
            ticker_data = await get_ticker_data(db)
            
            # Broadcast to all subscribers
            for symbol, data in ticker_data.items():
                await manager.broadcast_to_symbol(
                    json.dumps(data), 
                    symbol.lower()
                )
            
            # Broadcast to "all" subscribers
            await manager.broadcast_to_symbol(
                json.dumps(ticker_data), 
                "all"
            )
            
            await asyncio.sleep(5)  # Update every 5 seconds to respect API limits
            
        except Exception as e:
            logger.error(f"Error in ticker broadcaster: {e}")
            await asyncio.sleep(10)  # Wait longer on error
        finally:
            if db:
                db.close()

# Start the broadcaster task globally
ticker_task = None

async def start_ticker_broadcaster():
    """Start the ticker broadcaster task"""
    global ticker_task
    if not ticker_task:
        ticker_task = asyncio.create_task(ticker_broadcaster())

async def stop_ticker_broadcaster():
    """Stop the ticker broadcaster task"""
    global ticker_task
    if ticker_task:
        ticker_task.cancel()
        try:
            await ticker_task
        except asyncio.CancelledError:
            pass
        ticker_task = None

@router.websocket("/ticker")
async def websocket_ticker_endpoint(websocket: WebSocket, symbol: str = "all"):
    """
    WebSocket endpoint for real-time ticker data
    
    Query parameters:
    - symbol: Specific symbol to subscribe to (e.g., "btc", "eth") or "all" for all symbols
    """
    await manager.connect(websocket, symbol.lower())
    try:
        while True:
            # Keep connection alive and handle any incoming messages
            data = await websocket.receive_text()
            
            # Handle ping/pong or subscription changes
            try:
                message = json.loads(data)
                if message.get("type") == "ping":
                    await websocket.send_text(json.dumps({"type": "pong"}))
                elif message.get("type") == "subscribe":
                    new_symbol = message.get("symbol", "all").lower()
                    manager.disconnect(websocket, symbol.lower())
                    await manager.connect(websocket, new_symbol)
                    symbol = new_symbol
            except json.JSONDecodeError:
                # If not JSON, just ignore
                pass
                
    except WebSocketDisconnect:
        manager.disconnect(websocket, symbol.lower())
    except Exception as e:
        logger.error(f"WebSocket error: {e}")
        manager.disconnect(websocket, symbol.lower())

@router.get("/ticker/test")
async def test_ticker_page():
    """Test page for WebSocket ticker functionality"""
    html_content = """
    <!DOCTYPE html>
    <html>
    <head>
        <title>Ticker WebSocket Test</title>
    </head>
    <body>
        <h1>Real-time Ticker Data</h1>
        <div id="messages"></div>
        <script>
            const ws = new WebSocket("ws://localhost:8000/api/v1/ws/ticker");
            
            ws.onmessage = function(event) {
                const messages = document.getElementById('messages');
                const message = document.createElement('div');
                message.textContent = new Date().toLocaleTimeString() + ': ' + event.data;
                messages.appendChild(message);
                messages.scrollTop = messages.scrollHeight;
            };
            
            ws.onopen = function(event) {
                console.log("WebSocket connected");
            };
            
            ws.onclose = function(event) {
                console.log("WebSocket disconnected");
            };
        </script>
    </body>
    </html>
    """
    return HTMLResponse(content=html_content)