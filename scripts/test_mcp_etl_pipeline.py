#!/usr/bin/env python3
"""
Скрипт для тестирования ETL пайплайна через MCP Tools Integration.
"""
import asyncio
import json
import logging
import sys
import uuid
from datetime import datetime
from pathlib import Path

# Настраиваем логирование
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)

# Импортируем необходимые модули
try:
    sys.path.insert(0, str(Path(__file__).parent.parent))
    from backend.app.services.mcp_tools_integration import MCPToolsIntegration
    from backend.app.services.mcp_service import get_mcp_service
except ImportError as e:
    logger.error(f"Ошибка импорта: {e}")
    sys.exit(1)

async def test_etl_pipeline():
    """
    Тестирование ETL пайплайна через MCPToolsIntegration.
    """
    logger.info("Запуск тестирования ETL пайплайна")
    
    try:
        # Генерируем уникальный client_id для тестирования
        client_id = f"test_client_{uuid.uuid4()}"
        
        # Инициализируем MCP Service
        logger.info("Инициализация MCP Service")
        mcp = await get_mcp_service()
        
        # Создаем конфигурацию ETL пайплайна
        pipeline_config = {
            "name": "test_market_data_pipeline",
            "steps": [
                # Шаг 1: Извлечение данных рынка
                {
                    "type": "extract",
                    "symbols": ["BTC/USDT", "ETH/USDT", "SOL/USDT"]
                },
                # Шаг 2: Преобразование данных рынка
                {
                    "type": "transform",
                    "transformation_type": "market_data_normalization"
                },
                # Шаг 3: Загрузка данных в кэш
                {
                    "type": "load",
                    "destination": "cache",
                    "params": {
                        "key": "normalized_market_data",
                        "ttl": 3600  # 1 час
                    }
                },
                # Шаг 4: Анализ данных
                {
                    "type": "analyze",
                    "analysis_type": "basic"
                }
            ]
        }
        
        # Запускаем ETL пайплайн
        logger.info("Запуск ETL пайплайна")
        result = await MCPToolsIntegration.run_etl_pipeline(
            client_id=client_id,
            pipeline_config=pipeline_config
        )
        
        # Выводим результаты выполнения пайплайна
        logger.info("Результаты выполнения ETL пайплайна:")
        print_etl_results(result)
        
        # Проверяем данные в кэше
        logger.info("Проверка данных в кэше")
        cached_data = await mcp.get_cached_data("normalized_market_data")
        
        if cached_data:
            logger.info("Данные успешно сохранены в кэше")
            print("\nДАННЫЕ ИЗ КЭША:")
            print(json.dumps(cached_data, indent=2, ensure_ascii=False))
        else:
            logger.warning("Данные не найдены в кэше")
        
        logger.info("Тестирование ETL пайплайна успешно завершено")
        
    except Exception as e:
        logger.error(f"Ошибка при выполнении ETL пайплайна: {e}")

def print_etl_results(result: dict):
    """
    Вывод результатов выполнения ETL пайплайна в консоль.
    
    Args:
        result: Результаты выполнения ETL пайплайна
    """
    if result.get("status") == "error":
        logger.error(f"Ошибка выполнения: {result.get('error')}")
        return
        
    # Выводим общую информацию
    print("\n" + "=" * 50)
    print(f"Статус: {result.get('status')}")
    print(f"Пайплайн: {result.get('pipeline')}")
    print(f"Шагов: {result.get('steps')}")
    print(f"Временная метка: {result.get('timestamp')}")
    print("-" * 50)
    
    # Выводим результаты выполнения шагов
    if "results" in result:
        print("\nРЕЗУЛЬТАТЫ ВЫПОЛНЕНИЯ ШАГОВ:")
        for step_result in result["results"]:
            print(f"\nШаг {step_result.get('step')}: {step_result.get('type')}")
            print(f"Статус: {step_result.get('status')}")
            print(f"Временная метка: {step_result.get('timestamp')}")
    
    # Выводим итоговые данные
    if "final_data" in result and result["final_data"].get("status") == "success":
        final_data = result["final_data"]
        data_type = list(final_data.keys())[1] if len(final_data.keys()) > 1 else None
        
        if data_type and data_type in final_data:
            print(f"\nИТОГОВЫЕ ДАННЫЕ ({data_type}):")
            print(json.dumps(final_data[data_type], indent=2, ensure_ascii=False)[:500] + "...")
    
    print("=" * 50)

async def main():
    """Основная функция."""
    await test_etl_pipeline()

if __name__ == "__main__":
    asyncio.run(main())