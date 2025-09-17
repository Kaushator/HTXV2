#!/usr/bin/env node

/**
 * HTXV2 - MCP Server Starter
 *
 * Этот файл запускает MCP (Model Context Protocol) сервер для интеграции
 * HTXV2 с GitHub Copilot. MCP расширяет возможности Copilot,
 * предоставляя доступ к данным и функциям проекта.
 */

console.log("🚀 Запуск MCP-сервера HTXV2...");

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
  require("./mcp-server.js");
  console.log("✅ MCP-сервер успешно запущен и готов к работе!");
} catch (error) {
  console.error("❌ Ошибка при запуске MCP-сервера:", error);
  process.exit(1);
}
