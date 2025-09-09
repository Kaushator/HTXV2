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

---

## Обязательные проверки для Pull Requests

### Настройка в GitHub Repository Settings

Для обеспечения качества кода настройте обязательные проверки в настройках репозитория:

1. **Перейдите в Settings > Branches**
2. **Добавьте правило для ветки `main`** или отредактируйте существующее
3. **Включите следующие настройки**:

#### Required Status Checks
- ✅ **Require status checks to pass before merging**
- ✅ **Require branches to be up to date before merging**

#### Обязательные проверки (точные названия из workflow)
- `Backend (pytest)` - тесты и линтинг backend
- `Frontend (lint + type-check + tests)` - проверки frontend
- `Secret Scan (TruffleHog)` - сканирование секретов

#### Дополнительные защитные правила
- ✅ **Require pull request reviews before merging** (минимум 1 ревьюер)
- ✅ **Dismiss stale pull request approvals when new commits are pushed**
- ✅ **Require review from code owners** (если есть файл CODEOWNERS)
- ✅ **Restrict pushes that create files** (опционально)
- ✅ **Require linear history** (опционально, предотвращает merge коммиты)

### Автоматический Labeler для PR

Создайте файл `.github/labeler.yml` для автоматического добавления меток:

```yaml
# .github/labeler.yml
backend:
  - backend/**/*
  - backend/

frontend:
  - frontend/**/*
  - frontend/

documentation:
  - docs/**/*
  - docs/
  - README.md
  - "*.md"

infrastructure:
  - infra/**/*
  - infra/
  - docker-compose.yml
  - Dockerfile
  - .github/**/*

tests:
  - "**/*test*"
  - "**/*spec*"
  - test/
  - tests/
```

Добавьте job в workflow:

```yaml
labeler:
  permissions:
    contents: read
    pull-requests: write
  runs-on: ubuntu-latest
  if: github.event_name == 'pull_request'
  steps:
    - uses: actions/labeler@v5
      with:
        repo-token: "${{ secrets.GITHUB_TOKEN }}"
```

### Автоматический запрос ревьюеров

Создайте файл `.github/CODEOWNERS`:

```
# Global owners
* @Kaushator

# Backend code
backend/ @Kaushator
backend/**/*.py @Kaushator

# Frontend code  
frontend/ @Kaushator
frontend/**/*.ts @Kaushator
frontend/**/*.tsx @Kaushator

# Infrastructure
infra/ @Kaushator
docker-compose.yml @Kaushator
.github/ @Kaushator

# Documentation
docs/ @Kaushator
*.md @Kaushator
```

## Управление артефактами

### Доступные артефакты

Каждый запуск workflow генерирует следующие артефакты:

#### Backend Test Artifacts (`backend-tests`)
- `pytest-junit.xml` - результаты тестов в формате JUnit
- `pytest-report.html` - HTML отчет с детальными результатами
- `backend-lint.txt` - вывод ruff линтера
- `backend-errors.md` - сводный отчет об ошибках

#### Frontend Test Artifacts (`frontend-tests`)
- `coverage/` - отчеты покрытия кода Vitest (HTML и JSON)
- `frontend-lint.txt` - вывод ESLint
- `frontend-type-check.txt` - результаты TypeScript компилера
- `frontend-tests.txt` - результаты тестов Vitest
- `frontend-errors.md` - сводный отчет об ошибках

#### Error Summary (`error-summary`)
- `error-summary.md` - полный анализ ошибок с примерами

### Доступ к артефактам

1. **Перейдите на вкладку Actions** в репозитории
2. **Выберите запуск workflow**
3. **Прокрутите вниз до секции "Artifacts"**
4. **Скачайте нужный ZIP архив с артефактом**

### Срок хранения артефактов

- **Период хранения**: 90 дней (настройка GitHub по умолчанию)
- **Лимит размера**: 10GB на репозиторий
- **Индивидуальный лимит**: 2GB на артефакт

## Перезапуск workflow

### Ручной запуск

#### Через веб-интерфейс GitHub
1. Перейдите на **вкладку Actions** в репозитории
2. Выберите **workflow CI/CD**
3. Нажмите **"Run workflow"**
4. Выберите ветку и нажмите **"Run workflow"**

#### Через GitHub CLI
```bash
# Запуск workflow на текущей ветке
gh workflow run ci-cd.yml

# Запуск на определенной ветке
gh workflow run ci-cd.yml --ref feature-branch

# Проверка статуса workflow
gh run list --workflow=ci-cd.yml
```

### Перезапуск неудачных jobs

1. **Перейдите к неудачному запуску workflow**
2. **Нажмите "Re-run jobs"**
3. **Выберите**:
   - "Re-run failed jobs" - только неудачные jobs
   - "Re-run all jobs" - полный workflow

## Примеры ошибок и их анализ

### Типичные ошибки TypeScript
```
src/components/Header.tsx:42:10 - error TS2339: Property 'title' does not exist on type 'HeaderProps'.
src/utils/api.ts:78:15 - error TS2322: Type 'string | null' is not assignable to type 'string'.
```

### Предупреждения ESLint
```
src/hooks/useData.ts:24:5 - warning: React Hook useEffect has a missing dependency: 'fetchData'. Either include it or remove the dependency array. (react-hooks/exhaustive-deps)
src/pages/Dashboard.tsx:56:7 - warning: Do not use setState in componentDidMount (react/no-did-mount-set-state)
```

### Ошибки тестов Backend
```
FAILED app/tests/test_api.py::test_create_user - AssertionError: assert 201 == 400
FAILED app/tests/test_models.py::test_user_validation - ValidationError: {'email': ['Invalid email format']}
```

## Мониторинг и отладка

### Просмотр детальных логов

1. **Кликните на неудачный job** в запуске workflow
2. **Раскройте конкретный шаг** для просмотра детального вывода
3. **Используйте поиск** для поиска конкретных ошибок
4. **Скачайте логи** кнопкой "Download logs"

### Отладка типичных проблем

#### 1. Ошибки установки зависимостей
**Симптомы**: Установка Python/Node пакетов завершается неудачей
**Решения**:
- Проверьте `requirements.txt` и `package.json` на некорректные версии
- Убедитесь в совместимости зависимостей
- Очистите кэш, обновив запуски workflow

#### 2. Неудачи тестов
**Симптомы**: Тесты проходят локально, но падают в CI
**Решения**:
- Проверьте различия в окружении (версии Python/Node)
- Убедитесь в изоляции тестов и правильной очистке
- Проверьте настройки timeout для тестов
- Ищите race conditions в асинхронных тестах

### Status badges для README

Добавьте в README.md значки статуса сборки:

```markdown
[![CI/CD](https://github.com/Kaushator/HTX_interfacev2/workflows/CI%2FCD/badge.svg)](https://github.com/Kaushator/HTX_interfacev2/actions)
[![Backend Tests](https://github.com/Kaushator/HTX_interfacev2/workflows/CI%2FCD/badge.svg?event=push)](https://github.com/Kaushator/HTX_interfacev2/actions)
```
