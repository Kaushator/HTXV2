# Copilot Repository Instructions — HTXV2

## Project overview
HTXV2 — персональный трейдинг-ассистент для HTX: быстрый импорт данных (API + CSV/XLSX), оперативные сводки PnL/кэшфлоу (цель: Time-to-Insight ≤ 10 сек), анализ сигналов ИИ и интеграции (3Commas, GCP). Главная цель: улучшить мой пользовательский опыт и продуктивность.

## Architecture overview
- **Async-first design**: FastAPI backend с async SQLAlchemy + pgvector, Redis для кэширования
- **MCP (Master Control Program)**: Центральный сервис (`app/services/mcp_service.py`) для оркестрации задач и WebSocket
- **Multi-model ML stack**: FinGPT (локально), Vertex AI, OpenAI с автоматическим выбором (`ml/services/llm_selector.py`)
- **ETL Pipeline**: Async извлечение данных из HTX/Coingecko (`etl/extractors/`) с rate limiting
- **Infrastructure as Code**: Terraform для GCP ресурсов (BigQuery, Pub/Sub, VPC, Cloud Functions)

## Environments & runtime
- Разработка: **WSL2 (Ubuntu) + Docker Desktop** с GPU поддержкой (RTX 4060).
- Backend: FastAPI (+ async SQLAlchemy), WebSocket; ML: FinGPT/Mistral (локально или контейнеры).
- Database: PostgreSQL 15 + pgvector для эмбеддингов, Redis для кэша и real-time данных.
- Хранилище/облако: GCP (GCS, Pub/Sub, Dataflow, BigQuery, Vertex AI, Secret Manager).

## How to run locally
- **Full stack**: `cd docker && docker compose up -d` (PostgreSQL + Redis + backend + frontend)
- **GPU/AI stack**: `make gpu-start` для Docker с GPU (NVIDIA RTX 4060)  
- **Development**: `make setup && make dev-all` (backend на :8000, frontend на :3000)
- **API Documentation**: `http://localhost:8000/docs` (FastAPI автодокументация)
- **Database migrations**: `cd backend && alembic upgrade head`

### Key configuration patterns
- **Environment**: копируй `backend/.env.example` → `backend/.env`, настрой HTX_API_KEY, GCP_PROJECT_ID
- **Settings cascade**: Environment vars → `.env` файлы → Pydantic Settings (`backend/app/core/config.py`)
- **Secrets**: Fernet encryption для локальных ключей, GCP Secret Manager для продакшна
- **Database**: PostgreSQL с pgvector extension для семантического поиска (см. `docker/init-db.sql`)

## Build / test / quality
- **Linting**: `make lint-all` (black, isort, flake8 для backend; eslint, prettier для frontend)  
- **Testing**: `make test-all` или `cd backend && pytest tests/` + `cd frontend && npm test`
- **Type checking**: Backend использует type hints, frontend TypeScript с strict mode
- **Database**: Alembic migrations в `backend/alembic/versions/`, автосоздание таблиц через SQLAlchemy
- **Docker health checks**: Все сервисы имеют healthcheck (postgres, redis, backend)

### Project-specific conventions
- **Async everywhere**: Все DB операции через async SQLAlchemy, aiohttp для HTTP клиентов
- **Structured logging**: structlog с JSON форматом, корреляция через request_id
- **Error handling**: Custom exceptions наследуют от HTTPException, централизованный error handler
- **Rate limiting**: Декоратор `@rate_limiter` для ETL, Redis для хранения счетчиков

## Agent tasks (what you MAY do)
- **Data processing**: CSV/XLSX импорт через pandas, PnL расчеты, агрегации в BigQuery
- **API development**: FastAPI эндпойнты с async/await, Pydantic схемы, dependency injection
- **ML integration**: Подключение новых моделей через `llm_selector.py`, векторный поиск с pgvector
- **ETL optimization**: Улучшение extractors с rate limiting, retry logic, error handling
- **UI components**: React/Next.js с shadcn/ui, TanStack Query для state management

## Guardrails (what you MUST NOT do)
- **Никаких реальных ордеров**: только paper-trading/симуляция
- **Секреты не трогаем**: не раскрывать ключи, не писать их в код/логи, не коммитить `.env`, JSON-ключи GCP и т. д.
- **Никаких force-push в `main`**. Все изменения через PR c тест-шагами и планом отката
- **Не удалять пользовательские данные** и таблицы без явного запроса

## Code & PR style
- Один PR = одна задача. В описании: цель, изменения, как тестировать, влияние на схему.
- Добавляй/обновляй тесты, проверяй `docker compose -f docker/docker-compose.yml up` на «чистой» машине.
- Соблюдай структуру каталогов (`backend/app/...`, `infrastructure/...`, `scripts/`).
- Используй TypeScript для frontend, Python type hints для backend.
- Следуй конвенциям: черный код (black), сортировка импортов (isort), линтинг (flake8/eslint).

## Useful paths
- `backend/app/services/` — интеграции (HTX / GCP / AI).
- `backend/app/core/` — конфиг/секреты (Fernet/Secret Manager).
- `infrastructure/` — Terraform (включение API, SA, GCS, Pub/Sub, BigQuery, Scheduler).
- `frontend/` — Next.js приложение с TypeScript и shadcn/ui.
- `scripts/` — скрипты для разработки и деплоя.
- `docker/` — Docker конфигурации (docker-compose.yml, docker-compose.gpu.yml).
- `etl/` — ETL пайплайны для обработки данных.
- `ml/` — ML модели и обучение (FinGPT, локальные модели).

## Key patterns & integrations
- **MCP Service**: `mcp_service.py` координирует задачи через WebSocket + Redis pub/sub
- **Data Models**: SQLAlchemy с async sessions, модель `CryptoPriceData` для цен из HTX
- **ETL extractors**: `HTXExtractor` использует `@rate_limiter` с exponential backoff
- **Settings cascade**: Pydantic BaseSettings → env vars → `.env` → defaults
- **Frontend state**: TanStack Query для кэширования, shadcn/ui компоненты
- **Docker health**: все сервисы проверяются через healthcheck перед запуском

## Definition of Done
- Сборка проходит (Docker/WSL2).
- Тесты/линтеры зелёные.
- Документация обновлена (README/CHANGELOG)