"""
ETL Connector для интеграции с ETL процессами.
"""
import asyncio
import logging
import json
from typing import Dict, List, Any, Optional, Union
from datetime import datetime

from app.services.mcp_service import get_mcp_service

logger = logging.getLogger(__name__)

class ETLConnector:
    """Коннектор для взаимодействия с ETL процессами."""
    
    @staticmethod
    async def extract_market_data(symbols: List[str] = None) -> Dict[str, Any]:
        """
        Извлечение данных рынка из источника.
        
        Args:
            symbols: Список символов для извлечения (опционально)
            
        Returns:
            Dict с данными рынка
        """
        try:
            mcp = await get_mcp_service()
            
            # Используем MCP для получения данных
            market_data = await mcp.get_market_data("all", force_update=True)
            
            # Фильтруем данные по символам, если указаны
            if symbols:
                filtered_data = {}
                for symbol in symbols:
                    if symbol in market_data:
                        filtered_data[symbol] = market_data[symbol]
                market_data = filtered_data
                
            # Уведомляем подписчиков через MCP
            await mcp.publish_event("market_data_extracted", {
                "count": len(market_data),
                "symbols": list(market_data.keys()),
                "timestamp": datetime.now().isoformat()
            })
            
            return {
                "status": "success",
                "data": market_data,
                "count": len(market_data),
                "timestamp": datetime.now().isoformat()
            }
        
        except Exception as e:
            logger.error(f"Error extracting market data: {e}")
            return {
                "status": "error",
                "error": str(e),
                "timestamp": datetime.now().isoformat()
            }
    
    @staticmethod
    async def transform_data(data: Dict[str, Any], transformation_type: str) -> Dict[str, Any]:
        """
        Преобразование данных.
        
        Args:
            data: Данные для преобразования
            transformation_type: Тип преобразования
            
        Returns:
            Dict с преобразованными данными
            
        Raises:
            ValueError: Если тип преобразования не поддерживается
        """
        try:
            if transformation_type == "market_data_normalization":
                # Нормализация данных рынка
                normalized_data = {}
                
                for symbol, info in data.items():
                    normalized_data[symbol] = {
                        "price": float(info.get("price", 0)),
                        "volume_24h": float(info.get("volume", 0)),
                        "change_24h_percent": float(info.get("change_24h_percent", 0)),
                        "high_24h": float(info.get("high_24h", 0)),
                        "low_24h": float(info.get("low_24h", 0)),
                        "normalized_at": datetime.now().isoformat()
                    }
                
                return {
                    "status": "success",
                    "transformation_type": transformation_type,
                    "data": normalized_data,
                    "count": len(normalized_data),
                    "timestamp": datetime.now().isoformat()
                }
                
            elif transformation_type == "trade_data_enrichment":
                # Обогащение торговых данных
                if "trades" not in data:
                    raise ValueError("No trades found in data")
                    
                trades = data["trades"]
                enriched_trades = []
                
                for trade in trades:
                    # Добавляем дополнительные поля
                    enriched_trade = trade.copy()
                    
                    # Добавляем базовую и котировочную валюты
                    if "/" in trade.get("symbol", ""):
                        base, quote = trade["symbol"].split("/")
                        enriched_trade["base_currency"] = base
                        enriched_trade["quote_currency"] = quote
                    
                    # Добавляем стоимость сделки
                    if "price" in trade and "amount" in trade:
                        enriched_trade["value"] = float(trade["price"]) * float(trade["amount"])
                    
                    enriched_trades.append(enriched_trade)
                
                return {
                    "status": "success",
                    "transformation_type": transformation_type,
                    "data": {"trades": enriched_trades},
                    "count": len(enriched_trades),
                    "timestamp": datetime.now().isoformat()
                }
                
            else:
                raise ValueError(f"Unsupported transformation type: {transformation_type}")
                
        except Exception as e:
            logger.error(f"Error transforming data: {e}")
            return {
                "status": "error",
                "transformation_type": transformation_type,
                "error": str(e),
                "timestamp": datetime.now().isoformat()
            }
    
    @staticmethod
    async def load_data(data: Dict[str, Any], destination: str, params: Dict[str, Any] = None) -> Dict[str, Any]:
        """
        Загрузка данных в хранилище.
        
        Args:
            data: Данные для загрузки
            destination: Место назначения для загрузки (cache, db, bigquery и т.д.)
            params: Дополнительные параметры (опционально)
            
        Returns:
            Dict с результатами загрузки
        """
        try:
            params = params or {}
            mcp = await get_mcp_service()
            
            if destination == "cache":
                # Загрузка в кэш MCP
                key = params.get("key")
                if not key:
                    raise ValueError("Key parameter is required for cache destination")
                    
                ttl = params.get("ttl")
                
                # Сохраняем данные в кэше
                success = await mcp.set_cached_data(key, data, ttl)
                
                if success:
                    return {
                        "status": "success",
                        "destination": destination,
                        "key": key,
                        "ttl": ttl,
                        "timestamp": datetime.now().isoformat()
                    }
                else:
                    raise ValueError("Failed to save data in cache")
                    
            elif destination == "db":
                # Загрузка в базу данных (заглушка)
                table = params.get("table")
                if not table:
                    raise ValueError("Table parameter is required for db destination")
                
                # В реальном приложении здесь будет загрузка в базу данных
                
                return {
                    "status": "success",
                    "destination": destination,
                    "table": table,
                    "rows": len(data),
                    "timestamp": datetime.now().isoformat()
                }
                
            elif destination == "bigquery":
                # Загрузка в BigQuery (заглушка)
                dataset = params.get("dataset")
                table = params.get("table")
                
                if not dataset or not table:
                    raise ValueError("Dataset and table parameters are required for BigQuery destination")
                
                # В реальном приложении здесь будет загрузка в BigQuery
                
                return {
                    "status": "success",
                    "destination": destination,
                    "dataset": dataset,
                    "table": table,
                    "rows": len(data),
                    "timestamp": datetime.now().isoformat()
                }
                
            else:
                raise ValueError(f"Unsupported destination: {destination}")
                
        except Exception as e:
            logger.error(f"Error loading data: {e}")
            return {
                "status": "error",
                "destination": destination,
                "error": str(e),
                "timestamp": datetime.now().isoformat()
            }