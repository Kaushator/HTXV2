# Task Wave 17–25 (ClaudeAI)

Приоритеты и задачи сформированы так, чтобы не пересекаться с Codex (бэкенд‑ядро/observability/API‑keys остаются за Codex).

## P0
- 17) Typed API‑клиент из OpenAPI → фронтенд типы + клиент.
- 18) Playwright E2E (smoke) → главная, WS `/ws/ticker` подключение/рендер.

## P1
- 19) A11y аудит + фиксы (`jsx-a11y`/`axe`).
- 20) Lighthouse CI → budgets/thresholds, артефакты.

## P2
- 21) Storybook для shadcn/ui → истории для ключевых компонентов.
- 22) PWA/Cache стратегии → `public/sw.js` и краткий гайд.

## P3
- 23) Synthetic checks (cron) → GH Actions, отчёт в issue при деградации.
- 24) Автоматизация релиз‑нот → Action по тегам `v*`.
- 25) MSW мок‑сервер → dev/тесты без бэкенда.

DoD: кратко в `docs/journal/YYYY-MM-DD.md` (1–3 пункта + ссылка на PR). Без отчётов.

Смотри также: `docs/tasks-claude.md` (правила и ограничения) и `docs/token-economy.md`.
