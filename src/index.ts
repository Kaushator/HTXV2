/**
 * HTXV2 MCP Server
 * Model Context Protocol сервер для интеграции с GitHub Copilot
 */

import cors from "cors";
import dotenv from "dotenv";
import express from "express";
import http from "http";
import path from "path";
import { fileURLToPath } from "url";
import { WebSocketServer } from "ws";

// Импортируем наши сервисы
import { getRedisClient, initRedisClient } from "./services/redis";
import {
  availableResources,
  handleWebSocketMessage,
  registerClient,
} from "./services/websocket";

// Загрузка переменных окружения
dotenv.config();

// Константы и конфигурация
const PORT = parseInt(process.env.HTTP_PORT || "3001");
const REDIS_URL = process.env.REDIS_URL || "redis://localhost:6379";
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Инициализация приложения Express
const app = express();
app.use(cors());
app.use(express.json());

// Создание HTTP сервера
const server = http.createServer(app);

// Инициализация WebSocket сервера
const wss = new WebSocketServer({ server });

// HTTP эндпоинты

// Статус сервера
app.get("/status", (req, res) => {
  res.json({
    status: "ok",
    uptime: process.uptime(),
    timestamp: Date.now(),
    redisConnected: getRedisClient() !== null,
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
  const clientId = registerClient(ws);

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
    await handleWebSocketMessage(ws, message.toString());
  });
});

// Обработка сигналов для корректного завершения
process.on("SIGINT", async () => {
  console.log("� Получен сигнал SIGINT. Завершение работы...");
  await shutdown();
});

process.on("SIGTERM", async () => {
  console.log("� Получен сигнал SIGTERM. Завершение работы...");
  await shutdown();
});

// Функция корректного завершения работы
async function shutdown() {
  // Закрытие WebSocket сервера
  wss.close(() => {
    console.log("🔵 WebSocket сервер закрыт");
  });

  // Закрытие HTTP сервера
  server.close(() => {
    console.log("� HTTP сервер закрыт");
  });

  // Закрытие соединения с Redis
  try {
    const redis = getRedisClient();
    if (redis) {
      await redis.quit();
      console.log("� Redis соединение закрыто");
    }
  } catch (err) {
    console.error("🔴 Ошибка закрытия Redis соединения:", err);
  }

  // Выход из процесса
  process.exit(0);
}

// Запуск сервера
async function startServer() {
  try {
    // Инициализация Redis
    await initRedisClient(REDIS_URL);

    // Запуск сервера
    server.listen(PORT, () => {
      console.log(`🚀 MCP сервер запущен на порту ${PORT}`);
      console.log(`📘 API документация: http://localhost:${PORT}/help`);
    });
  } catch (err) {
    console.error("🔴 Ошибка запуска сервера:", err);
    process.exit(1);
  }
}

// Запуск приложения
startServer();

// Экспорт для использования в других модулях
export { app, server, wss };
