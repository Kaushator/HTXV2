"""
MCP - Simplified API for tests
"""
#!/usr/bin/env python3
"""
Simplified version of main.py for testing MCP
"""

import logging
import uuid
from typing import Dict, Any

from fastapi import FastAPI, WebSocket, WebSocketDisconnect, Depends
from fastapi.middleware.cors import CORSMiddleware

from app.services.mcp_service import get_mcp_service, MCPService

# Настройка логирования
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)

# Создание приложения FastAPI
app = FastAPI(
    title="MCP Tester",
    description="Тестовое приложение для MCP",
    version="0.1.0",
)

# Настройка CORS для фронтенда
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/api/health")
async def health_check():
    """Проверка работоспособности API."""
    return {"status": "ok", "service": "MCP Tester"}

@app.websocket("/ws/mcp")
async def websocket_endpoint(
    websocket: WebSocket,
    mcp_service: MCPService = Depends(get_mcp_service)
):
    """
    WebSocket эндпоинт для коммуникации с MCP Service.
    """
    client_id = str(uuid.uuid4())
    await websocket.accept()
    
    await mcp_service.register_connection(client_id, websocket)
    
    try:
        while True:
            data = await websocket.receive_json()
            await mcp_service.handle_client_message(client_id, data)
    except WebSocketDisconnect:
        await mcp_service.unregister_connection(client_id)
    except Exception as e:
        logging.error(f"WebSocket error: {e}")
        await mcp_service.unregister_connection(client_id)

@app.on_event("startup")
async def startup_event():
    """Действия при запуске приложения."""
    logging.info("Starting MCP Tester")
    
    # Инициализация MCP Service
    await get_mcp_service()

@app.on_event("shutdown")
async def shutdown_event():
    """Действия при остановке приложения."""
    logging.info("Shutting down MCP Tester")
    
    # Остановка MCP Service
    mcp_service = await get_mcp_service()
    await mcp_service.stop()