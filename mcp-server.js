/**
 * HTXV2 MCP Server
 * Простой MCP сервер для интеграции с GitHub Copilot
 */

// Импорты для ExpressJS
const express = require("express");
const cors = require("cors");
const http = require("http");
const WebSocket = require("ws");
const path = require("path");
const fs = require("fs");

// Загрузка переменных окружения
require("dotenv").config();

// Константы и конфигурация
const PORT = process.env.HTTP_PORT || 3001;
const API_BASE_URL = process.env.API_BASE_URL || "http://localhost:8000";

console.log(`🚀 HTXV2 MCP сервер инициализация...`);
console.log(`📌 Порт: ${PORT}`);
console.log(`📌 API URL: ${API_BASE_URL}`);

// Инициализация приложения Express
const app = express();
app.use(cors());
app.use(express.json());

// Создание HTTP сервера
const server = http.createServer(app);

// Инициализация WebSocket сервера
const wss = new WebSocket.Server({ server });

// Хранилище подключенных клиентов
const clients = new Map();

// Доступные ресурсы
const availableResources = [
  {
    name: "marketData",
    description: "Получение рыночных данных",
    params: ["symbol", "timeframe"],
  },
  {
    name: "portfolio",
    description: "Получение данных портфеля",
    params: ["includeHistory"],
  },
  {
    name: "tradingSignals",
    description: "Получение торговых сигналов",
    params: ["symbol", "timeframe", "source"],
  },
  { name: "help", description: "Получение справочной информации" },
];

// Функция для генерации уникального ID
function generateId() {
  return (
    Math.random().toString(36).substring(2, 15) +
    Math.random().toString(36).substring(2, 15)
  );
}

// HTTP эндпоинты

// Статус сервера
app.get("/status", (req, res) => {
  res.json({
    status: "ok",
    uptime: process.uptime(),
    timestamp: Date.now(),
    connections: clients.size,
  });
});

// Справочная информация по API
app.get("/help", (req, res) => {
  res.json({
    description: "HTXV2 MCP Server API",
    endpoints: [
      { path: "/status", method: "GET", description: "Статус сервера" },
      { path: "/help", method: "GET", description: "Справочная информация" },
    ],
    websocket: {
      url: `ws://localhost:${PORT}`,
      protocols: [
        { type: "ping", description: "Проверка соединения" },
        {
          type: "query",
          description: "Запрос данных",
          params: { resource: "string", params: "object" },
        },
      ],
      availableResources,
    },
  });
});

// Обработчик подключений WebSocket
wss.on("connection", (ws) => {
  // Регистрируем нового клиента
  const clientId = generateId();
  clients.set(clientId, { ws, connectedAt: Date.now() });

  console.log(`🔵 Новое WebSocket подключение: ${clientId}`);

  // Отправка приветственного сообщения
  ws.send(
    JSON.stringify({
      type: "connection",
      status: "established",
      clientId,
      message: "Подключение к HTXV2 MCP серверу установлено",
    })
  );

  // Обработчик входящих сообщений
  ws.on("message", async (message) => {
    try {
      const data = JSON.parse(message.toString());
      console.log(`📥 Получено сообщение от ${clientId}:`, data);

      // Обработка различных типов сообщений
      switch (data.type) {
        case "ping":
          ws.send(JSON.stringify({ type: "pong", timestamp: Date.now() }));
          break;
        case "query":
          // Обработка запросов данных
          await handleDataQuery(ws, data);
          break;
        default:
          ws.send(
            JSON.stringify({
              type: "error",
              message: "Неизвестный тип сообщения",
            })
          );
      }
    } catch (err) {
      console.error(`🔴 Ошибка обработки сообщения от ${clientId}:`, err);
      ws.send(
        JSON.stringify({
          type: "error",
          message: "Ошибка обработки запроса",
        })
      );
    }
  });

  // Обработчик закрытия соединения
  ws.on("close", () => {
    console.log(`🔵 WebSocket соединение закрыто: ${clientId}`);
    clients.delete(clientId);
  });
});

/**
 * Обработка запросов данных
 */
async function handleDataQuery(ws, data) {
  try {
    // В зависимости от запрашиваемого ресурса
    switch (data.resource) {
      case "marketData":
        await sendMarketData(ws, data.params);
        break;
      case "portfolio":
        await sendPortfolioData(ws, data.params);
        break;
      case "tradingSignals":
        await sendTradingSignals(ws, data.params);
        break;
      case "help":
        sendHelpInfo(ws);
        break;
      default:
        ws.send(
          JSON.stringify({
            type: "error",
            message: "Неизвестный ресурс",
          })
        );
    }
  } catch (err) {
    console.error("🔴 Ошибка обработки запроса данных:", err);
    ws.send(
      JSON.stringify({
        type: "error",
        message: "Ошибка обработки запроса данных",
      })
    );
  }
}

/**
 * Отправка рыночных данных
 */
async function sendMarketData(ws, params = {}) {
  try {
    const symbol = params.symbol || "BTC-USDT";

    // Заглушка для демонстрации
    const data = {
      symbol,
      price: 50000 + Math.random() * 1000,
      change24h: (Math.random() * 10 - 5).toFixed(2),
      volume24h: Math.random() * 10000000,
      timestamp: Date.now(),
    };

    ws.send(
      JSON.stringify({
        type: "response",
        resource: "marketData",
        data,
      })
    );
  } catch (err) {
    console.error("🔴 Ошибка при получении рыночных данных:", err);
    ws.send(
      JSON.stringify({
        type: "error",
        message: "Ошибка при получении рыночных данных",
      })
    );
  }
}

/**
 * Отправка данных портфеля
 */
async function sendPortfolioData(ws, params = {}) {
  try {
    // Заглушка для демонстрации
    const data = {
      totalValue: 100000 + Math.random() * 10000,
      assets: [
        { symbol: "BTC", amount: 1.5, valueUSD: 75000 },
        { symbol: "ETH", amount: 15, valueUSD: 30000 },
      ],
      pnl24h: (Math.random() * 5000 - 2500).toFixed(2),
      timestamp: Date.now(),
    };

    ws.send(
      JSON.stringify({
        type: "response",
        resource: "portfolio",
        data,
      })
    );
  } catch (err) {
    console.error("🔴 Ошибка при получении данных портфеля:", err);
    ws.send(
      JSON.stringify({
        type: "error",
        message: "Ошибка при получении данных портфеля",
      })
    );
  }
}

/**
 * Отправка торговых сигналов
 */
async function sendTradingSignals(ws, params = {}) {
  try {
    // Заглушка для демонстрации
    const data = {
      signals: [
        { symbol: "BTC-USDT", type: "BUY", confidence: 0.75, source: "AI" },
        {
          symbol: "ETH-USDT",
          type: "HOLD",
          confidence: 0.6,
          source: "Technical",
        },
      ],
      timestamp: Date.now(),
    };

    ws.send(
      JSON.stringify({
        type: "response",
        resource: "tradingSignals",
        data,
      })
    );
  } catch (err) {
    console.error("🔴 Ошибка при получении торговых сигналов:", err);
    ws.send(
      JSON.stringify({
        type: "error",
        message: "Ошибка при получении торговых сигналов",
      })
    );
  }
}

/**
 * Отправка справочной информации
 */
function sendHelpInfo(ws) {
  ws.send(
    JSON.stringify({
      type: "response",
      resource: "help",
      data: {
        availableResources,
        usage:
          'Отправьте JSON объект с полями type: "query" и resource: "<имя_ресурса>"',
      },
    })
  );
}

// Обработка сигналов для корректного завершения
process.on("SIGINT", () => {
  console.log("👋 Получен сигнал SIGINT. Завершение работы...");
  shutdown();
});

process.on("SIGTERM", () => {
  console.log("👋 Получен сигнал SIGTERM. Завершение работы...");
  shutdown();
});

// Функция корректного завершения работы
function shutdown() {
  // Закрытие WebSocket сервера
  wss.close(() => {
    console.log("🔵 WebSocket сервер закрыт");
  });

  // Закрытие HTTP сервера
  server.close(() => {
    console.log("🟣 HTTP сервер закрыт");
    process.exit(0);
  });
}

// Запуск сервера
server.listen(PORT, () => {
  console.log(`🚀 MCP сервер запущен на порту ${PORT}`);
  console.log(`📘 API документация: http://localhost:${PORT}/help`);
});

// Экспорт для использования в других модулях
module.exports = { app, server, wss };
