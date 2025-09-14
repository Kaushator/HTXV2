#!/bin/bash
set -e

echo "🚀 Запуск HTXV2 в режиме Codespaces (без GPU)"

# Установка зависимостей, если еще не установлены
if [ ! -d "backend/venv" ]; then
    echo "📦 Устанавливаем Python зависимости..."
    cd backend
    python -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt
    cd ..
fi

if [ ! -d "frontend/node_modules" ]; then
    echo "📦 Устанавливаем Node зависимости..."
    cd frontend
    npm install
    cd ..
fi

# Проверяем, доступен ли Docker
if command -v docker &> /dev/null; then
    # Запуск базы данных и Redis, если они не запущены
    if ! docker ps | grep -q postgres; then
        echo "🐘 Запускаем PostgreSQL..."
        docker compose -f docker/docker-compose.yml up -d postgres
    fi

    if ! docker ps | grep -q redis; then
        echo "🔄 Запускаем Redis..."
        docker compose -f docker/docker-compose.yml up -d redis
    fi
else
    echo "⚠️ Docker не обнаружен. Запускаем в режиме эмуляции (БД и Redis недоступны)"
    # Можно здесь добавить код для эмуляции Redis/PostgreSQL при необходимости
    # или запустить их через другой механизм
fi

# Запуск миграций (при наличии Docker)
if command -v docker &> /dev/null && docker ps | grep -q postgres; then
    echo "🔄 Применяем миграции..."
    cd backend
    source venv/bin/activate
    alembic upgrade head
    cd ..
fi

# Запуск backend и frontend
echo "🔙 Запускаем Backend..."
cd backend
source venv/bin/activate
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload &
BACKEND_PID=$!
cd ..

echo "🔜 Запускаем Frontend..."
cd frontend
npm run dev &
FRONTEND_PID=$!
cd ..

echo "✅ HTXV2 запущен!"
echo "📊 Frontend: http://localhost:3000"
echo "🔌 Backend API: http://localhost:8000"
echo "📚 API Docs: http://localhost:8000/docs"
echo ""
echo "⚠️ ВНИМАНИЕ: GPU функциональность отключена в Codespaces"
echo "⚡ MCP запущен в режиме без ML-моделей"
echo ""
echo "Нажмите Ctrl+C для завершения работы..."

# Функция для корректного завершения процессов
cleanup() {
    echo "Завершение работы..."
    kill $BACKEND_PID $FRONTEND_PID 2>/dev/null
    exit 0
}

# Настройка обработки сигнала прерывания
trap cleanup SIGINT

# Ожидание завершения
wait
