"""
Утилиты для MCP Service: retry-логика, мониторинг ресурсов и другие вспомогательные функции.
"""

import asyncio
import logging
import time
import functools
import random
from typing import Callable, TypeVar, Any, Dict, Optional, Coroutine

logger = logging.getLogger(__name__)

# Тип для обобщённой функции
T = TypeVar('T')


async def with_retry(func: Callable[..., Coroutine[Any, Any, T]], 
                    max_attempts: int = 3, 
                    base_delay: float = 0.1,
                    max_delay: float = 5.0,
                    backoff_factor: float = 2.0,
                    jitter: bool = True,
                    exception_types: tuple = (Exception,),
                    context: Optional[Dict[str, Any]] = None) -> T:
    """
    Выполняет асинхронную функцию с повторными попытками при возникновении исключений.
    
    Args:
        func: Асинхронная функция для выполнения
        max_attempts: Максимальное количество попыток
        base_delay: Базовая задержка между попытками в секундах
        max_delay: Максимальная задержка между попытками в секундах
        backoff_factor: Фактор экспоненциального увеличения задержки
        jitter: Добавлять случайное отклонение к задержке для предотвращения "thundering herd"
        exception_types: Типы исключений, для которых выполнять повторные попытки
        context: Контекстная информация для логирования
    
    Returns:
        Результат выполнения функции
    
    Raises:
        Последнее возникшее исключение, если все попытки не удались
    """
    ctx_str = f"[{', '.join(f'{k}={v}' for k, v in (context or {}).items())}]" if context else ""
    
    attempt = 0
    last_exception = None
    
    while attempt < max_attempts:
        try:
            return await func()
        except exception_types as e:
            attempt += 1
            last_exception = e
            
            if attempt >= max_attempts:
                logger.error(
                    f"All {max_attempts} attempts failed {ctx_str}: {e}"
                )
                break
            
            # Вычисляем задержку с экспоненциальным ростом
            delay = min(base_delay * (backoff_factor ** (attempt - 1)), max_delay)
            
            # Добавляем случайное отклонение (±25%)
            if jitter:
                delay = delay * (0.75 + random.random() * 0.5)
                
            logger.warning(
                f"Attempt {attempt}/{max_attempts} failed {ctx_str}: {e}. "
                f"Retrying in {delay:.2f}s"
            )
            
            await asyncio.sleep(delay)
    
    raise last_exception


def measure_execution_time(func):
    """
    Декоратор для измерения времени выполнения функции.
    Работает как с синхронными, так и с асинхронными функциями.
    """
    @functools.wraps(func)
    async def async_wrapper(*args, **kwargs):
        start_time = time.time()
        try:
            result = await func(*args, **kwargs)
            return result
        finally:
            elapsed = time.time() - start_time
            logger.debug(f"Function '{func.__name__}' took {elapsed:.4f}s to execute")
    
    @functools.wraps(func)
    def sync_wrapper(*args, **kwargs):
        start_time = time.time()
        try:
            result = func(*args, **kwargs)
            return result
        finally:
            elapsed = time.time() - start_time
            logger.debug(f"Function '{func.__name__}' took {elapsed:.4f}s to execute")
    
    if asyncio.iscoroutinefunction(func):
        return async_wrapper
    else:
        return sync_wrapper


class ResourceMonitor:
    """
    Класс для мониторинга использования ресурсов (CPU, память, подключения).
    """
    
    def __init__(self, history_size: int = 60):
        """
        Инициализация монитора ресурсов.
        
        Args:
            history_size: Количество точек истории для хранения
        """
        self.history_size = history_size
        self.metrics = []
        self.last_check = 0
        
    def collect_metrics(self, connections_count: int = 0) -> Dict[str, Any]:
        """
        Сбор метрик использования ресурсов.
        
        Args:
            connections_count: Количество активных подключений
            
        Returns:
            Dict с метриками
        """
        now = time.time()
        
        # Ограничиваем частоту сбора метрик (не чаще раза в секунду)
        if now - self.last_check < 1:
            if self.metrics:
                return self.metrics[-1]
            return {}
            
        self.last_check = now
        
        try:
            # Пытаемся импортировать psutil для получения метрик
            try:
                import psutil
                cpu_percent = psutil.cpu_percent(interval=None)
                memory = psutil.virtual_memory()
                memory_percent = memory.percent
                memory_used_mb = memory.used / (1024 * 1024)
                memory_available_mb = memory.available / (1024 * 1024)
            except ImportError:
                # Если psutil не доступен, используем заглушки
                cpu_percent = 0
                memory_percent = 0
                memory_used_mb = 0
                memory_available_mb = 0
                
            metrics = {
                "timestamp": now,
                "cpu_percent": cpu_percent,
                "memory_percent": memory_percent,
                "memory_used_mb": memory_used_mb,
                "memory_available_mb": memory_available_mb,
                "connections_count": connections_count,
            }
            
            self.metrics.append(metrics)
            
            # Удаляем старые метрики
            if len(self.metrics) > self.history_size:
                self.metrics = self.metrics[-self.history_size:]
                
            return metrics
        except Exception as e:
            logger.warning(f"Failed to collect resource metrics: {e}")
            return {
                "timestamp": now,
                "error": str(e)
            }
    
    def get_metrics_history(self) -> Dict[str, Any]:
        """
        Получение истории метрик с аналитикой.
        
        Returns:
            Dict с историей метрик и агрегированной аналитикой
        """
        if not self.metrics:
            return {"history": [], "aggregated": {}}
            
        # Рассчитываем агрегированные метрики
        cpu_values = [m.get("cpu_percent", 0) for m in self.metrics if "cpu_percent" in m]
        memory_values = [m.get("memory_percent", 0) for m in self.metrics if "memory_percent" in m]
        connections_values = [m.get("connections_count", 0) for m in self.metrics if "connections_count" in m]
        
        aggregated = {}
        
        if cpu_values:
            aggregated["cpu"] = {
                "avg": sum(cpu_values) / len(cpu_values),
                "max": max(cpu_values),
                "min": min(cpu_values)
            }
            
        if memory_values:
            aggregated["memory"] = {
                "avg": sum(memory_values) / len(memory_values),
                "max": max(memory_values),
                "min": min(memory_values)
            }
            
        if connections_values:
            aggregated["connections"] = {
                "avg": sum(connections_values) / len(connections_values),
                "max": max(connections_values),
                "min": min(connections_values),
                "current": connections_values[-1] if connections_values else 0
            }
            
        return {
            "history": self.metrics,
            "aggregated": aggregated
        }