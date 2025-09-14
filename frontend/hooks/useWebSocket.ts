'use client';

import { useEffect, useRef, useState, useCallback } from 'react';
import type { WebSocketMessage } from '@/types/api';

interface WebSocketHookOptions {
  url?: string;
  autoConnect?: boolean;
  reconnectInterval?: number;
  maxReconnectAttempts?: number;
}

export function useTradingWebSocket(options: WebSocketHookOptions = {}) {
  const {
    url = 'ws://localhost:8000/api/v1/mcp/ws',
    autoConnect = true,
    reconnectInterval = 3000,
    maxReconnectAttempts = 5
  } = options;

  const [isConnected, setIsConnected] = useState(false);
  const [lastMessage, setLastMessage] = useState<WebSocketMessage | null>(null);
  const [connectionStatus, setConnectionStatus] = useState<'connecting' | 'connected' | 'disconnected' | 'error'>('disconnected');

  const ws = useRef<WebSocket | null>(null);
  const reconnectAttempts = useRef(0);
  const reconnectTimer = useRef<NodeJS.Timeout>();

  const connect = useCallback(() => {
    if (ws.current?.readyState === WebSocket.OPEN) {
      return;
    }

    setConnectionStatus('connecting');
    
    try {
      ws.current = new WebSocket(url);
      
      ws.current.onopen = () => {
        setIsConnected(true);
        setConnectionStatus('connected');
        reconnectAttempts.current = 0;
        console.log('WebSocket connected');
      };

      ws.current.onmessage = (event) => {
        try {
          const message: WebSocketMessage = JSON.parse(event.data);
          setLastMessage(message);
        } catch (error) {
          console.error('Failed to parse WebSocket message:', error);
        }
      };

      ws.current.onclose = () => {
        setIsConnected(false);
        setConnectionStatus('disconnected');
        console.log('WebSocket disconnected');
        
        // Auto-reconnect
        if (reconnectAttempts.current < maxReconnectAttempts) {
          reconnectAttempts.current++;
          reconnectTimer.current = setTimeout(() => {
            connect();
          }, reconnectInterval);
        }
      };

      ws.current.onerror = (error) => {
        setConnectionStatus('error');
        console.error('WebSocket error:', error);
      };
    } catch (error) {
      setConnectionStatus('error');
      console.error('Failed to create WebSocket connection:', error);
    }
  }, [url, reconnectInterval, maxReconnectAttempts]);

  const disconnect = useCallback(() => {
    if (reconnectTimer.current) {
      clearTimeout(reconnectTimer.current);
    }
    
    if (ws.current) {
      ws.current.close();
      ws.current = null;
    }
    
    setIsConnected(false);
    setConnectionStatus('disconnected');
  }, []);

  const sendMessage = useCallback((message: any) => {
    if (ws.current?.readyState === WebSocket.OPEN) {
      ws.current.send(JSON.stringify(message));
      return true;
    }
    return false;
  }, []);

  useEffect(() => {
    if (autoConnect) {
      connect();
    }

    return () => {
      disconnect();
    };
  }, [autoConnect, connect, disconnect]);

  return {
    isConnected,
    connectionStatus,
    lastMessage,
    connect,
    disconnect,
    sendMessage
  };
}
