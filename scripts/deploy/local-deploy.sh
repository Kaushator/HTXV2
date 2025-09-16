#!/bin/bash
# local-deploy.sh - Скрипт для локального деплоя

set -e

echo "Начало процесса деплоя на локальную машину..."

# Создание необходимых директорий
echo "Создание директорий для данных и логов..."
mkdir -p ~/htx/data
mkdir -p ~/htx/logs

# Сборка образов
echo "Сборка Docker образов..."
docker compose -f docker-compose.build.yml build

# Сохранение текущих версий
echo "Сохранение текущих версий образов..."
if docker image inspect htx-interface-app:latest &> /dev/null; then
  docker tag htx-interface-app:latest htx-interface-app:previous
fi

if docker image inspect htx-fingpt:latest &> /dev/null; then
  docker tag htx-fingpt:latest htx-fingpt:previous
fi

# Деплой
echo "Деплой новой версии..."
docker compose -f docker-compose.local.yml down || true
docker compose -f docker-compose.local.yml up -d

echo "Деплой завершен. Приложение доступно по адресу:"
echo "  - Основное приложение: http://localhost:8000"
echo "  - FinGPT middleware: http://localhost:5000"
echo ""
echo "Логи доступны в директории ~/htx/logs"
