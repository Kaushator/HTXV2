# Обновления CI/CD (сводка)

## Коротко
- Обновлён сканер секретов на `trufflesecurity/trufflehog-actions@v0.0.8`.
- Прояснена настройка секрета `GCP_SA_KEY` для GitHub Actions.
- Добавлены сборка/публикация и деплой FinGPT в Cloud Run.
- Тюнинг ресурсов Cloud Run для backend/frontend/FinGPT.
- В README и деплой‑доках добавлены инструкции логина в Artifact Registry.

## TruffleHog (скан секретов)
- Замена `trufflesecurity/trufflehog@v3` → `trufflesecurity/trufflehog-actions@v0.0.8`.
- Параметры: `path: .`, `extra_args: --only-verified`.
- Применено в CI и CI/CD workflow.

## Секрет `GCP_SA_KEY` (Google Cloud)
- В workflow используется JSON‑ключ сервисного аккаунта: `${{ secrets.GCP_SA_KEY }}`.
- Как добавить:
  - GitHub → Settings → Secrets and variables → Actions → New repository secret
  - Name: `GCP_SA_KEY`
  - Value: полное содержимое JSON‑ключа сервисного аккаунта
- Роли сервисного аккаунта (минимум):
  - Artifact Registry Writer
  - Cloud Run Developer
  - Service Account User
  - Storage Admin

## Cloud Run — параметры ресурсов
- Backend API:
  - `--min-instances=1`, `--max-instances=10`, `--memory=1Gi` (постоянная доступность + масштабирование)
- Frontend:
  - `--min-instances=0`, `--max-instances=5`, `--memory=512Mi` (экономия)
  - Env для WebSocket: `NEXT_PUBLIC_WS_URL=wss://…/ws`
- FinGPT (ML‑сервис):
  - Деплой добавлен; ресурсы: `--cpu=2`, `--memory=8Gi`, `--min-instances=0`, `--max-instances=2`

## Artifact Registry — логин
- Вариант 1: `gcloud auth configure-docker us-central1-docker.pkg.dev`
- Вариант 2: `gcloud auth print-access-token | docker login -u oauth2accesstoken --password-stdin https://us-central1-docker.pkg.dev`

## Где смотреть результаты
- GitHub Actions → вкладка Actions → Workflows `CI` и `CI/CD`.
- Артефакты:
  - Backend: `backend-tests` (pytest JUnit и HTML)
  - Frontend: `frontend-coverage` (покрытие Vitest)

## Триггеры workflow
- CI: `push`/`pull_request` на `main`, `workflow_dispatch`.
- CI/CD: `push` на `main` (после прохождения CI), `workflow_dispatch` при необходимости.

## Дальше по плану
- Добавить деплой переменных окружения через `--set-env-vars`/`--update-env-vars` из GitHub Secrets.
- Добавить триггер по релизным тегам (`on: push: tags: 'v*'`).
