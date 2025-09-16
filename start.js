#!/usr/bin/env node

/**
 * HTXV2 - MCP Server Starter
 *
 * Этот файл запускает MCP (Model Context Protocol) сервер для интеграции
 * HTXV2 с GitHub Copilot. MCP расширяет возможности Copilot,
 * предоставляя доступ к данным и функциям проекта.
 */

// Автозагрузка переменных окружения из .env файла
import dotenv from "dotenv";
dotenv.config();

// Логирование параметров запуска
console.log("🚀 Запуск MCP-сервера HTXV2...");
console.log(`📋 Режим: ${process.env.NODE_ENV || "development"}`);
console.log(`🌐 Порт: ${process.env.HTTP_PORT || 3001}`);
console.log(
  `🔗 API URL: ${process.env.API_BASE_URL || "http://localhost:8000"}`
);

// Установка обработчиков сигналов для корректного завершения
process.on("SIGINT", () => {
  console.log("👋 Получен сигнал SIGINT. Завершение работы...");
  process.exit(0);
});

process.on("SIGTERM", () => {
  console.log("👋 Получен сигнал SIGTERM. Завершение работы...");
  process.exit(0);
});

// Импорт и запуск основного модуля
try {
  console.log("📦 Загрузка MCP модулей...");
  await import("./dist/index.js");
  console.log("✅ MCP-сервер успешно запущен и готов к работе!");
} catch (error) {
  console.error("❌ Ошибка при запуске MCP-сервера:", error);
  process.exit(1);
}
