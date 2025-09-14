# MCP Tools и Integration Guide

## Общий обзор

Master Control Program (MCP) - это центральный сервис для координации задач и потоков данных в HTXV2. Этот репозиторий содержит инструменты для интеграции с MCP и проведения анализа данных.

## Компоненты

1. **MCP Service** (`backend/app/services/mcp_service.py`) - основной сервис для управления WebSocket подключениями, задачами и кэшем.
2. **MCP Data Analyzer** (`backend/app/services/mcp_data_analyzer.py`) - сервис для анализа данных через инструменты.
3. **MCP Tools Integration** (`backend/app/services/mcp_tools_integration.py`) - высокоуровневый интерфейс для интеграции с инструментами.
4. **ETL Connector** (`backend/app/services/etl_connector.py`) - интеграция с ETL процессами.
5. **Tools** (`backend/app/tools/`) - набор инструментов для анализа и обработки данных:
   - `data_processor.py` - обработка CSV/XLSX файлов
   - `trading_analyzer.py` - анализ торговых данных

## Тестовые скрипты

Репозиторий включает несколько тестовых скриптов для проверки работоспособности MCP и инструментов:

1. **WebSocket Test** (`scripts/test_mcp_simple.py`) - базовое тестирование WebSocket соединения с MCP.
2. **Trading Analysis Test** (`scripts/test_mcp_trading_analysis.py`) - тестирование анализа торговых данных.
3. **File Processing Test** (`scripts/test_mcp_file_processing.py`) - тестирование обработки CSV/XLSX файлов.
4. **ETL Pipeline Test** (`scripts/test_mcp_etl_pipeline.py`) - тестирование ETL пайплайна.

## Запуск тестов

Для запуска всех тестов используйте скрипт:

```bash
./scripts/run_mcp_tests.py
```

Для запуска конкретных тестов используйте параметр `--tests`:

```bash
# Запуск теста WebSocket
./scripts/run_mcp_tests.py --tests websocket

# Запуск тестов анализа торговых данных и ETL пайплайна
./scripts/run_mcp_tests.py --tests trading etl
```

## Рекомендации по оптимизации

Смотрите файл `docs/MCP_OPTIMIZATION.md` для ознакомления с рекомендациями по оптимизации MCP Service.

## Примеры использования

### 1. Анализ торговых данных

```python
from backend.app.services.mcp_tools_integration import MCPToolsIntegration

# Анализ торговых данных
result = await MCPToolsIntegration.process_trading_data(
    client_id="your_client_id",
    data={
        "trades": trades_list,
        "analysis_type": "full",
        "include_fees": True
    }
)
```

### 2. Обработка файлов

```python
from backend.app.services.mcp_tools_integration import MCPToolsIntegration

# Чтение и обработка файла
with open("path/to/file.csv", "rb") as f:
    file_content = f.read()

result = await MCPToolsIntegration.process_file_data(
    client_id="your_client_id",
    file_content=file_content,
    filename="file.csv",
    file_type="csv"
)
```

### 3. Запуск ETL пайплайна

```python
from backend.app.services.mcp_tools_integration import MCPToolsIntegration

# Запуск ETL пайплайна
pipeline_config = {
    "name": "market_data_pipeline",
    "steps": [
        {"type": "extract", "symbols": ["BTC/USDT", "ETH/USDT"]},
        {"type": "transform", "transformation_type": "market_data_normalization"},
        {"type": "load", "destination": "cache", "params": {"key": "market_data"}}
    ]
}

result = await MCPToolsIntegration.run_etl_pipeline(
    client_id="your_client_id",
    pipeline_config=pipeline_config
)
```

## WebSocket API

MCP предоставляет WebSocket API для подключения клиентов и работы с данными в реальном времени:

1. **Endpoint**: `ws://localhost:8000/ws/mcp`

2. **Сообщения**:
   - `{"type": "ping", "timestamp": 123456789}` - проверка соединения
   - `{"type": "subscribe", "topics": ["market_data"]}` - подписка на топик
   - `{"type": "unsubscribe", "topics": ["market_data"]}` - отписка от топика
   - `{"type": "fetch_data", "data_type": "market_data", "params": {}}` - запрос данных
   - `{"type": "analyze_data", "analysis_type": "pnl", "data": {...}}` - запрос на анализ данных
   - `{"type": "run_task", "task_name": "import_data", "params": {...}}` - запуск задачи