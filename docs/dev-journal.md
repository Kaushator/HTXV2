# Журнал разработки HTX Interface v2

## 2025-09-08

### Финальная интеграция проекта
- [x] Интегрированы настройки frontend из PR #2 (Next.js + shadcn/ui)
- [x] Создана полная инфраструктура для 4 источников данных
- [x] Настроен Terraform для Google Cloud с Secret Manager
- [x] Подготовлен FinGPT контейнер для тензорного обучения
- [x] Создан hybrid AI подход (FinGPT + OpenAI + Vertex AI)

### Архитектурные решения
- **Frontend**: Next.js 14 + React + shadcn/ui + TailwindCSS
- **Backend**: FastAPI + SQLAlchemy + async PostgreSQL
- **Storage**: Cloud SQL (PostgreSQL + pgvector) + Redis кэширование
- **Data Pipeline**: 4 источника → ETL → BigQuery/Cloud SQL
- **ML Stack**: FinGPT на тензорах + OpenAI + Vertex AI
- **Vector Search**: pgvector + BigQuery Vector Search
- **Security**: Secret Manager + Workload Identity Federation
- **Infrastructure**: Terraform modules для полного развертывания

### Источники данных (4 источника):
1. **HTX API** - технические данные биржи с real-time обновлениями
2. **CoinGecko API** - рыночные данные и метрики
3. **CSV/Excel файлы** - пользовательские данные через Signed URLs
4. **CryptoPanic API** - новостные сигналы с ML фильтрацией

### ML/AI Pipeline:
- **FinGPT** - локальное обучение на тензорах для анализа сигналов
- **OpenAI Integration** - fallback для высокого качества
- **Vertex AI** - масштабируемые ML пайплайны и embeddings
- **Signal Analysis** - обучение на достоверности торговых сигналов

### Frontend Features (из PR #2):
- Автоматическое формирование списка монет (HTX + CSV)
- Ручное добавление/удаление монет через UI
- Real-time обновления через WebSocket
- PWA поддержка и dark/light theme
- Responsive дизайн с мобильной поддержкой

### Infrastructure Plan:
#### Фаза 1: Core Setup ✅
- [x] Terraform modules готовы для GCP
- [x] Secret Manager для безопасного хранения ключей
- [ ] (Удалено) Docker Compose для локальной разработки — используем локальные сервисы и Terraform
- [x] Makefile для удобного управления

#### Фаза 2: Data Integration (в работе)
- [ ] HTX API integration с rate limiting
- [ ] CoinGecko polling сервис
- [ ] CSV/Excel upload через Signed URLs
- [ ] CryptoPanic news filtering с ML

#### Фаза 3: ML Pipeline
- [ ] FinGPT Docker container с GPU поддержкой
- [ ] Тензорное обучение для анализа сигналов
- [ ] Vertex AI pipelines для автоматизации
- [ ] Model versioning и A/B testing

#### Фаза 4: Production Ready
- [ ] CI/CD через GitHub Actions
- [ ] Monitoring и alerting в Cloud
- [ ] Load balancing и auto-scaling
- [ ] Security audit и penetration testing

### Команды для запуска:
```bash
# Полная настройка
make setup

# Локальная разработка
make dev

# Terraform infrastructure
make tf-apply

# Индивидуальные сервисы
make backend    # FastAPI
make frontend   # Next.js
make fingpt     # FinGPT ML
make mcp        # MCP server
```

### Следующие шаги:
- [ ] Тестирование интеграции всех компонентов
- [ ] Настройка Google Cloud Secret Manager
- [ ] Развертывание FinGPT с GPU поддержкой
- [ ] Создание ETL пайплайнов для 4 источников
- [ ] Интеграция ML обучения для анализа сигналов

## 2025-09-08 — Push, CI и базовые тесты

### Что сделано
- [x] Ветка `main` синхронизирована с `origin/main` (SSH remote настроен)
- [x] Добавлен CI: backend pytest, frontend lint, TruffleHog secret scan
- [x] Добавлены базовые тесты backend (health/coins/analysis)
- [x] Frontend: добавлены провайдеры (query/theme), globals.css, фиксы health и App Router
- [x] Makefile: цели `prepare`, `ensure-submodules`, `ci-local`, `scan-secrets`

### Проверка
- Запуск локальных тестов: `make ci-local`
- Инициализация подмодуля: `git submodule update --init --recursive`
- Пуш выполнен: `git push -u origin main`

## 2025-09-08 — Docker dev-стек, HTX тикер, WS и CI отчёты

### Что сделано
- [x] Docker Desktop dev-стек: postgres, redis, backend (uvicorn --reload), frontend (next dev), FinGPT (CUDA 12.1, RTX 4060)
- [x] VS Code Dev Container на базе docker-compose
- [x] Backend конфиг: pydantic-settings, CORS из env, health `/health/details` с таймингами и логированием
- [x] HTX тикер (alpha): `/api/data/htx/ticker/{symbol}`
  - Нормализация и валидация пар (допустимые котировки: `HTX_ALLOWED_QUOTES`)
  - Redis-кэш с TTL и параметром `?ttl=` (ограничение `HTX_TICKER_TTL_MAX`)
  - Rate limiting (Redis-backed, fallback in-memory)
- [x] WebSocket стрим: `/ws/ticker?symbols=BTC,ETH&interval_ms=1000`
- [x] Тесты backend: HTX тикер (mock), rate limit (in-memory), WS smoke
- [x] CI: кэш pip, Vitest стек, публикация отчётов (pytest HTML/JUnit, Vitest coverage) как artifacts
- [x] Доки обновлены: deployment-plan (статус), api-endpoints (HTX тикер — implemented alpha)

### Проверка
- Docker: `docker compose up -d --build`
- Backend: `http://localhost:8000/health` и `/health/details`
- Тикер: `GET /api/data/htx/ticker/BTC?ttl=2`
- WS: подключиться к `/ws/ticker?symbols=BTC,ETH&interval_ms=1000`
- CI отчёты: GitHub → Actions → CI → Artifacts

### Следующие шаги
- [ ] Rate limiting по пользователю/API-ключу (как появится auth)
- [ ] CoinGecko интеграция (poll + кэш)
- [ ] ETL источников и схема БД (Alembic) под реальные данные
- [ ] Frontend: подписка на WS и отображение тикеров в UI
