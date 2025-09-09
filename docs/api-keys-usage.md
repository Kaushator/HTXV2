# API Keys — Usage Guide

This guide explains how to manage and use API keys in the backend.

## 1) Enabling API Keys
- Requires a PostgreSQL database and `DATABASE_URL` set in environment.
- Apply Alembic migrations (see `backend/alembic/versions/20250909_0002_api_keys.py`).

## 2) Managing Keys
- Create key (returns plaintext once):
  - `POST /api/keys` body:
    ```json
    {"name":"My key","description":"optional","rate_limit_per_minute":120,"rate_limit_window_sec":60}
    ```
  - Response: `{ meta: {...}, key: "<prefix>.<secret>" }`
- List keys (metadata): `GET /api/keys`
- Disable/enable key:
  - `POST /api/keys/{key_id}/disable`
  - `POST /api/keys/{key_id}/enable`
- Rotate key (reissue):
  - `POST /api/keys/{key_id}/rotate` — деактивирует старый и возвращает новый plaintext ключ
 - Revoke key:
   - `POST /api/keys/{key_id}/revoke` — помечает ключ как неактивный и сохраняет причину

Notes
- Endpoints return 501 if `DATABASE_URL` is not configured (local dev without DB).

## 3) Using Keys with Requests
- Pass key via one of:
  - Query: `?api_key=<prefix>.<secret>`
  - Header: `X-API-Key: <prefix>.<secret>`
- Rate limiting scopes per key when quotas are set.
- Logs/metrics never expose full key; only `key_prefix` is used in metrics (`api_key_requests_total`) and access logs (`api_key_prefix`).

## 4) Observability
- Metrics:
  - `api_key_requests_total{key_prefix,method,status}` — per‑key request count
- Logs:
  - Access JSON includes `api_key_prefix` (optional) and `request_id`.
- Last usage:
  - Backend updates `last_used_at` best‑effort for any request carrying a key.
