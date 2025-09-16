# Изменения для поддержки MCP в devContainer

## 1. Обновления Codex-BackE

### Dockerfile

- Добавлена установка Node.js (необходима для запуска MCP)
- Добавлена установка npm
- Добавлены curl и другие зависимости

### devcontainer.json

- Добавлены переменные окружения в containerEnv
- Добавлен postStartCommand для автозапуска MCP сервера
- Добавлены порты для всех сервисов (backend, frontend, MCP)
- Перенесены настройки в правильную секцию customizations.vscode.settings

## 2. Обновления Copilot-FrontE

### Dockerfile для Frontend

- Добавлена установка зависимостей для MCP
- Добавлена экспозиция порта 3010 для MCP
- Добавлено копирование package\*.json из корня проекта

### devcontainer.json для Frontend

- Добавлены переменные окружения в containerEnv
- Добавлен postStartCommand для автозапуска MCP сервера
- Обновлены forwardPorts для включения всех необходимых сервисов
- Перенесены настройки в правильную секцию customizations.vscode.settings

## 3. Обновление .env.dev

- Добавлены переменные окружения для MCP:
  - FINGPT_BASE
  - AI_PROVIDER
  - DEV_JOURNAL_PATH
  - REQUEST_TIMEOUT_MS

## 4. Обновление docker-compose.yml

- Добавлены переменные окружения для devcontainer
- Добавлено использование .env.dev через env_file
- Добавлен mockup сервис для FinGPT (fingpt_mock)

## 5. Созданы вспомогательные файлы

- Создан fingpt-routes.json для маршрутизации запросов к mock FinGPT
- Создан fingpt-middleware.js для обработки запросов к mock FinGPT
- Создана директория для журналов
- Создан демонстрационный файл журнала 2025-09-13.md

## Проверочные действия для запуска

1. Запустить VS Code с Remote-Containers
2. Выбрать "Reopen in Container"
3. Выбрать контейнер Codex-BackE или Copilot-FrontE
4. Убедиться, что автоматически запустился MCP сервер
5. Проверить доступность FinGPT по адресу `http://localhost:8080/predict`
6. Проверить наличие журнальных файлов в директории docs/journal

## Примечания

- MCP сервер использует переменные окружения из containerEnv
- FinGPT mock сервис слушает на порту 8080
- Основной API backend работает на порту 8000
- Next.js frontend доступен на порту 3000
