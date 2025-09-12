# TODO для Backend (Codex): HTXV2

## I. Подготовка инфраструктуры backend

- [ ] Убедиться, что backend поднимается через docker/make на локалке (FastAPI, ML, DB, Redis).
- [ ] Проверить и обновить requirements.txt/pyproject.toml.
- [ ] Все секреты и ключи — только через .env или Secret Manager, без хардкода.
- [ ] Настроить health checks для всех сервисов (FastAPI, ML, ETL).
- [ ] Логи в JSON, structured logging, не пишем секреты.

---

## II. Архитектура backend

- [ ] Проверить разделение: `services/`, `api/`, `schemas/`, `models/`, `core/`.
- [ ] Вынести бизнес-логику в отдельные сервисы, контроллеры только для роутинга.
- [ ] Все интеграции с внешними API (CoinGecko, GCP, AI) — отдельные модули.
- [ ] Миграции DB (alembic) — актуальны, все таблицы описаны.

---

## III. Функциональный backend TODO

- [ ] **WebSocket-API**
  - [ ] Реализовать стабильный endpoint для real-time ticker (поддержка reconnect, cleanup).
  - [ ] Rate limiting, валидация symbol.

- [ ] **API-ключи и квоты**
  - [ ] Механика хранения и ротации ключей (DB + сервис).
  - [ ] Привязка к лимитам, автоматический reset.



- [ ] **File Upload**
  - [ ] Асинхронный endpoint для загрузки, проверки формата, хранения файла (GCS + локально).
  - [ ] Поддержка больших файлов — chunked upload, ограничения размера, таймауты.
  - [ ] Preview/sample данных для фронта.

- [ ] **Мониторинг и метрики**
  - [ ] Endpoint для сбора метрик (Prometheus).
  - [ ] Логирование ошибок с correlation id.

---

## IV. Валидация и отладка

- [ ] Ручная проверка всех основных endpoints через FastAPI docs.
- [ ] Проверка работы с frontend компонентами.
- [ ] Валидация основных user flows (upload, trading, WebSocket).

---

## V. Полное делегирование завершения кода Codex

### Эффективные промпты для Codex:

```python
# @codex: Создай FastAPI endpoint для получения торговых сигналов
# Требования: асинхронность, валидация Pydantic, Redis кеширование, rate limiting
@router.get("/trading/signals", response_model=List[TradingSignalResponse])
async def get_trading_signals(
    symbol: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    @codex: Полная реализация с:
    - валидацией входных параметров
    - получением данных из базы с фильтрацией  
    - кешированием результатов в Redis
    - обработкой ошибок с proper HTTP статусами
    - логированием с correlation ID
    """
    pass

# @codex: Создай сервис для работы с торговыми данными  
class TradingDataService:
    """
    @codex: Реализуй сервис с методами:
    - get_market_data() - получение рыночных данных
    - calculate_portfolio() - расчет портфеля
    - format_trading_response() - форматирование ответов
    - validate_trading_params() - валидация параметров
    Включи error handling, logging, и rate limiting
    """
    pass
```

### Стратегии экономии токенов для Codex:

**1. Использование декораторов и middleware:**
```python
# @codex: Создай декоратор для rate limiting всех торговых endpoints
def trading_rate_limit(requests_per_minute: int = 60):
    """
    @codex: Реализуй декоратор с Redis backend для хранения лимитов
    """
    pass

# @codex: Создай middleware для логирования всех API запросов  
async def logging_middleware(request: Request, call_next):
    """
    @codex: Structured logging с correlation ID, timing, error tracking
    """
    pass

# @codex: Примени эти паттерны ко всем endpoints в: trading.py, portfolio.py, data.py
```

**2. Автогенерация схем и моделей:**
```python
# @codex: Создай Pydantic схемы на базе этого JSON response:
# {"user_id": 1, "portfolio": [{"symbol": "BTC", "quantity": 0.5, "avg_price": 45000}]}
# Сгенерируй: PortfolioResponse, AssetPosition, UserPortfolio с валидацией

# @codex: Создай SQLAlchemy модели соответствующие схемам выше
# с правильными relationships, indexes, constraints
```

**3. Сервисы и business logic:**
```python
# @codex: КОНТЕКСТ: HTXV2 криптотрейдинг платформа, paper trading только
# БЕЗОПАСНОСТЬ: никаких реальных ордеров, только симуляция

class TradingService:
    """
    @codex: Реализуй все методы для paper trading:
    - create_paper_order() - создание виртуального ордера
    - execute_paper_order() - исполнение по рыночной цене  
    - cancel_paper_order() - отмена ордера
    - get_portfolio_pnl() - расчет P&L портфеля
    - get_market_data() - получение рыночных данных
    
    Используй async/await, type hints, proper exception handling
    """
    pass
```

### Оптимизация использования токенов:

**1. Шаблоны для CRUD операций:**
```python
# @codex: Создай generic CRUD service по этому паттерну
class CRUDService(Generic[T]):
    """
    @codex: Universal CRUD operations для любой SQLAlchemy модели
    Методы: create, get, update, delete, list с фильтрацией и пагинацией
    """
    pass

# @codex: Создай наследников для: UserCRUD, TradeCRUD, PortfolioCRUD
# используя CRUDService как базовый класс
```

**2. Обработка ошибок и валидация:**
```python
# @codex: Создай централизованную систему обработки ошибок
class HTTPException(Exception):
    """
    @codex: Custom exceptions для всех типов ошибок в приложении
    """
    pass

# @codex: Exception handler middleware с proper HTTP статусами
# для ValidationError, DatabaseError, AuthenticationError, RateLimitError

# @codex: Валидаторы для торговых данных:
def validate_trading_symbol(symbol: str) -> str:
    """@codex: валидация символа криптопары"""
    pass

def validate_order_quantity(quantity: Decimal, symbol: str) -> Decimal:
    """@codex: валидация количества с учетом минимальных лотов"""
    pass
```

**3. Асинхронные операции и worker tasks:**
```python
# @codex: Создай Celery tasks для фоновых операций
@shared_task
def process_market_data_batch(data_batch: List[Dict]):
    """
    @codex: Обработка batch данных от криптобиржи
    - валидация данных
    - сохранение в БД  
    - отправка уведомлений через WebSocket
    - обновление кеша
    """
    pass

# @codex: WebSocket manager для real-time уведомлений
class WebSocketManager:
    """
    @codex: Менеджер WS соединений с поддержкой:
    - групповых подписок на символы
    - персональных уведомлений пользователей
    - автоматического переподключения
    - rate limiting для WS сообщений
    """
    pass
```

---

## VI. Финальный чеклист

- [ ] Все endpoints отдают корректные коды и ошибки, API-доки актуальны.
- [ ] Нет хардкода секретов или адресов.
- [ ] Основная функциональность работает на локалке.
- [ ] Логи чистые, нет лишних ворнингов.
- [ ] Проект запускается на ПК в режиме production.

---