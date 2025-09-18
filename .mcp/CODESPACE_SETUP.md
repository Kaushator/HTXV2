# 🚀 Настройка Codespace с MCP Tools для HTXV2

## ✅ Что уже настроено

### 1. DevContainer конфигурация
- ✅ Обновлен `.devcontainer/devcontainer.json`
- ✅ Добавлен скрипт `setup-mcp-tools.sh`
- ✅ Настроены порты: 3000, 8000, 5432, 6379
- ✅ Установлены расширения VS Code

### 2. MCP Tools
- ✅ Создан MCP сервер (`/workspace/.mcp/server.js`)
- ✅ Настроены инструменты: health_check, market_analysis, portfolio_status
- ✅ Создан package.json с зависимостями
- ✅ Настроена интеграция с VS Code

### 3. Экономия токенов
- ✅ Созданы инструкции в `TOKEN_ECONOMY.md`
- ✅ Настроены быстрые команды
- ✅ Оптимизированы запросы

## 🚀 Запуск Codespace

### Автоматический запуск
1. Откройте проект в GitHub Codespaces
2. DevContainer автоматически настроится
3. MCP tools будут установлены автоматически
4. Все сервисы запустятся через Docker Compose

### Ручной запуск (если нужно)
```bash
# 1. Запуск всех сервисов
cd /workspace
docker compose up -d

# 2. Проверка статуса
docker compose ps

# 3. Тестирование MCP
cd /workspace/.mcp
npm install
npm start
```

## 🔧 Доступные инструменты

### MCP Tools
- `health_check` - проверка состояния системы
- `list_assets` - список торговых активов
- `market_analysis` - анализ рыночных данных
- `portfolio_status` - статус портфеля
- `trading_signals` - торговые сигналы
- `upload_csv` - загрузка данных для анализа

### Быстрые команды
```bash
# Система
mcp-health          # проверка системы
mcp-assets          # список активов

# Анализ
mcp-btc             # анализ Bitcoin
mcp-eth             # анализ Ethereum
mcp_analyze BTC 4h  # анализ с параметрами

# Портфель
mcp-portfolio       # статус портфеля
mcp-signals         # торговые сигналы

# Тестирование
test-mcp            # тест MCP функциональности
```

## 📊 Экономия токенов

### Оптимизированные запросы
```bash
# ✅ Хорошо
"/tools market_analysis BTC 1h"
"Анализ BTC, ETH, BNB за 4h"

# ❌ Плохо
"Покажи анализ Bitcoin" + "Покажи анализ Ethereum"
```

### Группировка запросов
```bash
# ✅ Один запрос
"Портфель + сигналы + рекомендации для BTC, ETH"

# ❌ Множественные запросы
"Покажи портфель" + "Покажи сигналы" + "Дай рекомендации"
```

## 🔍 Проверка работоспособности

### 1. Проверка сервисов
```bash
# Статус контейнеров
docker compose ps

# Логи сервисов
docker compose logs backend
docker compose logs frontend
```

### 2. Проверка MCP
```bash
# Тест MCP сервера
cd /workspace/.mcp
npm test

# Проверка API
curl http://localhost:8000/api/v1/mcp/health
```

### 3. Проверка в VS Code
1. Откройте Copilot Chat
2. Введите `/tools`
3. Должны появиться доступные инструменты

## 🛠️ Устранение проблем

### Проблема: MCP tools не работают
```bash
# Решение
cd /workspace/.mcp
npm install
npm start
```

### Проблема: Сервисы не запускаются
```bash
# Решение
docker compose down
docker compose up -d
```

### Проблема: Порты заняты
```bash
# Решение
sudo lsof -ti:3000,8000,5432,6379 | xargs kill -9
docker compose up -d
```

## 📈 Мониторинг производительности

### Статистика использования
```bash
# Использование токенов
curl -s http://localhost:8000/api/v1/mcp/stats

# Статус системы
/tools health_check all
```

### Оптимизация
- Используйте `/tools` для системных команд
- Группируйте связанные запросы
- Конкретизируйте параметры
- Избегайте повторных запросов

## 🎯 Следующие шаги

### После запуска Codespace
1. ✅ Проверьте статус: `docker compose ps`
2. ✅ Тестируйте MCP: `test-mcp`
3. ✅ Откройте Copilot Chat
4. ✅ Введите `/tools` для проверки инструментов
5. ✅ Прочитайте `TOKEN_ECONOMY.md`

### Разработка
1. Изучите доступные MCP инструменты
2. Практикуйте оптимизированные запросы
3. Используйте быстрые команды
4. Следите за экономией токенов

## 📚 Дополнительные ресурсы

- [TOKEN_ECONOMY.md](./TOKEN_ECONOMY.md) - экономия токенов
- [README.md](./README.md) - общая информация о MCP
- [Backend MCP_README.md](../backend/MCP_README.md) - техническая документация

## 🆘 Поддержка

Если возникли проблемы:
1. Проверьте логи: `docker compose logs`
2. Перезапустите сервисы: `docker compose restart`
3. Проверьте MCP: `test-mcp`
4. Обратитесь к документации в `/workspace/docs/`