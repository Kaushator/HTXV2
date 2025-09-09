"use client";

import React, { useState, useEffect, useCallback, useRef } from 'react';
import { Card } from '@/components/ui/card';

interface TickerData {
  symbol: string;
  price: number;
  change_24h: number;
  volume_24h: number;
  timestamp: string;
  source: string;
}

interface TickerDisplayProps {
  symbols?: string[];
  autoConnect?: boolean;
  wsUrl?: string;
}

export const TickerDisplay: React.FC<TickerDisplayProps> = ({
  symbols = ['BTC', 'ETH'],
  autoConnect = true,
  wsUrl = 'ws://localhost:8000/api/v1/ws/ticker'
}) => {
  const [tickerData, setTickerData] = useState<Record<string, TickerData>>({});
  const [connectionStatus, setConnectionStatus] = useState<'connecting' | 'connected' | 'disconnected' | 'error'>('disconnected');
  const [error, setError] = useState<string | null>(null);
  const wsRef = useRef<WebSocket | null>(null);
  const reconnectTimeoutRef = useRef<NodeJS.Timeout | null>(null);
  const [reconnectAttempts, setReconnectAttempts] = useState(0);

  const connect = useCallback(() => {
    if (wsRef.current?.readyState === WebSocket.OPEN) {
      return;
    }

    setConnectionStatus('connecting');
    setError(null);

    try {
      const ws = new WebSocket(wsUrl);
      wsRef.current = ws;

      ws.onopen = () => {
        setConnectionStatus('connected');
        setReconnectAttempts(0);
        console.log('WebSocket connected');
      };

      ws.onmessage = (event) => {
        try {
          const data = JSON.parse(event.data);
          
          if (data.type === 'pong') {
            return; // Handle pong response
          }
          
          // Handle single ticker data
          if (data.symbol) {
            setTickerData(prev => ({
              ...prev,
              [data.symbol]: data
            }));
          } else {
            // Handle multiple ticker data
            setTickerData(data);
          }
        } catch (err) {
          console.error('Error parsing WebSocket message:', err);
        }
      };

      ws.onclose = (event) => {
        setConnectionStatus('disconnected');
        console.log('WebSocket disconnected:', event.code, event.reason);
        
        // Attempt to reconnect if not manually closed
        if (event.code !== 1000 && reconnectAttempts < 5) {
          setReconnectAttempts(prev => prev + 1);
          reconnectTimeoutRef.current = setTimeout(() => {
            connect();
          }, Math.pow(2, reconnectAttempts) * 1000); // Exponential backoff
        }
      };

      ws.onerror = (error) => {
        setConnectionStatus('error');
        setError('WebSocket connection failed');
        console.error('WebSocket error:', error);
      };

    } catch (err) {
      setError('Failed to create WebSocket connection');
      setConnectionStatus('error');
    }
  }, [wsUrl, reconnectAttempts]);

  const disconnect = useCallback(() => {
    if (reconnectTimeoutRef.current) {
      clearTimeout(reconnectTimeoutRef.current);
    }
    if (wsRef.current) {
      wsRef.current.close(1000, 'Manual disconnect');
      wsRef.current = null;
    }
    setConnectionStatus('disconnected');
  }, []);

  const sendPing = useCallback(() => {
    if (wsRef.current?.readyState === WebSocket.OPEN) {
      wsRef.current.send(JSON.stringify({ type: 'ping' }));
    }
  }, []);

  useEffect(() => {
    if (autoConnect) {
      connect();
    }

    // Ping every 30 seconds to keep connection alive
    const pingInterval = setInterval(sendPing, 30000);

    return () => {
      clearInterval(pingInterval);
      if (reconnectTimeoutRef.current) {
        clearTimeout(reconnectTimeoutRef.current);
      }
      disconnect();
    };
  }, [autoConnect, connect, disconnect, sendPing]);

  const formatPrice = (price: number): string => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      minimumFractionDigits: 2,
      maximumFractionDigits: 8
    }).format(price);
  };

  const formatChange = (change: number): string => {
    const sign = change >= 0 ? '+' : '';
    return `${sign}${change.toFixed(2)}%`;
  };

  const formatVolume = (volume: number): string => {
    if (volume >= 1000000) {
      return `${(volume / 1000000).toFixed(1)}M`;
    } else if (volume >= 1000) {
      return `${(volume / 1000).toFixed(1)}K`;
    }
    return volume.toString();
  };

  const getChangeColorClass = (change: number): string => {
    return change >= 0 ? 'text-green-600' : 'text-red-600';
  };

  const getStatusIndicator = () => {
    switch (connectionStatus) {
      case 'connected':
        return <div className="w-3 h-3 bg-green-500 rounded-full animate-pulse"></div>;
      case 'connecting':
        return <div className="w-3 h-3 bg-yellow-500 rounded-full animate-pulse"></div>;
      case 'error':
        return <div className="w-3 h-3 bg-red-500 rounded-full"></div>;
      default:
        return <div className="w-3 h-3 bg-gray-400 rounded-full"></div>;
    }
  };

  return (
    <div className="space-y-4">
      {/* Connection Status */}
      <div className="flex items-center justify-between mb-4">
        <h2 className="text-2xl font-bold">Real-time Tickers</h2>
        <div className="flex items-center space-x-2">
          {getStatusIndicator()}
          <span className="text-sm text-gray-600 capitalize">{connectionStatus}</span>
          {connectionStatus === 'disconnected' && (
            <button
              onClick={connect}
              className="px-3 py-1 text-sm bg-blue-500 text-white rounded hover:bg-blue-600"
            >
              Reconnect
            </button>
          )}
        </div>
      </div>

      {/* Error Display */}
      {error && (
        <div className="p-4 bg-red-100 border border-red-400 text-red-700 rounded">
          {error}
        </div>
      )}

      {/* Ticker Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {symbols.map((symbol) => {
          const ticker = tickerData[symbol];
          
          return (
            <Card key={symbol} className="p-6">
              <div className="flex items-center justify-between mb-2">
                <h3 className="text-lg font-semibold">{symbol}</h3>
                {ticker && (
                  <span className="text-xs text-gray-500">
                    {new Date(ticker.timestamp).toLocaleTimeString()}
                  </span>
                )}
              </div>
              
              {ticker ? (
                <div className="space-y-2">
                  <div className="text-2xl font-bold">
                    {formatPrice(ticker.price)}
                  </div>
                  <div className={`text-sm font-medium ${getChangeColorClass(ticker.change_24h)}`}>
                    {formatChange(ticker.change_24h)}
                  </div>
                  <div className="text-sm text-gray-600">
                    Volume: {formatVolume(ticker.volume_24h)}
                  </div>
                  <div className="text-xs text-gray-400">
                    Source: {ticker.source}
                  </div>
                </div>
              ) : (
                <div className="space-y-2">
                  <div className="text-gray-400">Waiting for data...</div>
                  <div className="animate-pulse bg-gray-200 h-8 rounded"></div>
                  <div className="animate-pulse bg-gray-200 h-4 rounded"></div>
                </div>
              )}
            </Card>
          );
        })}
      </div>

      {/* Debug Info (only in development) */}
      {process.env.NODE_ENV === 'development' && (
        <details className="mt-4">
          <summary className="text-sm text-gray-600 cursor-pointer">Debug Info</summary>
          <pre className="mt-2 text-xs bg-gray-100 p-2 rounded overflow-auto">
            {JSON.stringify({ connectionStatus, tickerData, reconnectAttempts }, null, 2)}
          </pre>
        </details>
      )}
    </div>
  );
};