/**
 * Пример использования MCP для получения рыночных данных
 *
 * Этот пример демонстрирует, как можно получать данные
 * о рынке криптовалют через MCP сервер.
 */

const WebSocket = require("ws");

// Функция для создания WebSocket подключения к MCP серверу
function connectToMCP() {
  return new Promise((resolve, reject) => {
    const ws = new WebSocket("ws://localhost:3001");

    ws.on("open", () => {
      console.log("🔵 Соединение с MCP установлено");
      resolve(ws);
    });

    ws.on("error", (error) => {
      console.error("❌ Ошибка подключения к MCP:", error);
      reject(error);
    });
  });
}

// Функция для запроса рыночных данных
function requestMarketData(ws, symbol = "BTC-USDT") {
  return new Promise((resolve) => {
    // Обработчик ответа
    const messageHandler = (message) => {
      const data = JSON.parse(message);

      // Если это ответ на запрос рыночных данных
      if (data.type === "response" && data.resource === "marketData") {
        // Удаляем обработчик, чтобы избежать утечек памяти
        ws.removeEventListener("message", messageHandler);
        resolve(data.data);
      }
    };

    // Добавляем обработчик для получения ответа
    ws.addEventListener("message", messageHandler);

    // Отправляем запрос
    const request = {
      type: "query",
      resource: "marketData",
      params: { symbol },
    };

    console.log(`📤 Запрос данных по символу ${symbol}...`);
    ws.send(JSON.stringify(request));
  });
}

// Основная функция
async function main() {
  try {
    // Подключаемся к MCP серверу
    const ws = await connectToMCP();

    // Получаем данные по нескольким символам
    const symbols = ["BTC-USDT", "ETH-USDT", "SOL-USDT", "XRP-USDT"];

    console.log("📊 Запрашиваем рыночные данные...");

    // Параллельно запрашиваем данные по всем символам
    const results = await Promise.all(
      symbols.map((symbol) => requestMarketData(ws, symbol))
    );

    // Выводим результаты
    console.log("\n📈 Полученные данные о рынке:");
    console.table(
      results.map((data) => ({
        Символ: data.symbol,
        Цена: `$${data.price.toFixed(2)}`,
        "Изменение 24ч": `${data.change24h}%`,
        "Объем 24ч": `$${(data.volume24h / 1000000).toFixed(2)}M`,
      }))
    );

    // Закрываем соединение
    ws.close();
    console.log("👋 Соединение с MCP закрыто");
  } catch (error) {
    console.error("❌ Произошла ошибка:", error);
    process.exit(1);
  }
}

// Запуск программы
main();
