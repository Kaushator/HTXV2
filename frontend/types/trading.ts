// Trading related types for HTXV2 frontend
export interface MarketData {
  symbol: string;
  price: number;
  change: number;
  changePercent: number;
  volume: number;
  high24h: number;
  low24h: number;
  lastUpdate: string;
}

export interface Order {
  id: string;
  symbol: string;
  side: 'buy' | 'sell';
  type: 'market' | 'limit' | 'stop';
  amount: number;
  price?: number;
  status: 'pending' | 'filled' | 'cancelled' | 'partially_filled';
  createdAt: string;
  updatedAt: string;
}

export interface Position {
  id: string;
  symbol: string;
  side: 'long' | 'short';
  size: number;
  entryPrice: number;
  currentPrice: number;
  pnl: number;
  pnlPercent: number;
  unrealizedPnl: number;
  createdAt: string;
}

export interface Portfolio {
  totalBalance: number;
  availableBalance: number;
  totalPnl: number;
  totalPnlPercent: number;
  positions: Position[];
  orders: Order[];
  assets: Record<string, number>;
}

// WebSocket message types
export interface WebSocketMessage<T = any> {
  type: string;
  data: T;
  timestamp: string;
}

export interface MarketDataUpdate extends WebSocketMessage<MarketData> {
  type: 'market_data';
}

export interface OrderUpdate extends WebSocketMessage<Order> {
  type: 'order_update';
}

export interface BalanceUpdate extends WebSocketMessage<Portfolio> {
  type: 'balance_update';
}

// AI/ML types
export interface AISignal {
  id: string;
  symbol: string;
  signal: 'buy' | 'sell' | 'hold';
  confidence: number; // 0-100
  reasoning: string;
  model: 'fingpt' | 'openai' | 'vertex';
  timeframe: '1m' | '5m' | '15m' | '1h' | '4h' | '1d';
  createdAt: string;
  expiresAt: string;
}

export interface AIAnalysisRequest {
  symbol: string;
  timeframe: string;
  model?: string;
  indicators?: string[];
}

export interface AIAnalysisResponse {
  signal: AISignal;
  technicalAnalysis: {
    indicators: Record<string, number>;
    support: number;
    resistance: number;
    trend: 'bullish' | 'bearish' | 'neutral';
  };
  marketSentiment: {
    score: number; // -100 to 100
    keywords: string[];
    newsCount: number;
  };
}

// File upload types
export interface UploadFile {
  id: string;
  name: string;
  size: number;
  type: string;
  status: 'pending' | 'uploading' | 'processing' | 'completed' | 'error';
  progress: number;
  url?: string;
  error?: string;
  createdAt: string;
}

export interface FileValidationResult {
  isValid: boolean;
  errors: string[];
  warnings: string[];
  rowCount: number;
  columnCount: number;
  preview: any[];
}

// UI component types
export interface TableColumn<T> {
  key: keyof T;
  label: string;
  sortable?: boolean;
  render?: (value: any, item: T) => React.ReactNode;
  width?: string;
}

export interface ChartDataPoint {
  timestamp: number;
  open: number;
  high: number;
  low: number;
  close: number;
  volume: number;
}

export interface TechnicalIndicator {
  name: string;
  value: number;
  signal: 'buy' | 'sell' | 'neutral';
  description: string;
}

// Store types
export interface TradingStore {
  // Market data
  marketData: Record<string, MarketData>;
  subscribedSymbols: string[];
  
  // Portfolio
  portfolio: Portfolio | null;
  
  // Orders
  orders: Order[];
  positions: Position[];
  
  // UI state
  selectedSymbol: string;
  selectedTimeframe: string;
  isConnected: boolean;
  
  // Actions
  updateMarketData: (symbol: string, data: MarketData) => void;
  addOrder: (order: Order) => void;
  updateOrder: (id: string, update: Partial<Order>) => void;
  setSelectedSymbol: (symbol: string) => void;
  setConnectionStatus: (status: boolean) => void;
}

export interface UIStore {
  theme: 'light' | 'dark' | 'system';
  sidebarOpen: boolean;
  notifications: Notification[];
  modals: Record<string, boolean>;
  
  setTheme: (theme: 'light' | 'dark' | 'system') => void;
  toggleSidebar: () => void;
  addNotification: (notification: Notification) => void;
  removeNotification: (id: string) => void;
  openModal: (name: string) => void;
  closeModal: (name: string) => void;
}

export interface Notification {
  id: string;
  type: 'success' | 'error' | 'warning' | 'info';
  title: string;
  message: string;
  duration?: number;
  createdAt: string;
}