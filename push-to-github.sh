#!/bin/bash
# Скрипт для отправки изменений в GitHub репозиторий

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

# Проверка наличия Git
if ! command -v git &> /dev/null; then
    error "Git не установлен. Пожалуйста, установите Git и повторите попытку."
fi

# Проверка параметров
COMMIT_MSG=""
BRANCH=""
SKIP_FORMAT=false
FORCE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -m|--message)
            COMMIT_MSG="$2"
            shift 2
            ;;
        -b|--branch)
            BRANCH="$2"
            shift 2
            ;;
        --skip-format)
            SKIP_FORMAT=true
            shift
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        *)
            warning "Неизвестный параметр: $1"
            shift
            ;;
    esac
done

# Проверка, находимся ли мы в Git-репозитории
if ! git rev-parse --is-inside-work-tree &> /dev/null; then
    error "Текущая директория не является Git-репозиторием."
fi

# Получение текущей ветки, если не указана
if [[ -z "$BRANCH" ]]; then
    BRANCH=$(git branch --show-current)
    info "Используется текущая ветка: $BRANCH"
fi

# Форматирование кода (если не пропущено)
if [[ "$SKIP_FORMAT" == "false" ]]; then
    section "Форматирование кода"
    
    # Форматирование Python кода
    if [[ -d "backend" ]]; then
        info "Форматирование Python кода..."
        if command -v black &> /dev/null && command -v isort &> /dev/null; then
            black backend --quiet
            isort backend --quiet
            success "Python код отформатирован"
        else
            warning "Форматирование Python кода будет пропущено. Установите black и isort для автоматического форматирования."
        fi
    fi
    
    # Форматирование JavaScript/TypeScript кода
    if [[ -d "frontend" && -f "package.json" ]]; then
        info "Форматирование JavaScript/TypeScript кода..."
        if npm run format --if-present 2>/dev/null; then
            success "JavaScript/TypeScript код отформатирован"
        else
            warning "Форматирование JavaScript/TypeScript кода будет пропущено. Убедитесь, что в package.json есть script 'format'."
        fi
    fi
else
    info "Форматирование кода пропущено."
fi

# Добавление изменений
section "Добавление изменений в Git"
info "Добавление всех изменений..."
git add .

STATUS=$(git status -s)
if [[ -z "$STATUS" ]]; then
    warning "Нет изменений для коммита."
    exit 0
else
    info "Статус файлов для коммита:"
    echo "$STATUS"
fi

# Создание коммита
section "Создание коммита"
if [[ -z "$COMMIT_MSG" ]]; then
    read -p "Введите сообщение коммита: " COMMIT_MSG
fi

if [[ -z "$COMMIT_MSG" ]]; then
    error "Сообщение коммита не может быть пустым."
fi

if ! git commit -m "$COMMIT_MSG"; then
    error "Ошибка при создании коммита."
fi
success "Коммит создан с сообщением: $COMMIT_MSG"

# Отправка изменений
section "Отправка изменений в GitHub"
info "Отправка изменений в ветку '$BRANCH'..."

PUSH_CMD="git push origin $BRANCH"
if [[ "$FORCE" == "true" ]]; then
    PUSH_CMD="git push origin $BRANCH --force-with-lease"
fi

if ! eval $PUSH_CMD; then
    error "Ошибка при отправке изменений в GitHub."
fi
success "Изменения успешно отправлены в GitHub!"

section "Завершение"
info "Ссылка на репозиторий: https://github.com/Kaushator/HTXV2"
info "Текущая ветка: $BRANCH"