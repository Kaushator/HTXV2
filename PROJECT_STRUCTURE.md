# Структура проекта HTXV2

## Основные компоненты

```plaintext
HTXV2/
├── .devcontainer/               # Настройки и скрипты для разработки в контейнере
│   ├── scripts/                 # Скрипты для работы с контейнерами
│   │   ├── powershell/          # PowerShell скрипты (кросс-платформенные)
│   │   └── *.sh                 # Bash скрипты
│   └── devcontainer.json        # Конфигурация dev-контейнера
│
├── .mcp/                        # Model Context Protocol конфигурация
│   └── README.md                # Инструкции по использованию MCP
│
├── .vscode/                     # Настройки VS Code
│   ├── extensions.json          # Рекомендуемые расширения
│   ├── launch.json              # Конфигурации для отладки
│   ├── settings.json            # Настройки редактора
│   └── tasks.json               # Задачи VS Code
│
├── backend/                     # FastAPI сервер (Python)
│   ├── app/                     # Исходный код приложения
│   │   ├── api/                 # Эндпоинты API
│   │   ├── core/                # Ядро приложения
│   │   ├── db/                  # Работа с базой данных
│   │   ├── models/              # Модели данных
│   │   └── main.py              # Точка входа
│   ├── alembic/                 # Миграции базы данных
│   └── tests/                   # Тесты
│
├── frontend/                    # Next.js приложение (TypeScript)
│   ├── app/                     # App Router (Next.js 13+)
│   ├── src/                     # Исходный код
│   │   ├── components/          # React компоненты
│   │   ├── hooks/               # React хуки
│   │   ├── styles/              # Стили (CSS/SCSS)
│   │   └── utils/               # Утилиты
│   └── public/                  # Статические файлы
│
├── fingpt/                      # Сервис для финансового анализа
│   ├── server.py                # Сервер на Python
│   └── requirements.txt         # Зависимости
│
├── docs/                        # Документация проекта
│   ├── devcontainer-init.md     # Инициализация dev-контейнера
│   ├── ai-assistant-guide.md    # Руководство для ИИ-ассистентов
│   └── quickstart.md            # Быстрый старт
│
└── docker-compose.yml           # Конфигурация Docker Compose
```

## Рабочие процессы

### Разработка

1. **Локальная разработка**:
   - Используйте VS Code + DevContainer
   - Запустите `DevContainer: Initialize` из списка задач VS Code
   - Запустите `Dev: All (MCP+Backend+Frontend)` для запуска всех сервисов

2. **Тестирование**:
   - Backend: Запустите `Backend: Run Tests` из списка задач
   - Frontend: Запустите `Frontend: Run Tests`

### Контейнеры

Проект использует следующие контейнеры:

1. **backend**: FastAPI сервер на Python
2. **frontend**: Next.js приложение
3. **fingpt**: Сервис для финансового анализа
4. **postgres**: База данных PostgreSQL
5. **redis**: Кэширование и хранение сессий

## Полезные команды

```bash
# Инициализация dev-контейнера
.devcontainer/scripts/init-dev-container.sh

# Проверка контейнеров
.devcontainer/scripts/powershell/test-containers.ps1

# Запуск бэкенда для разработки
cd backend && uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Запуск фронтенда для разработки
cd frontend && npm run dev

# Запуск всех контейнеров
docker compose up -d
```

## Дополнительные ресурсы

- [Полное руководство по инициализации dev-контейнера](./docs/devcontainer-init.md)
- [Руководство для ИИ-помощников](./docs/ai-assistant-guide.md)
- [Быстрый старт](./docs/quickstart.md)