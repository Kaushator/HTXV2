# Деплой с использованием Google Artifact Registry

Этот документ описывает процесс развертывания HTX Interface в Google Cloud Run с использованием Artifact Registry.

## 1. Настройка Google Cloud

```bash
# Настройка Google Cloud CLI
gcloud auth login
gcloud config set project vibrant-period-470810-p7

# Настройка Docker для работы с Artifact Registry (любой из вариантов)
gcloud auth configure-docker us-central1-docker.pkg.dev

# или через access token (bash)
gcloud auth print-access-token | docker login -u oauth2accesstoken --password-stdin https://us-central1-docker.pkg.dev

# PowerShell (Windows)
(gcloud auth print-access-token) | docker login -u oauth2accesstoken --password-stdin https://us-central1-docker.pkg.dev
```

## 2. Сборка Docker-образов

```bash
# Сборка backend
docker build -t us-central1-docker.pkg.dev/vibrant-period-470810-p7/htx-interface/backend:latest ./backend

# Сборка frontend
docker build -t us-central1-docker.pkg.dev/vibrant-period-470810-p7/htx-interface/frontend:latest ./frontend

# Сборка FinGPT
docker build -t us-central1-docker.pkg.dev/vibrant-period-470810-p7/htx-interface/fingpt:latest ./fingpt
```

## 3. Отправка образов в Artifact Registry

```bash
docker push us-central1-docker.pkg.dev/vibrant-period-470810-p7/htx-interface/backend:latest
docker push us-central1-docker.pkg.dev/vibrant-period-470810-p7/htx-interface/frontend:latest
docker push us-central1-docker.pkg.dev/vibrant-period-470810-p7/htx-interface/fingpt:latest
```

## 4. Развертывание в Google Cloud Run

```bash
# Развертывание backend
gcloud run deploy htx-interface-backend \
  --image=us-central1-docker.pkg.dev/vibrant-period-470810-p7/htx-interface/backend:latest \
  --platform=managed \
  --region=us-central1 \
  --allow-unauthenticated \
  --port=8000

# Развертывание frontend
gcloud run deploy htx-interface-frontend \
  --image=us-central1-docker.pkg.dev/vibrant-period-470810-p7/htx-interface/frontend:latest \
  --platform=managed \
  --region=us-central1 \
  --allow-unauthenticated \
  --port=3000
```

## 5. Доступные URL

- Backend API: https://htx-interface-backend-876480894698.us-central1.run.app
- Frontend: https://htx-interface-frontend-876480894698.us-central1.run.app

## 6. Настройка переменных окружения

Для frontend необходимо настроить переменные окружения, чтобы он мог обращаться к backend:

```bash
gcloud run services update htx-interface-frontend \
  --update-env-vars=NEXT_PUBLIC_API_URL=https://htx-interface-backend-876480894698.us-central1.run.app
```

## 7. CI/CD с GitHub Actions

Можно настроить автоматическую сборку и деплой при пуше в репозиторий:

```yaml
name: Build and Deploy to Cloud Run

on:
  push:
    branches:
      - main

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
    - name: Checkout
      uses: actions/checkout@v3

    - name: Set up gcloud
      uses: google-github-actions/setup-gcloud@v1
      with:
        service_account_key: ${{ secrets.GCP_SA_KEY }}
        project_id: vibrant-period-470810-p7

    - name: Configure Docker
      run: gcloud auth configure-docker us-central1-docker.pkg.dev

    - name: Build and Push Backend
      run: |
        docker build -t us-central1-docker.pkg.dev/vibrant-period-470810-p7/htx-interface/backend:latest ./backend
        docker push us-central1-docker.pkg.dev/vibrant-period-470810-p7/htx-interface/backend:latest

    - name: Build and Push Frontend
      run: |
        docker build -t us-central1-docker.pkg.dev/vibrant-period-470810-p7/htx-interface/frontend:latest ./frontend
        docker push us-central1-docker.pkg.dev/vibrant-period-470810-p7/htx-interface/frontend:latest

    - name: Deploy to Cloud Run
      run: |
        gcloud run deploy htx-interface-backend \
          --image=us-central1-docker.pkg.dev/vibrant-period-470810-p7/htx-interface/backend:latest \
          --platform=managed \
          --region=us-central1 \
          --allow-unauthenticated \
          --port=8000
        
        gcloud run deploy htx-interface-frontend \
          --image=us-central1-docker.pkg.dev/vibrant-period-470810-p7/htx-interface/frontend:latest \
          --platform=managed \
          --region=us-central1 \
          --allow-unauthenticated \
          --port=3000
```

## 8. Мониторинг и логи

- Cloud Run логи: https://console.cloud.google.com/logs/query
- Мониторинг: https://console.cloud.google.com/run/detail/us-central1/htx-interface-backend/metrics
