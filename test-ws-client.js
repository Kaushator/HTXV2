// Тестовый WebSocket клиент для проверки MCP сервера
const WebSocket = require("ws");

// Создание WebSocket соединения
const ws = new WebSocket("ws://localhost:3001");

// Обработчик открытия соединения
ws.on("open", function open() {
  console.log("🔵 Соединение установлено");

  // Отправка ping сообщения
  const pingMsg = { type: "ping" };
  console.log("📤 Отправка сообщения:", pingMsg);
  ws.send(JSON.stringify(pingMsg));

  // Отправка запроса на получение рыночных данных
  setTimeout(() => {
    const marketDataMsg = {
      type: "query",
      resource: "marketData",
      params: { symbol: "BTC-USDT" },
    };
    console.log("📤 Отправка сообщения:", marketDataMsg);
    ws.send(JSON.stringify(marketDataMsg));
  }, 1000);

  // Отправка запроса на получение данных портфеля
  setTimeout(() => {
    const portfolioMsg = {
      type: "query",
      resource: "portfolio",
    };
    console.log("📤 Отправка сообщения:", portfolioMsg);
    ws.send(JSON.stringify(portfolioMsg));
  }, 2000);

  // Отправка запроса на получение торговых сигналов
  setTimeout(() => {
    const signalsMsg = {
      type: "query",
      resource: "tradingSignals",
    };
    console.log("📤 Отправка сообщения:", signalsMsg);
    ws.send(JSON.stringify(signalsMsg));
  }, 3000);

  // Отправка запроса на получение справочной информации
  setTimeout(() => {
    const helpMsg = {
      type: "query",
      resource: "help",
    };
    console.log("📤 Отправка сообщения:", helpMsg);
    ws.send(JSON.stringify(helpMsg));
  }, 4000);

  // Закрытие соединения через 5 секунд
  setTimeout(() => {
    console.log("👋 Закрытие соединения");
    ws.close();
    process.exit(0);
  }, 5000);
});

// Обработчик получения сообщений
ws.on("message", function incoming(data) {
  const message = JSON.parse(data);
  console.log("📥 Получено сообщение:", message);
});

// Обработчик ошибок
ws.on("error", function error(err) {
  console.error("❌ Ошибка WebSocket:", err);
  process.exit(1);
});

// Обработчик закрытия соединения
ws.on("close", function close() {
  console.log("🔵 Соединение закрыто");
});
