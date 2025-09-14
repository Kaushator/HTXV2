#!/usr/bin/env python3
"""
Запуск всех тестов для MCP Service.
"""
import argparse
import asyncio
import logging
import os
import sys
import time
from pathlib import Path

# Добавляем корневую директорию проекта в sys.path для корректных импортов
sys.path.append(str(Path(__file__).parent.parent))

# Настраиваем логирование
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)

# Определяем путь к директории скриптов
SCRIPTS_DIR = Path(__file__).parent
TEST_SCRIPTS = {
    "websocket": SCRIPTS_DIR / "test_mcp_simple.py",
    "trading": SCRIPTS_DIR / "test_mcp_trading_analysis.py",
    "file": SCRIPTS_DIR / "test_mcp_file_processing.py",
    "etl": SCRIPTS_DIR / "test_mcp_etl_pipeline.py",
}

async def start_server():
    """Запуск сервера в фоновом режиме."""
    logger.info("Запуск FastAPI сервера с MCP-сервисом")
    
    # Команда для запуска сервера
    server_cmd = "cd /workspaces/HTXV2/backend && source venv/bin/activate && " \
                 "python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000"
    
    # Запускаем сервер в фоновом режиме
    proc = await asyncio.create_subprocess_shell(
        server_cmd,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE,
        shell=True
    )
    
    # Ждем 5 секунд для запуска сервера
    logger.info("Ожидание запуска сервера...")
    await asyncio.sleep(5)
    
    return proc

async def run_test(test_script, args=""):
    """
    Запуск тестового скрипта.
    
    Args:
        test_script: Путь к тестовому скрипту
        args: Аргументы для скрипта (опционально)
    """
    cmd = f"cd /workspaces/HTXV2 && source backend/venv/bin/activate && python {test_script} {args}"
    
    logger.info(f"Запуск теста: {test_script.name}")
    
    proc = await asyncio.create_subprocess_shell(
        cmd,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE,
        shell=True
    )
    
    stdout, stderr = await proc.communicate()
    
    if stdout:
        logger.info(f"Результаты теста {test_script.name}:")
        print(stdout.decode())
    
    if stderr:
        logger.error(f"Ошибки при выполнении теста {test_script.name}:")
        print(stderr.decode())
    
    return proc.returncode

async def main(tests_to_run=None):
    """
    Основная функция для запуска тестов.
    
    Args:
        tests_to_run: Список тестов для запуска (опционально)
    """
    # Останавливаем все процессы uvicorn, если они запущены
    os.system("pkill -f uvicorn || true")
    time.sleep(1)
    
    # Запускаем сервер
    server_proc = await start_server()
    
    try:
        # Определяем, какие тесты запускать
        if tests_to_run:
            tests = {k: v for k, v in TEST_SCRIPTS.items() if k in tests_to_run}
        else:
            tests = TEST_SCRIPTS
        
        # Запускаем тесты по очереди
        for test_name, test_script in tests.items():
            logger.info(f"=== Запуск теста: {test_name} ===")
            await run_test(test_script)
            logger.info(f"=== Завершение теста: {test_name} ===\n")
            # Делаем паузу между тестами
            await asyncio.sleep(2)
            
    finally:
        # Останавливаем сервер
        logger.info("Остановка сервера...")
        server_proc.terminate()
        await server_proc.wait()
        
        # На всякий случай убиваем все процессы uvicorn
        os.system("pkill -f uvicorn || true")

if __name__ == "__main__":
    # Парсим аргументы командной строки
    parser = argparse.ArgumentParser(description="Запуск тестов для MCP Service")
    parser.add_argument(
        "--tests",
        nargs="*",
        choices=TEST_SCRIPTS.keys(),
        help="Список тестов для запуска (websocket, trading, file, etl)"
    )
    
    args = parser.parse_args()
    
    # Запускаем тесты
    asyncio.run(main(args.tests))