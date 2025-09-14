#!/bin/bash

# Добавляем корректный импорт в каждый тестовый скрипт
for script in test_mcp_trading_analysis.py test_mcp_file_processing.py test_mcp_etl_pipeline.py; do
    echo "Исправление импортов в $script..."
    
    # Проверяем существует ли строка с sys.path.insert(0, ...)
    if grep -q "sys.path.insert(0, str(Path(__file__).parent.parent))" "/workspaces/HTXV2/scripts/$script"; then
        echo "Импорты в $script уже исправлены"
    else
        # Добавляем корректные импорты после импорта pathlib.Path
        sed -i '/from pathlib import Path/a\
# Добавляем корневую директорию проекта в sys.path для корректных импортов\
sys.path.insert(0, str(Path(__file__).parent.parent))' "/workspaces/HTXV2/scripts/$script"
        echo "Импорты исправлены в $script"
    fi
done

echo "Все скрипты обновлены"