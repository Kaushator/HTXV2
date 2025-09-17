/**
 * Интеграция MCP с основным модулем HTXV2
 *
 * Этот модуль позволяет взаимодействовать с основными функциями HTXV2
 * через MCP (Model Context Protocol).
 */

const WebSocket = require("ws");
const http = require("http");
const fs = require("fs").promises;
const path = require("path");

// Настройки MCP
const MCP_CONFIG = {
  url: "ws://localhost:3001",
  httpUrl: "http://localhost:3001",
  reconnectInterval: 5000, // 5 секунд
  maxReconnectAttempts: 5,
};

// Класс для работы с MCP
class MCPClient {
  constructor(config = MCP_CONFIG) {
    this.config = config;
    this.ws = null;
    this.isConnected = false;
    this.reconnectAttempts = 0;
    this.listeners = new Map();
    this.responseHandlers = new Map();
    this.requestId = 1;
  }

  /**
   * Подключение к MCP серверу
   */
  async connect() {
    return new Promise((resolve, reject) => {
      try {
        this.ws = new WebSocket(this.config.url);

        this.ws.on("open", () => {
          console.log("🔵 Соединение с MCP установлено");
          this.isConnected = true;
          this.reconnectAttempts = 0;
          resolve(true);
        });

        this.ws.on("message", (data) => {
          this.handleMessage(data);
        });

        this.ws.on("close", () => {
          console.log("🔵 Соединение с MCP закрыто");
          this.isConnected = false;
          this.tryReconnect();
        });

        this.ws.on("error", (error) => {
          console.error("❌ Ошибка соединения с MCP:", error);
          reject(error);
        });
      } catch (error) {
        console.error("❌ Ошибка подключения к MCP:", error);
        reject(error);
      }
    });
  }

  /**
   * Попытка переподключения при обрыве соединения
   */
  tryReconnect() {
    if (this.reconnectAttempts >= this.config.maxReconnectAttempts) {
      console.error(
        `❌ Превышено максимальное количество попыток подключения к MCP (${this.config.maxReconnectAttempts})`
      );
      return;
    }

    this.reconnectAttempts++;
    console.log(
      `🔄 Попытка переподключения к MCP (${this.reconnectAttempts}/${this.config.maxReconnectAttempts})...`
    );

    setTimeout(() => {
      this.connect().catch(() => {
        this.tryReconnect();
      });
    }, this.config.reconnectInterval);
  }

  /**
   * Обработка входящих сообщений
   */
  handleMessage(message) {
    try {
      const data = JSON.parse(message);

      // Если есть обработчик для этого типа сообщений
      if (data.requestId && this.responseHandlers.has(data.requestId)) {
        // Вызываем обработчик и удаляем его
        const handler = this.responseHandlers.get(data.requestId);
        this.responseHandlers.delete(data.requestId);
        handler(data);
        return;
      }

      // Уведомляем всех слушателей определенного типа
      if (data.type && this.listeners.has(data.type)) {
        this.listeners.get(data.type).forEach((listener) => {
          listener(data);
        });
      }

      // Уведомляем слушателей всех сообщений
      if (this.listeners.has("*")) {
        this.listeners.get("*").forEach((listener) => {
          listener(data);
        });
      }
    } catch (error) {
      console.error("❌ Ошибка обработки сообщения от MCP:", error);
    }
  }

  /**
   * Отправка запроса к MCP
   */
  async sendRequest(request) {
    if (!this.isConnected) {
      throw new Error("Нет соединения с MCP");
    }

    return new Promise((resolve, reject) => {
      try {
        const requestId = this.requestId++;
        const requestWithId = { ...request, requestId };

        // Устанавливаем обработчик ответа
        this.responseHandlers.set(requestId, (response) => {
          if (response.type === "error") {
            reject(new Error(response.message));
          } else {
            resolve(response);
          }
        });

        // Отправляем запрос
        this.ws.send(JSON.stringify(requestWithId));

        // Устанавливаем таймаут
        setTimeout(() => {
          if (this.responseHandlers.has(requestId)) {
            this.responseHandlers.delete(requestId);
            reject(new Error("Таймаут ответа от MCP"));
          }
        }, 10000); // 10 секунд на ответ
      } catch (error) {
        reject(error);
      }
    });
  }

  /**
   * Добавление слушателя определенного типа сообщений
   */
  addListener(type, listener) {
    if (!this.listeners.has(type)) {
      this.listeners.set(type, new Set());
    }
    this.listeners.get(type).add(listener);

    return () => {
      if (this.listeners.has(type)) {
        this.listeners.get(type).delete(listener);
      }
    };
  }

  /**
   * Получение рыночных данных
   */
  async getMarketData(params = {}) {
    const response = await this.sendRequest({
      type: "query",
      resource: "marketData",
      params,
    });

    return response.data;
  }

  /**
   * Получение данных портфеля
   */
  async getPortfolioData(params = {}) {
    const response = await this.sendRequest({
      type: "query",
      resource: "portfolio",
      params,
    });

    return response.data;
  }

  /**
   * Получение торговых сигналов
   */
  async getTradingSignals(params = {}) {
    const response = await this.sendRequest({
      type: "query",
      resource: "tradingSignals",
      params,
    });

    return response.data;
  }

  /**
   * Проверка статуса MCP сервера через HTTP
   */
  async checkStatus() {
    return new Promise((resolve, reject) => {
      http
        .get(`${this.config.httpUrl}/status`, (res) => {
          let data = "";

          res.on("data", (chunk) => {
            data += chunk;
          });

          res.on("end", () => {
            try {
              const status = JSON.parse(data);
              resolve(status);
            } catch (error) {
              reject(error);
            }
          });
        })
        .on("error", (error) => {
          reject(error);
        });
    });
  }

  /**
   * Закрытие соединения
   */
  close() {
    if (this.ws && this.isConnected) {
      this.ws.close();
      this.isConnected = false;
    }
  }
}

// Экспорт клиента MCP
module.exports = {
  MCPClient,
  createMCPClient: async (config) => {
    const client = new MCPClient(config);
    await client.connect();
    return client;
  },
};
