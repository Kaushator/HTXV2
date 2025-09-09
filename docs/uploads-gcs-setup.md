# Uploads: GCS Signed URL Setup

Этот документ описывает, как включить генерацию подписанных URL (V4 Signed URL) для загрузки CSV/XLSX в Google Cloud Storage.

## 1) Предпосылки
- Аккаунт GCP и проект по умолчанию настроен в gcloud (`gcloud config list`)
- Сервисный аккаунт, который использует backend (локально — ADC, в CI/CD — SA или WIF), имеет доступ к Storage
- В backend собрана зависимость `google-cloud-storage`

## 2) Права доступа (IAM)
Сервисному аккаунту, от имени которого backend генерирует ссылки, нужны права на объект в bucket. Минимум:
- `roles/storage.objectCreator` (создание объектов)
- Рекомендуется также `roles/storage.objectViewer` (чтение метаданных для некоторых сценариев)
- Для простоты отладки можно выдать `roles/storage.objectAdmin` на bucket (не для прод)

Пример (через gcloud):
```bash
# Допустим, SA: github-actions@PROJECT_ID.iam.gserviceaccount.com
# Bucket: htx-uploads-dev
PROJECT_ID=your-project
BUCKET=htx-uploads-dev
SA=github-actions@${PROJECT_ID}.iam.gserviceaccount.com

gcloud storage buckets add-iam-policy-binding gs://${BUCKET} \
  --member=serviceAccount:${SA} \
  --role=roles/storage.objectCreator
```

## 3) Настройка переменных окружения
В `.env`/секретах установите:
- `UPLOADS_GCS_BUCKET=<ваш-bucket>`
- `UPLOADS_MAX_SIZE_MB` (по умолчанию 10)
- `UPLOADS_ALLOWED_EXT=csv,xlsx`
- `UPLOADS_ALLOWED_CT=text/csv,application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`
- `UPLOADS_URL_TTL_SEC=600`

Локально аутентификация через ADC:
```bash
# Локальная разработка
gcloud auth application-default login
```

## 4) Как это работает в backend
- Эндпоинт: `POST /api/data/upload/request-signed-url`
- При наличии `UPLOADS_GCS_BUCKET` backend вызывает `google-cloud-storage` для генерации V4 Signed URL (метод PUT)
- При отсутствии/ошибке — возвращается безопасная заглушка с доменом `.invalid`

Пример запроса:
```bash
curl -s http://localhost:8000/api/data/upload/request-signed-url \
  -H 'Content-Type: application/json' \
  -d '{
    "filename": "data.csv",
    "content_type": "text/csv",
    "size_bytes": 1024
  }' | jq
```
Ответ (фрагмент):
```json
{
  "status": "ok",
  "method": "PUT",
  "upload_url": "https://storage.googleapis.com/<bucket>/uploads/<uuid>/data.csv?...",
  "headers": { "Content-Type": "text/csv" },
  "expires_at": "2025-09-09T12:00:00Z",
  "object_key": "uploads/<uuid>/data.csv",
  "max_size_bytes": 10485760
}
```

Загрузка файла по полученной ссылке:
```bash
curl -X PUT "<upload_url>" \
  -H "Content-Type: text/csv" \
  --upload-file ./data.csv -i
```

## 5) Отладка
- Проверьте, что backend логирует запросы (JSON) и ошибки — см. `docs/observability.md`
- Убедитесь, что ADC/SA действительно имеет доступ к bucket (ошибки прав будут в логах)
- Срок действия ссылки ограничен `UPLOADS_URL_TTL_SEC`

