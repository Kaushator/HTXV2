# Настройка инфраструктуры и CI/CD через Terraform

Данная инструкция описывает, как настроить полную инфраструктуру для HTX Interface v2 с использованием Terraform, включая CI/CD пайплайн и деплой в Cloud Run.

## Подготовка

### Предварительные требования

1. **Google Cloud CLI** - установлена и настроена
2. **Terraform** - установлен (версия >= 1.0.0)
3. **Docker** - установлен для локальной разработки

### Настройка аутентификации

```bash
# Аутентификация в Google Cloud
gcloud auth login

# Выбор проекта
gcloud config set project vibrant-period-470810-p7
```

## Применение Terraform

### Инициализация и планирование

```bash
# Перейти в директорию с конфигурацией Terraform
cd infra/terraform/envs/dev

# Инициализировать Terraform
terraform init

# Проверить план изменений
terraform plan
```

### Создание инфраструктуры

```bash
# Применить изменения
terraform apply -auto-approve
```

### Получение ключа сервисного аккаунта для GitHub Actions

После успешного применения Terraform, вы получите ключ сервисного аккаунта для GitHub Actions:

```bash
# Получить и сохранить ключ
terraform output -raw github_sa_key | base64 --decode > github-actions-key.json
```

## Настройка GitHub Actions

### Добавление секрета в GitHub

1. Перейдите в репозиторий на GitHub
2. Выберите Settings → Secrets and variables → Actions
3. Нажмите "New repository secret"
4. Имя: `GCP_SA_KEY`
5. Значение: Вставьте содержимое файла `github-actions-key.json`
6. Нажмите "Add secret"

## Созданные ресурсы

После применения Terraform будут созданы:

1. **Google Cloud APIs** - все необходимые API сервисы
2. **IAM** - сервисные аккаунты с минимальными привилегиями
   - Backend API SA
   - ETL SA
   - Scheduler SA
   - GitHub Actions SA (для CI/CD)
3. **Хранилища данных**
   - Cloud SQL (PostgreSQL с расширением pgvector)
   - Redis для кэширования
   - Cloud Storage (GCS) для файлового хранилища
   - BigQuery для аналитики
4. **Artifact Registry** - для хранения Docker образов
5. **Pub/Sub топики и подписки** - для асинхронной коммуникации
6. **Cloud Run сервисы**
   - Backend API (FastAPI)
   - Frontend (Next.js)
   - FinGPT ML сервис
   - Настроены с оптимальными параметрами автомасштабирования
7. **Secret Manager** - для безопасного хранения секретов

## Удаление ресурсов

При необходимости, можно удалить все созданные ресурсы:

```bash
terraform destroy -auto-approve
```

## Проверка работоспособности

После успешного применения Terraform вы можете проверить созданные ресурсы:

```bash
# Проверить URL сервисов
terraform output service_urls

# Проверить Cloud Run сервисы
gcloud run services list --platform managed

# Проверить Artifact Registry
gcloud artifacts repositories list
```

## Вывод GitHub Actions ключа

Ключ сервисного аккаунта для GitHub Actions сохранён в Secret Manager, а также выводится как output в Terraform (чувствительные данные). Вы можете получить его с помощью команды:

```bash
terraform output -raw github_sa_key | base64 --decode > github-actions-key.json
```

## Дополнительные настройки

### Настройка мониторинга и алертинга

Для настройки мониторинга и алертинга рекомендуется:

1. Создать дашборд в Cloud Monitoring
2. Настроить алерты для критических метрик (CPU, память, ошибки)
3. Настроить оповещения в Slack или по email

### Настройка логирования

По умолчанию все Cloud Run сервисы отправляют логи в Cloud Logging, где вы можете:

1. Просматривать логи в реальном времени
2. Настраивать Log-based metrics
3. Экспортировать логи в BigQuery для долгосрочного анализа
