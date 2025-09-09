# HTX Interface v2

![CI](https://github.com/Kaushator/HTX_interfacev2/actions/workflows/ci.yml/badge.svg)
![CI/CD](https://github.com/Kaushator/HTX_interfacev2/actions/workflows/ci-cd.yml/badge.svg)

HTX Interface v2 — финтех‑платформа для анализа криптоактивов с ML/LLM стеком.

Запуск локально
```bash
make prepare
make dev
```

Артефакт‑регистри (GCP) — вход в Docker
- Быстрый логин для Artifact Registry через gcloud:
  - Bash (Linux/macOS):
    - gcloud auth configure-docker us-central1-docker.pkg.dev
  - PowerShell (Windows):
    - gcloud auth configure-docker us-central1-docker.pkg.dev
- Альтернатива (access token через stdin):
  - Bash:
    - gcloud auth print-access-token | docker login -u oauth2accesstoken --password-stdin https://us-central1-docker.pkg.dev
  - PowerShell:
    - (gcloud auth print-access-token) | docker login -u oauth2accesstoken --password-stdin https://us-central1-docker.pkg.dev

Наблюдаемость
- Логи/ошибки/метрики описаны в `docs/observability.md` (JSON‑логи, единый формат ошибок, Prometheus `/metrics`).
 - Пример локального сбора метрик Prometheus: `docs/prometheus-scrape.md`.

Uploads
- Настройка GCS Signed URL: `docs/uploads-gcs-setup.md`.
