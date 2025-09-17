# Настройка MCP (Model Context Protocol) для HTXV2

## Обзор

MCP (Model Context Protocol) - это протокол, который позволяет GitHub Copilot получать доступ к данным и функциям вашего проекта. Для HTXV2 это обеспечивает следующие возможности:

- Доступ к рыночным данным из биржи HTX
- Анализ состояния портфеля и PnL метрик
- Отслеживание торговых сигналов и рекомендаций
- Интеграция с другими компонентами системы

## Шаги по настройке

### 1. Подготовка окружения

Убедитесь, что установлены все необходимые зависимости:

```bash
npm install
```

### 2. Конфигурация VS Code

Создайте или обновите файл `.vscode/settings.json` с настройками для MCP:

```json
{
  "mcp.enabled": true,
  "mcp.featureCompletions": true,
  "mcp.featureChat": true,
  "mcp.featureActions": true,
  "mcp.process": {
    "command": "node",
    "args": ["${workspaceFolder}/start.js"],
    "cwd": "${workspaceFolder}",
    "env": {
      "NODE_ENV": "development",
      "HTTP_PORT": "3001",
      "API_BASE_URL": "http://localhost:8000"
    }
  }
}
```

### 3. Запуск MCP сервера

Запустите MCP сервер выполнив:

```bash
node start.js
```

Вы должны увидеть сообщение об успешном запуске:

```
🚀 Запуск MCP-сервера HTXV2...
📦 Загрузка MCP модулей...
✅ MCP-сервер успешно запущен и готов к работе!
🚀 MCP сервер запущен на порту 3001
```

### 4. Проверка работоспособности

Для проверки работоспособности MCP сервера выполните:

```bash
node test-mcp.js
```

Для проверки WebSocket соединения:

```bash
node test-ws-client.js
```

## Структура MCP

### Основные файлы

- `start.js` - точка входа, запускает MCP сервер
- `mcp-server.js` - основная реализация MCP сервера
- `test-mcp.js` - тест HTTP эндпоинтов
- `test-ws-client.js` - тест WebSocket соединения

### Доступные ресурсы

MCP сервер предоставляет доступ к следующим ресурсам:

1. **marketData** - рыночные данные (котировки, объемы)
2. **portfolio** - данные портфеля (активы, PnL)
3. **tradingSignals** - торговые сигналы и рекомендации
4. **help** - справочная информация

### Пример запроса к MCP через WebSocket

```javascript
// Создание WebSocket соединения
const ws = new WebSocket("ws://localhost:3001");

// Отправка запроса на получение рыночных данных
ws.send(
  JSON.stringify({
    type: "query",
    resource: "marketData",
    params: { symbol: "BTC-USDT" },
  })
);

// Обработчик получения сообщений
ws.on("message", function (data) {
  const response = JSON.parse(data);
  console.log(response);
});
```

## Решение проблем

### MCP сервер не запускается

1. Проверьте, не занят ли порт 3001 другим приложением
2. Убедитесь, что установлены все необходимые зависимости
3. Проверьте журналы на наличие ошибок

### GitHub Copilot не подключается к MCP

1. Убедитесь, что MCP сервер запущен
2. Проверьте настройки в `.vscode/settings.json`
3. Перезапустите VS Code

### Дополнительная информация

Дополнительную информацию о MCP и GitHub Copilot можно найти в документации:

- [Документация GitHub Copilot](https://docs.github.com/en/copilot)
- [Model Context Protocol](https://github.com/microsoft/model-context-protocol)
