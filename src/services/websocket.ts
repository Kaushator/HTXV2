/**
 * Обработчики для WebSocket сообщений
 */

import { v4 as uuidv4 } from "uuid";
import { WebSocket } from "ws";
import {
  ClientConnection,
  MarketDataParams,
  PortfolioParams,
  QueryMessage,
  Resource,
  TradingSignalParams,
} from "../types";
import {
  fetchMarketData,
  fetchPortfolioData,
  fetchTradingSignals,
} from "./api";

// Хранилище подключенных клиентов
const clients: Map<string, ClientConnection> = new Map();

// Доступные ресурсы
export const availableResources: Resource[] = [
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

/**
 * Регистрация нового клиента
 */
export function registerClient(ws: WebSocket): string {
  const clientId = uuidv4();
  clients.set(clientId, { ws, id: clientId, connectedAt: Date.now() });

  console.log(`🔵 Новое WebSocket подключение: ${clientId}`);

  // Установка обработчика закрытия соединения
  ws.on("close", () => {
    clients.delete(clientId);
    console.log(`🔵 WebSocket соединение закрыто: ${clientId}`);
  });

  return clientId;
}

/**
 * Обработка входящего сообщения
 */
export async function handleWebSocketMessage(
  ws: WebSocket,
  message: string
): Promise<void> {
  try {
    const data = JSON.parse(message) as QueryMessage;
    console.log("📥 Получено сообщение:", data);

    switch (data.type) {
      case "ping":
        ws.send(JSON.stringify({ type: "pong", timestamp: Date.now() }));
        break;
      case "query":
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
    console.error("🔴 Ошибка обработки сообщения:", err);
    ws.send(
      JSON.stringify({
        type: "error",
        message: "Ошибка обработки запроса",
      })
    );
  }
}

/**
 * Обработка запроса данных
 */
async function handleDataQuery(
  ws: WebSocket,
  data: QueryMessage
): Promise<void> {
  switch (data.resource) {
    case "marketData":
      await sendMarketData(ws, data.params as MarketDataParams);
      break;
    case "portfolio":
      await sendPortfolioData(ws, data.params as PortfolioParams);
      break;
    case "tradingSignals":
      await sendTradingSignals(ws, data.params as TradingSignalParams);
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
}

/**
 * Отправка рыночных данных
 */
async function sendMarketData(
  ws: WebSocket,
  params: MarketDataParams = {}
): Promise<void> {
  try {
    const data = await fetchMarketData(params);
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
async function sendPortfolioData(
  ws: WebSocket,
  params: PortfolioParams = {}
): Promise<void> {
  try {
    const data = await fetchPortfolioData(params);
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
async function sendTradingSignals(
  ws: WebSocket,
  params: TradingSignalParams = {}
): Promise<void> {
  try {
    const data = await fetchTradingSignals(params);
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
function sendHelpInfo(ws: WebSocket): void {
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

/**
 * Рассылка сообщения всем подключенным клиентам
 */
export function broadcastMessage(message: any): void {
  const messageStr =
    typeof message === "string" ? message : JSON.stringify(message);

  for (const client of clients.values()) {
    if (client.ws.readyState === WebSocket.OPEN) {
      client.ws.send(messageStr);
    }
  }
}

/**
 * Получение всех подключенных клиентов
 */
export function getConnectedClients(): ClientConnection[] {
  return Array.from(clients.values());
}

/**
 * Отключение клиента по ID
 */
export function disconnectClient(clientId: string): boolean {
  const client = clients.get(clientId);
  if (client) {
    client.ws.close();
    clients.delete(clientId);
    return true;
  }
  return false;
}
