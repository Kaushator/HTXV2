# Задачи для ClaudeAI (параллельная разработка)

Цель: дать ClaudeAI самостоятельный и полезный фронт работ без конфликтов с текущими задачами основной ветки.

## Координация и границы
- Что сейчас забираю я (не трогать):
  - Логирование запросов/метрик (uvicorn access + структурные логи)
  - P1: Error handling: глобальный обработчик исключений + коды/сообщения
  - P2: CSV/XLSX Signed URL (заглушка → GCS), валидации, ограничения размера
- Файлы/папки, которые лучше не изменять без согласования (PR only):
  - `backend/app/main.py`, `backend/app/config.py`
  - `backend/app/routers/uploads.py`, `backend/app/utils/ratelimit.py`, `backend/app/services/quotas.py`
  - `docs/dev-journal.md`, `docs/tasks.md` (можно дополнять через отдельные файлы/ссылки)
  - `.github/workflows/ci.yml`, `.github/workflows/ci-cd.yml` (изменения только через отдельные шаги/джобы, без ломки текущей логики)
- Ветвление: `claude/<кратко-задача>`; коммиты с префиксом `[claude]`.
- Слияние: только через PR, без форс-пушей в `main`.

## Приоритеты и задачи (без конфликтов)

P0 — Самые приоритетные и независимые
1) Frontend: UI для `/ws/ticker` (полировка)
   - Что: отрисовка real-time обновлений для BTC/ETH, индикатор состояния (подключение/ошибка), настраиваемый `interval_ms`, скелетон на загрузке.
   - Критерии: открытие страницы отображает поток обновлений; ручной ввод тикеров; Vitest-стаб для ws-клиента; базовая документация в README.

2) CI/CD: обязательные проверки для PR
   - Что: настроить required checks в GitHub и соответствующие статусы из `ci.yml`; добавить labeler и автозапрос ревьюеров (по желанию).
   - Критерии: PR не мёржится без прохождения backend pytest, frontend type-check/tests и trufflehog.

3) Terraform: полезные outputs для dev
   - Что: добавить в `infra/terraform/envs/dev/*` выводы URL Cloud Run сервисов (`backend_url`, `frontend_url`, `fingpt_url`).
   - Критерии: `terraform output` показывает валидные ссылки после `apply`.

4) Документация: GitHub Actions и артефакты
   - Что: в `docs/github-actions-setup.md` и `docs/ci-cd-updates.md` описать, где смотреть артефакты pytest/Vitest, как перезапустить workflow, как читать отчёты.
   - Критерии: шаги воспроизводимы; ссылки на артефакты и скриншоты/примеры команд.

P1 — Полезные улучшения
5) Backend tests: углы для HTX ticker и rate limit
   - Что: тесты на TTL override (границы: 0, max, >max), поведение без Redis (in-memory fallback), серийные запросы под лимит.
   - Критерии: новые тесты зелёные локально и в CI; документация кейсов в `backend/tests/README.md`.

6) Исправление кодировки и плейсхолдеров в `docs/project-report.md`
   - Что: привести файл к UTF‑8, убрать артефакты шрифта/кодировки, заменить плейсхолдеры реальными данными (датами/описаниями).
   - Критерии: корректное отображение в IDE/GitHub; нет мусорных символов; актуальная дата.

7) Спецификация управления API-ключами
   - Что: подготовить `docs/api-keys-spec.md` (модель `api_keys`, роли/квоты, эндпоинты CRUD, хранение хеша/прав, ротация, троттлинг/квоты на ключ).
   - Критерии: согласованный документ со схемами, диаграммами последовательности (mermaid), примеры запросов/ответов.

P2 — Улучшение качества и наблюдаемости
8) Frontend tests: покрытие vitest ≥ 40% для key-компонентов
   - Что: тесты для `src/components/ui/*`, провайдеров и утилит; мок API-слоёв.
   - Критерии: отчёт coverage ≥ 40%, зелёные тесты локально/в CI.

9) Диаграммы потоков WS/HTTP
   - Что: `docs/flows.md` с mermaid-схемами для `/ws/ticker`, `/api/data/htx/ticker` и health-check цепочек.
   - Критерии: схемы рендерятся в GitHub; ссылки из `docs/architecture.md`.

P3 — Док- и DevEx-полировка
10) FinGPT: developer guide
   - Что: `docs/fingpt-dev.md` — локальный запуск, частые проблемы (CUDA/драйверы), как смотреть логи, как обновить образ.
   - Критерии: по шагам под Windows/Linux, проверено локально.

## Новая волна задач (не пересекаются)

P0 — CI/Docs/UX без бэкенда
11) Required checks и правила мёржа
   - Что: включить required checks в GitHub (backend pytest, frontend vitest, trufflehog), описать в `docs/github-actions.md` + добавить PR template.
   - DoD: защита ветки main настроена; PR template в `.github/PULL_REQUEST_TEMPLATE.md`.

12) WS UX: reconnection/backoff + индикаторы
   - Что: улучшить `useWebSocket`/UI — экспоненциальный backoff, индикатор статуса, кнопка reconnect.
   - DoD: покрытие тестами, поведение воспроизводимо в smoke.

P1 — Наблюдаемость/дашборды
13) Grafana dashboards (JSON)
   - Что: подготовить JSON‑дашборды (latency p95, RPS, errors) и гайд импорта `docs/grafana-dashboards.md`.
   - DoD: файлы JSON в `docs/grafana/`, инструкция проверена локально.

14) Диаграммы потоков
   - Что: дополнить `docs/flows.md` mermaid‑диаграммами: GCS uploads, WS поток, ошибки/ретраи.
   - DoD: диаграммы рендерятся в GitHub, ссылки из `docs/architecture.md`.

P2 — DevEx/процессы
15) Issue/PR templates
   - Что: добавить `.github/ISSUE_TEMPLATE/*` и обновить CODEOWNERS при необходимости.
   - DoD: шаблоны доступны при создании issue/PR.

16) OpenAPI артефакты
   - Что: экспортировать `/openapi.json` в `docs/openapi.json` и мини‑гайд как синхронизировать.
   - DoD: файл в репозитории, обновлённый.

## Definition of Done
- Чёткие критерии проверки в описании задачи выполнены.
- CI зелёный; без деградации существующих проверок.
- PR содержит краткий changelog и инструкции по проверке.

## Коммуникация и журнал
- Для записи прогресса — добавлять отдельные файлы в `docs/journal/` по дате (напр. `docs/journal/2025-09-10.md`).
- В `docs/dev-journal.md` прямые правки не делать (во избежание конфликтов кодировки) — только ссылки на новые записи.

## Как запускать локально (кратко)
- Backend: `make backend` или `uvicorn backend.app.main:app --reload`
- Frontend: `make frontend` или `npm run dev` в `frontend/`
- Тесты: backend `pytest -q`, frontend `npm run test` (Vitest)
- Dev контейнер: `.devcontainer/` (VS Code)
