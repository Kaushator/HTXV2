#!/bin/bash
# Git Sync Utility для HTXV2
set -e

echo "🔄 HTXV2 Git Sync Utility"
echo "-------------------------"

# Получаем текущую директорию
SCRIPT_DIR=$(dirname "$0")
REPO_DIR="$SCRIPT_DIR/.."
cd "$REPO_DIR"

# Определение текущей ветки
current_branch=$(git rev-parse --abbrev-ref HEAD)
echo "🌿 Текущая ветка: $current_branch"

# Показать изменения
echo "📋 Список измененных файлов:"
git status --short

# Проверка на наличие несохраненных изменений
if [ -n "$(git status --porcelain)" ]; then
    echo ""
    echo "⚠️ Обнаружены несохраненные изменения"
    
    # Предлагаем добавить файлы
    read -p "📝 Добавить все изменения? (y/n): " add_all
    
    if [[ "$add_all" == "y" || "$add_all" == "Y" ]]; then
        git add .
    else
        echo "ℹ️ Добавьте файлы вручную командой git add"
        exit 0
    fi
    
    # Получаем сообщение коммита
    read -p "📝 Введите сообщение коммита: " commit_message
    
    if [ -z "$commit_message" ]; then
        # Автогенерация сообщения коммита
        if grep -q "mcp_service.py" <(git diff --name-only --cached); then
            commit_message="Update: MCP Service optimization [$(date +"%Y-%m-%d")]"
        else
            commit_message="Update: Project changes [$(date +"%Y-%m-%d")]"
        fi
        echo "ℹ️ Используется автоматическое сообщение: $commit_message"
    fi
    
    # Коммитим изменения
    git commit -m "$commit_message"
else
    echo "✅ Несохраненных изменений не обнаружено"
fi

# Pull с ребазом
echo ""
echo "⬇️ Получение изменений с удаленного репозитория (git pull --rebase)..."
git pull --rebase origin $current_branch || {
    echo "❌ Ошибка при получении изменений. Проверьте конфликты и сетевое соединение."
    exit 1
}

# Push изменений
echo ""
echo "⬆️ Отправка локальных изменений (git push)..."
git push origin $current_branch || {
    echo "❌ Ошибка при отправке изменений. Возможно, нужны права на запись или произошел конфликт."
    exit 1
}

# Проверка, если это feature ветка
if [[ "$current_branch" == feature/* || "$current_branch" == codespace* ]]; then
    echo ""
    echo "📊 Информация о ветке $current_branch:"
    echo "- Коммитов в ветке: $(git rev-list --count HEAD ^main)"
    echo "- Последний коммит: $(git log -1 --pretty=%B | head -1)"
    
    # Предлагаем создать PR
    echo ""
    read -p "🚀 Создать Pull Request в main? (y/n): " create_pr
    
    if [[ "$create_pr" == "y" || "$create_pr" == "Y" ]]; then
        PR_URL="https://github.com/Kaushator/HTXV2/pull/new/$current_branch"
        echo "ℹ️ Откройте следующий URL для создания PR:"
        echo "$PR_URL"
        
        # Если есть команда для открытия URL
        if command -v xdg-open &> /dev/null; then
            read -p "Открыть URL в браузере? (y/n): " open_url
            if [[ "$open_url" == "y" || "$open_url" == "Y" ]]; then
                xdg-open "$PR_URL"
            fi
        fi
    fi
fi

# Итоговая статистика
echo ""
echo "✅ Синхронизация завершена успешно!"
echo "📊 Статистика:"
echo "- Последний коммит: $(git log -1 --pretty=%B | head -1)"
echo "- Автор: $(git log -1 --pretty=%an)"
echo "- Дата: $(git log -1 --pretty=%ad --date=format:'%Y-%m-%d %H:%M:%S')"

# Информация о MCP
if grep -q "mcp_service.py" <(git diff --name-only HEAD~1); then
    echo ""
    echo "⚡ MCP Service обновлен! Проверьте работоспособность системы."
    echo "Для запуска MCP выполните:"
    echo "  cd /workspaces/HTXV2/backend && source venv/bin/activate && python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000"
fi