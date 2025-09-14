"""
Тесты для интеграции инструментов с MCP сервисом
"""
import pytest
import asyncio
from unittest.mock import AsyncMock, MagicMock, patch
from typing import Dict, Any, List

from app.services.mcp_tool_manager import MCPToolManager
from app.services.mcp_service import MCPService
from app.services.mcp_errors import MCPDataError
from app.tools.data_processor import DataProcessor
from app.tools.trading_analyzer import TradingAnalyzer

# Тестовые данные
sample_trades = [
    {
        "side": "buy", 
        "price": 50000.0, 
        "quantity": 0.1, 
        "timestamp": "2023-01-01T12:00:00Z",
        "symbol": "BTC/USDT"
    },
    {
        "side": "sell", 
        "price": 51000.0, 
        "quantity": 0.1, 
        "timestamp": "2023-01-02T12:00:00Z",
        "symbol": "BTC/USDT",
        "fee": 2.5
    }
]

# ===== Тесты для MCPToolManager =====

@pytest.mark.asyncio
async def test_mcp_tool_manager_init():
    """Тест инициализации MCPToolManager."""
    manager = MCPToolManager()
    assert manager is not None

@pytest.mark.asyncio
async def test_mcp_tool_manager_process_file():
    """Тест обработки файла через MCPToolManager."""
    manager = MCPToolManager()
    
    # Мокаем статический метод в DataProcessor
    with patch.object(DataProcessor, 'process_file', new_callable=AsyncMock) as mock_process:
        mock_process.return_value = {"rows": 10, "columns": ["col1", "col2"]}
        
        # Вызываем метод менеджера
        file_content = b"test,data\n1,2\n3,4"
        result = await manager.process_file(file_content, "test.csv")
        
        # Проверяем, что метод DataProcessor был вызван с правильными параметрами
        mock_process.assert_called_once_with(
            file_content=file_content,
            filename="test.csv",
            file_type=None
        )
        
        # Проверяем результат
        assert result == {"rows": 10, "columns": ["col1", "col2"]}

@pytest.mark.asyncio
async def test_mcp_tool_manager_process_file_error():
    """Тест обработки ошибок при обработке файла через MCPToolManager."""
    manager = MCPToolManager()
    
    # Мокаем статический метод в DataProcessor с генерацией исключения
    with patch.object(DataProcessor, 'process_file', new_callable=AsyncMock) as mock_process:
        mock_process.side_effect = ValueError("Неподдерживаемый тип файла")
        
        # Вызываем метод менеджера и проверяем исключение
        with pytest.raises(MCPDataError):
            await manager.process_file(b"test data", "test.unknown")

def test_mcp_tool_manager_calculate_pnl():
    """Тест расчета PnL через MCPToolManager."""
    manager = MCPToolManager()
    
    # Мокаем статический метод в TradingAnalyzer
    with patch.object(TradingAnalyzer, 'calculate_pnl') as mock_calculate:
        mock_calculate.return_value = {
            "total_pnl": 100.0,
            "winning_trades": 1,
            "losing_trades": 0,
            "win_rate": 1.0
        }
        
        # Вызываем метод менеджера
        result = manager.calculate_pnl(sample_trades)
        
        # Проверяем, что метод TradingAnalyzer был вызван с правильными параметрами
        mock_calculate.assert_called_once_with(
            trades=sample_trades,
            include_fees=True
        )
        
        # Проверяем результат
        assert result["total_pnl"] == 100.0
        assert result["winning_trades"] == 1

def test_mcp_tool_manager_calculate_pnl_error():
    """Тест обработки ошибок при расчете PnL через MCPToolManager."""
    manager = MCPToolManager()
    
    # Мокаем статический метод в TradingAnalyzer с генерацией исключения
    with patch.object(TradingAnalyzer, 'calculate_pnl') as mock_calculate:
        mock_calculate.side_effect = ValueError("Отсутствуют обязательные поля")
        
        # Вызываем метод менеджера и проверяем исключение
        with pytest.raises(MCPDataError):
            manager.calculate_pnl([{"invalid": "data"}])

def test_mcp_tool_manager_analyze_trades():
    """Тест анализа сделок через MCPToolManager."""
    manager = MCPToolManager()
    
    # Мокаем статический метод в TradingAnalyzer
    with patch.object(TradingAnalyzer, 'analyze_trades') as mock_analyze:
        mock_analyze.return_value = {
            "pnl": {"total_pnl": 100.0},
            "metrics": {"hourly_activity": {12: 2}}
        }
        
        # Вызываем метод менеджера
        result = manager.analyze_trades(sample_trades)
        
        # Проверяем, что метод TradingAnalyzer был вызван с правильными параметрами
        mock_analyze.assert_called_once_with(trades=sample_trades)
        
        # Проверяем результат
        assert "pnl" in result
        assert "metrics" in result

# ===== Тесты для интеграции с MCP сервисом =====

@pytest.mark.asyncio
async def test_mcp_service_tool_integration():
    """Тест интеграции инструментов с MCP сервисом."""
    # Создаем экземпляр MCP сервиса
    mcp = MCPService(redis_url="redis://localhost:6379/1")
    
    # Проверяем, что экземпляр tool_manager создан
    assert mcp.tool_manager is not None

@pytest.mark.asyncio
async def test_mcp_service_process_file():
    """Тест метода обработки файла в MCP сервисе."""
    # Создаем экземпляр MCP сервиса
    mcp = MCPService(redis_url="redis://localhost:6379/1")
    
    # Мокаем метод process_file в tool_manager
    mcp.tool_manager.process_file = AsyncMock()
    mcp.tool_manager.process_file.return_value = {"rows": 10, "columns": ["col1", "col2"]}
    
    # Мокаем методы кэширования
    mcp.get_cache = AsyncMock(return_value=None)
    mcp.set_cache = AsyncMock()
    
    # Тестируем метод
    file_content = b"test,data\n1,2\n3,4"
    result = await mcp.process_file(file_content, "test.csv")
    
    # Проверяем результат
    assert "rows" in result
    assert result["rows"] == 10
    assert mcp.set_cache.called

@pytest.mark.asyncio
async def test_mcp_service_process_file_cached():
    """Тест использования кэша при обработке файла в MCP сервисе."""
    # Создаем экземпляр MCP сервиса
    mcp = MCPService(redis_url="redis://localhost:6379/1")
    
    # Мокаем метод tool_manager.process_file
    mcp.tool_manager.process_file = AsyncMock()
    
    # Мокаем методы кэширования с возвратом кэшированного результата
    cached_result = {"rows": 10, "columns": ["col1", "col2"], "cached": True}
    mcp.get_cache = AsyncMock(return_value=cached_result)
    mcp.set_cache = AsyncMock()
    
    # Тестируем метод
    result = await mcp.process_file(b"test data", "test.csv")
    
    # Проверяем, что результат взят из кэша
    assert result == cached_result
    assert not mcp.tool_manager.process_file.called
    assert not mcp.set_cache.called

def test_mcp_service_calculate_pnl():
    """Тест метода расчета PnL в MCP сервисе."""
    # Создаем экземпляр MCP сервиса
    mcp = MCPService(redis_url="redis://localhost:6379/1")
    
    # Мокаем метод в tool_manager
    mcp.tool_manager.calculate_pnl = MagicMock()
    mcp.tool_manager.calculate_pnl.return_value = {
        "total_pnl": 100.0,
        "winning_trades": 1
    }
    
    # Тестируем метод
    result = mcp.calculate_pnl(sample_trades)
    
    # Проверяем результат
    assert result["total_pnl"] == 100.0
    assert result["winning_trades"] == 1
    mcp.tool_manager.calculate_pnl.assert_called_once_with(
        trades=sample_trades,
        include_fees=True
    )

def test_mcp_service_analyze_trades():
    """Тест метода анализа сделок в MCP сервисе."""
    # Создаем экземпляр MCP сервиса
    mcp = MCPService(redis_url="redis://localhost:6379/1")
    
    # Мокаем метод в tool_manager
    mcp.tool_manager.analyze_trades = MagicMock()
    mcp.tool_manager.analyze_trades.return_value = {
        "pnl": {"total_pnl": 100.0},
        "symbols": {"BTC/USDT": {"total_pnl": 100.0}}
    }
    
    # Тестируем метод
    result = mcp.analyze_trades(sample_trades)
    
    # Проверяем результат
    assert "pnl" in result
    assert "symbols" in result
    assert result["symbols"]["BTC/USDT"]["total_pnl"] == 100.0
    mcp.tool_manager.analyze_trades.assert_called_once_with(trades=sample_trades)