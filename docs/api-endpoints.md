# HTX Interface v2 — API Endpoints

## Implemented (mock)
- GET `/` — API info
- GET `/health`, `/healthz` — basic health
- GET `/health/details` — dependency timings
- GET `/api/coins` — list coins (mock)
- POST `/api/coins` — add coin (mock)
- DELETE `/api/coins/{symbol}` — remove coin (mock)
- GET `/api/analysis/{symbol}` — analysis (mock)

## Pending (stubs return 501)
- GET `/api/data/sources` — list data sources
- GET `/api/data/coingecko/coin/{coin_id}` — CoinGecko coin info
- GET `/api/news/cryptopanic` — news with ML filtering
- POST `/api/llm/predict/{symbol}` — LLM prediction via FinGPT
 - GET `/api/keys/`, POST `/api/keys/` — API Keys management (requires DB; returns 501 if DATABASE_URL not set)
 - POST `/api/keys/{key_id}/disable` — deactivate key (requires DB)
 - POST `/api/keys/{key_id}/enable` — activate key (requires DB)
  - POST `/api/keys/{key_id}/rotate` — rotate key (deactivate old, issue new; requires DB)

Notes
- Stubs are wired via FastAPI routers with status 501 Not Implemented to reserve paths for later integration.
- Update this document as endpoints graduate from Pending to Implemented.

## Implemented (alpha)
- GET `/api/data/htx/ticker/{symbol}` — HTX ticker (with optional Redis caching)
 - GET `/ws/ticker?symbols=BTC,ETH&interval_ms=1000` — WebSocket ticker stream
 - POST `/api/data/upload/request-signed-url` — CSV/XLSX signed URL (validations; GCS when `UPLOADS_GCS_BUCKET` set, else stub)
 - GET `/metrics` — Prometheus metrics endpoint
