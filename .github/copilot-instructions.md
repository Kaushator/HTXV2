# Copilot Repository Instructions — HTXV2

## Project overview

HTXV2 — персональный трейдинг-ассистент для HTX: быстрый импорт данных (API + CSV/XLSX), оперативные сводки PnL/кэшфлоу (цель: Time-to-Insight ≤ 10 сек), анализ сигналов ИИ и интеграции (3Commas, GCP). Главная цель: улучшить пользовательский опыт и продуктивность трейдера.

## Architecture overview

- **Async-first design**: FastAPI backend с async SQLAlchemy + pgvector, Redis для кэширования
- **MCP (Master Control Program)**: Центральный сервис (`app/services/mcp_service.py`) оркестрирует задачи через WebSocket + Redis pub/sub
- **Multi-model ML stack**: FinGPT (локально), Vertex AI, OpenAI с автоматическим выбором/фолбэком (`ml/services/llm_selector.py`)
- **ETL Pipeline**: Async извлечение данных из HTX/Coingecko с rate limiting и экспоненциальным бэкоффом (`etl/extractors/`)
- **Infrastructure as Code**: Terraform для GCP ресурсов (BigQuery, Pub/Sub, VPC, Cloud Functions)

## Environments & runtime

- Разработка: **WSL2 (Ubuntu) + Docker Desktop** с GPU поддержкой (RTX 4060)
- Backend: FastAPI (+ async SQLAlchemy), WebSocket; ML: FinGPT/Mistral (локально или контейнеры)
- Database: PostgreSQL 15 + pgvector для эмбеддингов, Redis для кэша и real-time данных
- Хранилище/облако: GCP (GCS, Pub/Sub, Dataflow, BigQuery, Vertex AI, Secret Manager)

## How to run locally

- **Full stack**: `cd docker && docker compose up -d` (PostgreSQL + Redis + backend + frontend)
- **GPU/AI stack**: `make gpu-start` для Docker с GPU (NVIDIA RTX 4060)
- **Development**: `make setup && make dev-all` (backend на :8000, frontend на :3000)
- **API Documentation**: `http://localhost:8000/docs` (FastAPI автодокументация)
- **Database migrations**: `cd backend && alembic upgrade head`
- **MCP server**: `npm run build && npm start` или `./start-mcp.ps1` (для Copilot/Agent)

### Key configuration patterns

- **Environment**: копируй `backend/.env.example` → `backend/.env`, настрой HTX_API_KEY, GCP_PROJECT_ID
- **Settings cascade**: Environment vars → `.env` файлы → Pydantic Settings (`backend/app/core/config.py`)
- **Secrets**: Fernet encryption для локальных ключей, GCP Secret Manager для продакшна
- **Database**: PostgreSQL с pgvector extension для семантического поиска (см. `docker/init-db.sql`)
- **Dependency Injection**: FastAPI Depends для сервисов, сессий БД, аутентификации (`backend/app/deps.py`)

## Project-specific conventions

- **Async everywhere**: Все DB операции через async SQLAlchemy, aiohttp для HTTP клиентов
- **Context Manager Services**: Используем `async with service() as client:` паттерн для ресурсов
- **Structured logging**: structlog с JSON форматом, корреляция через request_id
- **Error handling**: Custom exceptions наследуют от HTTPException, централизованный error handler
- **Rate limiting**: Декоратор `@rate_limiter` для ETL, Redis для хранения счетчиков
- **Service Health Check**: Каждый сервис реализует метод `check_health()` для мониторинга MCP

## Data flow & Integration

- **ETL Pipeline**: `HTXExtractor` → `PostgreSQL` → `Data Services` → `Frontend/ML/WebSocket`
- **Trading Signals**: `MLProcessor` → `SignalValidator` → `MCP` → `WebSocket`
- **Real-time Data**: Redis pub/sub + WebSocket через MCP для market data и обновлений портфеля
- **User Data**: CSV/XLSX → Signed URL → GCS → Cloud Function → BigQuery → Dashboard

## Key files & components

- `backend/app/services/mcp_service.py` — центральная координация с WebSocket
- `backend/app/core/config.py` — Pydantic Settings и конфигурация
- `ml/services/llm_selector.py` — автоматический выбор AI модели с фолбэком
- `etl/extractors/htx_extractor.py` — асинхронное получение данных с rate limiting
- `docker/docker-compose.yml` — полный стэк контейнеров с healthcheck

## Common workflow patterns

- **Market Data**: `HTXExtractor` → `MarketDataService` → `CryptoAnalyticsService`
- **Portfolio Update**: `PortfolioService.update()` → `MCP.publish_update()` → WebSocket
- **AI Signal**: User query → `LLMSelector` → Best model → `SignalProcessor` → `MCP`

## Debugging & Development

- **Логи контейнеров**: `docker compose logs -f {service_name}`
- **Backend дебаг**: VS Code launch config + `.vscode/launch.json`
- **Frontend дебаг**: Chrome DevTools + React DevTools (port 3000)
- **MCP статус**: `curl http://localhost:3001/status` для проверки MCP сервера

## Guardrails (what you MUST NOT do)

- **Никаких реальных ордеров**: только paper-trading/симуляция
- **Секреты не трогаем**: не раскрывать ключи, не писать их в код/логи, не коммитить `.env`
- **Никаких force-push в `main`**. Все изменения через PR c тест-шагами
- **Не удалять пользовательские данные** и таблицы без явного запроса

## Code & PR style

- Один PR = одна задача. В описании: цель, изменения, тесты, влияние на схему.
- Добавляй/обновляй тесты, проверяй `docker compose -f docker/docker-compose.yml up` на «чистой» машине.
- Соблюдай структуру каталогов (`backend/app/...`, `infrastructure/...`, `scripts/`).
- Используй TypeScript для frontend, Python type hints для backend.
