# Инструкция по перезапуску DevContainer

Мы обновили конфигурацию DevContainer для корректной работы в GitHub Codespaces. Основные изменения:

1. Исправлены пути монтирования (с `/workspace` на `/workspaces/HTXV2`)
2. Добавлены необходимые фичи:
   - Docker-in-Docker для поддержки Docker внутри контейнера
   - Python 3.11 для корректной работы зависимостей

## Как перезапустить DevContainer:

1. В VS Code нажмите F1 или Ctrl+Shift+P для открытия Command Palette
2. Введите и выберите "Codespaces: Rebuild Container"
3. Подтвердите перестроение контейнера

После перезапуска у вас будет полностью рабочее окружение со всеми необходимыми инструментами.

## Проверка корректности настройки:

После перезапуска проверьте наличие Docker и Python:

```bash
# Проверка Docker
docker --version
docker-compose --version

# Проверка Python и pip
python --version
pip --version
```

## Запуск проекта:

```bash
# Запуск всего стека
cd /workspaces/HTXV2/docker && docker-compose up -d

# Запуск стека с поддержкой GPU
cd /workspaces/HTXV2 && make gpu-start
```