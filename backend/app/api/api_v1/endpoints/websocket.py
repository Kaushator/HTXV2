"""
WebSocket API для коммуникации с MCP Service.
"""
import asyncio
import logging
import json
import uuid
from typing import Dict, Any, List, Optional

from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends, Query
from app.services.mcp_service import get_mcp_service, MCPService

logger = logging.getLogger(__name__)

# Создаем роутер для WebSocket API
router = APIRouter()

@router.websocket("/ws")
@router.websocket("/ws/mcp")
async def websocket_endpoint(
    websocket: WebSocket,
    topics: str = Query(None),  # Опциональные топики для подписки через query параметры
    mcp_service: MCPService = Depends(get_mcp_service)
):
    """
    WebSocket эндпоинт для коммуникации с MCP Service.
    
    Args:
        websocket: WebSocket соединение
        topics: Список топиков для автоматической подписки (через запятую)
        mcp_service: Экземпляр MCP Service
    """
    client_id = str(uuid.uuid4())
    await websocket.accept()
    
    # Регистрируем соединение в MCP
    await mcp_service.register_connection(client_id, websocket)
    
    # Если указаны топики, автоматически подписываемся
    if topics:
        topics_list = [t.strip() for t in topics.split(",")]
        await mcp_service.handle_client_message(
            client_id, 
            {"type": "subscribe", "topics": topics_list}
        )
    
    try:
        # Обработка сообщений от клиента
        while True:
            # Ожидаем сообщение с таймаутом 1 час (для long-polling)
            try:
                data = await asyncio.wait_for(websocket.receive_json(), timeout=3600)
                await mcp_service.handle_client_message(client_id, data)
            except asyncio.TimeoutError:
                # Если таймаут, отправляем ping для проверки соединения
                try:
                    await websocket.send_json({"type": "ping"})
                except:
                    # Если не удалось отправить ping, соединение разорвано
                    break
    except WebSocketDisconnect:
        # Обрабатываем отключение клиента
        await mcp_service.unregister_connection(client_id)
        logger.info(f"Клиент {client_id} отключился")
    except Exception as e:
        # Обрабатываем другие ошибки
        logger.exception(f"Ошибка WebSocket: {e}")
        await mcp_service.unregister_connection(client_id)
        try:
            await websocket.close(code=1011, reason=f"Внутренняя ошибка: {str(e)}")
        except:
            pass