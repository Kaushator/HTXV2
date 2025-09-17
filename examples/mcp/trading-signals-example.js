/**
 * Пример использования MCP для анализа торговых сигналов
 *
 * Этот пример демонстрирует, как можно получать и анализировать
 * торговые сигналы через MCP сервер.
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

// Функция для запроса торговых сигналов
function requestTradingSignals(ws) {
  return new Promise((resolve) => {
    // Обработчик ответа
    const messageHandler = (message) => {
      const data = JSON.parse(message);

      // Если это ответ на запрос торговых сигналов
      if (data.type === "response" && data.resource === "tradingSignals") {
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
      resource: "tradingSignals",
    };

    console.log("📤 Запрос торговых сигналов...");
    ws.send(JSON.stringify(request));
  });
}

// Функция для оценки торгового сигнала
function evaluateSignal(signal) {
  let emoji = "❓";
  let recommendation = "Нейтрально";

  // Определение эмодзи и рекомендации на основе типа сигнала и уровня уверенности
  if (signal.type === "BUY") {
    if (signal.confidence >= 0.8) {
      emoji = "🟢";
      recommendation = "Сильный сигнал на покупку";
    } else if (signal.confidence >= 0.6) {
      emoji = "🟡";
      recommendation = "Умеренный сигнал на покупку";
    } else {
      emoji = "⚪";
      recommendation = "Слабый сигнал на покупку";
    }
  } else if (signal.type === "SELL") {
    if (signal.confidence >= 0.8) {
      emoji = "🔴";
      recommendation = "Сильный сигнал на продажу";
    } else if (signal.confidence >= 0.6) {
      emoji = "🟠";
      recommendation = "Умеренный сигнал на продажу";
    } else {
      emoji = "⚪";
      recommendation = "Слабый сигнал на продажу";
    }
  } else if (signal.type === "HOLD") {
    emoji = "🔵";
    recommendation = "Удержание позиции";
  }

  return {
    ...signal,
    emoji,
    recommendation,
  };
}

// Основная функция
async function main() {
  try {
    // Подключаемся к MCP серверу
    const ws = await connectToMCP();

    // Получаем торговые сигналы
    const { signals, timestamp } = await requestTradingSignals(ws);

    // Оцениваем каждый сигнал
    const evaluatedSignals = signals.map(evaluateSignal);

    // Выводим результаты
    console.log("\n🎯 Анализ торговых сигналов:");
    console.log(`Дата и время: ${new Date(timestamp).toLocaleString()}`);
    console.log(`Количество сигналов: ${signals.length}`);

    console.log("\n📊 Торговые сигналы:");
    evaluatedSignals.forEach((signal) => {
      console.log(
        `${signal.emoji} ${signal.symbol}: ${signal.recommendation} (${
          signal.confidence * 100
        }% уверенность)`
      );
      console.log(`   Источник: ${signal.source}`);
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
