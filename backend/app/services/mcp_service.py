import asyncio
import json
import time
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional, Set

from sqlalchemy.ext.asyncio import AsyncSession

try:
    import redis.asyncio as redis
except ImportError:
    import redis

from app.core.config import settings
from app.schemas.mcp import (HealthStatus, MarketDataUpdate, PortfolioUpdate,
                             ServiceHealth, SystemHealth, TaskInfo, TaskStatus,
                             TradingSignalUpdate, WebSocketMessage)


class MCPService:
    """Master Control Program service for orchestrating tasks and real-time communication"""

    def __init__(self, db: AsyncSession):
        self.db = db
        self.redis_client: Optional[redis.Redis] = None
        self.websocket_connections: Set = set()

    async def initialize(self):
        """Initialize MCP service connections"""
        try:
            self.redis_client = redis.from_url(settings.REDIS_URL)
            await self.redis_client.ping()
        except Exception as e:
            print(f"Failed to connect to Redis: {e}")
            self.redis_client = None

    async def check_system_health(self) -> SystemHealth:
        """Check health of all system dependencies"""
        services = []
        overall_status = HealthStatus.HEALTHY

        # Check database health
        db_health = await self._check_database_health()
        services.append(db_health)
        if db_health.status != HealthStatus.HEALTHY:
            overall_status = HealthStatus.DEGRADED

        # Check Redis health
        redis_health = await self._check_redis_health()
        services.append(redis_health)
        if redis_health.status != HealthStatus.HEALTHY:
            overall_status = HealthStatus.DEGRADED

        # Check external APIs health
        htx_health = await self._check_htx_api_health()
        services.append(htx_health)
        if (
            htx_health.status != HealthStatus.HEALTHY
            and overall_status == HealthStatus.HEALTHY
        ):
            overall_status = HealthStatus.DEGRADED

        coingecko_health = await self._check_coingecko_api_health()
        services.append(coingecko_health)
        if (
            coingecko_health.status != HealthStatus.HEALTHY
            and overall_status == HealthStatus.HEALTHY
        ):
            overall_status = HealthStatus.DEGRADED

        return SystemHealth(
            status=overall_status,
            services=services,
            timestamp=datetime.now(timezone.utc),
        )

    async def _check_database_health(self) -> ServiceHealth:
        """Check PostgreSQL database health"""
        start_time = time.time()
        try:
            # Simple query to check database connectivity
            result = await self.db.execute("SELECT 1")
            await result.fetchone()
            response_time = (time.time() - start_time) * 1000

            return ServiceHealth(
                name="PostgreSQL",
                status=HealthStatus.HEALTHY,
                response_time_ms=response_time,
                last_checked=datetime.now(timezone.utc),
            )
        except Exception as e:
            return ServiceHealth(
                name="PostgreSQL",
                status=HealthStatus.UNHEALTHY,
                details={"error": str(e)},
                last_checked=datetime.now(timezone.utc),
            )

    async def _check_redis_health(self) -> ServiceHealth:
        """Check Redis health"""
        start_time = time.time()
        try:
            if self.redis_client is None:
                await self.initialize()

            if self.redis_client:
                await self.redis_client.ping()
                response_time = (time.time() - start_time) * 1000

                return ServiceHealth(
                    name="Redis",
                    status=HealthStatus.HEALTHY,
                    response_time_ms=response_time,
                    last_checked=datetime.now(timezone.utc),
                )
            else:
                return ServiceHealth(
                    name="Redis",
                    status=HealthStatus.UNHEALTHY,
                    details={"error": "Redis client not initialized"},
                    last_checked=datetime.now(timezone.utc),
                )
        except Exception as e:
            return ServiceHealth(
                name="Redis",
                status=HealthStatus.UNHEALTHY,
                details={"error": str(e)},
                last_checked=datetime.now(timezone.utc),
            )

    async def _check_htx_api_health(self) -> ServiceHealth:
        """Check HTX API health"""
        start_time = time.time()
        try:
            # Import httpx dynamically to avoid dependency issues
            try:
                import httpx
            except ImportError:
                return ServiceHealth(
                    name="HTX API",
                    status=HealthStatus.UNHEALTHY,
                    details={"error": "httpx not available"},
                    last_checked=datetime.now(timezone.utc),
                )

            async with httpx.AsyncClient() as client:
                response = await client.get(
                    "https://api.huobi.pro/v1/common/timestamp", timeout=5.0
                )
                response_time = (time.time() - start_time) * 1000

                if response.status_code == 200:
                    return ServiceHealth(
                        name="HTX API",
                        status=HealthStatus.HEALTHY,
                        response_time_ms=response_time,
                        last_checked=datetime.now(timezone.utc),
                    )
                else:
                    return ServiceHealth(
                        name="HTX API",
                        status=HealthStatus.DEGRADED,
                        response_time_ms=response_time,
                        details={"status_code": response.status_code},
                        last_checked=datetime.now(timezone.utc),
                    )
        except Exception as e:
            return ServiceHealth(
                name="HTX API",
                status=HealthStatus.UNHEALTHY,
                details={"error": str(e)},
                last_checked=datetime.now(timezone.utc),
            )

    async def _check_coingecko_api_health(self) -> ServiceHealth:
        """Check CoinGecko API health"""
        start_time = time.time()
        try:
            try:
                import httpx
            except ImportError:
                return ServiceHealth(
                    name="CoinGecko API",
                    status=HealthStatus.UNHEALTHY,
                    details={"error": "httpx not available"},
                    last_checked=datetime.now(timezone.utc),
                )

            async with httpx.AsyncClient() as client:
                response = await client.get(
                    "https://api.coingecko.com/api/v3/ping", timeout=5.0
                )
                response_time = (time.time() - start_time) * 1000

                if response.status_code == 200:
                    return ServiceHealth(
                        name="CoinGecko API",
                        status=HealthStatus.HEALTHY,
                        response_time_ms=response_time,
                        last_checked=datetime.now(timezone.utc),
                    )
                else:
                    return ServiceHealth(
                        name="CoinGecko API",
                        status=HealthStatus.DEGRADED,
                        response_time_ms=response_time,
                        details={"status_code": response.status_code},
                        last_checked=datetime.now(timezone.utc),
                    )
        except Exception as e:
            return ServiceHealth(
                name="CoinGecko API",
                status=HealthStatus.UNHEALTHY,
                details={"error": str(e)},
                last_checked=datetime.now(timezone.utc),
            )

    async def add_websocket_connection(self, websocket):
        """Add WebSocket connection to active connections"""
        self.websocket_connections.add(websocket)

    async def remove_websocket_connection(self, websocket):
        """Remove WebSocket connection from active connections"""
        self.websocket_connections.discard(websocket)

    async def broadcast_message(self, message: WebSocketMessage):
        """Broadcast message to all connected WebSocket clients"""
        if not self.websocket_connections:
            return

        message_json = message.model_dump_json()
        disconnected = set()

        for websocket in self.websocket_connections:
            try:
                await websocket.send_text(message_json)
            except Exception:
                # Connection is closed, mark for removal
                disconnected.add(websocket)

        # Remove disconnected connections
        for websocket in disconnected:
            self.websocket_connections.discard(websocket)

    async def broadcast_market_data(self, market_data: MarketDataUpdate):
        """Broadcast market data update"""
        message = WebSocketMessage(
            type="market_data",
            data=market_data.model_dump(),
            timestamp=datetime.now(timezone.utc),
        )
        await self.broadcast_message(message)

    async def broadcast_trading_signal(self, signal: TradingSignalUpdate):
        """Broadcast trading signal update"""
        message = WebSocketMessage(
            type="trading_signal",
            data=signal.model_dump(),
            timestamp=datetime.now(timezone.utc),
        )
        await self.broadcast_message(message)

    async def broadcast_portfolio_update(self, portfolio: PortfolioUpdate):
        """Broadcast portfolio update to specific user"""
        message = WebSocketMessage(
            type="portfolio_update",
            data=portfolio.model_dump(),
            timestamp=datetime.now(timezone.utc),
            user_id=portfolio.user_id,
        )
        await self.broadcast_message(message)

    async def schedule_task(
        self, task_name: str, parameters: Optional[Dict[str, Any]] = None
    ) -> str:
        """Schedule a background task (placeholder for Celery integration)"""
        # This would integrate with Celery in a real implementation
        task_id = f"task_{int(time.time() * 1000)}"

        # Store task info in Redis if available
        if self.redis_client:
            task_info = TaskInfo(
                task_id=task_id,
                name=task_name,
                status=TaskStatus.PENDING,
                created_at=datetime.now(timezone.utc),
            )
            await self.redis_client.setex(
                f"task:{task_id}", 3600, task_info.model_dump_json()  # 1 hour TTL
            )

        return task_id

    async def get_task_status(self, task_id: str) -> Optional[TaskInfo]:
        """Get task status by ID"""
        if not self.redis_client:
            return None

        try:
            task_data = await self.redis_client.get(f"task:{task_id}")
            if task_data:
                return TaskInfo.model_validate_json(task_data)
        except Exception:
            pass

        return None

    async def get_active_tasks(self) -> List[TaskInfo]:
        """Get list of active tasks"""
        if not self.redis_client:
            return []

        try:
            keys = await self.redis_client.keys("task:*")
            tasks = []

            for key in keys:
                task_data = await self.redis_client.get(key)
                if task_data:
                    task_info = TaskInfo.model_validate_json(task_data)
                    if task_info.status in [TaskStatus.PENDING, TaskStatus.RUNNING]:
                        tasks.append(task_info)

            return tasks
        except Exception:
            return []
