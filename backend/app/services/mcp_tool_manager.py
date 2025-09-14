"""
MCP Tool Manager - интеграционный слой для инструментов анализа данных.

Этот модуль обеспечивает централизованную точку доступа к различным инструментам
для обработки и анализа данных, включая CSV/XLSX файлы и торговые данные.
"""

import logging
import asyncio
from typing import Dict, List, Any, Optional, Union, Callable
from pathlib import Path

from app.services.mcp_errors import MCPError, MCPDataError, MCPTaskError
from app.tools.data_processor import DataProcessor
from app.tools.trading_analyzer import TradingAnalyzer

logger = logging.getLogger(__name__)

class MCPToolManager:
    """Менеджер инструментов для MCP сервиса."""
    
    def __init__(self):
        """Инициализация менеджера инструментов."""
        logger.info("Initializing MCP Tool Manager")
        self._data_processor = DataProcessor()
        self._trading_analyzer = TradingAnalyzer()
    
    async def process_file(self, 
                          file_content: bytes, 
                          filename: str, 
                          file_type: Optional[str] = None) -> Dict[str, Any]:
        """
        Обработка файла с помощью DataProcessor.
        
        Args:
            file_content: Содержимое файла в байтах
            filename: Имя файла
            file_type: Тип файла (опционально)
            
        Returns:
            Dict с результатами обработки файла
            
        Raises:
            MCPDataError: При ошибке обработки файла
        """
        try:
            logger.debug(f"Processing file {filename} with type {file_type}")
            result = await DataProcessor.process_file(
                file_content=file_content,
                filename=filename,
                file_type=file_type
            )
            return result
        except ValueError as e:
            logger.error(f"Error processing file {filename}: {e}")
            raise MCPDataError(f"Ошибка обработки файла: {e}")
        except Exception as e:
            logger.exception(f"Unexpected error processing file {filename}")
            raise MCPDataError(f"Непредвиденная ошибка при обработке файла: {e}")
    
    def calculate_pnl(self, 
                     trades: List[Dict[str, Any]], 
                     include_fees: bool = True) -> Dict[str, Any]:
        """
        Расчет PnL по списку сделок с помощью TradingAnalyzer.
        
        Args:
            trades: Список сделок для расчета
            include_fees: Учитывать ли комиссии при расчете
            
        Returns:
            Dict с результатами расчета PnL
            
        Raises:
            MCPDataError: При ошибке расчета PnL
        """
        try:
            logger.debug(f"Calculating PnL for {len(trades)} trades")
            result = TradingAnalyzer.calculate_pnl(
                trades=trades,
                include_fees=include_fees
            )
            return result
        except ValueError as e:
            logger.error(f"Error calculating PnL: {e}")
            raise MCPDataError(f"Ошибка расчета PnL: {e}")
        except Exception as e:
            logger.exception("Unexpected error calculating PnL")
            raise MCPDataError(f"Непредвиденная ошибка при расчете PnL: {e}")
    
    def analyze_trades(self, 
                      trades: List[Dict[str, Any]]) -> Dict[str, Any]:
        """
        Расширенный анализ сделок с помощью TradingAnalyzer.
        
        Args:
            trades: Список сделок для анализа
            
        Returns:
            Dict с результатами анализа сделок
            
        Raises:
            MCPDataError: При ошибке анализа сделок
        """
        try:
            logger.debug(f"Analyzing {len(trades)} trades")
            result = TradingAnalyzer.analyze_trades(trades=trades)
            return result
        except ValueError as e:
            logger.error(f"Error analyzing trades: {e}")
            raise MCPDataError(f"Ошибка анализа сделок: {e}")
        except Exception as e:
            logger.exception("Unexpected error analyzing trades")
            raise MCPDataError(f"Непредвиденная ошибка при анализе сделок: {e}")