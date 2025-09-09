# Observability: Logs, Errors, Metrics

This project exposes structured JSON logs, consistent error responses, and Prometheus metrics.

## JSON Access Logs
- Logger: `htx.access`
- One line per request at INFO level
- Fields: `ts`, `level`, `logger`, `message`, `event=access`, `request_id`, `method`, `path`, `query`, `status_code`, `duration_ms`, `client_ip`, `user_agent`, `trace_id?`, `span_id?`

Example:
```
{"ts":"2025-09-09T20:15:12.345Z","level":"INFO","logger":"htx.access","message":"access","event":"access","request_id":"abc123","trace_id":"4bf92f3577b34da6a3ce929d0e0e4736","span_id":"00f067aa0ba902b7","method":"GET","path":"/health","status_code":200,"duration_ms":3}
```

## Error Responses (JSON)
- All errors include `request_id`, `path`, and an `error` object with `code` and `message`.
- Examples:
  - 404 Not Found:
    ```json
    {"status":"error","request_id":"abc","path":"/no","error":{"code":"http_404","message":"Not Found"},"http_status":404}
    ```
  - 422 Validation:
    ```json
    {"status":"error","error":{"code":"validation_error","message":"Request validation failed","details":{"errors":[...]}}}
    ```
  - 500 Internal:
    ```json
    {"status":"error","error":{"code":"internal_error","message":"Internal server error"}}
    ```

## Metrics (Prometheus)
- Endpoint: `GET /metrics`
- Exported:
  - `http_requests_total{method,path,status}` — request count
  - `http_request_duration_seconds{method,path,status}` — latency histogram
  - `http_requests_in_progress` — in-flight requests
  - `http_errors_total{method,path,status}` — error count (4xx/5xx)
  - `api_key_requests_total{key_prefix,method,status}` — per‑API‑key (prefix‑only) счетчик

Notes
- Labels use raw `path`. For high-cardinality paths consider mapping to route patterns in a follow-up.
 - If `X-Cloud-Trace-Context` is present (Cloud Run/Load Balancer), logs include `trace_id`/`span_id` for correlation.
