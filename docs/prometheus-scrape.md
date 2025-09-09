# Prometheus: Local Scrape of Backend Metrics

Backend экспонирует метрики по `GET /metrics` в формате Prometheus. Ниже пример локального запуска Prometheus и базовой конфигурации.

## 1) Конфиг `prometheus.yml`
```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'backend'
    metrics_path: /metrics
    static_configs:
      - targets: ['localhost:8000']
```

## 2) Запуск Prometheus через Docker
```bash
docker run --rm -p 9090:9090 \
  -v $(pwd)/prometheus.yml:/etc/prometheus/prometheus.yml \
  prom/prometheus:latest
```

Откройте http://localhost:9090 и выполните запросы:
- `rate(http_requests_total[1m])`
- `histogram_quantile(0.95, sum by (le) (rate(http_request_duration_seconds_bucket[5m])))`
- `sum(http_errors_total)`

## 3) Примечания
- Для прод-среды используйте Google Managed Service for Prometheus или иной управляемый стек. Для Cloud Run потребуется отдельная конфигурация сбора (scrape публичного URL или push через OpenTelemetry/Cloud Monitoring).
- Избегайте высоко-кардинальных меток (например, динамические пути) — при необходимости в будущем заменим метку `path` на шаблон маршрута.

