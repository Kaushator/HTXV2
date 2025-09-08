# План развертывания HTX Interface v2 в Google Cloud Platform

## 🎯 Цель: Создание production-ready финтех платформы в GCP

### Фаза 1: Инфраструктура и Data Lake (1-2 недели)

#### 1.1 Terraform Infrastructure
- [x] Terraform модуль для GCP готов с подтягиванием секретов
- [ ] Развертывание базовой инфраструктуры:
  - VPC + Subnets с приватными IP
  - Cloud SQL for PostgreSQL (с pgvector)
  - Memorystore (Redis) для кэширования
  - GCS buckets для Data Lake
  - BigQuery datasets (raw, curated, features)
  - Artifact Registry для контейнерных образов
  - Secret Manager для безопасного хранения ключей

#### 1.2 Security & DevOps
- [ ] Настройка Workload Identity Federation (WIF)
- [ ] IAM роли с минимальными правами per-service
- [ ] Secret Manager integration (HTX API, OpenAI keys)
- [ ] VPC + Serverless VPC Access для приватного доступа
- [ ] Cloud Build + GitHub Actions CI/CD

#### 1.3 Monitoring & Logging
- [ ] Cloud Logging централизованные логи
- [ ] Cloud Monitoring + Error Reporting
- [ ] Alerting Policy для критических сервисов

### Фаза 2: Backend Services (1-2 недели)

#### 2.1 Core API
- [ ] FastAPI backend в Cloud Run
- [ ] SQLAlchemy ORM с Cloud SQL PostgreSQL
- [ ] Redis integration через Memorystore
- [ ] Сборка контейнерных образов в Artifact Registry (через Cloud Build)

#### 2.2 ETL Pipeline
- [ ] Cloud Scheduler → Pub/Sub триггеры
- [ ] Cloud Run Jobs для ETL процессов:
  - HTX API polling
  - CoinGecko data ingestion  
  - CryptoPanic news parsing
  - CSV/XLSX processing (Signed URLs → GCS → BigQuery)

#### 2.3 Data Flow Architecture
```
GCS (raw) → Cloud Run Jobs → BigQuery (curated) → Cloud SQL (operational)
     ↓              ↓              ↓                    ↓
 Signed URLs   Normalization   Partitioning        Fast aggregates
```

### Фаза 3: ML/LLM Stack (2-3 недели)

#### 3.1 Feature Store Strategy
**Вариант А (бюджетный)**: Cloud SQL + pgvector
- [ ] Таблицы фич в PostgreSQL
- [ ] Vector search через pgvector
- [ ] DAO/Repository pattern

**Вариант Б (GCP-нативный)**: Vertex AI Feature Store v2
- [ ] Feature Store на базе BigQuery
- [ ] MLOps мониторинг дрейфа
- [ ] Auto-materialization в BigQuery

#### 3.2 Vector Search Options
**Простой старт**: BigQuery Vector Search
- [ ] Embeddings в BigQuery таблицах
- [ ] Vector similarity через SQL
- [ ] Интеграция с Vertex AI Embeddings

**Продвинутый**: Vertex AI Matching Engine
- [ ] High-performance ANN search
- [ ] Real-time vector indexing
- [ ] Масштабируемый поиск

#### 3.3 ML Pipeline
- [ ] Vertex AI Workbench для notebooks
- [ ] Vertex AI Pipelines (Kubeflow) для MLOps
- [ ] Vertex AI Model Registry для версионирования
- [ ] Vertex AI Endpoints для inference

#### 3.4 Hybrid LLM Stack
- [ ] **Local FinGPT**: LoRA на RTX 4060 в Docker
- [ ] **OpenAI**: Fallback для качества
- [ ] **Vertex AI**: Gemini/Text-Bison для GCP-нативности
- [ ] LLM selector в backend API

### Фаза 4: Frontend & Integration (1-2 недели)

#### 4.1 Frontend Development
- [ ] Next.js + React + shadcn/ui
- [ ] WebSocket integration для real-time
- [ ] File upload через Signed URLs
- [ ] Deployment в Cloud Run

#### 4.2 MCP Server Integration
- [ ] GitHub Copilot Chat integration
- [ ] Claude/Cursor support
- [ ] Tool registry для AI assistants

### Фаза 5: Analytics & BI (1 неделя)

#### 5.1 Business Intelligence
- [ ] Looker Studio dashboards
- [ ] BigQuery data marts
- [ ] Real-time KPI monitoring

#### 5.2 Backtesting & Signals
- [ ] BigQuery SQL/UDTF для backtester
- [ ] Signal labeler в Vertex AI Workbench
- [ ] Performance metrics dashboard

---

## 🛠️ Инструкция по развертыванию

### Подготовка окружения

1. **Установка инструментов**:
```bash
# Google Cloud SDK
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
gcloud init

# Terraform
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install terraform

# Контейнерные образы
sudo apt-get install docker.io
sudo usermod -aG docker $USER
```

2. **Настройка GCP проекта**:
```bash
# Создание проекта
gcloud projects create htx-interface-v2 --name="HTX Interface v2"
gcloud config set project htx-interface-v2

# Включение API
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable sqladmin.googleapis.com
gcloud services enable redis.googleapis.com
gcloud services enable bigquery.googleapis.com
gcloud services enable aiplatform.googleapis.com
gcloud services enable secretmanager.googleapis.com
```

### Развертывание инфраструктуры

3. **Terraform deployment**:
```bash
cd infra/terraform

# Инициализация
terraform init

# Планирование
terraform plan -var="project_id=htx-interface-v2"

# Применение
terraform apply -var="project_id=htx-interface-v2"
```

4. **Настройка секретов**:
```bash
# HTX API ключи
gcloud secrets create htx-api-key --data-file=./secrets/htx-api.txt
gcloud secrets create htx-api-secret --data-file=./secrets/htx-secret.txt

# OpenAI API ключ
gcloud secrets create openai-api-key --data-file=./secrets/openai.txt

# Database connection
gcloud secrets create postgres-password --data-file=./secrets/db-password.txt
```

### Backend Development

5. **Локальная разработка**:
```bash
# Backend
cd backend
pip install -r requirements.txt
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# MCP Server
cd ../
npm install
npm run dev
```

6. **Docker build & deploy**:
```bash
# Backend API
cd backend
# Рекомендуется использовать Cloud Build: `gcloud builds submit`
docker push gcr.io/htx-interface-v2/backend:latest

# Deploy to Cloud Run
gcloud run deploy backend-api \
  --image gcr.io/htx-interface-v2/backend:latest \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated
```

### ETL Pipeline Setup

7. **Cloud Run Jobs для ETL**:
```bash
# ETL Job
cd etl
# Рекомендуется использовать Cloud Build: `gcloud builds submit`
docker push gcr.io/htx-interface-v2/etl:latest

# Create scheduled job
gcloud run jobs create etl-htx-poller \
  --image gcr.io/htx-interface-v2/etl:latest \
  --region us-central1 \
  --task-timeout 3600 \
  --max-retries 3
```

8. **Cloud Scheduler setup**:
```bash
# HTX data polling every 5 minutes
gcloud scheduler jobs create http htx-data-poll \
  --schedule="*/5 * * * *" \
  --uri="https://pubsub.googleapis.com/v1/projects/htx-interface-v2/topics/etl-trigger:publish" \
  --message-body='{"task":"htx_poll"}'
```

### ML/LLM Stack

9. **FinGPT local setup**:
```bash
cd fingpt
# Сборка образа FinGPT с GPU через Cloud Build или nvidia-container-toolkit
docker run --gpus all -p 8055:8055 gcr.io/htx-interface-v2/fingpt:latest
```

10. **Vertex AI setup**:
```bash
# Create Vertex AI Workbench instance
gcloud notebooks instances create htx-workbench \
  --vm-image-project=deeplearning-platform-release \
  --vm-image-family=tf-ent-2-11-cu113-v20230925-debian-11-py310 \
  --machine-type=n1-standard-4 \
  --location=us-central1-b
```

### Frontend Deployment

11. **Next.js app**:
```bash
cd frontend
npm install
npm run build

# Docker build
# Рекомендуется использовать Cloud Build: `gcloud builds submit`
docker push gcr.io/htx-interface-v2/frontend:latest

# Deploy to Cloud Run
gcloud run deploy frontend \
  --image gcr.io/htx-interface-v2/frontend:latest \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated
```

### Monitoring & Logging

12. **Настройка мониторинга**:
```bash
# Alerting policy для критических сервисов
gcloud alpha monitoring policies create --policy-from-file=monitoring/api-errors.yaml

# Log-based metrics
gcloud logging metrics create error_rate \
  --description="Rate of error logs" \
  --log-filter='severity>=ERROR'
```

### BI & Analytics

13. **BigQuery datasets & Looker**:
```bash
# Create datasets
bq mk --dataset htx-interface-v2:raw_data
bq mk --dataset htx-interface-v2:curated_data  
bq mk --dataset htx-interface-v2:feature_store

# Load initial schemas
bq load --source_format=NEWLINE_DELIMITED_JSON \
  htx-interface-v2:raw_data.htx_trades \
  schemas/htx_trades.json
```

---

## 🔍 Чек-лист проверки

### Безопасность ✅
- [ ] Все секреты в Secret Manager
- [ ] Workload Identity Federation настроен
- [ ] IAM роли с минимальными правами
- [ ] VPC с приватными подсетями
- [ ] HTTPS везде с автоматическими сертификатами

### Performance ✅
- [ ] Redis кэширование настроено
- [ ] BigQuery партиционирование по датам
- [ ] Cloud SQL connection pooling
- [ ] CDN для статических ресурсов

### Observability ✅
- [ ] Centralized logging в Cloud Logging
- [ ] Metrics в Cloud Monitoring
- [ ] Error tracking в Error Reporting
- [ ] Distributed tracing настроен

### Cost Optimization ✅
- [ ] Auto-scaling для Cloud Run
- [ ] BigQuery slot reservations для предсказуемых costs
- [ ] GCS lifecycle policies для архивирования
- [ ] Preemptible instances где возможно

---

## 📊 Ожидаемые результаты

### Производительность
- **API Response Time**: < 200ms для 95% запросов
- **ETL Processing**: < 30 минут для daily batch
- **ML Inference**: < 5 секунд для FinGPT responses

### Надежность
- **Uptime**: 99.9% для критических сервисов
- **RTO**: < 15 минут для полного восстановления
- **Backup**: Automated daily backups с 30-day retention

### Масштабируемость
- **Concurrent Users**: 1000+ одновременных пользователей
- **Data Volume**: 100GB+ ежедневной обработки данных
- **ML Throughput**: 1000+ inference requests/minute
