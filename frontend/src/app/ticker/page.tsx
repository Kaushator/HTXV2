'use client'

import { useState, useCallback, useMemo } from 'react'
import { useWebSocket } from '@/hooks/useWebSocket'
import { TickerCard } from '@/components/TickerCard'
import { WebSocketControls } from '@/components/WebSocketControls'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { ArrowLeft, Activity } from 'lucide-react'
import Link from 'next/link'

interface TickerData {
  symbol: string
  price: number
  change_24h: number
  change_24h_percent: number
  volume_24h: number
  high_24h: number
  low_24h: number
  timestamp: string
  source: string
  error?: string
}

export default function TickerPage() {
  const [symbols, setSymbols] = useState<string[]>(['BTC', 'ETH'])
  const [interval, setInterval] = useState(1000)
  const [tickerData, setTickerData] = useState<Record<string, TickerData>>({})
  const [isConnected, setIsConnected] = useState(false)

  // Construct WebSocket URL
  const wsUrl = useMemo(() => {
    if (!isConnected || symbols.length === 0) return null
    
    const baseUrl = process.env.NODE_ENV === 'development' 
      ? 'ws://localhost:8000' 
      : `ws://${window.location.host}`
    
    const params = new URLSearchParams({
      symbols: symbols.join(','),
      interval_ms: interval.toString()
    })
    
    return `${baseUrl}/ws/ticker?${params}`
  }, [isConnected, symbols, interval])

  // Handle WebSocket messages
  const handleMessage = useCallback((data: any) => {
    if (data.type === 'ticker_batch' && data.data) {
      setTickerData(prevData => ({
        ...prevData,
        ...data.data
      }))
    }
  }, [])

  // Handle WebSocket connection events
  const handleConnect = useCallback(() => {
    console.log('WebSocket connected')
  }, [])

  const handleDisconnect = useCallback(() => {
    console.log('WebSocket disconnected')
  }, [])

  const handleError = useCallback((error: Event) => {
    console.error('WebSocket error:', error)
  }, [])

  // Use WebSocket hook
  const {
    status,
    lastMessage,
    sendMessage,
    connect,
    disconnect,
    isConnected: wsConnected,
    isConnecting,
    hasError,
    reconnectAttemptsLeft,
    nextReconnectIn
  } = useWebSocket(wsUrl, {
    onMessage: handleMessage,
    onConnect: handleConnect,
    onDisconnect: handleDisconnect,
    onError: handleError,
    reconnectAttempts: 5,
    reconnectInterval: 3000,
    maxReconnectInterval: 30000,
    reconnectDecay: 1.5
  })

  // Control handlers
  const handleConnectToggle = useCallback(() => {
    if (wsConnected) {
      disconnect()
    } else {
      setIsConnected(true)
      // The WebSocket will connect automatically when wsUrl changes
    }
  }, [wsConnected, disconnect])

  const handleDisconnectToggle = useCallback(() => {
    setIsConnected(false)
    disconnect()
  }, [disconnect])

  const handleSymbolsChange = useCallback((newSymbols: string[]) => {
    setSymbols(newSymbols)
    // Clear ticker data for removed symbols
    setTickerData(prevData => {
      const filteredData: Record<string, TickerData> = {}
      newSymbols.forEach(symbol => {
        if (prevData[symbol]) {
          filteredData[symbol] = prevData[symbol]
        }
      })
      return filteredData
    })
  }, [])

  const handleIntervalChange = useCallback((newInterval: number) => {
    setInterval(newInterval)
  }, [])

  return (
    <div className="min-h-screen bg-gradient-to-b from-blue-50 to-white dark:from-gray-900 dark:to-gray-800">
      <div className="container mx-auto px-4 py-8">
        {/* Header */}
        <div className="mb-8">
          <div className="flex items-center gap-4 mb-4">
            <Button variant="outline" size="sm" asChild>
              <Link href="/">
                <ArrowLeft className="h-4 w-4 mr-2" />
                Back to Home
              </Link>
            </Button>
          </div>
          
          <div className="text-center">
            <h1 className="text-4xl font-bold text-gray-900 dark:text-white mb-2 flex items-center justify-center gap-3">
              <Activity className="h-10 w-10 text-blue-600" />
              Real-Time Ticker
            </h1>
            <p className="text-lg text-gray-600 dark:text-gray-300">
              Live cryptocurrency prices via WebSocket
            </p>
          </div>
        </div>

        {/* Main Content */}
        <div className="grid grid-cols-1 lg:grid-cols-4 gap-6">
          {/* WebSocket Controls */}
          <div className="lg:col-span-1">
            <WebSocketControls
              status={status}
              isConnected={wsConnected}
              isConnecting={isConnecting}
              reconnectAttemptsLeft={reconnectAttemptsLeft}
              nextReconnectIn={nextReconnectIn}
              symbols={symbols}
              interval={interval}
              onConnect={handleConnectToggle}
              onDisconnect={handleDisconnectToggle}
              onSymbolsChange={handleSymbolsChange}
              onIntervalChange={handleIntervalChange}
            />
            
            {/* Connection Statistics */}
            <Card className="mt-4">
              <CardHeader>
                <CardTitle className="text-sm">Statistics</CardTitle>
              </CardHeader>
              <CardContent className="text-sm space-y-1">
                <div className="flex justify-between">
                  <span>Status:</span>
                  <span className={
                    wsConnected ? 'text-green-600' : 
                    isConnecting ? 'text-yellow-600' : 
                    'text-red-600'
                  }>
                    {status}
                  </span>
                </div>
                <div className="flex justify-between">
                  <span>Symbols:</span>
                  <span>{symbols.length}</span>
                </div>
                <div className="flex justify-between">
                  <span>Updates:</span>
                  <span>Every {interval}ms</span>
                </div>
                <div className="flex justify-between">
                  <span>Data Points:</span>
                  <span>{Object.keys(tickerData).length}</span>
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Ticker Cards */}
          <div className="lg:col-span-3">
            {symbols.length === 0 ? (
              <Card>
                <CardContent className="text-center py-12">
                  <Activity className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                  <h3 className="text-lg font-semibold text-gray-600 mb-2">
                    No Symbols Selected
                  </h3>
                  <p className="text-gray-500">
                    Add cryptocurrency symbols to start tracking real-time prices
                  </p>
                </CardContent>
              </Card>
            ) : (
              <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
                {symbols.map((symbol) => (
                  <TickerCard
                    key={symbol}
                    symbol={symbol}
                    data={tickerData[symbol] || null}
                    isLoading={wsConnected && !tickerData[symbol]}
                    hasError={tickerData[symbol]?.error !== undefined}
                  />
                ))}
              </div>
            )}
          </div>
        </div>

        {/* Instructions */}
        <Card className="mt-8">
          <CardHeader>
            <CardTitle className="text-lg">How to Use</CardTitle>
          </CardHeader>
          <CardContent className="space-y-2 text-sm text-gray-600 dark:text-gray-300">
            <div className="flex items-start gap-2">
              <span className="font-semibold text-blue-600 min-w-[20px]">1.</span>
              <span>Add cryptocurrency symbols (e.g., BTC, ETH, DOGE) using the input field</span>
            </div>
            <div className="flex items-start gap-2">
              <span className="font-semibold text-blue-600 min-w-[20px]">2.</span>
              <span>Adjust the update interval (200ms - 10000ms) in the settings</span>
            </div>
            <div className="flex items-start gap-2">
              <span className="font-semibold text-blue-600 min-w-[20px]">3.</span>
              <span>Click "Connect" to start receiving real-time price updates</span>
            </div>
            <div className="flex items-start gap-2">
              <span className="font-semibold text-blue-600 min-w-[20px]">4.</span>
              <span>Watch the price cards update with live data from HTX exchange</span>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}
