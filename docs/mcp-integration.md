# Интеграция HTXV2 с GitHub Copilot через MCP

## Что такое MCP

MCP (Model Context Protocol) — это протокол, который позволяет интегрировать GitHub Copilot с вашим проектом, предоставляя доступ к данным и функциям проекта.

## Настройка MCP для HTXV2

### Предварительные требования

- Node.js 16.x или выше
- npm 7.x или выше
- VS Code с расширением GitHub Copilot

### Установка и настройка

1. Установите зависимости:

   ```
   npm install
   ```

2. Соберите проект:

   ```
   npm run build
   ```

3. Запустите MCP сервер:

   ```
   node start.js
   ```

   Или используйте готовый скрипт:

   ```
   .\start-mcp.ps1
   ```

4. Проверьте работоспособность:
   - Откройте http://localhost:3001/status в браузере
   - Должен отобразиться статус сервера в JSON формате

### Конфигурация VS Code

В `.vscode/settings.json` уже настроена интеграция с MCP:

```json
"mcp.enabled": true,
"mcp.featureCompletions": true,
"mcp.featureChat": true,
"mcp.featureActions": true,
"mcp.process": {
  "command": "node",
  "args": ["${workspaceFolder}/start.js"],
  "cwd": "${workspaceFolder}"
}
```

## Использование MCP с GitHub Copilot

После запуска MCP сервера, GitHub Copilot получает доступ к данным и функциям HTXV2:

1. **Данные рынка**:

   - Запрос котировок
   - Исторические данные

2. **Портфель**:

   - Состояние активов
   - PnL метрики

3. **Торговые сигналы**:
   - AI рекомендации
   - Технические индикаторы

## Примеры запросов к Copilot

После запуска MCP сервера вы можете запрашивать у Copilot информацию о HTXV2:

- "Показать текущий статус портфеля"
- "Какие сигналы доступны для BTC?"
- "Построить график цены ETH за последнюю неделю"

## Диагностика

Если MCP не работает:

1. Убедитесь, что MCP сервер запущен:

   ```
   curl http://localhost:3001/status
   ```

2. Проверьте логи VS Code (View > Output > GitHub Copilot)

3. Перезапустите VS Code и MCP сервер
