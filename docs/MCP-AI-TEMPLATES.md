# MCP AI Context Templates for Token Optimization

## Service Module Context Template
```python
# @cursor: КОНТЕКСТ: HTXV2 MCP Service - Модуль {module_name}
# ЦЕЛЬ: {purpose}
# ИНТЕГРАЦИИ: {integrations}
# ПАТТЕРНЫ: async/await, error handling, structured logging

# @cursor: Оптимизируй этот модуль для минимального использования токенов
# Фокус: {focus_areas}
```

## API Endpoint Context Template
```python
# @cursor: КОНТЕКСТ: HTXV2 MCP API - {endpoint_type}
# ЦЕЛЬ: {endpoint_purpose}
# МЕТОДЫ: {http_methods}
# АВТОРИЗАЦИЯ: {auth_requirements}

# @cursor: Создай эффективные API endpoints с валидацией
# Схемы: Pydantic models в schemas/mcp.py
```

## WebSocket Context Template
```python
# @cursor: КОНТЕКСТ: HTXV2 MCP WebSocket - Real-time communication
# ЦЕЛЬ: Bidirectional communication for trading platform
# СОБЫТИЯ: {event_types}
# БИЗНЕС-ЛОГИКА: {business_logic}

# @cursor: Оптимизируй WebSocket соединения и обработку сообщений
# Паттерны: connection pooling, message queuing, error recovery
```

## Health Check Context Template
```python
# @cursor: КОНТЕКСТ: HTXV2 Health Monitoring
# СЕРВИСЫ: PostgreSQL, Redis, HTX API, CoinGecko API
# МЕТРИКИ: response_time, availability, error_rate
# АЛЕРТЫ: {alert_conditions}

# @cursor: Создай эффективный health monitoring с минимальными ресурсами
```

## Task Management Context Template  
```python
# @cursor: КОНТЕКСТ: HTXV2 Task Orchestration
# ЗАДАЧИ: {task_types}
# ПЛАНИРОВЩИК: {scheduler_type}
# ПЕРСИСТЕНТНОСТЬ: Redis + Database

# @cursor: Оптимизируй управление задачами для production load
# Фокус: scalability, reliability, monitoring
```