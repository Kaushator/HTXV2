#!/usr/bin/env python3
"""
Скрипт для тестирования анализа торговых данных через MCP Tools Integration.
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

async def test_trading_analysis(trades_file: str):
    """
    Тестирование анализа торговых данных через MCPToolsIntegration.
    
    Args:
        trades_file: Путь к файлу с тестовыми торговыми данными
    """
    logger.info(f"Загрузка торговых данных из файла {trades_file}")
    
    try:
        # Загружаем данные из файла
        with open(trades_file, 'r') as f:
            data = json.load(f)
            
        if "trades" not in data:
            logger.error("В файле отсутствует ключ 'trades'")
            return
            
        trades = data["trades"]
        logger.info(f"Загружено {len(trades)} торговых записей")
        
        # Генерируем уникальный client_id для тестирования
        client_id = f"test_client_{uuid.uuid4()}"
        
        # Инициализируем MCP Service
        logger.info("Инициализация MCP Service")
        mcp = await get_mcp_service()
        
        # Тестируем полный анализ торговых данных
        logger.info("Запуск полного анализа торговых данных")
        full_analysis = await MCPToolsIntegration.process_trading_data(
            client_id=client_id,
            data={
                "trades": trades,
                "analysis_type": "full",
                "include_fees": True
            }
        )
        
        logger.info("Результаты полного анализа:")
        print_analysis_results(full_analysis)
        
        # Тестируем только PnL расчет
        logger.info("Запуск расчета PnL")
        pnl_analysis = await MCPToolsIntegration.process_trading_data(
            client_id=client_id,
            data={
                "trades": trades,
                "analysis_type": "pnl",
                "include_fees": True
            }
        )
        
        logger.info("Результаты расчета PnL:")
        print_analysis_results(pnl_analysis)
        
        # Тестируем анализ без учета комиссий
        logger.info("Запуск анализа без учета комиссий")
        no_fees_analysis = await MCPToolsIntegration.process_trading_data(
            client_id=client_id,
            data={
                "trades": trades,
                "analysis_type": "full",
                "include_fees": False
            }
        )
        
        logger.info("Результаты анализа без учета комиссий:")
        print_analysis_results(no_fees_analysis)
        
        logger.info("Тестирование анализа торговых данных успешно завершено")
        
    except FileNotFoundError:
        logger.error(f"Файл {trades_file} не найден")
    except json.JSONDecodeError:
        logger.error(f"Ошибка декодирования JSON из файла {trades_file}")
    except Exception as e:
        logger.error(f"Ошибка при анализе торговых данных: {e}")

def print_analysis_results(results: dict):
    """
    Вывод результатов анализа в консоль.
    
    Args:
        results: Результаты анализа
    """
    if results.get("status") == "error":
        logger.error(f"Ошибка анализа: {results.get('error')}")
        return
        
    # Получаем данные из результатов
    data = results.get("data", {})
    
    # Выводим общую информацию
    print("\n" + "=" * 50)
    print(f"Статус: {results.get('status')}")
    print(f"Тип анализа: {results.get('analysis_type')}")
    print(f"Временная метка: {results.get('timestamp')}")
    print("-" * 50)
    
    # Выводим PnL данные, если доступны
    if "pnl" in data:
        pnl = data["pnl"]
        print("\nPnL АНАЛИЗ:")
        print(f"Общий PnL: {pnl.get('total_pnl', 0):.2f} USDT")
        print(f"Выигрышные сделки: {pnl.get('winning_trades', 0)}")
        print(f"Проигрышные сделки: {pnl.get('losing_trades', 0)}")
        print(f"Безубыточные сделки: {pnl.get('break_even_trades', 0)}")
        print(f"Винрейт: {pnl.get('win_rate', 0) * 100:.2f}%")
        print(f"Всего сделок: {pnl.get('trade_count', 0)}")
    
    # Выводим данные по символам, если доступны
    if "symbols" in data:
        print("\nАНАЛИЗ ПО СИМВОЛАМ:")
        for symbol, stats in data["symbols"].items():
            print(f"\n{symbol}:")
            print(f"  PnL: {stats.get('total_pnl', 0):.2f} USDT")
            print(f"  Винрейт: {stats.get('win_rate', 0) * 100:.2f}%")
            print(f"  Сделок: {stats.get('trade_count', 0)}")
    
    # Выводим метрики активности, если доступны
    if "metrics" in data:
        metrics = data["metrics"]
        if "hourly_activity" in metrics:
            print("\nАКТИВНОСТЬ ПО ЧАСАМ:")
            hours = sorted(metrics["hourly_activity"].items())
            for hour, count in hours:
                print(f"  {hour}:00 - {count} сделок")
        
        if "daily_activity" in metrics:
            print("\nАКТИВНОСТЬ ПО ДНЯМ НЕДЕЛИ:")
            days = sorted(metrics["daily_activity"].items())
            day_names = ["Понедельник", "Вторник", "Среда", "Четверг", "Пятница", "Суббота", "Воскресенье"]
            for day_num, count in days:
                print(f"  {day_names[int(day_num)]} - {count} сделок")
    
    print("=" * 50)

async def main():
    """Основная функция."""
    if len(sys.argv) < 2:
        trades_file = str(Path(__file__).parent / "sample_trades.json")
        logger.info(f"Путь к файлу не указан, используется файл по умолчанию: {trades_file}")
    else:
        trades_file = sys.argv[1]
    
    await test_trading_analysis(trades_file)

if __name__ == "__main__":
    asyncio.run(main())