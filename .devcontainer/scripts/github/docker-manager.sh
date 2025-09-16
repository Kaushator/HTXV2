#!/bin/bash
# Скрипт для проверки и запуска контейнеров Docker
# Использование: ./docker-manager.sh [start|stop|status|restart|logs]

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Проверка наличия Docker
check_docker() {
    if ! command -v docker &> /dev/null; then
        error "Docker не установлен. Установите Docker перед использованием этого скрипта."
    fi

    if ! docker info &> /dev/null; then
        error "Docker не запущен или у вас нет прав для его использования."
    fi
}

# Проверка наличия docker-compose
check_docker_compose() {
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        error "Docker Compose не установлен. Установите Docker Compose перед использованием этого скрипта."
    fi
}

# Проверка наличия файла docker-compose.yml
check_compose_file() {
    if [ ! -f "docker-compose.yml" ]; then
        error "Файл docker-compose.yml не найден в текущей директории."
    fi
}

# Запуск контейнеров
start_containers() {
    info "Запуск контейнеров Docker..."

    if docker compose up -d --build; then
        success "Контейнеры успешно запущены."
    else
        error "Не удалось запустить контейнеры."
    fi
}

# Остановка контейнеров
stop_containers() {
    info "Остановка контейнеров Docker..."

    if docker compose down; then
        success "Контейнеры успешно остановлены."
    else
        error "Не удалось остановить контейнеры."
    fi
}

# Перезапуск контейнеров
restart_containers() {
    info "Перезапуск контейнеров Docker..."

    stop_containers
    start_containers
}

# Проверка статуса контейнеров
check_status() {
    info "Проверка статуса контейнеров Docker..."

    docker compose ps
}

# Просмотр логов контейнеров
show_logs() {
    info "Вывод логов контейнеров Docker..."

    if [ -z "$2" ]; then
        docker compose logs
    else
        docker compose logs "$2"
    fi
}

# Основная логика
main() {
    check_docker
    check_docker_compose
    check_compose_file

    case "$1" in
        start)
            start_containers
            ;;
        stop)
            stop_containers
            ;;
        restart)
            restart_containers
            ;;
        status)
            check_status
            ;;
        logs)
            show_logs "$@"
            ;;
        *)
            echo "Использование: $0 [start|stop|status|restart|logs [имя_сервиса]]"
            echo ""
            echo "Команды:"
            echo "  start    - Запуск контейнеров"
            echo "  stop     - Остановка контейнеров"
            echo "  restart  - Перезапуск контейнеров"
            echo "  status   - Проверка статуса контейнеров"
            echo "  logs     - Вывод логов контейнеров (опционально можно указать имя сервиса)"
            exit 1
            ;;
    esac
}

main "$@"
