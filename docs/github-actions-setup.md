# Настройка GitHub Actions для HTX Interface v2

## Обзор CI/CD пайплайна

Наш CI/CD пайплайн выполняет следующие задачи:
1. Запускает тесты и линтинг для backend (Python)
2. Запускает тесты, линтинг и проверку типов для frontend (Next.js)
3. Сканирует код на наличие секретов с помощью TruffleHog
4. Собирает Docker образы для backend и frontend
5. Публикует образы в Google Artifact Registry
6. Деплоит сервисы в Google Cloud Run

## Требования перед запуском

Для успешного выполнения всех шагов CI/CD, необходимо настроить следующие секреты в репозитории:

### 1. Настройка GCP Service Account Key

Для аутентификации в Google Cloud необходимо создать сервисный аккаунт и загрузить его ключ в секреты GitHub.

#### Шаги для создания сервисного аккаунта:

1. Перейдите в [Google Cloud Console](https://console.cloud.google.com/)
2. Выберите проект `vibrant-period-470810-p7`
3. Перейдите в "IAM & Admin" -> "Service Accounts"
4. Нажмите "Create Service Account"
5. Укажите имя `github-actions-deployer` и описание
6. Добавьте следующие роли:
   - Artifact Registry Writer
   - Cloud Run Developer
   - Service Account User
   - Storage Admin
7. После создания сервисного аккаунта, нажмите на него в списке
8. Перейдите на вкладку "Keys"
9. Нажмите "Add Key" -> "Create new key"
10. Выберите формат "JSON" и нажмите "Create"
11. Сохраните загруженный файл ключа (он загрузится автоматически)

#### Добавление ключа в секреты GitHub:

1. Откройте репозиторий GitHub HTX Interface v2
2. Перейдите в "Settings" -> "Secrets and variables" -> "Actions"
3. Нажмите "New repository secret"
4. Имя: `GCP_SA_KEY`
5. Значение: вставьте полное содержимое JSON-файла ключа
6. Нажмите "Add secret"

## Запуск пайплайна

После настройки секретов пайплайн будет автоматически запускаться при:
- Push в ветку `main`
- Pull Request в ветку `main`
- Ручном запуске через GitHub Actions UI

## Артефакты и отчеты

После выполнения пайплайна будут доступны следующие артефакты:
- Backend test reports: `backend-tests`
  - pytest-junit.xml (для интеграции с CI системами)
  - pytest-report.html (для визуального анализа результатов)
- Frontend coverage: `frontend-coverage`
  - Отчеты о покрытии кода тестами

## Деплой и доступ к сервисам

После успешного деплоя сервисы будут доступны по следующим URL:
- Backend API: https://htx-interface-backend-876480894698.us-central1.run.app
- Frontend: https://htx-interface-frontend-876480894698.us-central1.run.app

## Дополнительная настройка

### Мониторинг и алертинг

Для настройки мониторинга в Google Cloud:
1. Перейдите в Cloud Monitoring
2. Создайте дашборд для отслеживания:
   - Latency сервисов Cloud Run
   - Error rate
   - CPU и Memory utilization
3. Настройте алертинг для уведомления при критических ситуациях

### Дополнительные секреты для внешних сервисов

Если в приложении используются внешние сервисы (HTX API, OpenAI и т.д.), добавьте их ключи в GitHub секреты и настройте передачу этих секретов в сервисы Cloud Run.

### Аутентификация Docker к Artifact Registry в Actions

В workflow используйте шаг для настройки Docker через gcloud (после setup-gcloud):

```yaml
- name: Configure Docker to push to Artifact Registry
  run: gcloud auth configure-docker us-central1-docker.pkg.dev
```

Либо применяйте `docker/login-action` с access token от `gcloud auth print-access-token`.
