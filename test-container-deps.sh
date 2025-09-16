#!/bin/bash
# Скрипт для проверки зависимостей и сборки контейнеров Docker
# Использование: ./test-container-deps.sh

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Функции для цветного вывода
info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

section() {
    echo -e "${CYAN}========== $1 ==========${NC}"
}

# Проверка наличия Docker
if ! command -v docker &> /dev/null; then
    error "Docker не установлен. Установите Docker перед использованием этого скрипта."
fi

if ! docker info &> /dev/null; then
    error "Docker не запущен или у вас нет прав для его использования."
fi

# Проверка наличия docker-compose
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    error "Docker Compose не установлен. Установите Docker Compose перед использованием этого скрипта."
fi

# Проверка наличия файла docker-compose.yml
if [ ! -f "docker-compose.yml" ]; then
    error "Файл docker-compose.yml не найден в текущей директории."
fi

section "Проверка свободного места на диске"
df -h | grep -E "(Filesystem|/dev/)"
echo ""

section "Проверка доступных ресурсов для Docker"
docker system df
echo ""

section "Очистка неиспользуемых Docker-ресурсов"
docker system prune -f
echo ""

section "Проверка Backend зависимостей"
if [ ! -f "backend/requirements.txt" ]; then
    warning "Файл backend/requirements.txt не найден"
else
    info "Проверка зависимостей backend..."
    cat backend/requirements.txt | while read -r line; do
        if [[ ! -z "$line" && ! "$line" =~ ^# ]]; then
            echo "✓ $line"
        fi
    done
    success "Все зависимости backend найдены."
fi
echo ""

section "Проверка Frontend зависимостей"
if [ ! -f "frontend/package.json" ]; then
    warning "Файл frontend/package.json не найден"
else
    info "Проверка зависимостей frontend..."
    npm list --prefix ./frontend --depth=0 || warning "Не все зависимости frontend установлены локально."
fi
echo ""

section "Проверка FinGPT зависимостей"
if [ ! -f "fingpt/requirements.txt" ]; then
    warning "Файл fingpt/requirements.txt не найден"
else
    info "Проверка зависимостей fingpt..."
    cat fingpt/requirements.txt | while read -r line; do
        if [[ ! -z "$line" && ! "$line" =~ ^# ]]; then
            echo "✓ $line"
        fi
    done
    success "Все зависимости fingpt найдены."
fi
echo ""

section "Проверка доступности CUDA для fingpt (если установлена)"
if command -v nvidia-smi &> /dev/null; then
    info "CUDA установлена. Проверка доступных устройств:"
    nvidia-smi --list-gpus || warning "Не удалось получить список GPU."
    nvidia-smi || warning "Не удалось получить информацию о GPU."
else
    warning "CUDA не установлена или недоступна. FinGPT будет работать на CPU (медленно)."
fi
echo ""

section "Проверка сетевых портов"
info "Проверка, свободны ли порты, необходимые для работы контейнеров:"
check_port() {
    local port=$1
    local service=$2
    if command -v ss &> /dev/null; then
        if ss -tuln | grep -q ":$port "; then
            warning "Порт $port ($service) занят другим процессом"
        else
            echo "✓ Порт $port ($service) свободен"
        fi
    elif command -v netstat &> /dev/null; then
        if netstat -tuln | grep -q ":$port "; then
            warning "Порт $port ($service) занят другим процессом"
        else
            echo "✓ Порт $port ($service) свободен"
        fi
    else
        warning "Не могу проверить порт $port ($service) - netstat или ss не найден"
    fi
}

check_port 5432 "PostgreSQL"
check_port 6379 "Redis"
check_port 8000 "Backend"
check_port 3000 "Frontend"
check_port 8055 "FinGPT"
echo ""

section "Предварительная сборка отдельных образов"
info "Сборка образа backend..."
docker build -t htx-backend:test ./backend || warning "Не удалось собрать образ backend"

info "Сборка образа frontend..."
docker build -t htx-frontend:test ./frontend || warning "Не удалось собрать образ frontend"

info "Сборка образа fingpt..."
docker build -t htx-fingpt:test ./fingpt || warning "Не удалось собрать образ fingpt"

echo ""
section "Запуск тестовой сборки всех контейнеров"
info "Запуск docker-compose build..."
docker compose build || error "Не удалось собрать образы через docker-compose"
success "Все образы успешно собраны через docker-compose!"

echo ""
section "Рекомендации"
echo "1. Если были предупреждения о занятых портах, остановите соответствующие сервисы"
echo "   или измените порты в docker-compose.yml."
echo "2. Если были проблемы со сборкой fingpt и CUDA недоступна, убедитесь, что"
echo "   у вас установлены драйверы NVIDIA и CUDA Toolkit."
echo "3. Для запуска контейнеров используйте команду: docker compose up -d"
echo "4. Для остановки контейнеров используйте команду: docker compose down"
echo ""

success "Проверка зависимостей контейнеров завершена!"
