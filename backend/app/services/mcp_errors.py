"""
Исключения для MCP сервиса с контекстной информацией и поддержкой вложенных ошибок.
"""
from typing import Dict, Any, Optional


class MCPError(Exception):
    """Базовый класс для ошибок MCP."""
    
    def __init__(self, 
                 message: str, 
                 context: Optional[Dict[str, Any]] = None, 
                 original_error: Optional[Exception] = None):
        """
        Инициализация ошибки MCP с контекстом.
        
        Args:
            message: Сообщение об ошибке
            context: Контекстная информация об ошибке (опционально)
            original_error: Оригинальное исключение (опционально)
        """
        self.message = message
        self.context = context or {}
        self.original_error = original_error
        
        # Формируем подробное сообщение
        detailed_message = f"{message}"
        if context:
            context_str = ", ".join(f"{k}={v}" for k, v in context.items())
            detailed_message += f" [Context: {context_str}]"
        if original_error:
            detailed_message += f" [Original error: {str(original_error)}]"
            
        super().__init__(detailed_message)


class MCPConnectionError(MCPError):
    """Ошибка соединения MCP."""
    pass


class MCPDataError(MCPError):
    """Ошибка данных MCP."""
    pass


class MCPTaskError(MCPError):
    """Ошибка задачи MCP."""
    pass


class MCPCacheError(MCPError):
    """Ошибка кэш�� MCP."""
    pass


class MCPAuthenticationError(MCPError):
    """Ошибка аутентификации MCP."""
    pass


class MCPWebSocketError(MCPError):
    """Ошибка WebSocket соединения MCP."""
    pass