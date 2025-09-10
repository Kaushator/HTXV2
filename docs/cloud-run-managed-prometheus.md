# Cloud Run + Managed Prometheus (Runbook)

Цель: собирать метрики из backend `/metrics` в Google Cloud Managed Service for Prometheus и отображать в облачных дашбордах.

## 1) Подготовка
- Убедитесь, что сервис Cloud Run доступен по HTTPS и `/metrics` открыт (или доступен через VPC/прокси)
- Включите Managed Service for Prometheus в проекте GCP

## 2) Опции сбора
1. Scrape напрямую публичный `/metrics` (для dev):
   - Настройка scrape в Prometheus с таргетом `https://<service-url>/metrics`
2. Sidecar/Agent в GKE/Cloud Run Jobs (продвинутый вариант)
3. Перекладка через OpenTelemetry Collector → Cloud Monitoring

Для Cloud Run часто используют Cloud Monitoring + Prometheus sidecar/collector. Сервисы пушат/экспортируют метрики, которые затем доступны в Metrics Explorer.

## 3) Пример правил (PromQL)
- RPS: `sum(rate(http_requests_total[1m])) by (path)`
- Latency p95: `histogram_quantile(0.95, sum by (le) (rate(http_request_duration_seconds_bucket[5m])))`
- Errors: `sum(rate(http_errors_total[5m])) by (status)`
- Per‑key: `sum(rate(api_key_requests_total[5m])) by (key_prefix)`

## 4) Трейс‑корреляция
- Backend включает `request_id`, `trace_id`/`span_id` в JSON‑логах (если есть `X-Cloud-Trace-Context`).
- Для сквозной корреляции подключите Cloud Trace и используйте общий `trace_id` в логах и трассировках.

## 5) Безопасность
- `/metrics` может содержать чувствительные агрегаты. Для прод — закрыть эндпоинт внешним LB/прокси и/или ограничить доступ (IAP/Firewall/VPC‑SC).

