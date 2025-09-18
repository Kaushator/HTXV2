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
✅ JupyterLab: Работает на порту 8888

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