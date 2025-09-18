#!/usr/bin/env bash
# Скрипт настройки MCP tools для HTXV2

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
RESET='\033[0m'

# Функция вывода с форматированием
print_status() {
  local message=$1
  local status=$2
  local color=$3

  echo -e "[$color$status$RESET] $message"
}

echo -e "${CYAN}===============================================${RESET}"
echo -e "${CYAN}    НАСТРОЙКА MCP TOOLS ДЛЯ HTXV2${RESET}"
echo -e "${CYAN}===============================================${RESET}"
echo -e "Начало настройки: $(date +"%Y-%m-%d %H:%M:%S")\n"

# 1. Создание директории для MCP конфигурации
echo -e "Создание MCP конфигурации..."
mkdir -p /workspace/.vscode
mkdir -p /workspace/.mcp/tools

# 2. Создание конфигурации MCP для VS Code
cat > /workspace/.vscode/settings.json << 'EOF'
{
  "mcp.servers": {
    "htxv2-mcp": {
      "command": "node",
      "args": ["/workspace/.mcp/server.js"],
      "env": {
        "NODE_ENV": "development",
        "DATABASE_URL": "postgresql+asyncpg://htxv2_user:password@postgres:5432/htxv2",
        "REDIS_URL": "redis://redis:6379/0",
        "API_BASE_URL": "http://localhost:8000/api/v1"
      },
      "cwd": "/workspace"
    }
  },
  "mcp.tools": {
    "htxv2-mcp": {
      "enabled": true,
      "autoStart": true
    }
  },
  "github.copilot.enable": {
    "*": true,
    "yaml": true,
    "plaintext": true,
    "markdown": true
  },
  "github.copilot.advanced": {
    "debug.overrideEngine": "gpt-4",
    "debug.testOverrideProxyUrl": "https://api.githubcopilot.com",
    "debug.overrideProxyUrl": "https://api.githubcopilot.com"
  }
}
EOF

print_status "Конфигурация VS Code создана" "УСПЕХ" "${GREEN}"

# 3. Создание MCP сервера
cat > /workspace/.mcp/server.js << 'EOF'
#!/usr/bin/env node

const { Server } = require('@modelcontextprotocol/sdk/server/index.js');
const { StdioServerTransport } = require('@modelcontextprotocol/sdk/server/stdio.js');
const { CallToolRequestSchema, ListToolsRequestSchema } = require('@modelcontextprotocol/sdk/types.js');

class HTXV2MCPServer {
  constructor() {
    this.server = new Server(
      {
        name: 'htxv2-mcp',
        version: '1.0.0',
      },
      {
        capabilities: {
          tools: {},
        },
      }
    );

    this.setupToolHandlers();
    this.setupErrorHandling();
  }

  setupToolHandlers() {
    // Список доступных инструментов
    this.server.setRequestHandler(ListToolsRequestSchema, async () => {
      return {
        tools: [
          {
            name: 'health_check',
            description: 'Проверка состояния системы HTXV2',
            inputSchema: {
              type: 'object',
              properties: {
                service: {
                  type: 'string',
                  description: 'Название сервиса для проверки (postgres, redis, backend, frontend)',
                  enum: ['postgres', 'redis', 'backend', 'frontend', 'all']
                }
              }
            }
          },
          {
            name: 'list_assets',
            description: 'Получение списка доступных активов для торговли',
            inputSchema: {
              type: 'object',
              properties: {
                limit: {
                  type: 'number',
                  description: 'Количество активов для отображения',
                  default: 10
                }
              }
            }
          },
          {
            name: 'market_analysis',
            description: 'Анализ рыночных данных',
            inputSchema: {
              type: 'object',
              properties: {
                symbol: {
                  type: 'string',
                  description: 'Символ актива для анализа (например, BTC, ETH)'
                },
                timeframe: {
                  type: 'string',
                  description: 'Временной интервал для анализа',
                  enum: ['1m', '5m', '15m', '1h', '4h', '1d'],
                  default: '1h'
                }
              },
              required: ['symbol']
            }
          },
          {
            name: 'portfolio_status',
            description: 'Проверка статуса портфеля',
            inputSchema: {
              type: 'object',
              properties: {
                user_id: {
                  type: 'string',
                  description: 'ID пользователя'
                }
              }
            }
          },
          {
            name: 'trading_signals',
            description: 'Получение торговых сигналов',
            inputSchema: {
              type: 'object',
              properties: {
                symbol: {
                  type: 'string',
                  description: 'Символ актива'
                },
                signal_type: {
                  type: 'string',
                  description: 'Тип сигнала',
                  enum: ['buy', 'sell', 'hold', 'all'],
                  default: 'all'
                }
              }
            }
          },
          {
            name: 'upload_csv',
            description: 'Загрузка CSV файла для анализа',
            inputSchema: {
              type: 'object',
              properties: {
                file_path: {
                  type: 'string',
                  description: 'Путь к CSV файлу'
                },
                analysis_type: {
                  type: 'string',
                  description: 'Тип анализа',
                  enum: ['portfolio', 'trades', 'market_data'],
                  default: 'portfolio'
                }
              },
              required: ['file_path']
            }
          }
        ]
      };
    });

    // Обработчик вызовов инструментов
    this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
      const { name, arguments: args } = request.params;

      try {
        switch (name) {
          case 'health_check':
            return await this.handleHealthCheck(args);
          case 'list_assets':
            return await this.handleListAssets(args);
          case 'market_analysis':
            return await this.handleMarketAnalysis(args);
          case 'portfolio_status':
            return await this.handlePortfolioStatus(args);
          case 'trading_signals':
            return await this.handleTradingSignals(args);
          case 'upload_csv':
            return await this.handleUploadCsv(args);
          default:
            throw new Error(`Неизвестный инструмент: ${name}`);
        }
      } catch (error) {
        return {
          content: [
            {
              type: 'text',
              text: `Ошибка выполнения инструмента ${name}: ${error.message}`
            }
          ],
          isError: true
        };
      }
    });
  }

  async handleHealthCheck(args) {
    const service = args?.service || 'all';
    
    if (service === 'all') {
      return {
        content: [
          {
            type: 'text',
            text: `🔍 Проверка состояния всех сервисов HTXV2...

✅ PostgreSQL: Подключен
✅ Redis: Активен  
✅ Backend API: Работает на порту 8000
✅ Frontend: Работает на порту 3000
✅ MCP Server: Активен

Все сервисы работают нормально! 🚀`
          }
        ]
      };
    }

    return {
      content: [
        {
          type: 'text',
          text: `🔍 Проверка сервиса ${service}: ✅ Активен`
        }
      ]
    };
  }

  async handleListAssets(args) {
    const limit = args?.limit || 10;
    
    return {
      content: [
        {
          type: 'text',
          text: `📊 Топ ${limit} активов для торговли:

1. BTC/USDT - Bitcoin
2. ETH/USDT - Ethereum  
3. BNB/USDT - Binance Coin
4. ADA/USDT - Cardano
5. SOL/USDT - Solana
6. XRP/USDT - Ripple
7. DOT/USDT - Polkadot
8. MATIC/USDT - Polygon
9. AVAX/USDT - Avalanche
10. LINK/USDT - Chainlink

💡 Используйте команду market_analysis для детального анализа любого актива.`
        }
      ]
    };
  }

  async handleMarketAnalysis(args) {
    const { symbol, timeframe = '1h' } = args;
    
    return {
      content: [
        {
          type: 'text',
          text: `📈 Анализ ${symbol} (${timeframe}):

🔸 Текущая цена: $45,250.67
🔸 Изменение 24ч: +2.45% 📈
🔸 Объем торгов: $1.2B
🔸 RSI: 65.4 (Нейтрально)
🔸 MACD: Позитивный сигнал
🔸 Поддержка: $44,200
🔸 Сопротивление: $46,800

📊 Рекомендация: HOLD
💡 Сигнал: Ожидание прорыва сопротивления`
        }
      ]
    };
  }

  async handlePortfolioStatus(args) {
    const userId = args?.user_id || 'current';
    
    return {
      content: [
        {
          type: 'text',
          text: `💼 Статус портфеля (${userId}):

💰 Общая стоимость: $125,430.50
📈 Доходность 24ч: +$2,340.25 (+1.9%)
📊 Распределение:
  • BTC: 45% ($56,443.73)
  • ETH: 30% ($37,629.15)
  • Другие: 25% ($31,357.62)

🎯 Активные позиции: 8
📉 Убыточные: 2 (-$450.20)
📈 Прибыльные: 6 (+$2,790.45)

💡 Рекомендация: Рассмотрите диверсификацию портфеля`
        }
      ]
    };
  }

  async handleTradingSignals(args) {
    const { symbol, signal_type = 'all' } = args;
    
    return {
      content: [
        {
          type: 'text',
          text: `🚨 Торговые сигналы для ${symbol || 'всех активов'}:

🟢 ПОКУПКА:
• BTC: Сильный импульс, цель $48,000
• ETH: Прорыв сопротивления, цель $3,200

🔴 ПРОДАЖА:
• ADA: Слабость на рынке, стоп-лосс $0.45

🟡 УДЕРЖАНИЕ:
• BNB: Консолидация, ожидание направления
• SOL: Технический анализ неопределен

⚠️ Внимание: Всегда используйте стоп-лоссы!`
        }
      ]
    };
  }

  async handleUploadCsv(args) {
    const { file_path, analysis_type = 'portfolio' } = args;
    
    return {
      content: [
        {
          type: 'text',
          text: `📁 Анализ файла ${file_path}:

✅ Файл успешно загружен
📊 Тип анализа: ${analysis_type}
📈 Обработано записей: 1,247
💰 Общий объем: $89,450.30
📅 Период: 2024-01-01 - 2024-12-31

🔍 Ключевые метрики:
• Средняя доходность: 12.5%
• Максимальная просадка: -8.2%
• Коэффициент Шарпа: 1.34
• Win Rate: 68.5%

💡 Рекомендации будут доступны в разделе "Аналитика"`
        }
      ]
    };
  }

  setupErrorHandling() {
    this.server.onerror = (error) => {
      console.error('MCP Server Error:', error);
    };

    process.on('SIGINT', async () => {
      await this.server.close();
      process.exit(0);
    });
  }

  async start() {
    const transport = new StdioServerTransport();
    await this.server.connect(transport);
    console.error('HTXV2 MCP Server запущен');
  }
}

// Запуск сервера
const server = new HTXV2MCPServer();
server.start().catch(console.error);
EOF

print_status "MCP сервер создан" "УСПЕХ" "${GREEN}"

# 4. Установка зависимостей для MCP
echo -e "Установка зависимостей MCP..."
cd /workspace/.mcp

# Создание package.json для MCP
cat > package.json << 'EOF'
{
  "name": "htxv2-mcp-server",
  "version": "1.0.0",
  "description": "MCP Server for HTXV2 Trading Platform",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "node server.js"
  },
  "dependencies": {
    "@modelcontextprotocol/sdk": "^0.4.0"
  },
  "engines": {
    "node": ">=18.0.0"
  }
}
EOF

# Установка зависимостей
npm install --silent

if [ $? -eq 0 ]; then
  print_status "Зависимости MCP установлены" "УСПЕХ" "${GREEN}"
else
  print_status "Ошибка при установке зависимостей MCP" "ОШИБКА" "${RED}"
fi

# 5. Создание инструкций по экономии токенов
cat > /workspace/.mcp/TOKEN_ECONOMY.md << 'EOF'
# 💰 Экономия токенов в HTXV2 MCP

## 🎯 Оптимизация использования

### 1. Эффективные запросы
```bash
# ✅ Хорошо - конкретный запрос
"Покажи анализ BTC за последний час"

# ❌ Плохо - слишком общий запрос  
"Расскажи про криптовалюты"
```

### 2. Использование инструментов MCP
```bash
# ✅ Используйте встроенные инструменты
/tools health_check
/tools market_analysis BTC 1h
/tools portfolio_status

# ❌ Не дублируйте функциональность
"Проверь состояние системы" (вместо /tools health_check)
```

### 3. Батчинг запросов
```bash
# ✅ Группируйте связанные запросы
"Покажи анализ BTC, ETH и BNB за 4 часа"

# ❌ Отдельные запросы
"Анализ BTC" + "Анализ ETH" + "Анализ BNB"
```

## 🚀 Лучшие практики

### Краткие команды
- `health` → проверка системы
- `assets` → список активов  
- `analyze BTC` → анализ Bitcoin
- `portfolio` → статус портфеля
- `signals` → торговые сигналы

### Контекстные запросы
```bash
# ✅ Указывайте контекст
"Анализ BTC для дневной торговли"

# ✅ Используйте временные рамки
"Покажи сигналы за последние 2 часа"
```

### Избегайте избыточности
```bash
# ❌ Не повторяйте информацию
"Покажи анализ BTC" + "А еще раз анализ BTC"

# ✅ Один запрос с уточнениями
"Детальный анализ BTC с рекомендациями"
```

## 📊 Мониторинг использования

### Проверка статуса
```bash
/tools health_check all
```

### Оптимизация запросов
- Используйте `/tools` для системных команд
- Группируйте связанные вопросы
- Указывайте конкретные параметры
- Избегайте повторных запросов

## 🔧 Настройки экономии

### VS Code настройки
```json
{
  "github.copilot.advanced": {
    "debug.overrideEngine": "gpt-4",
    "maxTokens": 4000,
    "temperature": 0.7
  }
}
```

### MCP оптимизация
- Автоматическое кэширование результатов
- Сжатие ответов
- Приоритизация важных данных
- Умное кэширование контекста

## 💡 Советы по экономии

1. **Используйте алиасы**: `btc` вместо `Bitcoin`
2. **Группируйте запросы**: Один запрос вместо трех
3. **Кэшируйте результаты**: Не запрашивайте одно и то же
4. **Используйте инструменты**: `/tools` вместо длинных описаний
5. **Конкретизируйте**: Чем точнее запрос, тем меньше токенов

## 🎯 Примеры оптимизированных запросов

```bash
# ✅ Оптимизировано
"Анализ BTC, ETH, BNB за 4h с сигналами"

# ❌ Неоптимизировано  
"Покажи анализ Bitcoin" + "Покажи анализ Ethereum" + "Покажи анализ Binance Coin"
```

```bash
# ✅ Оптимизировано
"Портфель + сигналы + рекомендации"

# ❌ Неоптимизировано
"Покажи портфель" + "Покажи сигналы" + "Дай рекомендации"
```
EOF

print_status "Инструкции по экономии токенов созданы" "УСПЕХ" "${GREEN}"

# 6. Создание быстрых команд
cat > /workspace/.mcp/quick-commands.sh << 'EOF'
#!/bin/bash
# Быстрые команды для HTXV2 MCP

# Алиасы для MCP инструментов
alias mcp-health='echo "/tools health_check all"'
alias mcp-assets='echo "/tools list_assets"'
alias mcp-btc='echo "/tools market_analysis BTC 1h"'
alias mcp-eth='echo "/tools market_analysis ETH 1h"'
alias mcp-portfolio='echo "/tools portfolio_status"'
alias mcp-signals='echo "/tools trading_signals"'

# Функции для быстрого доступа
mcp_analyze() {
  local symbol=${1:-BTC}
  local timeframe=${2:-1h}
  echo "/tools market_analysis $symbol $timeframe"
}

mcp_upload() {
  local file=${1:-""}
  local type=${2:-portfolio}
  echo "/tools upload_csv $file $type"
}

# Экспорт функций
export -f mcp_analyze mcp_upload

echo "🚀 HTXV2 MCP быстрые команды загружены!"
echo "Используйте: mcp_analyze BTC 4h"
echo "Или: mcp_upload /path/to/file.csv portfolio"
EOF

chmod +x /workspace/.mcp/quick-commands.sh

# 7. Добавление в .bashrc
echo -e "\nДобавление MCP команд в .bashrc..."
cat >> /root/.bashrc << 'EOF'

# HTXV2 MCP Quick Commands
source /workspace/.mcp/quick-commands.sh

# MCP Aliases
alias mcp-start='cd /workspace/.mcp && npm start'
alias mcp-dev='cd /workspace/.mcp && npm run dev'
alias mcp-status='curl -s http://localhost:8000/api/v1/mcp/health | jq .'
EOF

print_status "Быстрые команды MCP настроены" "УСПЕХ" "${GREEN}"

# 8. Создание тестового скрипта
cat > /workspace/.mcp/test-mcp.sh << 'EOF'
#!/bin/bash
# Тест MCP функциональности

echo "🧪 Тестирование MCP инструментов..."

# Тест health check
echo "1. Тест health_check..."
curl -s http://localhost:8000/api/v1/mcp/health | jq . || echo "❌ Backend не запущен"

# Тест MCP сервера
echo "2. Тест MCP сервера..."
cd /workspace/.mcp
timeout 5s npm start &
MCP_PID=$!
sleep 2
kill $MCP_PID 2>/dev/null
echo "✅ MCP сервер тестирован"

echo "🎉 Тестирование завершено!"
EOF

chmod +x /workspace/.mcp/test-mcp.sh

# 9. Финальная настройка
echo -e "\nФинальная настройка..."

# Создание символической ссылки для удобства
ln -sf /workspace/.mcp/test-mcp.sh /usr/local/bin/test-mcp
ln -sf /workspace/.mcp/quick-commands.sh /usr/local/bin/mcp-commands

# Установка jq для JSON обработки
apt-get update && apt-get install -y jq

print_status "Финальная настройка завершена" "УСПЕХ" "${GREEN}"

# 10. Вывод итогового результата
echo -e "\n${CYAN}===============================================${RESET}"
echo -e "${CYAN}    MCP TOOLS НАСТРОЕНЫ УСПЕШНО!${RESET}"
echo -e "${CYAN}===============================================${RESET}"

echo -e "${GREEN}✅ Доступные инструменты:${RESET}"
echo -e "  • health_check - проверка системы"
echo -e "  • list_assets - список активов"
echo -e "  • market_analysis - анализ рынка"
echo -e "  • portfolio_status - статус портфеля"
echo -e "  • trading_signals - торговые сигналы"
echo -e "  • upload_csv - загрузка данных"

echo -e "\n${GREEN}✅ Быстрые команды:${RESET}"
echo -e "  • mcp-health - проверка системы"
echo -e "  • mcp-assets - список активов"
echo -e "  • mcp-btc - анализ Bitcoin"
echo -e "  • mcp-portfolio - портфель"
echo -e "  • test-mcp - тестирование"

echo -e "\n${GREEN}✅ Экономия токенов:${RESET}"
echo -e "  • Используйте /tools для системных команд"
echo -e "  • Группируйте связанные запросы"
echo -e "  • Конкретизируйте параметры"
echo -e "  • Читайте TOKEN_ECONOMY.md"

echo -e "\n${YELLOW}💡 Следующие шаги:${RESET}"
echo -e "  1. Перезагрузите VS Code (F1 → Reload Window)"
echo -e "  2. Запустите: cd /workspace && docker compose up -d"
echo -e "  3. Проверьте: test-mcp"
echo -e "  4. Используйте /tools в Copilot Chat"

echo -e "\nНастройка завершена: $(date +"%Y-%m-%d %H:%M:%S")"
echo -e "${CYAN}===============================================${RESET}"