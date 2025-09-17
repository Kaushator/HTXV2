/**
 * Сервис для работы с внешним API
 */

import {
  MarketData,
  MarketDataParams,
  PortfolioData,
  PortfolioParams,
  TradingSignalParams,
  TradingSignalsData,
} from "../types";

// Base URL для API
const API_BASE_URL = process.env.API_BASE_URL || "http://localhost:8000";

/**
 * Получение рыночных данных
 */
export async function fetchMarketData(
  params: MarketDataParams
): Promise<MarketData> {
  try {
    const symbol = params.symbol || "BTC-USDT";

    // Для демонстрации мы используем заглушку, но в реальной системе здесь будет API запрос
    // const response = await fetch(`${API_BASE_URL}/api/market-data/${symbol}`);
    // if (!response.ok) throw new Error(`API error: ${response.status}`);
    // return await response.json() as MarketData;

    // Заглушка
    return {
      symbol,
      price: 50000 + Math.random() * 1000,
      change24h: (Math.random() * 10 - 5).toFixed(2),
      volume24h: Math.random() * 10000000,
      timestamp: Date.now(),
    };
  } catch (error) {
    console.error("Error fetching market data:", error);
    throw error;
  }
}

/**
 * Получение данных портфеля
 */
export async function fetchPortfolioData(
  params: PortfolioParams
): Promise<PortfolioData> {
  try {
    // Для демонстрации мы используем заглушку, но в реальной системе здесь будет API запрос
    // const response = await fetch(`${API_BASE_URL}/api/portfolio`);
    // if (!response.ok) throw new Error(`API error: ${response.status}`);
    // return await response.json() as PortfolioData;

    // Заглушка
    return {
      totalValue: 100000 + Math.random() * 10000,
      assets: [
        { symbol: "BTC", amount: 1.5, valueUSD: 75000 },
        { symbol: "ETH", amount: 15, valueUSD: 30000 },
      ],
      pnl24h: (Math.random() * 5000 - 2500).toFixed(2),
      timestamp: Date.now(),
    };
  } catch (error) {
    console.error("Error fetching portfolio data:", error);
    throw error;
  }
}

/**
 * Получение торговых сигналов
 */
export async function fetchTradingSignals(
  params: TradingSignalParams
): Promise<TradingSignalsData> {
  try {
    // Для демонстрации мы используем заглушку, но в реальной системе здесь будет API запрос
    // const response = await fetch(`${API_BASE_URL}/api/signals`);
    // if (!response.ok) throw new Error(`API error: ${response.status}`);
    // return await response.json() as TradingSignalsData;

    // Заглушка
    return {
      signals: [
        { symbol: "BTC-USDT", type: "BUY", confidence: 0.75, source: "AI" },
        {
          symbol: "ETH-USDT",
          type: "HOLD",
          confidence: 0.6,
          source: "Technical",
        },
      ],
      timestamp: Date.now(),
    };
  } catch (error) {
    console.error("Error fetching trading signals:", error);
    throw error;
  }
}
