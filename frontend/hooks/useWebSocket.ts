// @cursor: КОНТЕКСТ: HTXV2 - криптотрейдинг платформа
// ТЕХНОЛОГИИ: TypeScript, WebSocket, React hooks для real-time данных
// ЦЕЛЬ: WebSocket хук с автореконнектом, обработкой ошибок и типизацией
// ПАТТЕРН: Переиспользуемый хук с состоянием подключения и подписками

import { useEffect, useRef, useState, useCallback } from 'react';

// Define types locally instead of importing from missing types file
interface WebSocketMessage {
  type: string;
  data?: any;
  timestamp?: string;
}

interface TickerMessage {
  symbol: string;
  price: number;
  change_24h: number;
  volume: number;
}

interface OrderBookUpdate {
  symbol: string;
  bids: [number, number][];
  asks: [number, number][];
  timestamp: string;
}

// WebSocket Configuration
const WS_CONFIG = {
  url: process.env.NEXT_PUBLIC_WS_URL || 'ws://localhost:8000/ws',
  reconnectInterval: 5000,
  maxReconnectAttempts: 10,
  heartbeatInterval: 30000, // 30 seconds
};

export type WebSocketStatus = 'connecting' | 'connected' | 'disconnected' | 'error';

interface UseWebSocketOptions {
  onConnect?: () => void;
  onDisconnect?: () => void;
  onError?: (error: Event) => void;
  onMessage?: (message: WebSocketMessage) => void;
  autoReconnect?: boolean;
}

export function useWebSocket(options: UseWebSocketOptions = {}) {
  const [status, setStatus] = useState<WebSocketStatus>('disconnected');
  const [lastMessage, setLastMessage] = useState<WebSocketMessage | null>(null);
  const [error, setError] = useState<string | null>(null);
  
  const wsRef = useRef<WebSocket | null>(null);
  const reconnectAttemptsRef = useRef(0);
  const reconnectTimeoutRef = useRef<NodeJS.Timeout | null>(null);
  const heartbeatTimeoutRef = useRef<NodeJS.Timeout | null>(null);
  const subscriptionsRef = useRef<Set<string>>(new Set());

  const { autoReconnect = true, onConnect, onDisconnect, onError, onMessage } = options;

  // Clear timeouts
  const clearTimeouts = useCallback(() => {
    if (reconnectTimeoutRef.current) {
      clearTimeout(reconnectTimeoutRef.current);
      reconnectTimeoutRef.current = null;
    }
    if (heartbeatTimeoutRef.current) {
      clearTimeout(heartbeatTimeoutRef.current);
      heartbeatTimeoutRef.current = null;
    }
  }, []);

  // Send heartbeat
  const sendHeartbeat = useCallback(() => {
    if (wsRef.current?.readyState === WebSocket.OPEN) {
      wsRef.current.send(JSON.stringify({ type: 'ping' }));
      heartbeatTimeoutRef.current = setTimeout(sendHeartbeat, WS_CONFIG.heartbeatInterval);
    }
  }, []);

  // Connect to WebSocket
  const connect = useCallback(() => {
    try {
      setStatus('connecting');
      setError(null);
      
      const ws = new WebSocket(WS_CONFIG.url);
      wsRef.current = ws;

      ws.onopen = () => {
        setStatus('connected');
        reconnectAttemptsRef.current = 0;
        onConnect?.();
        
        // Start heartbeat
        sendHeartbeat();
        
        // Resubscribe to channels
        subscriptionsRef.current.forEach(channel => {
          ws.send(JSON.stringify({ type: 'subscribe', channel }));
        });
      };

      ws.onmessage = (event) => {
        try {
          const message: WebSocketMessage = JSON.parse(event.data);
          setLastMessage(message);
          onMessage?.(message);
        } catch (parseError) {
          console.error('Failed to parse WebSocket message:', parseError);
        }
      };

      ws.onclose = () => {
        setStatus('disconnected');
        clearTimeouts();
        onDisconnect?.();
        
        // Auto-reconnect logic
        if (autoReconnect && reconnectAttemptsRef.current < WS_CONFIG.maxReconnectAttempts) {
          reconnectAttemptsRef.current++;
          const delay = Math.min(1000 * Math.pow(2, reconnectAttemptsRef.current), 30000);
          
          reconnectTimeoutRef.current = setTimeout(() => {
            connect();
          }, delay);
        }
      };

      ws.onerror = (errorEvent) => {
        setStatus('error');
        setError('WebSocket connection error');
        onError?.(errorEvent);
      };

    } catch (connectError) {
      setStatus('error');
      setError('Failed to create WebSocket connection');
      console.error('WebSocket connect error:', connectError);
    }
  }, [autoReconnect, onConnect, onDisconnect, onError, onMessage, sendHeartbeat, clearTimeouts]);

  // Disconnect from WebSocket
  const disconnect = useCallback(() => {
    clearTimeouts();
    if (wsRef.current) {
      wsRef.current.close();
      wsRef.current = null;
    }
    setStatus('disconnected');
  }, [clearTimeouts]);

  // Subscribe to channel
  const subscribe = useCallback((channel: string) => {
    subscriptionsRef.current.add(channel);
    
    if (wsRef.current?.readyState === WebSocket.OPEN) {
      wsRef.current.send(JSON.stringify({ type: 'subscribe', channel }));
    }
  }, []);

  // Unsubscribe from channel
  const unsubscribe = useCallback((channel: string) => {
    subscriptionsRef.current.delete(channel);
    
    if (wsRef.current?.readyState === WebSocket.OPEN) {
      wsRef.current.send(JSON.stringify({ type: 'unsubscribe', channel }));
    }
  }, []);

  // Send message
  const sendMessage = useCallback((message: any) => {
    if (wsRef.current?.readyState === WebSocket.OPEN) {
      wsRef.current.send(JSON.stringify(message));
    } else {
      console.warn('WebSocket is not connected');
    }
  }, []);

  // Cleanup on unmount
  useEffect(() => {
    return () => {
      clearTimeouts();
      if (wsRef.current) {
        wsRef.current.close();
      }
    };
  }, [clearTimeouts]);

  return {
    status,
    lastMessage,
    error,
    connect,
    disconnect,
    subscribe,
    unsubscribe,
    sendMessage,
    isConnected: status === 'connected',
  };
}

// Specialized hook for trading WebSocket
export function useTradingWebSocket() {
  const [tickers, setTickers] = useState<Record<string, TickerMessage>>({});
  const [orderBooks, setOrderBooks] = useState<Record<string, OrderBookUpdate>>({});

  const ws = useWebSocket({
    onMessage: (message) => {
      switch (message.type) {
        case 'ticker':
          const tickerData = message.data as TickerMessage;
          setTickers(prev => ({
            ...prev,
            [tickerData.symbol]: tickerData
          }));
          break;
          
        case 'orderbook':
          const orderbookData = message.data as OrderBookUpdate;
          setOrderBooks(prev => ({
            ...prev,
            [orderbookData.symbol]: orderbookData
          }));
          break;
      }
    },
    autoReconnect: true,
  });

  // Subscribe to ticker updates for symbol
  const subscribeToTicker = useCallback((symbol: string) => {
    ws.subscribe(`ticker.${symbol}`);
  }, [ws]);

  // Subscribe to orderbook updates for symbol
  const subscribeToOrderBook = useCallback((symbol: string) => {
    ws.subscribe(`orderbook.${symbol}`);
  }, [ws]);

  // Unsubscribe from ticker updates
  const unsubscribeFromTicker = useCallback((symbol: string) => {
    ws.unsubscribe(`ticker.${symbol}`);
  }, [ws]);

  // Unsubscribe from orderbook updates
  const unsubscribeFromOrderBook = useCallback((symbol: string) => {
    ws.unsubscribe(`orderbook.${symbol}`);
  }, [ws]);

  return {
    ...ws,
    tickers,
    orderBooks,
    subscribeToTicker,
    subscribeToOrderBook,
    unsubscribeFromTicker,
    unsubscribeFromOrderBook,
  };
}