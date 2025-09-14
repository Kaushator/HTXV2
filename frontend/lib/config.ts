// API Configuration for HTXV2 Frontend
// Central configuration for all API-related settings

export const API_CONFIG = {
  baseURL: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000/api/v1',
  timeout: parseInt(process.env.NEXT_PUBLIC_API_TIMEOUT || '30000'),
  retries: parseInt(process.env.NEXT_PUBLIC_API_RETRIES || '3'),
  retryDelay: parseInt(process.env.NEXT_PUBLIC_API_RETRY_DELAY || '1000'),
}

// WebSocket Configuration
export const WS_CONFIG = {
  url: process.env.NEXT_PUBLIC_WS_URL || 'ws://localhost:8000/ws',
  reconnectInterval: parseInt(process.env.NEXT_PUBLIC_WS_RECONNECT_INTERVAL || '5000'),
  maxReconnectAttempts: parseInt(process.env.NEXT_PUBLIC_WS_MAX_RECONNECT_ATTEMPTS || '10'),
}

// Feature Flags Configuration
export const FEATURE_FLAGS = {
  ENABLE_ADVANCED_TRADING: process.env.NEXT_PUBLIC_ENABLE_ADVANCED_TRADING === 'true',
  ENABLE_AI_ANALYSIS: process.env.NEXT_PUBLIC_ENABLE_AI_ANALYSIS === 'true',
  ENABLE_CHAT: process.env.NEXT_PUBLIC_ENABLE_CHAT === 'true',
  ENABLE_PWA: process.env.NEXT_PUBLIC_ENABLE_PWA === 'true',
  ENABLE_DEVTOOLS: process.env.NEXT_PUBLIC_ENABLE_DEVTOOLS === 'true',
  ENABLE_PERFORMANCE_MONITORING: process.env.NEXT_PUBLIC_ENABLE_PERFORMANCE_MONITORING === 'true',
  ENABLE_ERROR_TRACKING: process.env.NEXT_PUBLIC_ENABLE_ERROR_TRACKING === 'true',
}

// External Services Configuration
export const EXTERNAL_SERVICES = {
  coingecko: {
    baseURL: process.env.NEXT_PUBLIC_COINGECKO_API_URL || 'https://api.coingecko.com/api/v3',
  },
}

// Application Configuration
export const APP_CONFIG = {
  name: process.env.NEXT_PUBLIC_APP_NAME || 'HTXV2',
  version: process.env.NEXT_PUBLIC_APP_VERSION || '1.0.0',
  environment: process.env.NEXT_PUBLIC_ENVIRONMENT || 'development',
  isDevelopment: process.env.NEXT_PUBLIC_ENVIRONMENT === 'development',
  isProduction: process.env.NEXT_PUBLIC_ENVIRONMENT === 'production',
}

// Cache Configuration
export const CACHE_KEYS = {
  market_data: 'market_data',
  portfolio: 'portfolio',
  user_preferences: 'user_preferences',
  trading_pairs: 'trading_pairs',
}

// Default React Query Configuration
export const QUERY_CONFIG = {
  staleTime: 30000, // 30 seconds
  cacheTime: 300000, // 5 minutes
  retry: 3,
  refetchOnWindowFocus: false,
}

// Performance Monitoring Configuration
export const PERFORMANCE_CONFIG = {
  enabled: FEATURE_FLAGS.ENABLE_PERFORMANCE_MONITORING,
  sampleRate: 0.1, // 10% sampling
  trackUserActions: true,
  trackPageLoads: true,
  trackErrors: FEATURE_FLAGS.ENABLE_ERROR_TRACKING,
}

// Security Configuration
export const SECURITY_CONFIG = {
  csrfProtection: true,
  contentSecurityPolicy: true,
  secureCookies: APP_CONFIG.isProduction,
}