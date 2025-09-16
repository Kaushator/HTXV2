#!/bin/bash
# set-executable.sh
#
# Описание: Скрипт устанавливает права на выполнение для всех .sh файлов
# в указанной директории, с опцией рекурсивного поиска.
#
# Использование:
#   ./set-executable.sh [директория] [-r|--recursive]
#
# Параметры:
#   директория    - Путь к директории с bash-скриптами (по умолчанию - текущая директория)
#   -r, --recursive - Если указан, скрипт будет искать файлы рекурсивно в поддиректориях
#
# Пример:
#   ./set-executable.sh .devcontainer/scripts/github --recursive

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Функции для цветного вывода
info() {
    echo -e "${CYAN}[INFO]${NC} $1"
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

# Инициализация переменных
directory="."
recursive=false

# Парсинг параметров
while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--recursive)
            recursive=true
            shift
            ;;
        -*)
            error "Неизвестный параметр: $1"
            ;;
        *)
            directory=$1
            shift
            ;;
    esac
done

# Проверка существования директории
if [ ! -d "$directory" ]; then
    error "Директория '$directory' не существует."
fi

# Поиск bash-скриптов
info "Поиск bash-скриптов в директории '$directory'$(if $recursive; then echo " (рекурсивно)"; else echo ""; fi)..."

if [ "$recursive" = true ]; then
    scripts=$(find "$directory" -name "*.sh" -type f)
else
    scripts=$(find "$directory" -maxdepth 1 -name "*.sh" -type f)
fi

# Подсчет количества найденных скриптов
script_count=$(echo "$scripts" | grep -v "^$" | wc -l)

if [ "$script_count" -eq 0 ]; then
    warning "Bash-скриптов (.sh) не найдено в указанной директории."
    exit 0
fi

info "Найдено скриптов: $script_count"

# Установка прав на выполнение
count=0
while IFS= read -r script; do
    if [ -z "$script" ]; then
        continue
    fi

    info "Установка прав на выполнение для $script"

    if chmod +x "$script"; then
        # Обновление индекса Git, если мы находимся в Git репозитории
        if git rev-parse --is-inside-work-tree &>/dev/null; then
            git update-index --chmod=+x "$script" 2>/dev/null || true
        fi

        count=$((count+1))
    else
        warning "Не удалось установить права для $script"
    fi
done <<< "$scripts"

success "Права на выполнение установлены для $count из $script_count скриптов."
