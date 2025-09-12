// @cursor: КОНТЕКСТ: HTXV2 - криптотрейдинг платформа, FastAPI backend, Next.js frontend
// ЦЕЛЬ: TypeScript типы для API интеграции с backend
// ТЕХНОЛОГИИ: TypeScript, shadcn/ui, React Query, WebSocket, Zustand

// Base API Response Types
export interface ApiResponse<T> {
  data: T;
  success: boolean;
  message?: string;
  timestamp: string;
}

export interface ApiError {
  message: string;
  code: string;
  details?: Record<string, any>;
}

// Authentication Types
export interface LoginRequest {
  email: string;
  password: string;
}

export interface AuthTokens {
  access_token: string;
  refresh_token: string;
  token_type: string;
  expires_in: number;
}

export interface User {
  id: string;
  email: string;
  username: string;
  created_at: string;
  is_active: boolean;
}

// Market Data Types
export interface MarketData {
  symbol: string;
  price: number;
  change_24h: number;
  change_24h_percent: number;
  volume_24h: number;
  high_24h: number;
  low_24h: number;
  market_cap?: number;
  last_updated: string;
}

export interface TradingPair {
  symbol: string;
  base_currency: string;
  quote_currency: string;
  status: 'active' | 'inactive';
  min_order_size: number;
  max_order_size: number;
  price_precision: number;
  quantity_precision: number;
}

export interface PriceUpdate {
  symbol: string;
  price: number;
  timestamp: string;
  volume?: number;
}

// Trading Types
export interface Order {
  id: string;
  symbol: string;
  side: 'buy' | 'sell';
  type: 'market' | 'limit';
  quantity: number;
  price?: number;
  status: 'pending' | 'filled' | 'cancelled' | 'rejected';
  created_at: string;
  updated_at: string;
  filled_quantity: number;
  average_price?: number;
}

export interface Portfolio {
  total_value: number;
  total_pnl: number;
  total_pnl_percent: number;
  positions: Position[];
  last_updated: string;
}

export interface Position {
  symbol: string;
  quantity: number;
  average_price: number;
  current_price: number;
  unrealized_pnl: number;
  unrealized_pnl_percent: number;
  market_value: number;
}

// WebSocket Message Types
export interface WebSocketMessage<T = any> {
  type: string;
  channel: string;
  data: T;
  timestamp: string;
}

export interface TickerMessage {
  symbol: string;
  price: number;
  change: number;
  change_percent: number;
  volume: number;
}

export interface OrderBookUpdate {
  symbol: string;
  bids: [number, number][];
  asks: [number, number][];
  timestamp: string;
}

// File Upload Types
export interface FileUploadProgress {
  file_id: string;
  filename: string;
  progress: number;
  status: 'uploading' | 'processing' | 'completed' | 'error';
  error_message?: string;
}

export interface UploadedFile {
  id: string;
  filename: string;
  size: number;
  type: string;
  url: string;
  uploaded_at: string;
  processed_rows?: number;
}

// AI/ML Types
export interface TradingSignal {
  id: string;
  symbol: string;
  signal_type: 'buy' | 'sell' | 'hold';
  confidence: number;
  price_target?: number;
  stop_loss?: number;
  reasoning: string;
  generated_at: string;
  model_used: string;
}

export interface AnalysisRequest {
  symbol: string;
  timeframe: '1h' | '4h' | '1d' | '1w';
  analysis_type: 'technical' | 'sentiment' | 'comprehensive';
}

export interface AnalysisResult {
  symbol: string;
  analysis_type: string;
  summary: string;
  signals: TradingSignal[];
  confidence_score: number;
  generated_at: string;
}