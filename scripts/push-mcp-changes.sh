#!/bin/bash
# Скрипт для пуша изменений в репозиторий

# Проверка текущей ветки
CURRENT_BRANCH=$(git branch --show-current)
echo "Текущая ветка: $CURRENT_BRANCH"

# Создаем новую ветку для изменений, если мы не в ветке feature/
if [[ "$CURRENT_BRANCH" != feature/* ]]; then
    NEW_BRANCH="feature/mcp-optimizations-$(date +%Y%m%d)"
    echo "Создание новой ветки: $NEW_BRANCH"
    git checkout -b $NEW_BRANCH
else
    NEW_BRANCH=$CURRENT_BRANCH
    echo "Используем текущую ветку: $NEW_BRANCH"
fi

# Добавляем измененные файлы
echo "Добавление файлов в индекс..."
git add \
    /workspaces/HTXV2/backend/app/services/mcp_service.py \
    /workspaces/HTXV2/backend/app/services/mcp_errors.py \
    /workspaces/HTXV2/backend/app/services/mcp_utils.py

# Проверяем статус
git status

# Запрашиваем подтверждение для коммита
read -p "Выполнить коммит изменений? (y/n): " confirm

if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
    # Делаем коммит
    git commit -m "Оптимизация MCP Service: кэширование, мониторинг ресурсов, обработка ошибок

- Добавлено многоуровневое кэширование с интеллектуальным TTL
- Добавлен мониторинг использования ресурсов
- Улучшена обработка ошибок с контекстной информацией
- Добавлена retry-логика для повторных попыток
- Оптимизирована отправка WebSocket сообщений
- Добавлены методы для получения метрик и статуса системы"

    # Запрашиваем подтверждение для пуша
    read -p "Выполнить push изменений в удаленный репозиторий? (y/n): " push_confirm
    
    if [[ "$push_confirm" == "y" || "$push_confirm" == "Y" ]]; then
        # Push изменений
        git push origin $NEW_BRANCH
        
        echo "Изменения успешно отправлены в ветку: $NEW_BRANCH"
        echo "URL для создания Pull Request: https://github.com/Kaushator/HTXV2/pull/new/$NEW_BRANCH"
    else
        echo "Изменения закоммичены в локальную ветку: $NEW_BRANCH"
        echo "Для отправки изменений позже используйте: git push origin $NEW_BRANCH"
    fi
else
    echo "Коммит отменен, изменения остались в рабочей директории"
fi