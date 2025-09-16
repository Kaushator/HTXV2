# Спецификация отладки DevContainers и настройки MCP Tools

## Общее описание

Данная спецификация описывает полный процесс настройки, отладки и использования двух DevContainer'ов для проекта HTXEnterface_v2, а также настройку Model Context Protocol (MCP) инструментов и поддержку параллельной разработки вплоть до релиза и деплоя на локальной машине.

## 1. Настройка и отладка DevContainers

### 1.1. DevContainer для основного приложения

#### Конфигурация

```json
{
  "name": "HTX Interface Main",
  "dockerComposeFile": ["../docker-compose.yml", "docker-compose.extend.yml"],
  "service": "app",
  "workspaceFolder": "/workspace",
  "settings": {
    "terminal.integrated.shell.linux": "/bin/bash",
    "python.pythonPath": "/usr/local/bin/python",
    "python.linting.enabled": true,
    "python.linting.pylintEnabled": true,
    "python.formatting.provider": "black"
  },
  "extensions": [
    "ms-python.python",
    "ms-python.vscode-pylance",
    "dbaeumer.vscode-eslint",
    "esbenp.prettier-vscode",
    "github.copilot",
    "github.copilot-chat"
  ],
  "forwardPorts": [3000, 8000],
  "postCreateCommand": "pip install -r backend/requirements.txt && npm install"
}
```

#### Процедура отладки

1. Проверить конфигурацию в `.devcontainer/devcontainer.json`
2. Запустить VS Code и выбрать "Reopen in Container"
3. Проверить наличие всех необходимых зависимостей и расширений
4. Запустить задачу `Backend: Run Dev Server` для проверки работоспособности
5. Запустить задачу `Frontend: Run Dev Server` для проверки работоспособности
6. Проверить подключение к сервисам базы данных

### 1.2. DevContainer для FinGPT middleware

#### Конфигурация

```json
{
  "name": "FinGPT Middleware",
  "dockerComposeFile": ["../docker-compose.yml", "docker-compose.fingpt.yml"],
  "service": "fingpt",
  "workspaceFolder": "/app",
  "settings": {
    "terminal.integrated.shell.linux": "/bin/bash",
    "python.pythonPath": "/usr/local/bin/python",
    "python.linting.enabled": true
  },
  "extensions": [
    "ms-python.python",
    "ms-python.vscode-pylance",
    "github.copilot",
    "github.copilot-chat"
  ],
  "forwardPorts": [5000],
  "postCreateCommand": "pip install -r requirements.txt"
}
```

#### Процедура отладки

1. Проверить конфигурацию в `.devcontainer/fingpt/devcontainer.json`
2. Запустить VS Code и выбрать "Reopen in Container" для этой папки
3. Проверить установку зависимостей
4. Запустить сервер FinGPT с помощью `python server.py`
5. Проверить доступность API на порту 5000
6. Проверить интеграцию с основным приложением

## 2. Настройка Model Context Protocol (MCP) Tools

### 2.1. Установка и конфигурация

1. Установка MCP CLI инструментов:

   ```bash
   npm install -g @microsoft/mcp-cli
   ```

2. Инициализация MCP в проекте:

   ```bash
   cd e:\HTXEnterface_v2
   mcp init
   ```

3. Настройка файла конфигурации MCP:
   ```json
   {
     "version": "1.0",
     "sources": [
       {
         "type": "code",
         "path": "./",
         "exclude": ["node_modules", ".git", "dist", "build"]
       },
       {
         "type": "documentation",
         "path": "./docs"
       }
     ],
     "ai": {
       "provider": "openai",
       "model": "gpt-4",
       "settings": {
         "temperature": 0.2
       }
     }
   }
   ```

### 2.2. Интеграция с DevContainers

1. Добавление MCP расширений в devcontainer.json:

   ```json
   "extensions": [
     // ... существующие расширения
     "ms-mcp.mcp-vscode-extension"
   ]
   ```

2. Настройка общего контекста между контейнерами:

   - Создание общего тома для данных MCP
   - Настройка общего доступа к моделям и конфигурации

3. Скрипт синхронизации контекста между контейнерами:

   ```bash
   #!/bin/bash
   # mcp-sync.sh

   # Синхронизация контекста между контейнерами
   rsync -avz --exclude='node_modules' --exclude='.git' /workspace/.mcp/ /shared/mcp/
   ```

## 3. Процессы параллельной разработки

### 3.1. Рабочий процесс Git

1. Основная структура веток:

   - `main` - стабильная версия
   - `dev` - разработка
   - `feature/*` - новые функции
   - `hotfix/*` - исправления ошибок

2. Процесс интеграции изменений:

   ```
   feature/branch -> dev -> main
   ```

3. Настройка pre-commit хуков для проверки качества кода

### 3.2. Параллельная работа с контейнерами

1. Запуск нескольких контейнеров:

   ```bash
   docker compose up -d app fingpt
   ```

2. Настройка коммуникации между контейнерами:

   - Использование внутренней сети Docker
   - Проверка доступности по внутренним именам хостов

3. Синхронизация изменений:
   - Использование общих томов для критичных компонентов
   - Обновление зависимостей при изменении package.json/requirements.txt

### 3.3. Интеграционное тестирование

1. Настройка CI пайплайна для тестирования:

   ```yaml
   name: Integration Tests

   on:
     push:
       branches: [dev, main]
     pull_request:
       branches: [dev, main]

   jobs:
     test:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v3
         - name: Setup environment
           run: docker compose -f docker-compose.test.yml up -d
         - name: Run tests
           run: docker compose -f docker-compose.test.yml run app pytest
         - name: Run frontend tests
           run: docker compose -f docker-compose.test.yml run frontend npm test
   ```

## 4. Процесс релиза и деплоя

### 4.1. Подготовка к релизу

1. Сборка финальных артефактов:

   ```bash
   # Сборка бэкенда
   cd backend
   python build.py

   # Сборка фронтенда
   cd frontend
   npm run build
   ```

2. Создание релизной ветки:

   ```bash
   git checkout -b release/vX.Y.Z
   git add .
   git commit -m "Release vX.Y.Z"
   git tag vX.Y.Z
   git push origin vX.Y.Z
   ```

3. Проверка качества релиза:
   - Запуск полного набора тестов
   - Проверка производительности
   - Проверка безопасности

### 4.2. Деплой на локальную машину

1. Подготовка локальной среды:

   ```bash
   # Создание директорий для данных
   mkdir -p ~/htx/data
   mkdir -p ~/htx/logs
   ```

2. Конфигурация для локального деплоя:

   ```yaml
   # docker-compose.local.yml
   version: "3"
   services:
     app:
       image: htx-interface-app:latest
       volumes:
         - ~/htx/data:/data
         - ~/htx/logs:/logs
       ports:
         - "8000:8000"
       environment:
         - ENV=production
         - DB_HOST=localhost
         - DB_PORT=5432

     fingpt:
       image: htx-fingpt:latest
       ports:
         - "5000:5000"
       volumes:
         - ~/htx/data:/data
         - ~/htx/logs:/logs
   ```

3. Запуск локального деплоя:
   ```bash
   docker compose -f docker-compose.local.yml up -d
   ```

### 4.3. Мониторинг и поддержка

1. Настройка логирования:

   - Централизованный сбор логов
   - Ротация логов
   - Алерты при критических ошибках

2. Процедура отката:

   ```bash
   # Откат к предыдущей версии
   docker compose -f docker-compose.local.yml down
   docker tag htx-interface-app:previous htx-interface-app:latest
   docker tag htx-fingpt:previous htx-fingpt:latest
   docker compose -f docker-compose.local.yml up -d
   ```

3. Процедура обновления:

   ```bash
   # Скрипт обновления
   #!/bin/bash
   # update.sh

   # Сохранение текущей версии
   docker tag htx-interface-app:latest htx-interface-app:previous
   docker tag htx-fingpt:latest htx-fingpt:previous

   # Сборка новой версии
   docker compose -f docker-compose.build.yml build

   # Деплой новой версии
   docker compose -f docker-compose.local.yml down
   docker compose -f docker-compose.local.yml up -d
   ```

## 5. Требования к системе

### 5.1. Аппаратные требования

- CPU: минимум 4 ядра
- RAM: минимум 16 GB
- Disk: минимум 50 GB свободного места
- GPU: опционально, для ускорения работы FinGPT

### 5.2. Программные требования

- Docker Desktop
- Visual Studio Code с поддержкой Remote Containers
- Git
- Node.js 18+
- Python 3.9+
- MCP CLI инструменты

## 6. Контрольный список готовности

- [ ] DevContainers успешно запускаются и работают
- [ ] MCP инструменты настроены и доступны в обоих контейнерах
- [ ] Настроена параллельная разработка и синхронизация
- [ ] CI пайплайн настроен и работает
- [ ] Процесс релиза документирован и протестирован
- [ ] Деплой на локальную машину работает
- [ ] Мониторинг и логирование настроены
