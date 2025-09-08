# 🚀 Быстрый старт HTX Interface v2

## Минимальный набор для разработки (30 минут)

### 1. Локальная разработка
```bash
# Клонируем и настраиваем
git clone https://github.com/Kaushator/HTXV2.git
cd HTXEnterface_v2

# MCP Server
npm install
cp .env.example .env
npm run build
npm start

# Backend (в новом терминале)
cd backend
pip install -r requirements.txt
uvicorn app.main:app --reload

# Frontend (в новом терминале)  
cd frontend
npm install
npm run dev
```

### 2. Docker Compose (все сервисы сразу)
```bash
# Запуск всех сервисов
docker-compose up -d

# Проверка статуса
docker-compose ps
```

### 3. Проверка работоспособности
- **MCP Server**: http://localhost:8000 (настроен в VS Code)
- **Backend API**: http://localhost:8000/docs
- **Frontend**: http://localhost:3000
- **FinGPT**: http://localhost:8055/predict

---

## GCP Production Deployment (1 день)

### Предварительные требования
```bash
# Инструменты
gcloud auth login
terraform --version
docker --version

# GCP проект
export PROJECT_ID="htx-interface-v2"
gcloud config set project $PROJECT_ID
```

### Phase 1: Infrastructure (20 минут)
```bash
cd infra/terraform

# Быстрое развертывание
terraform init
terraform apply -auto-approve \
  -var="project_id=$PROJECT_ID" \
  -var="region=us-central1"
```

**Что создается**:
- VPC + Subnets
- Cloud SQL (PostgreSQL + pgvector)
- Memorystore (Redis)  
- GCS buckets
- BigQuery datasets
- Secret Manager
- IAM роли

### Phase 2: Backend Services (15 минут)
```bash
# Build & Deploy Backend
cd backend
gcloud builds submit --tag gcr.io/$PROJECT_ID/backend
gcloud run deploy backend-api \
  --image gcr.io/$PROJECT_ID/backend \
  --platform managed \
  --allow-unauthenticated

# Deploy ETL Jobs
cd ../etl  
gcloud builds submit --tag gcr.io/$PROJECT_ID/etl
gcloud run jobs create etl-processor \
  --image gcr.io/$PROJECT_ID/etl
```

### Phase 3: Frontend (10 минут)
```bash
cd frontend
gcloud builds submit --tag gcr.io/$PROJECT_ID/frontend
gcloud run deploy frontend \
  --image gcr.io/$PROJECT_ID/frontend \
  --allow-unauthenticated
```

### Phase 4: Secrets & Config (5 минут)
```bash
# Загрузка секретов
echo "your-htx-api-key" | gcloud secrets create htx-api-key --data-file=-
echo "your-openai-key" | gcloud secrets create openai-api-key --data-file=-

# Cloud Scheduler для ETL
gcloud scheduler jobs create pubsub htx-poller \
  --schedule="*/5 * * * *" \
  --topic=etl-trigger \
  --message-body='{"source":"htx"}'
```

---

## Проверка развертывания

### Health Checks
```bash
# Backend API
curl https://backend-api-xxx-uc.a.run.app/health

# ETL Job
gcloud run jobs execute etl-processor --wait

# Database connection
gcloud sql connect htx-db --user=postgres

# Redis cache
gcloud redis instances describe htx-cache --region=us-central1
```

### Logs & Monitoring
```bash
# Real-time logs
gcloud logging read "resource.type=cloud_run_revision" --limit=50 --format=table

# Metrics dashboard
echo "https://console.cloud.google.com/monitoring/dashboards"
```

---

## Стоимость (примерная)

### Development (месяц)
- Cloud Run: $10-20
- Cloud SQL: $30-50  
- Redis: $20-30
- Storage: $5-10
- **Итого**: ~$65-110/месяц

### Production (месяц, 1000 активных пользователей)
- Cloud Run: $50-100
- Cloud SQL: $100-200
- Redis: $50-100
- BigQuery: $100-200
- Vertex AI: $200-500
- **Итого**: ~$500-1100/месяц

---

## Следующие шаги

### Неделя 1: Core Services
- [ ] Backend API с всеми endpoints
- [ ] ETL pipeline для HTX/CoinGecko
- [ ] Basic frontend UI

### Неделя 2: ML Integration  
- [ ] FinGPT Docker container
- [ ] Vertex AI Workbench setup
- [ ] Vector search в BigQuery

### Неделя 3: Production Ready
- [ ] CI/CD pipeline
- [ ] Monitoring & alerting
- [ ] Load testing
- [ ] Security audit

### Неделя 4: Business Features
- [ ] Portfolio tracking
- [ ] Signal generation
- [ ] Backtesting tools
- [ ] Advanced analytics

---

## 🆘 Поддержка

### Troubleshooting
- **Logs**: `gcloud logging read --limit=100`
- **Errors**: Cloud Console → Error Reporting
- **Performance**: Cloud Console → Monitoring

### Полезные команды
```bash
# Restart сервиса
gcloud run services update backend-api --region=us-central1

# Rollback
gcloud run services update backend-api --to-revision=backend-api-00001

# Scale to zero (экономия)
gcloud run services update backend-api --concurrency=1 --min-instances=0
```
