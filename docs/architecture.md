# HTX Interface v2 - Архитектура системы

## Обзор архитектуры

HTX Interface v2 представляет собой комплексную финтех-платформу для анализа криптовалютных активов с использованием машинного обучения и больших языковых моделей.

## Схема архитектуры

```
[Frontend (Next.js/React, shadcn)]
          |        REST/WS
          v
[Backend API (FastAPI)]  —— gRPC/HTTP ———————————————————————————————─┐
          | SQLAlchemy                |                                  |
          |                           |                                  |
          v                           v                                  v
  [Cloud SQL for PostgreSQL]   [Memorystore (Redis)]           [Artifact Registry]
          |                           |                                  |
          | ETL writes/reads          | caching / queues                 | images for API/ETL/LLM
          v                           v                                  v
 [Feature Store (Postgres/pgvector)]  [Pub/Sub] <——— Cloud Scheduler ————┐
          ^            ^                 ^                                |
          |            |                 | triggers                       |
          |            |           Dataflow jobs / Cloud Run Jobs         |
          |            |                                                  |
          |            └——— Embeddings ————> [Vertex AI Matching Engine]* |
          |                                            (или BigQuery Vector Search)
          |
          |                ┌──────────── Batch/Stream ingestion ───────────────┐
          |                |                                                   |
          v                v                                                   v
 [GCS (raw landing)] -> [Dataflow | Cloud Run Jobs] -> [BigQuery (curated/dwh)] ---> [Looker/BI]
         ^  ^                    ^                         ^     ^
         |  |                    |                         |     └———> Backtester/Signal Labeler (BQ SQL/UDTF)
 Uploads |  |            HTX, Coingecko,             CSV/XLSX
 (CSV/XLSX) |            Cryptopanic, etc.           parsed & versioned
            |
            └——— Signed URLs / resumable uploads

                   ┌────────────────────────────────────────────────────────────┐
                   │                       ML/LLM Stack                         │
                   │                                                            │
   [FinGPT (LoRA, локально, Docker, RTX)]  <—— feature/label data ———  [Vertex AI Workbench]
                   |  infer via local        ^                                 │
                   |                         | notebooks, prompt eval           │
                   |                         |                                  │
             [Inference Service (local)]     |                           [Vertex AI Pipelines]
                   |                         |                         train/eval/deploy (custom or foundation models)
                   |                         |                                  │
                   v                         |                                  v
         [Vertex AI Endpoints / Prediction Service]  <——— deploy  ——  [Vertex AI Model Registry]
                   |  online/batch predict                          (версионирование моделей)
                   |                                                       
                   v
          [Backend API (LLM selector)] ——> local FinGPT | OpenAI | Vertex AI
```

## Компоненты системы

### Frontend Layer
- **Next.js/React с shadcn/ui** - современный веб-интерфейс
- **WebSocket/REST API** - связь с backend в реальном времени

### Backend Services
- **FastAPI** - основной API-сервер
- **SQLAlchemy** - ORM для работы с базами данных
- **MCP Server** - интеграция с GitHub Copilot Chat

### Data Storage
- **Cloud SQL (PostgreSQL)** - основная реляционная база данных
- **Memorystore (Redis)** - кэширование и очереди сообщений
- **Feature Store (Postgres/pgvector)** - хранение векторных данных

### Data Pipeline
- **Google Cloud Storage** - первичное хранение сырых данных
- **Dataflow/Cloud Run Jobs** - ETL процессы
- **BigQuery** - хранилище данных и аналитика
- **Cloud Scheduler** - планировщик задач
- **Pub/Sub** - асинхронная обработка событий

### ML/AI Stack
- **FinGPT (локально)** - специализированная финансовая LLM
- **Vertex AI Workbench** - среда разработки ML
- **Vertex AI Pipelines** - ML пайплайны
- **Vertex AI Model Registry** - управление моделями
- **Vertex AI Matching Engine** - векторный поиск

### External Data Sources
- **HTX API** - данные биржи HTX
- **CoinGecko** - рыночные данные криптовалют
- **CryptoPanic** - новости и события

## Особенности архитектуры

### Hybrid AI Approach
Система поддерживает три типа AI провайдеров:
- **Local FinGPT** - для специализированных финансовых задач
- **OpenAI** - для общих задач генерации текста
- **Vertex AI** - для масштабируемых ML решений

### Scalable Data Processing
- Batch и stream обработка данных
- Автоматическое масштабирование через Cloud Run
- Кэширование на уровне Redis для высокой производительности

### Vector Search & Embeddings
- pgvector для векторного поиска в PostgreSQL
- Vertex AI Matching Engine для масштабируемого поиска по сходству
- Интеграция с BigQuery Vector Search

### Development Tools
- **MCP Server** - интеграция с AI-ассистентами (Copilot, Claude)
- **Jupyter Notebooks** - исследовательская аналитика
- Контейнеризация через Cloud Build/Run (без локального Docker Compose)

## Потоки данных

### Real-time Data Flow
1. External APIs → Pub/Sub → Dataflow → Feature Store
2. Frontend → WebSocket → Backend → Redis → Response

### Batch Processing
1. CSV/XLSX uploads → GCS → Dataflow → BigQuery
2. Scheduled jobs → Cloud Run → Feature Store → Vector embeddings

### ML Inference
1. User request → Backend → LLM selector → FinGPT/OpenAI/Vertex AI
2. Batch predictions → Vertex AI Endpoints → BigQuery results

## Deployment

Система развернута в Google Cloud Platform с использованием:
- **Cloud Run** для сервисов
- **Cloud SQL** для баз данных
- **Artifact Registry** для Docker образов
- **Cloud Load Balancer** для распределения нагрузки

## Мониторинг и Observability

- **Cloud Monitoring** - метрики производительности
- **Cloud Logging** - централизованные логи
- **Cloud Trace** - трассировка запросов
- **Looker** - бизнес-аналитика и дашборды
 - Подробнее: `docs/observability.md` (формат логов, ошибки, /metrics)

## Detailed Flow Diagrams

For detailed data flow diagrams and system interactions, see:
- **[Data Flow Diagrams](flows.md)** - WebSocket, HTTP API, health checks, and error handling flows
- Covers WebSocket ticker subscriptions, HTTP API patterns, caching strategies, and component interactions
