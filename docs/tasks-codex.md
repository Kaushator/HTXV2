# Задачи для Codex (основной поток)

Цель: сфокусировать мой фронт работ и исключить пересечения с задачами ClaudeAI.

## Координация и границы
- Моё: 
  - Логирование запросов/метрик (uvicorn access + структурные логи)
  - P1: Error handling — глобальный обработчик исключений + коды/сообщения
  - P2: CSV/XLSX Signed URL (заглушка → GCS), валидации, ограничения размера
- Не менять без согласования (PR only):
  - `frontend/*` (в т.ч. UI для `/ws/ticker` и Vitest)
  - Документация от Claude: `docs/*` связанная с GH Actions/flows, encoding-фиксы
  - Terraform outputs и PR required checks (ведёт Claude)
- Ветки: `codex/<кратко-задача>`; коммиты с префиксом `[codex]`.
- Слияние: через PR, без форс-пушей в `main`.

## Приоритеты и задачи

P0 — Логирование и метрики
1) Structured access logs + метрики
   - Что: JSON-логи запросов (method, path, status, duration_ms, client_ip, ua, request_id), добавление `X-Request-ID`, единый формат.
   - Как: middleware + настр. логгера, единый формат для `htx.*`, подавить дубли `uvicorn.access` или перенастроить под JSON.
   - DoD: 1 строка на запрос в JSON, `X-Request-ID` в ответе, читаемость в CI/Cloud Run.

P1 — Error handling
2) Глобальные обработчики исключений
   - Что: единый ответ-оболочка с кодами/сообщениями; обработчики `HTTPException`, `RequestValidationError`, fallback `Exception`.
   - DoD: консистентный JSON-ответ с `error.code`, `error.message`, `request_id`, корректные статусы HTTP.

P2 — CSV/XLSX Signed URL
3) Заглушка GCS Signed URL + валидации
   - Что: эндпоинт, возвращающий временный URL (пока заглушка), проверка размера/типа, ограничения по расширению.
   - DoD: контракт согласован и задокументирован; базовые проверки работают; расширяемо до GCS.

## Definition of Done
- Тесты и CI зелёные, без деградации существующих проверок.
- Логи в JSON со стабильной схемой; ошибки — в едином формате.
- Документация обновлена краткими примерами и командами.

## Журнал и коммуникация
- Прогресс фиксирую файлами `docs/journal/YYYY-MM-DD.md`.
- В `docs/dev-journal.md` прямые правки не делаю (кодировка), только ссылки.

## Прогресс (текущее)
- DONE: Structured access logs + `X-Request-ID` (middleware, JSON formatter)
- DONE: Error handling (HTTP/Validation/Unhandled) — единый JSON
- DONE: Prometheus `/metrics` (`http_requests_total`, `http_request_duration_seconds`, `http_requests_in_progress`)
- DONE: Error counter `http_errors_total{method,path,status}`
- DONE: Signed URL stub + валидации (CSV/XLSX)
- DONE: Документация — `docs/observability.md`, ссылки в `README.md`, `docs/api-endpoints.md`
