# OpenTelemetry Tracing Runbook

Цель: связать логируемый `request_id` и `trace_id`/`span_id` в backend с распределённой трассировкой (Cloud Trace/OTel).

## 1) Текущая корелляция в backend
- Middleware читает заголовок `X-Cloud-Trace-Context` и добавляет `trace_id`/`span_id` в JSON‑логи.
- Для каждого запроса создаётся `X-Request-ID` и логируется `request_id`.

## 2) Варианты интеграции OTel
1. Автоинструментация FastAPI/Uvicorn
   - Установить `opentelemetry-instrumentation-fastapi`, `opentelemetry-instrumentation-asyncpg`, `opentelemetry-exporter-google-cloud` (или OTLP):
     ```bash
     pip install opentelemetry-distro opentelemetry-instrumentation-fastapi opentelemetry-instrumentation-asyncpg opentelemetry-exporter-otlp
     ```
   - Запуск через:
     ```bash
     opentelemetry-instrument --traces_exporter otlp --metrics_exporter none \
       uvicorn app.main:app --host 0.0.0.0 --port 8000
     ```
   - Для GCP используйте Google exporter или OTLP → Cloud Trace.

2. Явная инициализация SDK в коде
   - Настроить `TracerProvider`, `BatchSpanProcessor`, `OTLPSpanExporter` (gRPC/HTTP) в `startup` backend.
   - Проставлять `request_id` как атрибут span (`http.request_id`).

## 3) Атрибуты и контекст
- Полезные атрибуты: `http.method`, `http.target`, `http.status_code`, `net.peer.ip`, `request_id`, `api.key_prefix`.
- Для логов и трассировок используйте один `trace_id` для корреляции в Cloud Logging/Trace.

## 4) Безопасность
- Не передавать полный API‑ключ в атрибутах/логах — только префикс.

## 5) Проверка
- Сгенерируйте трафик, убедитесь, что в логах есть `trace_id` и что трассы появляются в выбранном бэкенде (Cloud Trace/Grafana Tempo/Jaeger).

