// Market Data WebSocket Hook for HTXV2
// Connects to the new /api/v1/ws/market-data/{symbol} endpoint
// Provides real-time market data updates with authentication

import { useEffect, useRef, useState, useCallback } from 'react';
import { MarketDataUpdate } from '@/types/api';

const WS_BASE_URL = process.env.NEXT_PUBLIC_WS_URL || 'ws://localhost:8000/api/v1/ws';

export type ConnectionStatus = 'connecting' | 'connected' | 'disconnected' | 'error';

interface MarketDataMessage {
  type: 'market_data' | 'market_data_update' | 'price_history' | 'connection_established' | 'error' | 'ping' | 'pong';
  symbol?: string;
  price?: number;
  change_24h?: number;
  volume_24h?: number;
  high_24h?: number;
  low_24h?: number;
  timestamp?: string;
  message?: string;
  data?: any[];
}

interface UseMarketDataWebSocketOptions {
  symbol: string;
  token?: string;
  onConnect?: () => void;
  onDisconnect?: () => void;
  onError?: (error: string) => void;
  onMarketData?: (data: MarketDataMessage) => void;
  autoReconnect?: boolean;
}

export function useMarketDataWebSocket(options: UseMarketDataWebSocketOptions) {
  const {
    symbol,
    token,
    autoReconnect = true,
    onConnect,
    onDisconnect,
    onError,
    onMarketData
  } = options;

  const [status, setStatus] = useState<ConnectionStatus>('disconnected');
  const [lastMessage, setLastMessage] = useState<MarketDataMessage | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [marketData, setMarketData] = useState<MarketDataUpdate | null>(null);

  const wsRef = useRef<WebSocket | null>(null);
  const reconnectAttemptsRef = useRef(0);
  const reconnectTimeoutRef = useRef<NodeJS.Timeout | null>(null);
  const pingTimeoutRef = useRef<NodeJS.Timeout | null>(null);

  const maxReconnectAttempts = 5;
  const reconnectInterval = 3000;
  const pingInterval = 25000; // 25 seconds (server expects 30s timeout)

  // Clear timeouts
  const clearTimeouts = useCallback(() => {
    if (reconnectTimeoutRef.current) {
      clearTimeout(reconnectTimeoutRef.current);
      reconnectTimeoutRef.current = null;
    }
    if (pingTimeoutRef.current) {
      clearTimeout(pingTimeoutRef.current);
      pingTimeoutRef.current = null;
    }
  }, []);

  // Send ping to keep connection alive
  const sendPing = useCallback(() => {
    if (wsRef.current?.readyState === WebSocket.OPEN) {
      wsRef.current.send(JSON.stringify({ type: 'ping' }));
      pingTimeoutRef.current = setTimeout(sendPing, pingInterval);
    }
  }, []);

  // Connect to WebSocket
  const connect = useCallback(() => {
    if (!symbol) {
      setError('Symbol is required');
      return;
    }

    try {
      setStatus('connecting');
      setError(null);
      clearTimeouts();

      // Build WebSocket URL with symbol and optional token
      let wsUrl = `${WS_BASE_URL}/market-data/${symbol.toUpperCase()}`;
      if (token) {
        wsUrl += `?token=${encodeURIComponent(token)}`;
      }

      const ws = new WebSocket(wsUrl);
      wsRef.current = ws;

      ws.onopen = () => {
        console.log(`WebSocket connected to ${symbol} market data`);
        setStatus('connected');
        setError(null);
        reconnectAttemptsRef.current = 0;
        onConnect?.();
        
        // Start ping interval
        sendPing();
      };

      ws.onmessage = (event) => {
        try {
          const message: MarketDataMessage = JSON.parse(event.data);
          setLastMessage(message);

          // Handle different message types
          switch (message.type) {
            case 'market_data':
            case 'market_data_update':
              if (message.price !== undefined) {
                const marketUpdate: MarketDataUpdate = {
                  symbol: message.symbol || symbol,
                  price: message.price,
                  volume: message.volume_24h || 0,
                  change_24h: message.change_24h || 0,
                  timestamp: new Date(message.timestamp || Date.now())
                };
                setMarketData(marketUpdate);
                onMarketData?.(message);
              }
              break;
              
            case 'connection_established':
              console.log(`Connected to ${symbol} market data feed`);
              break;
              
            case 'error':
              const errorMsg = message.message || 'WebSocket error';
              setError(errorMsg);
              onError?.(errorMsg);
              break;
              
            case 'ping':
              // Respond to server ping
              ws.send(JSON.stringify({ type: 'pong' }));
              break;
              
            case 'pong':
              // Server acknowledged our ping
              break;
              
            default:
              console.log('Unknown message type:', message.type);
          }
        } catch (parseError) {
          console.error('Failed to parse WebSocket message:', parseError);
          setError('Failed to parse message');
        }
      };

      ws.onclose = (event) => {
        console.log(`WebSocket disconnected from ${symbol}:`, event.code, event.reason);
        setStatus('disconnected');
        clearTimeouts();
        onDisconnect?.();

        // Auto-reconnect logic
        if (autoReconnect && reconnectAttemptsRef.current < maxReconnectAttempts) {
          reconnectAttemptsRef.current++;
          console.log(`Reconnect attempt ${reconnectAttemptsRef.current}/${maxReconnectAttempts} in ${reconnectInterval}ms`);
          
          reconnectTimeoutRef.current = setTimeout(() => {
            connect();
          }, reconnectInterval);
        } else if (reconnectAttemptsRef.current >= maxReconnectAttempts) {
          setError('Max reconnection attempts reached');
          onError?.('Max reconnection attempts reached');
        }
      };

      ws.onerror = (event) => {
        console.error('WebSocket error:', event);
        setStatus('error');
        setError('Connection error');
        onError?.('Connection error');
      };

    } catch (err) {
      console.error('Failed to create WebSocket connection:', err);
      setStatus('error');
      setError('Failed to create connection');
      onError?.('Failed to create connection');
    }
  }, [symbol, token, autoReconnect, onConnect, onDisconnect, onError, onMarketData, sendPing, clearTimeouts]);

  // Disconnect from WebSocket
  const disconnect = useCallback(() => {
    clearTimeouts();
    if (wsRef.current) {
      wsRef.current.close();
      wsRef.current = null;
    }
    setStatus('disconnected');
  }, [clearTimeouts]);

  // Send message to WebSocket
  const sendMessage = useCallback((message: object) => {
    if (wsRef.current?.readyState === WebSocket.OPEN) {
      wsRef.current.send(JSON.stringify(message));
      return true;
    }
    return false;
  }, []);

  // Request price history
  const requestHistory = useCallback((timeframe: string = '1h') => {
    return sendMessage({
      type: 'request_history',
      timeframe
    });
  }, [sendMessage]);

  // Auto-connect and disconnect on mount/unmount
  useEffect(() => {
    connect();
    
    return () => {
      disconnect();
    };
  }, [connect, disconnect]);

  // Reconnect when symbol changes
  useEffect(() => {
    if (wsRef.current) {
      disconnect();
      // Small delay before reconnecting to new symbol
      setTimeout(connect, 100);
    }
  }, [symbol, token]);

  return {
    status,
    error,
    marketData,
    lastMessage,
    connect,
    disconnect,
    sendMessage,
    requestHistory,
    isConnected: status === 'connected',
    isConnecting: status === 'connecting',
    reconnectAttempts: reconnectAttemptsRef.current
  };
}