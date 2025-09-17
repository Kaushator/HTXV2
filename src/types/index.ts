/**
 * Определения типов для MCP сервера
 */

import { WebSocket } from "ws";

export interface MarketDataParams {
  symbol?: string;
  timeframe?: string;
}

export interface PortfolioParams {
  includeHistory?: boolean;
}

export interface TradingSignalParams {
  symbol?: string;
  timeframe?: string;
  source?: string[];
}

export interface MarketData {
  symbol: string;
  price: number;
  change24h: string | number;
  volume24h: number;
  timestamp: number;
}

export interface PortfolioData {
  totalValue: number;
  assets: PortfolioAsset[];
  pnl24h: string | number;
  timestamp: number;
}

export interface PortfolioAsset {
  symbol: string;
  amount: number;
  valueUSD: number;
}

export interface TradingSignal {
  symbol: string;
  type: "BUY" | "SELL" | "HOLD";
  confidence: number;
  source: string;
}

export interface TradingSignalsData {
  signals: TradingSignal[];
  timestamp: number;
}

export interface WebSocketMessage {
  type: string;
  [key: string]: any;
}

export interface QueryMessage extends WebSocketMessage {
  resource: string;
  params?: any;
}

export interface ResponseMessage extends WebSocketMessage {
  resource: string;
  data: any;
}

export interface ErrorMessage extends WebSocketMessage {
  message: string;
}

export interface ClientConnection {
  ws: WebSocket;
  id: string;
  connectedAt: number;
}

export interface Resource {
  name: string;
  description: string;
  params?: string[];
}
