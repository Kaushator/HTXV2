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
- [x] Docker Compose для локальной разработки
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

# Docker окружение
make docker-up

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
