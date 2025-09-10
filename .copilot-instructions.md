# Copilot Repository Instructions — HTXV2

## Project overview
HTXV2 — персональный трейдинг-ассистент для HTX: быстрый импорт данных (API + CSV/XLSX), оперативные сводки PnL/кэшфлоу (цель: Time-to-Insight ≤ 10 сек), анализ сигналов ИИ и интеграции (3Commas, GCP). Главная цель: улучшить мой пользовательский опыт и продуктивность.

## Environments & runtime
- Разработка: **WSL2 (Ubuntu) + Docker Desktop**.
- Backend: FastAPI (+ async SQLAlchemy), WebSocket; ML: FinGPT/Mistral (локально или контейнеры).
- Хранилище/облако (опционально): GCP (GCS, Pub/Sub, Dataflow, BigQuery, Vertex AI, Secret Manager).

## How to run locally
- Docker: `docker compose -f docker/docker-compose.yml up -d`  
- Бекенд по умолчанию: `http://localhost:8000`  
- Frontend: `http://localhost:3000`
- API Documentation: `http://localhost:8000/docs`
- Setup development: `./scripts/setup-dev.sh` или `make setup`
- Конфигурация окружения: скопируй `backend/.env.example` → `backend/.env` и настрой секреты; файлы с секретами не коммитим.

## Build / test / quality
- Линтеры/форматтеры: `make lint-all` (или `black`, `isort`, `flake8` для backend; `npm run lint` для frontend)  
- Тесты: `make test-all` или `cd backend && pytest tests/` (backend), `cd frontend && npm test` (frontend)  
- Миграции БД: `cd backend && alembic upgrade head`
- Сборка: `make setup` для настройки окружения
- CI/CD: автоматическая проверка через GitHub Actions при push/PR

## Agent tasks (what you MAY do)
- Импорт/нормализация CSV/XLSX, расчёт PnL/кэшфлоу, агрегации BigQuery.
- Рефакторинг сервисов интеграций (HTX, GCP), улучшение логирования/ретраев.
- Семантический поиск по журналам (embeddings/pgvector) и API-эндпойнты.
- Улучшение UX «первого запуска»: интерактивная настройка ключей → Fernet.

## Guardrails (what you MUST NOT do)
- **Никаких реальных ордеров**: только paper-trading/симуляция.
- **Секреты не трогаем**: не раскрывать ключи, не писать их в код/логи, не коммитить `.env`, JSON-ключи GCP и т. д.
- **Никаких force-push в `main`**. Все изменения через PR c тест-шагами и планом отката.
- Не удалять пользовательские данные и таблицы без явного запроса.

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

## Definition of Done
- Сборка проходит (Docker/WSL2).
- Тесты/линтеры зелёные.
- Документация обновлена (README/CHANGELOG)