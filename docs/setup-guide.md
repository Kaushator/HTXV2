# Руководство по настройке и развертыванию HTX Interface v2

Данное руководство описывает процесс настройки инфраструктуры и развертывания проекта HTX Interface v2 с использованием Terraform и GitHub Actions.

## 1. Предварительные требования

- Доступ к проекту Google Cloud Platform (GCP)
- Аккаунт GitHub с доступом к репозиторию
- Установленные инструменты:
  - Git
  - Terraform (версия >= 1.3)
  - Google Cloud SDK (gcloud)
  - Docker

## 2. Структура проекта

```
HTXEnterface_v2/
├── backend/           # API сервер на Python
├── frontend/          # Веб-интерфейс
├── fingpt/            # Сервис FinGPT
├── infra/             # Инфраструктурный код
│   └── terraform/     # Terraform конфигурация
├── docs/              # Документация
└── .github/
    └── workflows/     # GitHub Actions workflows
```

## 3. Настройка инфраструктуры через Terraform

### 3.1. Инициализация Terraform

```bash
cd infra/terraform
terraform init
```

### 3.2. Применение инфраструктуры

```bash
terraform apply -var="project_id=vibrant-period-470810-p7"
```

После выполнения команды Terraform создаст:
- Сервисный аккаунт для CI/CD
- Репозиторий в Artifact Registry
- Сервисы Cloud Run для backend, frontend и fingpt

### 3.3. Получение ключа сервисного аккаунта

```bash
terraform output -raw github_actions_sa_key > sa-key.json
```

## 4. Настройка GitHub Actions

### 4.1. Добавление секретов

Добавьте следующие секреты в GitHub репозиторий:
- `GCP_SA_KEY`: содержимое файла sa-key.json в формате base64
- `GCP_PROJECT_ID`: ID вашего проекта GCP (`vibrant-period-470810-p7`)
- `GCP_REGION`: регион GCP (`us-central1`)

### 4.2. Структура CI/CD pipeline

CI/CD pipeline состоит из следующих этапов:
1. **Backend тесты**:
   - Проверка кода линтером (ruff)
   - Запуск pytest
   - Сбор отчетов об ошибках

2. **Frontend тесты**:
   - Проверка ESLint
   - Проверка типов TypeScript
   - Запуск unit-тестов (Vitest)
   - Сбор отчетов об ошибках

3. **Сканирование секретов**:
   - Анализ кода на наличие секретов (TruffleHog)

4. **Сборка и развертывание**:
   - Сборка Docker образов для backend, frontend, fingpt
   - Публикация образов в Artifact Registry
   - Развертывание сервисов в Cloud Run
   - Проверка здоровья сервисов

5. **Сводка ошибок**:
   - Создание сводного отчета об ошибках и предупреждениях
   - Сохранение отчета как артефакт

## 5. Запуск CI/CD pipeline

### 5.1. Автоматический запуск

CI/CD pipeline запускается автоматически при:
- Push в ветку `main`
- Pull Request в ветку `main`

### 5.2. Ручной запуск

Для ручного запуска workflow:
1. Перейдите в раздел "Actions" в GitHub репозитории
2. Выберите workflow "CI/CD"
3. Нажмите "Run workflow"

## 6. Мониторинг и отладка

### 6.1. Просмотр логов GitHub Actions

1. Перейдите в раздел "Actions" в GitHub репозитории
2. Выберите конкретный запуск workflow
3. Раскройте нужный job для просмотра логов

### 6.2. Просмотр отчетов об ошибках

1. Перейдите в завершенный запуск workflow
2. В разделе "Artifacts" скачайте артефакт "error-summary"
3. Откройте файл `error-summary.md` для просмотра сводки ошибок

### 6.3. Мониторинг сервисов в Google Cloud

1. Перейдите в консоль Google Cloud
2. Выберите Cloud Run и просмотрите сервисы:
   - `htx-interface-backend`
   - `htx-interface-frontend`
   - `htx-interface-fingpt`
3. Для каждого сервиса доступны метрики, логи и настройки

## 7. Устранение неполадок

### 7.1. Проблемы с Terraform

Если возникают проблемы с Terraform:
1. Проверьте логи ошибок
2. Убедитесь, что аутентификация в Google Cloud настроена правильно
3. Проверьте права доступа в Google Cloud

### 7.2. Проблемы с CI/CD

Если CI/CD pipeline завершается с ошибкой:
1. Проверьте логи конкретного шага
2. Убедитесь, что секреты настроены правильно
3. Проверьте, что сервисный аккаунт имеет все необходимые права

### 7.3. Проблемы с сервисами

Если сервисы не работают или недоступны:
1. Проверьте логи сервисов в Cloud Run
2. Проверьте, что образы Docker правильно собраны и опубликованы
3. Убедитесь, что переменные окружения настроены корректно

## 8. Обновление и изменение инфраструктуры

### 8.1. Обновление Terraform конфигурации

1. Внесите изменения в файлы в директории `infra/terraform`
2. Примените изменения:
   ```bash
   terraform plan
   terraform apply
   ```

### 8.2. Обновление CI/CD pipeline

1. Внесите изменения в файл `.github/workflows/ci-cd.yml`
2. Закоммитьте и отправьте изменения
3. Проверьте работу обновленного pipeline

## 9. Рекомендации по безопасности

- Регулярно ротируйте ключи сервисного аккаунта
- Используйте принцип наименьших привилегий для сервисных аккаунтов
- Регулярно проверяйте логи на наличие подозрительной активности
- Настройте мониторинг безопасности в Google Cloud

## 10. Дополнительные ресурсы

- [Документация Terraform для Google Cloud](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Документация GitHub Actions](https://docs.github.com/en/actions)
- [Документация Google Cloud Run](https://cloud.google.com/run/docs)
- [Документация Artifact Registry](https://cloud.google.com/artifact-registry/docs)
