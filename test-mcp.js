// Тестовый скрипт для проверки MCP сервера
const http = require("http");

// Функция для HTTP запроса
function httpRequest(url, method = "GET") {
  return new Promise((resolve, reject) => {
    http
      .request(url, { method }, (res) => {
        let data = "";
        res.on("data", (chunk) => {
          data += chunk;
        });
        res.on("end", () => {
          resolve({
            statusCode: res.statusCode,
            headers: res.headers,
            data: JSON.parse(data),
          });
        });
      })
      .on("error", (err) => {
        reject(err);
      })
      .end();
  });
}

// Тестирование HTTP эндпоинтов
async function testHttpEndpoints() {
  try {
    // Проверка статуса
    console.log("Тестирование эндпоинта /status...");
    const statusResponse = await httpRequest("http://localhost:3001/status");
    console.log(`Статус: ${statusResponse.statusCode}`);
    console.log("Данные:", JSON.stringify(statusResponse.data, null, 2));

    // Проверка справки
    console.log("\nТестирование эндпоинта /help...");
    const helpResponse = await httpRequest("http://localhost:3001/help");
    console.log(`Статус: ${helpResponse.statusCode}`);
    console.log(
      "Доступные ресурсы:",
      helpResponse.data.websocket.availableResources
    );

    console.log("\n✅ HTTP эндпоинты работают корректно!");
  } catch (error) {
    console.error("❌ Ошибка при тестировании HTTP эндпоинтов:", error);
  }
}

// Запуск тестов
testHttpEndpoints();
