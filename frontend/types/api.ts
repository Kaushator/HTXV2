// API Response Types
export interface ApiResponse<T = any> {
  data: T;
  status: number;
  message?: string;
}

// Market Data Types
export interface MarketData {
  symbol: string;
  price: number;
  change: number;
  changePercent: number;
  volume: number;
  high24h: number;
  low24h: number;
  timestamp: string;
}

export interface TradingPair {
  symbol: string;
  baseAsset: string;
  quoteAsset: string;
  status: string;
  minPrice: number;
  maxPrice: number;
  tickSize: number;
  minQty: number;
  maxQty: number;
}

export interface OrderBookData {
  symbol: string;
  bids: [number, number][];
  asks: [number, number][];
  timestamp: string;
}

export interface PriceHistory {
  timestamp: string;
  open: number;
  high: number;
  low: number;
  close: number;
  volume: number;
}

// Trading Types
export interface Order {
  id: string;
  symbol: string;
  side: 'buy' | 'sell';
  type: 'market' | 'limit' | 'stop';
  quantity: number;
  price?: number;
  stopPrice?: number;
  status: 'active' | 'filled' | 'cancelled' | 'rejected';
  createdAt: string;
  updatedAt: string;
}

export interface Portfolio {
  totalValue: number;
  totalPnL: number;
  totalPnLPercent: number;
  balances: PortfolioBalance[];
  positions: Position[];
}

export interface PortfolioBalance {
  asset: string;
  free: number;
  locked: number;
  total: number;
  usdValue: number;
}

export interface Position {
  symbol: string;
  size: number;
  entryPrice: number;
  currentPrice: number;
  unrealizedPnL: number;
  unrealizedPnLPercent: number;
  side: 'long' | 'short';
}

// WebSocket Types
export interface WebSocketMessage {
  type: 'market_data' | 'order_update' | 'portfolio_update' | 'error';
  data: any;
  timestamp: string;
}

// File Upload Types
export interface FileUploadProgress {
  fileName: string;
  progress: number;
  status: 'uploading' | 'processing' | 'completed' | 'error';
  error?: string;
}

export interface FileUploadResult {
  fileName: string;
  recordsProcessed: number;
  errors: string[];
  preview: any[];
}