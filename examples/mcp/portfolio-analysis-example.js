/**
 * Пример использования MCP для анализа портфеля
 *
 * Этот пример демонстрирует, как можно получать данные
 * о состоянии портфеля через MCP сервер.
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

// Функция для запроса данных портфеля
function requestPortfolioData(ws) {
  return new Promise((resolve) => {
    // Обработчик ответа
    const messageHandler = (message) => {
      const data = JSON.parse(message);

      // Если это ответ на запрос данных портфеля
      if (data.type === "response" && data.resource === "portfolio") {
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
      resource: "portfolio",
    };

    console.log("📤 Запрос данных портфеля...");
    ws.send(JSON.stringify(request));
  });
}

// Функция для анализа портфеля
function analyzePortfolio(portfolioData) {
  const { totalValue, assets, pnl24h } = portfolioData;

  // Расчет распределения активов (в процентах)
  const assetDistribution = assets.map((asset) => ({
    symbol: asset.symbol,
    percentage: ((asset.valueUSD / totalValue) * 100).toFixed(2),
  }));

  // Расчет процентного изменения PnL
  const pnlPercentage = ((parseFloat(pnl24h) / totalValue) * 100).toFixed(2);

  return {
    totalValue: totalValue.toFixed(2),
    assetCount: assets.length,
    pnl24h,
    pnlPercentage,
    assetDistribution,
  };
}

// Основная функция
async function main() {
  try {
    // Подключаемся к MCP серверу
    const ws = await connectToMCP();

    // Получаем данные портфеля
    const portfolioData = await requestPortfolioData(ws);

    // Анализируем данные
    const analysis = analyzePortfolio(portfolioData);

    // Выводим результаты
    console.log("\n💼 Анализ портфеля:");
    console.log(`Общая стоимость: $${analysis.totalValue}`);
    console.log(`Количество активов: ${analysis.assetCount}`);
    console.log(`PnL за 24ч: $${analysis.pnl24h} (${analysis.pnlPercentage}%)`);

    console.log("\n📊 Распределение активов:");
    analysis.assetDistribution.forEach((asset) => {
      console.log(`${asset.symbol}: ${asset.percentage}%`);
    });

    // Закрываем соединение
    ws.close();
    console.log("\n👋 Соединение с MCP закрыто");
  } catch (error) {
    console.error("❌ Произошла ошибка:", error);
    process.exit(1);
  }
}

// Запуск программы
main();
