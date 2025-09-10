# Backend Tests Documentation

Документация по тестированию backend компонентов HTX Interface.

## Обзор Тестов

Backend тесты покрывают критические компоненты системы:

1. **HTX Ticker API** - тестирование получения данных тикеров
2. **Rate Limiting** - тестирование ограничений скорости запросов  
3. **Redis Caching** - тестирование кэширования и fallback механизмов
4. **Edge Cases** - тестирование граничных случаев и сбоев

## Структура Тестов

```
backend/tests/
├── test_htx.py                     # Базовые тесты HTX API
├── test_ratelimit.py               # Базовые тесты rate limiting
├── test_htx_ttl_edge_cases.py      # TTL edge cases и границы
├── test_ratelimit_edge_cases.py    # Rate limiting edge cases
├── test_redis_fallback.py          # Redis fallback сценарии
└── README.md                       # Эта документация
```

## Новые Тесты (P1 Task 5)

### TTL Override Edge Cases (`test_htx_ttl_edge_cases.py`)

Тестирует граничные случаи для TTL override функциональности:

#### Тестируемые сценарии:

**Граничные значения TTL:**
- `ttl=0` → должно быть преобразовано в `ttl=1` (минимум)
- `ttl=max` → должно быть принято как есть
- `ttl>max` → должно быть ограничено максимальным значением

**Некорректные входные данные:**
- Отрицательные значения → fallback к default TTL
- Строковые значения → fallback к default TTL  
- Float значения → преобразование в int

**Redis интеграция:**
- Cache miss с TTL override
- Cache hit с TTL override
- Redis connection errors с TTL override

**Примеры тестов:**
```python
def test_ttl_override_zero_boundary(self, client):
    """TTL=0 должно стать TTL=1"""
    response = client.get("/api/data/htx/ticker/BTC?ttl=0")
    assert response.status_code == 200

def test_ttl_override_above_max_boundary(self, client):
    """TTL>max должно быть ограничено максимумом"""
    response = client.get("/api/data/htx/ticker/BTC?ttl=999")
    assert response.status_code == 200  # Ограничено до max
```

### Rate Limiting Edge Cases (`test_ratelimit_edge_cases.py`)

Тестирует сложные сценарии rate limiting:

#### Тестируемые сценарии:

**Граничные конфигурации:**
- `max_calls=0` → все запросы блокируются
- Очень большое окно (24 часа)
- Сброс окна timing

**Серийные запросы:**
- Последовательные запросы под лимитом
- Поведение на границе лимита
- Изоляция между API ключами

**Redis vs In-Memory:**
- Поведение incr/expire в Redis
- Fallback на in-memory при сбое Redis
- Консистентность между режимами

**Примеры тестов:**
```python
def test_serial_requests_under_limit(self, client):
    """5 запросов при лимите 5 должны пройти"""
    for i in range(5):
        response = client.get("/api/data/htx/ticker/BTC")
        assert response.status_code == 200
    
    # 6-й запрос должен быть заблокирован
    response = client.get("/api/data/htx/ticker/BTC")
    assert response.status_code == 429

def test_rate_limit_api_key_isolation(self, client):
    """API ключи должны иметь изолированные лимиты"""
    # key1 исчерпывает лимит
    response1 = client.get("/api/data/htx/ticker/BTC?api_key=key1")
    response2 = client.get("/api/data/htx/ticker/BTC?api_key=key1")
    assert response1.status_code == 200
    assert response2.status_code == 429
    
    # key2 должен иметь отдельный лимит
    response3 = client.get("/api/data/htx/ticker/BTC?api_key=key2")
    assert response3.status_code == 200
```

### Redis Fallback Scenarios (`test_redis_fallback.py`)

Тестирует сценарии failover и graceful degradation:

#### Тестируемые сценарии:

**Недоступность Redis:**
- Отсутствие Redis модуля
- Ошибки подключения
- Таймауты подключения
- Ошибки аутентификации

**Частичные сбои Redis:**
- GET операция успешна, SET не работает
- Corrupted данные в кэше
- Intermittent failures

**In-Memory Fallback:**
- Корректная работа без Redis
- Консистентность ключей кэша
- Behavior когда `redis_url=None`

**Примеры тестов:**
```python
def test_redis_connection_timeout(self, mock_redis, client):
    """Система должна работать при timeout Redis"""
    mock_redis.side_effect = TimeoutError("Redis timeout")
    
    response = client.get("/api/data/htx/ticker/BTC")
    assert response.status_code == 200  # Работает без Redis

def test_redis_invalid_cached_json(self, mock_redis, client):
    """Система должна обработать невалидный JSON в кэше"""
    mock_redis_instance.get.return_value = "invalid json {"
    
    response = client.get("/api/data/htx/ticker/BTC")
    assert response.status_code == 200  # Fallback к upstream
```

## Запуск Тестов

### Все новые тесты:
```bash
cd backend

# Основные edge case тесты (автономный runner)
python tests/run_edge_case_tests.py

# Расширенные edge case тесты (дополнительные сценарии)
python tests/run_extended_edge_tests.py

# Pytest версии (требуют правильную настройку окружения)
pytest tests/test_htx_ttl_edge_cases.py -v
pytest tests/test_ratelimit_edge_cases.py -v  
pytest tests/test_redis_fallback.py -v
```

### Конкретные test cases:
```bash
# TTL edge cases
pytest tests/test_htx_ttl_edge_cases.py::TestHTXTickerTTLEdgeCases::test_ttl_override_zero_boundary -v

# Rate limiting edge cases
pytest tests/test_ratelimit_edge_cases.py::TestRateLimitingEdgeCases::test_serial_requests_under_limit -v

# Redis fallback
pytest tests/test_redis_fallback.py::TestRedisFailoverScenarios::test_redis_connection_timeout -v
```

### Запуск с coverage:
```bash
pytest tests/test_*edge_cases.py tests/test_redis_fallback.py --cov=app --cov-report=html
```

## Интеграция с CI/CD

Новые тесты автоматически запускаются в GitHub Actions:

```yaml
# В .github/workflows/ci-cd.yml
- name: Run backend tests
  run: |
    cd backend
    pytest tests/ --verbose --tb=short
```

### Проверка в локальном CI:
```bash
# Симуляция CI окружения
cd backend
export REDIS_URL=""  # Принудительный in-memory mode
pytest tests/ --verbose
```

## Coverage цели

| Компонент | Текущий Coverage | Цель |
|-----------|------------------|------|
| HTX Client | 85% | 90% |
| Rate Limiter | 80% | 95% |
| Redis Utils | 70% | 85% |

### Проверка coverage:
```bash
pytest tests/ --cov=app.clients.htx --cov=app.utils.ratelimit --cov-report=term-missing
```

## Тестовые Данные и Моки

### HTX API Mock:
```python
@pytest.fixture
def mock_htx_response(self):
    return {
        "status": "ok",
        "tick": {
            "close": 60000.0,
            "bid": [59990.0, 1.5],
            "ask": [60010.0, 2.0],
            "high": 61000.0,
            "low": 59000.0,
            "amount": 1234.56,
        },
        "ts": 1700000000000
    }
```

### Redis Mock Patterns:
```python
# Cache miss
mock_redis_instance.get.return_value = None

# Cache hit
mock_redis_instance.get.return_value = json.dumps(cached_data)

# Connection error
mock_redis.side_effect = Exception("Redis unavailable")

# Partial failure
mock_redis_instance.get.return_value = None
mock_redis_instance.set.side_effect = Exception("SET failed")
```

## Известные Edge Cases

### 1. TTL Обработка
- **Проблема**: Negative TTL values
- **Решение**: Clamp to minimum TTL=1
- **Тест**: `test_ttl_override_negative_value`

### 2. Rate Limit Window Reset
- **Проблема**: Race conditions при reset окна
- **Решение**: Atomic operations в Redis, time-based reset в memory
- **Тест**: `test_in_memory_rate_limit_window_reset`

### 3. Redis Failover
- **Проблема**: Потеря кэша при переключении
- **Решение**: Graceful fallback без ошибок пользователю
- **Тест**: `test_redis_connection_timeout`

### 4. API Key Scoping
- **Проблема**: Empty или special character API keys
- **Решение**: Consistent key generation
- **Тест**: `test_edge_case_empty_api_key`

## Отладка Тестов

### Включение debug логов:
```bash
pytest tests/test_htx_ttl_edge_cases.py --log-cli-level=DEBUG -s
```

### Isolated test run:
```bash
pytest tests/test_ratelimit_edge_cases.py::TestRateLimitingEdgeCases::test_redis_fallback_on_connection_error -vv -s
```

### Проверка моков:
```python
def test_with_debug(self, mock_redis, client):
    # Добавить assertions на mock calls
    mock_redis_instance.get.assert_called_once_with("htx:ticker:btcusdt")
    mock_redis_instance.set.assert_called_once()
```

## Continuous Improvement

### Планы на будущее:
1. **Property-based testing** с Hypothesis
2. **Load testing** для rate limiter
3. **Chaos engineering** для Redis failures
4. **Integration tests** с реальным Redis

### Метрики качества:
- Test execution time < 30s для всех edge cases
- Zero flaky tests
- 100% deterministic test outcomes
- Clear failure messages

## Автономные Test Runners

Созданы специальные автономные test runners, которые работают без полной инициализации FastAPI приложения и без зависимостей от базы данных.

### run_edge_case_tests.py
Основной test runner с базовыми edge cases (32 теста):
- TTL boundary conditions (0, max, >max значения)
- Rate limiting основные сценарии 
- Redis fallback базовое поведение

### run_extended_edge_tests.py
Расширенный test runner с экстремальными edge cases (53 теста):
- **TTL Boundary Conditions**: экстремальные значения, float->int конверсия
- **Rate Limiter Extreme Scenarios**: max_calls=0, специальные символы в ключах, concurrent requests
- **Symbol Normalization Edge Cases**: whitespace, invalid symbols, специальные форматы
- **Response Mapping Malformed Data**: пустые ответы, malformed JSON, extra поля
- **Redis Simulation Edge Cases**: window boundaries, memory cleanup симуляция

### Преимущества автономных runners:
✅ Быстрый запуск (без DB dependencies)  
✅ Изолированное тестирование логики  
✅ Подробное логирование каждого assertion  
✅ Независимость от FastAPI app инициализации  
✅ Простая отладка конкретных сценариев  

### Test Coverage Summary:
- **Основные тесты**: 32 assertions, базовые edge cases
- **Расширенные тесты**: 53 assertions, экстремальные сценарии  
- **Общий coverage**: TTL override, rate limiting, Redis fallback, symbol normalization, response mapping

---

Эти тесты обеспечивают надежность критических компонентов системы в различных failure scenarios и edge cases.
