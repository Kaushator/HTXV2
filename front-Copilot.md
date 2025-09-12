# Frontend Development Guide (Copilot/Cursor): HTXV2

## I. Подготовка инфраструктуры фронта ✅

- [x] Проект запускается через `npm run dev` и `npm run build`
- [x] Настроены зависимости: Next.js 14, TypeScript, shadcn/ui, TanStack Query, Zustand
- [x] Создана базовая структура: `lib/utils.ts`, компоненты UI, провайдеры
- [ ] Создать `.env.local.example` с переменными для API (WS_URL, API_URL)
- [ ] Настроить переменные окружения для dev/prod
- [ ] Добавить мониторинг ошибок (Sentry/LogRocket)

---

## II. Архитектура и структура фронта ⚡

- [x] Структура папок: `app/`, `components/`, `lib/`, (требуется: `hooks/`, `types/`)
- [ ] Создать `types/` директорию для всех TypeScript интерфейсов
- [ ] Создать `hooks/` директорию для кастомных React хуков
- [ ] Организовать по бизнес-модулям: `trading/`, `portfolio/`, `analytics/`, `upload/`
- [ ] Настроить абсолютные импорты в `tsconfig.json`

---

## III. Критические компоненты - TODO

### 🎯 **Trading Dashboard** (Приоритет: ВЫСОКИЙ)

- [ ] **TradingDashboard** - главный компонент торговой панели
- [ ] **MarketTicker** - real-time котировки с WebSocket
- [ ] **OrderBook** - стакан заявок с обновлениями
- [ ] **TradingChart** - график цен с техническими индикаторами
- [ ] **OrderForm** - форма создания ордеров (buy/sell)
- [ ] **PositionsTable** - таблица открытых позиций
- [ ] **TradingHistory** - история сделок

### 📊 **Portfolio Management**

- [ ] **PortfolioDashboard** - обзор портфеля
- [ ] **AssetAllocation** - распределение активов (пай-чарт)
- [ ] **PnLChart** - график прибылей/убытков
- [ ] **BalanceCard** - карточка баланса с анимацией
- [ ] **AssetList** - список активов с сортировкой

### 📁 **File Upload System**

- [ ] **FileUploadZone** - drag&drop зона для CSV/XLSX
- [ ] **FilePreview** - предпросмотр загружаемых данных
- [ ] **UploadProgress** - прогресс загрузки с анимацией
- [ ] **FileValidator** - валидация файлов на клиенте
- [ ] **UploadHistory** - история загруженных файлов

### 🤖 **AI/ML Integration**

- [ ] **AIAnalysis** - компонент для AI анализа
- [ ] **ModelSelector** - выбор AI модели (FinGPT/OpenAI/Vertex)
- [ ] **SignalCard** - карточка торгового сигнала
- [ ] **ConfidenceIndicator** - индикатор уверенности AI
- [ ] **AIChat** - чат с AI ассистентом

---

## IV. Критические хуки - TODO

### 🔌 **WebSocket Hooks**

- [ ] **useWebSocket** - базовый WebSocket хук с переподключением
- [ ] **useTradingWebSocket** - WebSocket для торговых данных
- [ ] **useMarketData** - real-time рыночные данные
- [ ] **useOrderBook** - real-time стакан заявок
- [ ] **useTradeStream** - поток сделок

### 🔄 **Data Management Hooks**

- [ ] **useTradingAPI** - API для торговых операций
- [ ] **usePortfolio** - управление портфелем
- [ ] **useMarketHistory** - исторические данные
- [ ] **useFileUpload** - загрузка файлов с прогрессом
- [ ] **useAIAnalysis** - интеграция с AI сервисами

### 🎨 **UI State Hooks**

- [ ] **useTheme** - управление темой (dark/light)
- [ ] **useNotifications** - уведомления/тосты
- [ ] **useModal** - управление модальными окнами
- [ ] **useLocalStorage** - сохранение настроек
- [ ] **usePagination** - пагинация таблиц

---

## V. Продвинутые компоненты UI

### 📈 **Charts & Visualizations**

- [ ] **TradingViewChart** - продвинутый график с индикаторами
- [ ] **MiniChart** - мини-график для карточек
- [ ] **HeatMap** - тепловая карта активов
- [ ] **VolumeChart** - график объемов
- [ ] **PerformanceChart** - график производительности

### 🎛️ **Advanced Controls**

- [ ] **DataTable** - универсальная таблица с сортировкой/фильтрацией
- [ ] **SearchWithFilters** - поиск с множественными фильтрами
- [ ] **DateRangePicker** - выбор периода для анализа
- [ ] **AdvancedSelect** - мультивыбор с поиском
- [ ] **NumericInput** - ввод чисел с валидацией

---

## VI. WebSocket Architecture & Real-time Data

### 🌐 **WebSocket Infrastructure**

- [ ] **WebSocketProvider** - контекст для WebSocket соединений
- [ ] **ConnectionMonitor** - мониторинг состояния соединения
- [ ] **MessageQueue** - очередь сообщений при отключении
- [ ] **ReconnectionLogic** - логика переподключения с экспоненциальной задержкой
- [ ] **MessageParser** - парсинг входящих WebSocket сообщений

### 📡 **Real-time Subscriptions**

- [ ] **MarketDataSubscription** - подписка на рыночные данные
- [ ] **UserDataSubscription** - подписка на пользовательские данные
- [ ] **NotificationSubscription** - подписка на уведомления
- [ ] **SystemStatusSubscription** - подписка на статус системы

---

## VII. UX/UI Patterns & Optimizations

### ⚡ **Performance Optimizations**

- [ ] **VirtualizedTable** - виртуализация для больших таблиц
- [ ] **LazyLoading** - ленивая загрузка компонентов
- [ ] **ImageOptimization** - оптимизация изображений
- [ ] **BundleAnalysis** - анализ размера бандла
- [ ] **MemoryMonitoring** - мониторинг утечек памяти

### 🎯 **User Experience**

- [ ] **LoadingStates** - состояния загрузки для всех компонентов
- [ ] **ErrorBoundaries** - обработка ошибок с fallback UI
- [ ] **SkeletonLoaders** - скелетоны для улучшения восприятия
- [ ] **ProgressIndicators** - индикаторы прогресса
- [ ] **EmptyStates** - состояния "нет данных"

### 📱 **Responsive Design**

- [ ] **MobileNavigation** - навигация для мобильных устройств
- [ ] **TabletLayout** - адаптация для планшетов
- [ ] **BreakpointHooks** - хуки для работы с breakpoints
- [ ] **TouchGestures** - жесты для мобильных устройств

---

## VIII. Оптимизированные промпты для Cursor/Copilot 🚀

### 🎯 **Промпты для компонентов**

```typescript
// @cursor: Создай TradingDashboard компонент для HTXV2 криптотрейдинг платформы
// ТРЕБОВАНИЯ: TypeScript, shadcn/ui, TanStack Query, Zustand store, real-time WebSocket
// СТРУКТУРА: interface Props, main component, hooks integration, error boundaries
interface TradingDashboardProps {
  symbol: string;
  interval: '1m' | '5m' | '15m' | '1h' | '4h' | '1d';
  // @cursor: добавь остальные пропсы для полной функциональности
}

const TradingDashboard: React.FC<TradingDashboardProps> = ({ symbol, interval }) => {
  // @cursor: используй useTradingData хук, добавь loading/error states, WebSocket integration
  // @cursor: создай layout с: MarketTicker, TradingChart, OrderBook, OrderForm
}
```

```typescript
// @cursor: Создай FileUploadZone для загрузки CSV/XLSX торговых данных
// ТЕХНОЛОГИИ: react-dropzone, @tanstack/react-query, zod валидация
// ФУНКЦИИ: drag&drop, file validation, upload progress, error handling, preview
const FileUploadZone: React.FC = () => {
  // @cursor: complete implementation with:
  // - dropzone config (CSV/XLSX only, max 10MB)
  // - file validation (structure, headers, data types)
  // - upload mutation with progress tracking
  // - preview table with first 10 rows
  // - error states with retry functionality
}
```

```typescript
// @cursor: Создай AIAnalysisPanel для торговых сигналов и рекомендаций
// МОДЕЛИ: FinGPT (local), OpenAI, Vertex AI через llm_selector.py
// UI: model selector, confidence indicator, signal cards, loading states
interface AIAnalysisPanelProps {
  symbol: string;
  timeframe: string;
  // @cursor: добавь типы для AI response, confidence scores, signal types
}

const AIAnalysisPanel: React.FC<AIAnalysisPanelProps> = ({ symbol, timeframe }) => {
  // @cursor: integrate with backend AI endpoints, handle model switching
  // @cursor: create signal cards with confidence bars, recommendation badges
}
```

### 🔌 **Промпты для WebSocket хуков**

```typescript
// @cursor: Создай useWebSocket хук для HTXV2 с auto-reconnect и queue
// ФИЧИ: connection management, message queue, exponential backoff, TypeScript types
export const useWebSocket = <T = any>(
  url: string,
  options?: WebSocketOptions
) => {
  // @cursor: полная реализация с:
  // - useRef для WebSocket instance
  // - useState для connection status (connecting, connected, disconnected, error)
  // - useCallback для send message with queue when disconnected
  // - useEffect для cleanup и reconnection logic
  // - TypeScript generics для типизации сообщений
  
  return {
    connectionStatus,
    sendMessage,
    lastMessage,
    reconnect,
    disconnect
  }
}
```

```typescript
// @cursor: Создай useTradingWebSocket специально для торговых данных HTX
// ПОДПИСКИ: market data, user orders, balance updates, notifications
// ТИПЫ: MarketData, OrderUpdate, BalanceUpdate из types/trading.ts
export const useTradingWebSocket = (symbol: string) => {
  // @cursor: используй базовый useWebSocket, добавь:
  // - subscription management для разных каналов
  // - message parsing и validation
  // - state management через Zustand store
  // - error handling с fallback к REST API
}
```

```typescript
// @cursor: Создай useFileUpload хук с progress tracking и chunked upload
// BACKEND: FastAPI endpoint /api/upload с multipart/form-data
// FEATURES: progress callbacks, pause/resume, error recovery, file validation
export const useFileUpload = () => {
  // @cursor: реализуй с помощью @tanstack/react-query mutation:
  // - chunked upload для больших файлов
  // - progress tracking через XMLHttpRequest
  // - retry logic с exponential backoff
  // - client-side validation перед upload
}
```

### 🎨 **Промпты для UI компонентов**

```typescript
// @cursor: Создай DataTable универсальный компонент для HTXV2
// ФИЧИ: sorting, filtering, pagination, virtual scrolling, column resize
// ИСПОЛЬЗОВАНИЕ: orders table, trades history, portfolio holdings
interface DataTableProps<T> {
  data: T[];
  columns: Column<T>[];
  // @cursor: добавь типы для sorting, filtering, pagination
}

const DataTable = <T,>({ data, columns, ...props }: DataTableProps<T>) => {
  // @cursor: используй @tanstack/react-table v8, shadcn/ui Table components
  // @cursor: добавь виртуализацию для больших dataset через @tanstack/react-virtual
}
```

```typescript
// @cursor: Создай TradingChart компонент с техническими индикаторами
// БИБЛИОТЕКА: lightweight-charts или TradingView widget
// ИНДИКАТОРЫ: SMA, EMA, RSI, MACD, Bollinger Bands, Volume
const TradingChart: React.FC<TradingChartProps> = ({ symbol, interval, height = 400 }) => {
  // @cursor: полная реализация с:
  // - chart initialization и cleanup
  // - real-time data updates через WebSocket
  // - technical indicators overlay
  // - zoom, pan, crosshair functionality
  // - responsive design для мобильных устройств
}
```

### ⚡ **Промпты для оптимизации производительности**

```typescript
// @cursor: Создай useVirtualizedTable для больших datasets (10k+ rows)
// ТЕХНОЛОГИЯ: @tanstack/react-virtual + @tanstack/react-table
// ПРИМЕНЕНИЕ: trading history, market data, large CSV imports
export const useVirtualizedTable = <T>(
  data: T[],
  options: VirtualizationOptions
) => {
  // @cursor: реализуй с помощью react-virtual:
  // - virtual scrolling для строк
  // - dynamic row heights
  // - horizontal scrolling для множества колонок
  // - performance optimization с memo и callback
}
```

```typescript
// @cursor: Создай useDebouncedSearch для поиска по торговым парам
// ИНТЕГРАЦИЯ: HTX API для search symbols, local storage для recent searches
// ОПТИМИЗАЦИЯ: debounce 300ms, cache results, keyboard navigation
export const useDebouncedSearch = (
  searchFn: (query: string) => Promise<SearchResult[]>,
  delay = 300
) => {
  // @cursor: реализуй с useCallback, useMemo, useEffect
  // @cursor: добавь cancel previous requests, loading states
}
```

---

## IX. Архитектурные паттерны для Cursor

### 🏗️ **Store Management Patterns**

```typescript
// @cursor: Создай trading store используя Zustand для HTXV2
// СОСТОЯНИЕ: active positions, orders, balance, market data, UI preferences  
// ПАТТЕРН: slices pattern для разделения логики
interface TradingStore {
  // Market data slice
  marketData: Record<string, MarketData>;
  updateMarketData: (symbol: string, data: MarketData) => void;
  
  // Orders slice
  orders: Order[];
  addOrder: (order: Order) => void;
  updateOrder: (id: string, update: Partial<Order>) => void;
  
  // @cursor: добавь остальные slices для portfolio, preferences, ui state
}

const useTradingStore = create<TradingStore>((set, get) => ({
  // @cursor: реализуй каждый slice с immutable updates
  // @cursor: добавь middleware для persistence и devtools
}));
```

### 🔄 **Error Handling Patterns**

```typescript
// @cursor: Создай ErrorBoundary специально для HTXV2 торговых компонентов
// ФУНКЦИИ: error reporting, graceful fallbacks, retry mechanisms
// ИНТЕГРАЦИЯ: Sentry для production, console.error для development
class TradingErrorBoundary extends Component<ErrorBoundaryProps, ErrorBoundaryState> {
  // @cursor: реализуй с:
  // - static getDerivedStateFromError для UI fallback
  // - componentDidCatch для error reporting
  // - retry functionality с exponential backoff
  // - разные fallback UI для разных типов ошибок (network, data, component)
}
```

### 📱 **Responsive Design Patterns**

```typescript
// @cursor: Создай useBreakpoint хук для адаптивного дизайна HTXV2
// BREAKPOINTS: mobile (< 768px), tablet (768-1024px), desktop (> 1024px)
// ПРИМЕНЕНИЕ: conditional rendering, layout switching, chart sizing
export const useBreakpoint = () => {
  // @cursor: используй matchMedia API, создай типизированные breakpoints
  // @cursor: добавь SSR safety, cleanup listeners
  
  return {
    isMobile,
    isTablet, 
    isDesktop,
    breakpoint: 'mobile' | 'tablet' | 'desktop'
  }
}
```

---

## X. Testing Patterns for Cursor

### 🧪 **Component Testing**

```typescript
// @cursor: Создай тесты для TradingDashboard компонента
// БИБЛИОТЕКИ: @testing-library/react, @testing-library/user-event, vitest
// MOCK: WebSocket connections, API calls, Zustand store
describe('TradingDashboard', () => {
  // @cursor: создай тесты для:
  // - rendering с разными props
  // - WebSocket connection и reconnection
  // - user interactions (order placement, chart interactions)
  // - error states и loading states
  // - responsive behavior
  
  it('should display market data when WebSocket connects', async () => {
    // @cursor: mock WebSocket, render component, assert data display
  });
});
```

### 🔌 **Hook Testing**

```typescript
// @cursor: Создай тесты для useWebSocket хука
// FOCUS: connection states, message handling, reconnection logic
// MOCK: WebSocket API, setTimeout для reconnection testing
describe('useWebSocket', () => {
  // @cursor: используй renderHook из @testing-library/react
  // @cursor: тестируй все connection states и error scenarios
  
  it('should reconnect with exponential backoff on connection loss', async () => {
    // @cursor: mock WebSocket failures, test reconnection timing
  });
});
```

---

## XI. Deployment & Production Patterns

### 🚀 **Build Optimization**

```typescript
// @cursor: Оптимизируй next.config.js для production HTXV2
// ОПТИМИЗАЦИИ: bundle analyzer, compression, image optimization, PWA
/** @type {import('next').NextConfig} */
const nextConfig = {
  // @cursor: добавь:
  // - experimental features для performance
  // - webpack config для bundle optimization  
  // - PWA configuration с next-pwa
  // - security headers
  // - redirects для SEO
}
```

### 📊 **Monitoring & Analytics**

```typescript
// @cursor: Создай performance monitoring для HTXV2
// МЕТРИКИ: component render times, WebSocket latency, API response times
// ИНСТРУМЕНТЫ: performance API, custom hooks, error tracking
export const usePerformanceMonitoring = () => {
  // @cursor: track key metrics:
  // - component mount/unmount times
  // - WebSocket message latency
  // - user interaction response times
  // - bundle size impact
}
```

---

## XII. Финальный чеклист готовности

### ✅ **Pre-deployment Checklist**

- [ ] **Функциональность**: Все критические компоненты работают
- [ ] **Performance**: Bundle size < 1MB, FCP < 2s, WebSocket latency < 100ms  
- [ ] **Responsive**: Тестирование на mobile/tablet/desktop
- [ ] **Accessibility**: ARIA labels, keyboard navigation, screen reader support
- [ ] **Security**: CSP headers, environment variables protection
- [ ] **Testing**: 80%+ coverage для критических компонентов
- [ ] **Documentation**: README.md обновлен, API documentation актуальна
- [ ] **Error Handling**: Graceful degradation для всех error states

### 🎯 **Production Ready Criteria**

- [ ] **Real-time Data**: WebSocket работает стабильно с reconnection
- [ ] **File Upload**: CSV/XLSX загрузка с валидацией и preview
- [ ] **AI Integration**: Модели работают с confidence indicators
- [ ] **Trading Interface**: Orders можно создавать и отслеживать
- [ ] **Portfolio Management**: Баланс и позиции отображаются корректно
- [ ] **Mobile Experience**: Полнофункциональная мобильная версия

---

**💡 Tip**: Используй эти промпты как шаблоны в Cursor/Copilot для быстрой разработки. Каждый промпт содержит контекст HTXV2, технологический стек и конкретные требования для максимальной эффективности AI-ассистента.