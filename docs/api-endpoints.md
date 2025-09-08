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
- GET `/api/data/htx/ticker/{symbol}` — HTX ticker
- GET `/api/data/coingecko/coin/{coin_id}` — CoinGecko coin info
- POST `/api/data/upload/request-signed-url` — CSV/XLSX signed URL
- GET `/api/news/cryptopanic` — news with ML filtering
- POST `/api/llm/predict/{symbol}` — LLM prediction via FinGPT

Notes
- Stubs are wired via FastAPI routers with status 501 Not Implemented to reserve paths for later integration.
- Update this document as endpoints graduate from Pending to Implemented.
