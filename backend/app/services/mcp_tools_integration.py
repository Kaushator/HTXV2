"""
MCP Tools Integration - интеграция инструментов и сервисов с MCP.
"""
import asyncio
import logging
from typing import Dict, List, Any, Optional, Union
from datetime import datetime

from app.services.mcp_service import get_mcp_service
from app.services.mcp_data_analyzer import MCPDataAnalyzer
from app.services.etl_connector import ETLConnector

logger = logging.getLogger(__name__)

class MCPToolsIntegration:
    """Класс для интеграции инструментов с MCP Service."""
    
    @staticmethod
    async def register_tools(mcp):
        """
        Регистрирует инструменты в MCP сервисе.
        
        Args:
            mcp: Экземпляр MCP Service
        """
        # Здесь в будущем можно регистрировать дополнительные инструменты
        logger.info("Registering tools with MCP Service")
    
    @staticmethod
    async def process_trading_data(client_id: str, data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Обработка торговых данных с использованием интегрированных инструментов.
        
        Args:
            client_id: ID клиента
            data: Данные для обработки
            
        Returns:
            Dict с результатами обработки
        """
        try:
            mcp = await get_mcp_service()
            
            # Проверяем наличие необходимых данных
            if "trades" not in data:
                raise ValueError("No trades data provided")
                
            trades = data["trades"]
            analysis_type = data.get("analysis_type", "full")
            include_fees = data.get("include_fees", True)
            
            # Уведомляем клиента о начале обработки
            await mcp.send_message(client_id, {
                "type": "processing_started",
                "message": f"Started processing {len(trades)} trades",
                "timestamp": datetime.now().isoformat()
            })
            
            # Используем MCPDataAnalyzer для анализа данных
            result = await MCPDataAnalyzer.analyze_trading_data(
                trades=trades,
                analysis_type=analysis_type,
                include_fees=include_fees
            )
            
            # Уведомляем клиента о завершении обработки
            await mcp.send_message(client_id, {
                "type": "processing_completed",
                "message": f"Completed processing {len(trades)} trades",
                "result": result,
                "timestamp": datetime.now().isoformat()
            })
            
            return result
            
        except Exception as e:
            logger.error(f"Error processing trading data: {e}")
            
            # Уведомляем клиента об ошибке
            mcp = await get_mcp_service()
            await mcp.send_message(client_id, {
                "type": "processing_error",
                "message": f"Error processing trading data: {str(e)}",
                "timestamp": datetime.now().isoformat()
            })
            
            return {
                "status": "error",
                "error": str(e),
                "timestamp": datetime.now().isoformat()
            }
    
    @staticmethod
    async def process_file_data(client_id: str, file_content: bytes, filename: str, file_type: Optional[str] = None) -> Dict[str, Any]:
        """
        Обработка файловых данных с использованием интегрированных инструментов.
        
        Args:
            client_id: ID клиента
            file_content: Содержимое файла в байтах
            filename: Имя файла
            file_type: Тип файла (опционально)
            
        Returns:
            Dict с результатами обработки
        """
        try:
            mcp = await get_mcp_service()
            
            # Уведомляем клиента о начале обработки
            await mcp.send_message(client_id, {
                "type": "processing_started",
                "message": f"Started processing file {filename}",
                "timestamp": datetime.now().isoformat()
            })
            
            # Используем MCPDataAnalyzer для обработки файла
            result = await MCPDataAnalyzer.process_file_data(
                file_content=file_content,
                filename=filename,
                file_type=file_type
            )
            
            # Уведомляем клиента о завершении обработки
            await mcp.send_message(client_id, {
                "type": "processing_completed",
                "message": f"Completed processing file {filename}",
                "result": result,
                "timestamp": datetime.now().isoformat()
            })
            
            return result
            
        except Exception as e:
            logger.error(f"Error processing file data: {e}")
            
            # Уведомляем клиента об ошибке
            mcp = await get_mcp_service()
            await mcp.send_message(client_id, {
                "type": "processing_error",
                "message": f"Error processing file {filename}: {str(e)}",
                "timestamp": datetime.now().isoformat()
            })
            
            return {
                "status": "error",
                "error": str(e),
                "filename": filename,
                "timestamp": datetime.now().isoformat()
            }
    
    @staticmethod
    async def run_etl_pipeline(client_id: str, pipeline_config: Dict[str, Any]) -> Dict[str, Any]:
        """
        Запуск ETL пайплайна с использованием интегрированных инструментов.
        
        Args:
            client_id: ID клиента
            pipeline_config: Конфигурация пайплайна
            
        Returns:
            Dict с результатами выполнения пайплайна
        """
        try:
            mcp = await get_mcp_service()
            
            # Проверяем наличие необходимых данных
            if "steps" not in pipeline_config:
                raise ValueError("No pipeline steps provided")
                
            steps = pipeline_config["steps"]
            
            # Уведомляем клиента о начале выполнения пайплайна
            await mcp.send_message(client_id, {
                "type": "pipeline_started",
                "message": f"Started ETL pipeline with {len(steps)} steps",
                "timestamp": datetime.now().isoformat()
            })
            
            # Выполняем шаги пайплайна
            results = []
            current_data = None
            
            for i, step in enumerate(steps):
                step_type = step.get("type")
                
                # Уведомляем о выполнении текущего шага
                await mcp.send_message(client_id, {
                    "type": "pipeline_step",
                    "message": f"Executing step {i+1}/{len(steps)}: {step_type}",
                    "step": i+1,
                    "total_steps": len(steps),
                    "timestamp": datetime.now().isoformat()
                })
                
                if step_type == "extract":
                    # Извлечение данных
                    symbols = step.get("symbols")
                    current_data = await ETLConnector.extract_market_data(symbols)
                    
                elif step_type == "transform":
                    # Преобразование данных
                    if not current_data:
                        raise ValueError("No data to transform")
                        
                    transformation_type = step.get("transformation_type")
                    if not transformation_type:
                        raise ValueError("No transformation type specified")
                        
                    current_data = await ETLConnector.transform_data(
                        data=current_data.get("data", {}),
                        transformation_type=transformation_type
                    )
                    
                elif step_type == "load":
                    # Загрузка данных
                    if not current_data:
                        raise ValueError("No data to load")
                        
                    destination = step.get("destination")
                    if not destination:
                        raise ValueError("No destination specified")
                        
                    params = step.get("params", {})
                    
                    current_data = await ETLConnector.load_data(
                        data=current_data.get("data", {}),
                        destination=destination,
                        params=params
                    )
                    
                elif step_type == "analyze":
                    # Анализ данных
                    if not current_data:
                        raise ValueError("No data to analyze")
                        
                    analysis_type = step.get("analysis_type")
                    if not analysis_type:
                        raise ValueError("No analysis type specified")
                        
                    # Определяем тип данных
                    if "trades" in current_data.get("data", {}):
                        # Торговые данные
                        trades = current_data.get("data", {}).get("trades", [])
                        current_data = await MCPDataAnalyzer.analyze_trading_data(
                            trades=trades,
                            analysis_type=analysis_type
                        )
                    else:
                        # Рыночные данные
                        market_data = current_data.get("data", {})
                        current_data = await MCPDataAnalyzer.analyze_market_data(
                            market_data=market_data,
                            analysis_type=analysis_type
                        )
                        
                else:
                    raise ValueError(f"Unsupported pipeline step type: {step_type}")
                    
                # Сохраняем результат шага
                results.append({
                    "step": i+1,
                    "type": step_type,
                    "status": current_data.get("status"),
                    "timestamp": datetime.now().isoformat()
                })
            
            # Уведомляем клиента о завершении выполнения пайплайна
            await mcp.send_message(client_id, {
                "type": "pipeline_completed",
                "message": f"Completed ETL pipeline with {len(steps)} steps",
                "results": results,
                "timestamp": datetime.now().isoformat()
            })
            
            return {
                "status": "success",
                "pipeline": pipeline_config.get("name", "unnamed"),
                "steps": len(steps),
                "results": results,
                "final_data": current_data,
                "timestamp": datetime.now().isoformat()
            }
            
        except Exception as e:
            logger.error(f"Error running ETL pipeline: {e}")
            
            # Уведомляем клиента об ошибке
            mcp = await get_mcp_service()
            await mcp.send_message(client_id, {
                "type": "pipeline_error",
                "message": f"Error running ETL pipeline: {str(e)}",
                "timestamp": datetime.now().isoformat()
            })
            
            return {
                "status": "error",
                "pipeline": pipeline_config.get("name", "unnamed"),
                "error": str(e),
                "timestamp": datetime.now().isoformat()
            }