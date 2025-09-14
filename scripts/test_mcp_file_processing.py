#!/usr/bin/env python3
"""
Скрипт для тестирования обработки файлов через MCP Data Analyzer.
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

async def test_file_processing(file_path: str):
    """
    Тестирование обработки файлов через MCPDataAnalyzer.
    
    Args:
        file_path: Путь к файлу для обработки
    """
    logger.info(f"Обработка файла {file_path}")
    
    try:
        # Проверяем существование файла
        file = Path(file_path)
        if not file.exists():
            logger.error(f"Файл {file_path} не найден")
            return
            
        # Определяем тип файла по расширению
        file_type = None
        if file.suffix.lower() == ".csv":
            file_type = "csv"
        elif file.suffix.lower() in [".xlsx", ".xls"]:
            file_type = "excel"
        else:
            logger.error(f"Неподдерживаемый тип файла: {file.suffix}")
            return
            
        # Читаем содержимое файла
        file_content = file.read_bytes()
        
        # Генерируем уникальный client_id для тестирования
        client_id = f"test_client_{uuid.uuid4()}"
        
        # Инициализируем MCP Service
        logger.info("Инициализация MCP Service")
        mcp = await get_mcp_service()
        
        # Обрабатываем файл
        logger.info(f"Обработка файла {file.name} типа {file_type}")
        result = await MCPToolsIntegration.process_file_data(
            client_id=client_id,
            file_content=file_content,
            filename=file.name,
            file_type=file_type
        )
        
        # Выводим результаты обработки
        logger.info("Результаты обработки файла:")
        print_file_processing_results(result)
        
    except Exception as e:
        logger.error(f"Ошибка при обработке файла: {e}")

def print_file_processing_results(result: dict):
    """
    Вывод результатов обработки файла в консоль.
    
    Args:
        result: Результаты обработки файла
    """
    if result.get("status") == "error":
        logger.error(f"Ошибка обработки: {result.get('error')}")
        return
        
    # Получаем данные из результатов
    data = result.get("data", {})
    
    # Выводим общую информацию
    print("\n" + "=" * 50)
    print(f"Статус: {result.get('status')}")
    print(f"Файл: {data.get('filename')}")
    print(f"Тип: {data.get('type')}")
    print(f"Строк: {data.get('rows')}")
    print(f"Столбцы: {', '.join(data.get('columns', []))}")
    print("-" * 50)
    
    # Выводим статистику
    if "stats" in data:
        stats = data["stats"]
        
        # Выводим информацию о пропущенных значениях
        if "missing_values" in stats:
            print("\nПРОПУЩЕННЫЕ ЗНАЧЕНИЯ:")
            for col, count in stats["missing_values"].items():
                if count > 0:
                    print(f"  {col}: {count}")
        
        # Выводим информацию о типах данных
        if "dtypes" in stats:
            print("\nТИПЫ ДАННЫХ:")
            for col, dtype in stats["dtypes"].items():
                print(f"  {col}: {dtype}")
        
        # Выводим сводную статистику для числовых столбцов
        if "summary" in stats and "numeric" in stats["summary"]:
            print("\nСТАТИСТИКА ПО ЧИСЛОВЫМ СТОЛБЦАМ:")
            for col, values in stats["summary"]["numeric"].items():
                print(f"\n  {col}:")
                for stat_name, stat_value in values.items():
                    print(f"    {stat_name}: {stat_value}")
        
        # Выводим информацию о категориальных столбцах
        if "summary" in stats and "categorical" in stats["summary"]:
            print("\nСТАТИСТИКА ПО КАТЕГОРИАЛЬНЫМ СТОЛБЦАМ:")
            for col, values in stats["summary"]["categorical"].items():
                print(f"\n  {col}:")
                print(f"    Уникальных значений: {values.get('unique_values')}")
                print("    Топ значения:")
                for val, count in values.get("top_values", {}).items():
                    print(f"      {val}: {count}")
    
    # Выводим превью данных
    if "data" in data:
        print("\nПРЕВЬЮ ДАННЫХ:")
        preview_limit = data.get("preview_limit", 5)
        preview_data = data["data"][:min(5, len(data["data"]))]
        
        # Выводим данные в табличном формате
        cols = data.get("columns", [])
        if cols:
            # Определяем ширину каждой колонки
            col_width = {}
            for col in cols:
                col_width[col] = max(len(col), max([len(str(row.get(col, ""))) for row in preview_data]) + 2)
                
            # Выводим заголовки
            header = " | ".join([col.ljust(col_width[col]) for col in cols])
            print(f"\n{header}")
            print("-" * len(header))
            
            # Выводим данные
            for row in preview_data:
                row_str = " | ".join([str(row.get(col, "")).ljust(col_width[col]) for col in cols])
                print(row_str)
            
            # Если есть ещё данные
            if len(data["data"]) > preview_limit:
                print(f"\n... и еще {len(data['data']) - preview_limit} строк")
    
    print("=" * 50)

async def main():
    """Основная функция."""
    if len(sys.argv) < 2:
        file_path = str(Path(__file__).parent / "sample_trades.csv")
        logger.info(f"Путь к файлу не указан, используется файл по умолчанию: {file_path}")
    else:
        file_path = sys.argv[1]
    
    await test_file_processing(file_path)

if __name__ == "__main__":
    asyncio.run(main())