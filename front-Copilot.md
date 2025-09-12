# TODO для Frontend (Copilot): HTXV2

## I. Подготовка инфраструктуры фронта

- [ ] Убедиться, что проект полностью запускается через make/docker на локалке.
- [ ] Проверить и почистить зависимости (`package.json`, `node_modules`).
- [ ] Обновить .env.local.example с реальными урлами для API.
- [ ] Добавить конфиги для локальных/продовых переменных (API_URL, WS_URL и т.д.).
- [ ] Проверить, что используется только локальные шрифты и ресурсы.

---

## II. Архитектура и структура фронта

- [ ] Проверить структуру папок: `components/`, `hooks/`, `lib/`, `types/`, `pages/`.
- [ ] Вынести все типы и интерфейсы в отдельные `types.ts`.
- [ ] Вынести все повторяющиеся функции/хуки в `lib/` и `hooks/`.
- [ ] Для каждой бизнес-фичи (trading, file upload, demo) — отдельная папка или модуль.

---

## III. Функциональный фронтенд TODO

- [ ] **Trading View**
  - [ ] Реализовать компонент Ticker с real-time обновлением через WebSocket.
  - [ ] Вынести данные и логику работы с WS в хук useTicker.
  - [ ] Реализовать отображение истории цен/график.
  - [ ] Добавить фильтрацию по монетам/периодам.

- [ ] **File Upload**
  - [ ] Компонент drag&drop для загрузки CSV/XLSX.
  - [ ] Реализовать реальное превью и валидацию файла на фронте.
  - [ ] Интеграция с API для upload и получения signed URL.
  - [ ] Отображение ошибок, прогресса, успешной загрузки.



- [ ] **Демо/витрина**
  - [ ] Страница demo с showcase: trading, upload.
  - [ ] Возможность симулировать ошибки/edge-cases.

---

## IV. UX и оптимизация

- [ ] Везде реализовать загрузку (Skeleton/Loader) и обработку ошибок (ErrorBoundary).
- [ ] Адаптировать UI под мобилку и разные размеры экрана.
- [ ] Проверить и пофиксить все ворнинги/ошибки в консоли.
- [ ] Реализовать краткие гайды/подсказки для пользователя (tooltips, onboarding).

---

## V. Полное делегирование завершения кода Cursor

### Эффективные промпты для Cursor:

```typescript
// @cursor: Создай компонент TradingDashboard с real-time обновлением через WebSocket
// Требования: TypeScript, shadcn/ui, React Query, таблица ордеров, график цен
// Структура: interface TradingData, хук useTradingData, компонент TradingChart
interface TradingDashboardProps {
  symbol: string;
  // @cursor: добавь остальные пропсы для полной функциональности
}

// @cursor: Создай полный хук для управления WebSocket соединением 
// с автореконнектом, обработкой ошибок и типизацией сообщений
export const useTradingWebSocket = () => {
  // @cursor: полная реализация с useEffect, useState, useRef
}

// @cursor: Реализуй компонент FileUploadZone для drag&drop CSV/XLSX
// с прогресс-баром, валидацией типов файлов, превью данных
const FileUploadZone: React.FC = () => {
  // @cursor: complete implementation with react-dropzone, file validation, upload progress
}
```

### Стратегии экономии токенов для Cursor:

**1. Использование шаблонов и паттернов:**
```typescript
// @cursor: Используй этот паттерн для всех API хуков
const useApiHook = (endpoint: string) => {
  // @cursor: стандартная реализация с React Query, error handling, loading states
}

// @cursor: Создай аналогичные хуки для: useMarketData, usePortfolio, useTrading
// по этому же паттерну
```

**2. Автогенерация типов и интерфейсов:**
```typescript
// @cursor: Сгенерируй TypeScript типы на основе этого API response:
// {"symbol": "BTCUSDT", "price": 50000, "change": "+2.5%", "volume": 1000000}
// Создай интерфейсы для MarketData, PriceUpdate, TradingPair

// @cursor: Экспорт всех типов в types/trading.ts с полной документацией JSDoc
```

**3. Быстрое создание компонентов по образцу:**
```typescript
// @cursor: Создай компоненты по этому паттерну для всех страниц проекта:
const PageTemplate: React.FC<{title: string, children: React.ReactNode}> = ({title, children}) => {
  // @cursor: Layout с Header, Navigation, Content area, Error boundary
}

// @cursor: Создай страницы: TradingPage, PortfolioPage, AnalyticsPage, SettingsPage
// используя PageTemplate как основу
```

### Оптимизация использования токенов:

**1. Контекстные комментарии:**
```typescript
// @cursor: КОНТЕКСТ: HTXV2 - криптотрейдинг платформа, FastAPI backend, Next.js frontend
// ЦЕЛЬ: Создать реал-тайм dashboard для торговли криптовалютами
// ТЕХНОЛОГИИ: TypeScript, shadcn/ui, React Query, WebSocket, Zustand

// @cursor: Создай store для управления состоянием торговли
// Включи: активные ордера, баланс портфеля, настройки пользователя
interface TradingStore {
  // @cursor: complete store with actions and getters
}
```

**2. Пошаговые инструкции:**
```typescript
// @cursor: ШАГ 1: Создай базовую структуру компонента
// @cursor: ШАГ 2: Добавь state management с Zustand  
// @cursor: ШАГ 3: Интегрируй WebSocket для real-time данных
// @cursor: ШАГ 4: Добавь обработку ошибок и loading states
// @cursor: ШАГ 5: Стилизуй с использованием shadcn/ui компонентов

const TradingComponent = () => {
  // @cursor: Реализуй каждый шаг последовательно
}
```

**3. Переиспользование и DRY принцип:**
```typescript
// @cursor: Создай универсальный DataTable компонент
// для отображения: ордеров, истории сделок, портфеля
// Параметризуй: columns, data, actions, loading state

// @cursor: Создай shared utilities для:
// - форматирования валют и процентов
// - работы с WebSocket
// - обработки API ошибок
// - валидации форм торговли
```

---

## VI. Финальный чеклист

- [ ] Проект собирается и запускается на ПК без ошибок.
- [ ] Все основные user flows работают при ручной проверке.
- [ ] Нет лишних зависимостей, неиспользуемых файлов.
- [ ] Документация (README, DEMO.md) обновлена и понятна.
- [ ] Можно сделать релизную сборку (`npm run build` проходит без ошибок).

---