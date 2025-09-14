#!/usr/bin/env python3
"""
MCP Service - Master Control Program для управления потоками данных и задач.

Этот сервис обеспечивает координацию между различными компонентами системы,
включая WebSocket для real-time данных и управление задачами.

Версия 2.0 с улучшенной системой кэширования, обработкой ошибок и мониторингом ресурсов.
"""

import asyncio
import logging
import uuid
import json
import time
from typing import Dict, List, Any, Optional, Union, Callable
from datetime import datetime, timedelta
from functools import wraps

import redis.asyncio as redis
from pydantic import BaseModel, Field

from app.services.mcp_errors import (
    MCPError, MCPConnectionError, MCPDataError,
    MCPTaskError, MCPCacheError, MCPWebSocketError
)
from app.services.mcp_utils import with_retry, measure_execution_time, ResourceMonitor

logger = logging.getLogger(__name__)

# Модели данных для MCP
class MCPTask(BaseModel):
    """Модель задачи для MCP."""
    task_id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    name: str
    status: str = "pending"
    created_at: datetime = Field(default_factory=datetime.now)
    updated_at: datetime = Field(default_factory=datetime.now)
    params: Dict[str, Any] = {}
    result: Optional[Dict[str, Any]] = None
    error: Optional[str] = None

class MCPSubscription(BaseModel):
    """Модель подписки на события MCP."""
    client_id: str
    topics: List[str]
    created_at: datetime = Field(default_factory=datetime.now)

class MCPCacheItem(BaseModel):
    """Модель элемента кэша MCP."""
    key: str
    value: Any
    ttl: Optional[int] = None
    created_at: datetime = Field(default_factory=datetime.now)
    expires_at: Optional[datetime] = None

class MCPService:
    """Master Control Program Service для централизованного управления задачами."""
    
    def __init__(self, redis_url: str = "redis://localhost:6379/1", 
               max_connections: int = 1000,
               enable_monitoring: bool = True):
        self.active_connections: Dict[str, Any] = {}
        self.tasks: Dict[str, asyncio.Task] = {}
        self.data_cache: Dict[str, Any] = {}
        self.subscriptions: Dict[str, List[str]] = {}  # client_id -> list of topics
        self.redis_url = redis_url
        self.redis: Optional[redis.Redis] = None
        
        # Новые параметры
        self.max_connections = max_connections  # Максимальное количество WebSocket подключений
        self.enable_monitoring = enable_monitoring
        self.resource_monitor = ResourceMonitor(history_size=120)  # 2 часа истории с шагом в минуту
        self.reconnect_attempts = 0  # Счетчик попыток переподключения к Redis
        self.local_cache_size = 0  # Счетчик размера локального кэша
        
        logger.info("MCP Service initialized")
    
    async def start(self):
        """Запуск MCP сервиса."""
        logger.info("Starting MCP Service")
        
        # Запоминаем время старта для расчета uptime
        self.start_time = time.time()
        
        # Инициализация Redis соединения
        try:
            self.redis = redis.from_url(self.redis_url, decode_responses=True)
            await self.redis.ping()
            logger.info("Redis connection established")
            self.reconnect_attempts = 0  # Сбрасываем счетчик при успешном подключении
        except Exception as e:
            logger.warning(f"Redis connection failed: {e}, using in-memory cache")
            self.redis = None
            self.reconnect_attempts += 1  # Увеличиваем счетчик попыток
        
        # Запуск фоновых задач
        self.background_task = asyncio.create_task(self._background_worker())
        self.cleanup_task = asyncio.create_task(self._cleanup_worker())
        
        # Инициализация статистики кэша
        self.local_cache_size = 0
        
        return self
    
    async def stop(self):
        """Остановка MCP сервиса."""
        logger.info("Stopping MCP Service")
        if hasattr(self, 'background_task'):
            self.background_task.cancel()
            try:
                await self.background_task
            except asyncio.CancelledError:
                pass
                
        if hasattr(self, 'cleanup_task'):
            self.cleanup_task.cancel()
            try:
                await self.cleanup_task
            except asyncio.CancelledError:
                pass
                
        # Отмена всех активных задач
        for task_id, task in list(self.tasks.items()):
            task.cancel()
            try:
                await task
            except asyncio.CancelledError:
                pass
            self.tasks.pop(task_id, None)
            
        # Закрытие Redis соединения
        if self.redis:
            await self.redis.close()
            logger.info("Redis connection closed")
            
        logger.info("MCP Service stopped")
    
    @measure_execution_time
    async def register_connection(self, client_id: str, connection: Any):
        """Регистрация нового WebSocket-соединения с проверкой лимита подключений."""
        try:
            # Проверяем лимит подключений
            if len(self.active_connections) >= self.max_connections:
                error_message = f"Connection limit reached ({self.max_connections})"
                logger.warning(f"Rejected connection from {client_id}: {error_message}")
                
                # Отправляем сообщение об ошибке перед закрытием
                try:
                    await connection.send_json({
                        "type": "error",
                        "error": "too_many_connections",
                        "message": error_message,
                        "timestamp": datetime.now().isoformat()
                    })
                except Exception:
                    pass
                
                # Закрываем соединение
                try:
                    await connection.close(code=1013, reason=error_message)  # 1013 - Try Again Later
                except Exception:
                    pass
                
                raise MCPConnectionError(
                    message="Connection limit exceeded",
                    context={"client_id": client_id, "connections_count": len(self.active_connections)}
                )
            
            # Регистрируем подключение
            self.active_connections[client_id] = connection
            
            # Инициализация подписок для клиента
            if client_id not in self.subscriptions:
                self.subscriptions[client_id] = []
            
            # Обновляем метрики
            if self.enable_monitoring:
                self.resource_monitor.collect_metrics(len(self.active_connections))
            
            logger.info(f"Registered connection for client {client_id} (active: {len(self.active_connections)})")
            
            # Отправляем приветственное сообщение
            await self.send_message(client_id, {
                "type": "welcome",
                "message": "Connected to MCP Service",
                "client_id": client_id,
                "timestamp": datetime.now().isoformat()
            })
        except MCPError:
            # Пробрасываем наши ошибки дальше
            raise
        except Exception as e:
            # Оборачиваем остальные ошибки
            raise MCPConnectionError(
                message="Failed to register connection",
                context={"client_id": client_id},
                original_error=e
            ) from e
    
    async def unregister_connection(self, client_id: str):
        """Удаление WebSocket-соединения."""
        self.active_connections.pop(client_id, None)
        logger.info(f"Unregistered connection for client {client_id}")
    
    @measure_execution_time
    async def send_message(self, client_id: str, message: Dict[str, Any], max_attempts: int = 3) -> bool:
        """
        Отправка сообщения клиенту через WebSocket с повторными попытками.
        
        Args:
            client_id: Идентификатор клиента
            message: Сообщение для отправки
            max_attempts: Максимальное количество попыток (по умолчанию 3)
            
        Returns:
            bool: True в случае успешной отправки, иначе False
        """
        connection = self.active_connections.get(client_id)
        if not connection:
            logger.warning(f"No active connection for client {client_id}")
            return False
        
        try:
            # Добавляем timestamp, если его еще нет
            if "timestamp" not in message:
                message["timestamp"] = datetime.now().isoformat()
            
            # Определяем функцию для отправки
            async def send_attempt():
                await connection.send_json(message)
            
            # Отправляем с повторными попытками
            context = {
                "client_id": client_id, 
                "message_type": message.get("type", "unknown")
            }
            
            await with_retry(
                send_attempt, 
                max_attempts=max_attempts,
                base_delay=0.1,
                context=context,
                exception_types=(Exception,)  # Любые исключения
            )
            
            logger.debug(f"Sent {message.get('type')} message to client {client_id}")
            return True
            
        except Exception as e:
            logger.error(
                f"Failed to send {message.get('type')} message to client {client_id} after {max_attempts} attempts: {e}",
                exc_info=True
            )
            
            # Если соединение похоже разорвано, удаляем его
            if "connection" in str(e).lower() or "closed" in str(e).lower():
                logger.info(f"Connection appears broken for client {client_id}, removing")
                await self.unregister_connection(client_id)
                
            return False
    
    @measure_execution_time
    async def broadcast_message(self, message: Dict[str, Any], 
                               exclude: Optional[List[str]] = None,
                               topics: Optional[List[str]] = None,
                               max_concurrency: int = 10):
        """
        Рассылка сообщения всем подключенным клиентам с ограничением конкурентности.
        
        Args:
            message: Сообщение для рассылки
            exclude: Список ID клиентов, которым не нужно отправлять сообщение
            topics: Список топиков для фильтрации (отправка только подписчикам этих топиков)
            max_concurrency: Максимальное количество одновременных отправок
        """
        exclude = exclude or []
        topics = topics or []
        
        # Добавляем timestamp, если его еще нет
        if "timestamp" not in message:
            message["timestamp"] = datetime.now().isoformat()
            
        # Создаем семафор для ограничения конкурентных задач
        semaphore = asyncio.Semaphore(max_concurrency)
        
        # Подготавливаем задачи отправки
        send_tasks = []
        
        for client_id, connection in list(self.active_connections.items()):
            # Пропускаем исключенных клиентов
            if client_id in exclude:
                continue
                
            # Если указаны топики, проверяем подписку клиента
            if topics and not any(topic in self.subscriptions.get(client_id, []) for topic in topics):
                continue
                
            # Создаем задачу отправки с семафором
            async def send_with_semaphore(client):
                async with semaphore:
                    await self.send_message(client, message)
                    
            send_tasks.append(send_with_semaphore(client_id))
            
        # Запускаем все задачи отправки
        if send_tasks:
            try:
                # gather с return_exceptions=True не выбросит исключения
                await asyncio.gather(*send_tasks, return_exceptions=True)
                logger.info(f"Broadcast message sent to {len(send_tasks)} clients")
            except Exception as e:
                logger.error(f"Error during broadcast: {e}", exc_info=True)
    
    async def handle_client_message(self, client_id: str, message: Dict[str, Any]):
        """Обработка сообщения от клиента."""
        logger.info(f"Received message from client {client_id}: {message}")
        
        message_type = message.get("type")
        if message_type == "ping":
            await self.send_message(client_id, {"type": "pong", "timestamp": message.get("timestamp")})
        
        elif message_type == "subscribe":
            # Подписка на топики
            topics = message.get("topics", [])
            if not topics:
                await self.send_message(client_id, {
                    "type": "error",
                    "message": "No topics specified for subscription"
                })
                return
                
            # Сохраняем подписки клиента
            self.subscriptions[client_id] = topics
            
            # Отправляем подтверждение
            await self.send_message(client_id, {
                "type": "subscribed", 
                "topics": topics,
                "message": f"Subscribed to topics: {topics}"
            })
            
            # Отправляем последние данные из кэша, если есть
            for topic in topics:
                cached_data = await self.get_cached_data(f"topic_{topic}")
                if cached_data:
                    await self.send_message(client_id, {
                        "type": "data_update",
                        "topic": topic,
                        "data": cached_data,
                        "cached": True,
                        "timestamp": datetime.now().isoformat()
                    })
        
        elif message_type == "unsubscribe":
            # Отписка от топиков
            topics = message.get("topics", [])
            if not topics:
                # Отписываемся от всех топиков
                self.subscriptions.pop(client_id, None)
                await self.send_message(client_id, {
                    "type": "unsubscribed", 
                    "message": "Unsubscribed from all topics"
                })
            else:
                # Отписываемся от указанных топиков
                if client_id in self.subscriptions:
                    for topic in topics:
                        if topic in self.subscriptions[client_id]:
                            self.subscriptions[client_id].remove(topic)
                    
                    # Если не осталось подписок, удаляем клиента из словаря
                    if not self.subscriptions[client_id]:
                        self.subscriptions.pop(client_id, None)
                
                await self.send_message(client_id, {
                    "type": "unsubscribed", 
                    "topics": topics,
                    "message": f"Unsubscribed from topics: {topics}"
                })
        
        elif message_type == "fetch_data":
            # Запрос данных по типу
            data_type = message.get("data_type")
            params = message.get("params", {})
            
            # Получаем данные из кэша или источника
            try:
                data = await self.get_data(data_type, params)
                await self.send_message(client_id, {
                    "type": "data_response",
                    "data_type": data_type,
                    "data": data,
                    "timestamp": datetime.now().isoformat()
                })
            except Exception as e:
                logger.error(f"Error fetching data: {e}")
                await self.send_message(client_id, {
                    "type": "error",
                    "data_type": data_type,
                    "message": f"Error fetching data: {str(e)}"
                })
                
        elif message_type == "analyze_data":
            # Запрос на анализ данных
            analysis_type = message.get("analysis_type")
            data = message.get("data")
            
            if not analysis_type or data is None:
                await self.send_message(client_id, {
                    "type": "error",
                    "message": "Missing analysis_type or data in analyze_data request"
                })
                return
            
            # Используем интеграцию с инструментами для анализа
            try:
                from app.services.mcp_tools_integration import MCPToolsIntegration
                
                if "trades" in data:
                    # Анализ торговых данных
                    result = await MCPToolsIntegration.process_trading_data(
                        client_id=client_id,
                        data=data
                    )
                else:
                    # Анализ рыночных данных или другой тип
                    result = await self.analyze_data(analysis_type, data)
                    
                # Отправляем результаты анализа
                await self.send_message(client_id, {
                    "type": "analysis_response",
                    "analysis_type": analysis_type,
                    "result": result,
                    "timestamp": datetime.now().isoformat()
                })
                
            except Exception as e:
                logger.error(f"Error analyzing data: {e}")
                await self.send_message(client_id, {
                    "type": "error",
                    "analysis_type": analysis_type,
                    "message": f"Error analyzing data: {str(e)}"
                })
        
        elif message_type == "run_task":
            # Запуск асинхронной задачи
            task_name = message.get("task_name")
            task_params = message.get("params", {})
            
            if not task_name:
                await self.send_message(client_id, {
                    "type": "error",
                    "message": "No task_name specified"
                })
                return
            
            # Создаем и запускаем задачу
            task_id = await self.create_task(task_name, task_params)
            await self.send_message(client_id, {
                "type": "task_created",
                "task_id": task_id,
                "task_name": task_name,
                "message": f"Task {task_name} created with ID {task_id}"
            })
        
        elif message_type == "task_status":
            # Проверка статуса задачи
            task_id = message.get("task_id")
            
            if not task_id:
                await self.send_message(client_id, {
                    "type": "error",
                    "message": "No task_id specified"
                })
                return
            
            # Получаем статус задачи
            task_status = await self.get_task_status(task_id)
            
            if task_status:
                await self.send_message(client_id, {
                    "type": "task_status",
                    "task_id": task_id,
                    "status": task_status
                })
            else:
                await self.send_message(client_id, {
                    "type": "error",
                    "message": f"Task with ID {task_id} not found"
                })
        
        else:
            await self.send_message(client_id, {
                "type": "error",
                "message": f"Unknown message type: {message_type}"
            })
    
    async def _background_worker(self):
        """Фоновый процесс для периодических задач."""
        try:
            while True:
                # Рассылка heartbeat каждые 30 секунд
                await asyncio.sleep(30)
                await self.broadcast_message({
                    "type": "heartbeat", 
                    "status": "ok",
                    "timestamp": datetime.now().isoformat(),
                    "connections": len(self.active_connections),
                    "tasks": len(self.tasks)
                })
                
                # Обновление данных из внешних источников каждые 30 секунд
                try:
                    await self.update_market_data()
                except Exception as e:
                    logger.error(f"Error updating market data: {e}")
        except asyncio.CancelledError:
            logger.info("Background worker stopped")
            raise
            
    async def _cleanup_worker(self):
        """Фоновый процесс для очистки устаревших данных."""
        try:
            while True:
                # Очистка каждые 5 минут
                await asyncio.sleep(300)
                
                # Очищаем устаревшие данные в кэше
                if self.redis:
                    # Redis TTL работает автоматически
                    pass
                else:
                    # Очищаем устаревшие данные в памяти
                    now = datetime.now()
                    expired_keys = []
                    
                    for key, value in self.data_cache.items():
                        if isinstance(value, MCPCacheItem) and value.expires_at and value.expires_at < now:
                            expired_keys.append(key)
                    
                    for key in expired_keys:
                        self.data_cache.pop(key, None)
                        
                    if expired_keys:
                        logger.info(f"Cleaned up {len(expired_keys)} expired cache items")
                
                # Очищаем завершенные задачи старше суток
                day_ago = datetime.now() - timedelta(days=1)
                task_keys = list(self.data_cache.keys())
                
                for key in task_keys:
                    if key.startswith("task_") and isinstance(self.data_cache[key], MCPTask):
                        task = self.data_cache[key]
                        if task.status in ["completed", "failed"] and task.updated_at < day_ago:
                            self.data_cache.pop(key, None)
                
        except asyncio.CancelledError:
            logger.info("Cleanup worker stopped")
            raise

    async def get_cached_data(self, key: str) -> Optional[Any]:
        """
        Получение данных из кэша с многоуровневым подходом (сначала локальный кэш, затем Redis).
        
        Args:
            key: Ключ для поиска в кэше
            
        Returns:
            Данные из кэша или None, если данные не найдены
        """
        try:
            # Сначала проверяем локальный кэш (быстрее)
            cache_item = self.data_cache.get(key)
            if cache_item:
                if isinstance(cache_item, MCPCacheItem):
                    if cache_item.expires_at and cache_item.expires_at < datetime.now():
                        # Удаляем устаревшие данные
                        self.data_cache.pop(key, None)
                    else:
                        # Возвращаем данные из локального кэша
                        return cache_item.value
                else:
                    return cache_item
            
            # Затем проверяем Redis, если доступен
            if self.redis:
                try:
                    data = await self.redis.get(key)
                    if data:
                        try:
                            parsed_data = json.loads(data)
                            # Обновляем локальный кэш данными из Redis
                            ttl = await self.redis.ttl(key)
                            if ttl > 0:
                                expires_at = datetime.now() + timedelta(seconds=ttl)
                                self.data_cache[key] = MCPCacheItem(
                                    key=key,
                                    value=parsed_data,
                                    ttl=ttl,
                                    expires_at=expires_at
                                )
                            return parsed_data
                        except json.JSONDecodeError:
                            logger.warning(f"Error deserializing data from Redis for key {key}, returning raw data")
                            return data
                except Exception as e:
                    logger.warning(f"Error accessing Redis for key {key}: {e}")
            
            return None
        except Exception as e:
            logger.error(f"Error retrieving cached data for key {key}: {e}", exc_info=True)
            # В случае ошибки пытаемся вернуть данные из локального кэша, если они есть
            cache_item = self.data_cache.get(key)
            if cache_item and isinstance(cache_item, MCPCacheItem):
                return cache_item.value
            return None
        
    async def set_cached_data(self, key: str, value: Any, ttl: Optional[int] = None) -> bool:
        """
        Сохранение данных в кэш (Redis и локальная память) с интеллектуальным выбором TTL.
        
        Args:
            key: Ключ для сохранения в кэше
            value: Данные для сохранения
            ttl: Время жизни данных в секундах (опционально)
            
        Returns:
            True, если данные успешно сохранены, иначе False
        """
        try:
            # Интеллектуальный выбор TTL на основе типа данных
            if ttl is None:
                if 'price' in key or 'order' in key or 'ticker' in key:
                    # Высокая изменчивость (цены, ордера)
                    ttl = 10  # 10 секунд
                elif 'balance' in key or 'portfolio' in key:
                    # Средняя изменчивость (балансы)
                    ttl = 60  # 60 секунд
                elif 'topic' in key:
                    # Данные топиков - средний срок хранения
                    ttl = 300  # 5 минут
                else:
                    # По умолчанию - долгое хранение
                    ttl = 3600  # 1 час
            
            # Всегда сохраняем в локальный кэш для быстрого доступа
            expires_at = None
            if ttl:
                expires_at = datetime.now() + timedelta(seconds=ttl)
                
            local_cache_item = MCPCacheItem(
                key=key,
                value=value,
                ttl=ttl,
                expires_at=expires_at
            )
            self.data_cache[key] = local_cache_item
            
            # Если Redis доступен, сохраняем и там
            if self.redis:
                try:
                    serialized = json.dumps(value) if not isinstance(value, (str, bytes)) else value
                    if ttl:
                        await self.redis.setex(key, ttl, serialized)
                    else:
                        await self.redis.set(key, serialized)
                except Exception as e:
                    logger.warning(f"Failed to save data to Redis for key {key}: {e}, but saved to local cache")
                    # Даже если Redis не сработал, мы всё равно сохранили в локальный кэш
                    return True
            
            return True
        except Exception as e:
            logger.error(f"Error caching data for key {key}: {e}", exc_info=True)
            try:
                # Пытаемся сохранить хотя бы в локальный кэш с коротким TTL
                self.data_cache[key] = MCPCacheItem(
                    key=key,
                    value=value,
                    ttl=60,  # Аварийный TTL - 1 минута
                    expires_at=datetime.now() + timedelta(seconds=60)
                )
                return True
            except:
                return False
            
    async def get_data(self, data_type: str, params: Dict[str, Any] = None) -> Dict[str, Any]:
        """
        Получение данных по типу и параметрам.
        
        Args:
            data_type: Тип данных для получения (market_data, trades, portfolio и т.д.)
            params: Параметры запроса (опционально)
            
        Returns:
            Данные указанного типа
            
        Raises:
            ValueError: Если тип данных не поддерживается
        """
        params = params or {}
        
        # Проверяем, есть ли данные в кэше
        cache_key = f"{data_type}_{json.dumps(params, sort_keys=True)}"
        cached_data = await self.get_cached_data(cache_key)
        
        if cached_data:
            return {
                "data": cached_data,
                "source": "cache",
                "timestamp": datetime.now().isoformat()
            }
        
        # Если данных нет в кэше, получаем из источника
        if data_type == "market_data":
            # Получаем данные рынка
            symbol = params.get("symbol", "all")
            return await self.get_market_data(symbol)
            
        elif data_type == "portfolio":
            # Получаем данные портфеля
            return await self.get_portfolio_data(params)
            
        elif data_type == "trades":
            # Получаем данные сделок
            start_time = params.get("start_time")
            end_time = params.get("end_time")
            symbol = params.get("symbol")
            return await self.get_trades_data(start_time, end_time, symbol)
            
        elif data_type == "analysis":
            # Запускаем анализ данных
            analysis_type = params.get("analysis_type")
            data = params.get("data")
            return await self.analyze_data(analysis_type, data)
            
        else:
            raise ValueError(f"Unsupported data type: {data_type}")

    async def update_market_data(self):
        """
        Обновление рыночных данных и уведомление подписчиков.
        """
        try:
            # Получаем актуальные данные рынка
            market_data = await self.get_market_data("all", force_update=True)
            
            # Публикуем событие с обновленными данными
            await self.publish_event("market_data", {
                "data": market_data,
                "timestamp": datetime.now().isoformat()
            })
            
            return market_data
        except Exception as e:
            logger.error(f"Error updating market data: {e}")
            raise
            
    async def get_market_data(self, symbol: str = "all", force_update: bool = False) -> Dict[str, Any]:
        """
        Получение рыночных данных.
        
        Args:
            symbol: Символ рынка или "all" для всех
            force_update: Принудительное обновление из источника
            
        Returns:
            Рыночные данные
        """
        cache_key = f"market_data_{symbol}"
        
        # Проверяем кэш, если не требуется принудительное обновление
        if not force_update:
            cached_data = await self.get_cached_data(cache_key)
            if cached_data:
                return cached_data
        
        # Здесь будет логика получения данных с биржи
        # В этой имплементации просто заглушка
        data = {
            "BTC/USDT": {"price": 65000, "volume": 1000000},
            "ETH/USDT": {"price": 3500, "volume": 500000},
            "SOL/USDT": {"price": 150, "volume": 300000}
        }
        
        if symbol != "all" and symbol in data:
            result = {symbol: data[symbol]}
        else:
            result = data
            
        # Кэшируем результат на 60 секунд
        await self.set_cached_data(cache_key, result, ttl=60)
        
        return result
        
    async def get_portfolio_data(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """
        Получение данных портфеля.
        
        Args:
            params: Параметры запроса
            
        Returns:
            Данные портфеля
        """
        # Заглушка для данных портфеля
        portfolio = {
            "assets": {
                "BTC": {"amount": 0.5, "value_usd": 32500},
                "ETH": {"amount": 5, "value_usd": 17500},
                "USDT": {"amount": 10000, "value_usd": 10000}
            },
            "total_value_usd": 60000,
            "pnl_24h_percent": 2.5
        }
        
        # Кэшируем результат на 300 секунд (5 минут)
        await self.set_cached_data("portfolio_data", portfolio, ttl=300)
        
        return portfolio
        
    async def get_trades_data(self, start_time: Optional[str], end_time: Optional[str], symbol: Optional[str]) -> Dict[str, Any]:
        """
        Получение данных о сделках.
        
        Args:
            start_time: Начальное время (опционально)
            end_time: Конечное время (опционально)
            symbol: Символ рынка (опционально)
            
        Returns:
            Данные о сделках
        """
        # Заглушка для данных о сделках
        trades = [
            {"id": "1", "symbol": "BTC/USDT", "side": "buy", "price": 64500, "amount": 0.1, "timestamp": "2025-09-13T10:00:00"},
            {"id": "2", "symbol": "ETH/USDT", "side": "sell", "price": 3550, "amount": 1.0, "timestamp": "2025-09-13T11:30:00"},
            {"id": "3", "symbol": "BTC/USDT", "side": "sell", "price": 65200, "amount": 0.05, "timestamp": "2025-09-14T09:15:00"}
        ]
        
        # Применяем фильтры, если они указаны
        filtered_trades = trades
        
        if symbol:
            filtered_trades = [t for t in filtered_trades if t["symbol"] == symbol]
            
        if start_time:
            start_dt = datetime.fromisoformat(start_time)
            filtered_trades = [t for t in filtered_trades if datetime.fromisoformat(t["timestamp"]) >= start_dt]
            
        if end_time:
            end_dt = datetime.fromisoformat(end_time)
            filtered_trades = [t for t in filtered_trades if datetime.fromisoformat(t["timestamp"]) <= end_dt]
            
        return {"trades": filtered_trades, "count": len(filtered_trades)}

    async def publish_event(self, topic: str, data: Dict[str, Any]):
        """
        Публикация события для всех подписчиков.
        
        Args:
            topic: Топик события
            data: Данные события
        """
        # Формируем сообщение события
        event_message = {
            "type": "event",
            "topic": topic,
            "data": data,
            "timestamp": datetime.now().isoformat()
        }
        
        # Сохраняем последнее событие в кэше
        await self.set_cached_data(f"topic_{topic}", data, ttl=3600)
        
        # Находим всех клиентов, подписанных на этот топик
        subscribed_clients = []
        for client_id, topics in self.subscriptions.items():
            if topic in topics:
                subscribed_clients.append(client_id)
        
        # Рассылаем сообщение подписчикам
        for client_id in subscribed_clients:
            await self.send_message(client_id, event_message)

    async def analyze_data(self, analysis_type: str, data: Any) -> Dict[str, Any]:
        """
        Анализ данных с использованием инструментов.
        
        Args:
            analysis_type: Тип анализа
            data: Данные для анализа
            
        Returns:
            Результаты анализа
            
        Raises:
            ValueError: Если тип анализа не поддерживается
        """
        # Используем MCPDataAnalyzer для анализа данных
        from app.services.mcp_data_analyzer import MCPDataAnalyzer
        
        if analysis_type in ["pnl_calculation", "pnl"]:
            # Анализ PnL с использованием MCPDataAnalyzer
            if not isinstance(data, list):
                raise ValueError("Data must be a list of trades")
                
            # Используем MCPDataAnalyzer
            result = await MCPDataAnalyzer.analyze_trading_data(
                trades=data, 
                analysis_type="pnl",
                include_fees=True
            )
            return result
            
        elif analysis_type == "trade_analysis":
            # Детальный анализ торговых данных
            if not isinstance(data, list):
                raise ValueError("Data must be a list of trades")
                
            # Используем MCPDataAnalyzer
            result = await MCPDataAnalyzer.analyze_trading_data(
                trades=data, 
                analysis_type="full",
                include_fees=True
            )
            return result
            
        elif analysis_type == "market_data_analysis":
            # Анализ рыночных данных
            if not isinstance(data, dict):
                raise ValueError("Data must be a dictionary with market data")
                
            # Используем MCPDataAnalyzer
            result = await MCPDataAnalyzer.analyze_market_data(
                market_data=data, 
                analysis_type="basic"
            )
            return result
            
        else:
            raise ValueError(f"Unsupported analysis type: {analysis_type}")
            
    async def get_system_status(self) -> Dict[str, Any]:
        """
        Получение статуса системы MCP, включая метрики и состояние компонентов.
        
        Returns:
            Dict с информацией о состоянии MCP
        """
        try:
            # Обновляем метрики при запросе статуса
            if self.enable_monitoring:
                metrics = self.resource_monitor.collect_metrics(len(self.active_connections))
            else:
                metrics = {}
            
            # Статистика кэша
            cache_stats = {
                "local_cache_items": len(self.data_cache),
                "redis_available": self.redis is not None,
            }
            
            # Если Redis доступен, собираем дополнительную статистику
            if self.redis:
                try:
                    cache_stats["redis_keys_count"] = await self.redis.dbsize()
                    info = await self.redis.info()
                    cache_stats["redis_used_memory"] = info.get("used_memory_human", "unknown")
                    cache_stats["redis_clients_connected"] = info.get("connected_clients", 0)
                except Exception as e:
                    logger.warning(f"Failed to get Redis stats: {e}")
                    cache_stats["redis_error"] = str(e)
            
            # Статистика соединений
            connections_stats = {
                "active_connections": len(self.active_connections),
                "max_connections": self.max_connections,
                "subscriptions": sum(len(topics) for topics in self.subscriptions.values()),
                "clients_with_subscriptions": len(self.subscriptions)
            }
            
            # Статистика задач
            tasks_stats = {
                "active_tasks": len(self.tasks),
            }
            
            return {
                "status": "operational",
                "uptime": time.time() - self.start_time if hasattr(self, 'start_time') else 0,
                "timestamp": datetime.now().isoformat(),
                "metrics": metrics,
                "cache": cache_stats,
                "connections": connections_stats,
                "tasks": tasks_stats,
                "monitoring_enabled": self.enable_monitoring
            }
        except Exception as e:
            logger.error(f"Error getting system status: {e}", exc_info=True)
            return {
                "status": "error",
                "error": str(e),
                "timestamp": datetime.now().isoformat()
            }
    
    async def get_metrics_history(self) -> Dict[str, Any]:
        """
        Получение истории метрик мониторинга с аналитикой.
        
        Returns:
            Dict с историей метрик и агрегированной статистикой
        """
        if not self.enable_monitoring:
            return {
                "status": "disabled",
                "message": "Monitoring is disabled"
            }
            
        try:
            metrics_data = self.resource_monitor.get_metrics_history()
            return {
                "status": "success",
                "timestamp": datetime.now().isoformat(),
                "data": metrics_data
            }
        except Exception as e:
            logger.error(f"Error getting metrics history: {e}", exc_info=True)
            return {
                "status": "error",
                "error": str(e),
                "timestamp": datetime.now().isoformat()
            }


# Глобальный экземпляр MCP Service
mcp_service: Optional[MCPService] = None

async def get_mcp_service() -> MCPService:
    """
    Singleton для доступа к MCP Service.
    Создает и запускает сервис, если он еще не запущен.
    """
    global mcp_service
    if mcp_service is None:
        mcp_service = MCPService()
        await mcp_service.start()
    return mcp_service
