import { useEffect, useRef, useState, useCallback } from 'react'

export type WebSocketStatus = 'connecting' | 'connected' | 'disconnected' | 'error' | 'reconnecting'

interface UseWebSocketOptions {
  onMessage?: (data: any) => void
  onError?: (error: Event) => void
  onConnect?: () => void
  onDisconnect?: () => void
  reconnectAttempts?: number
  reconnectInterval?: number
  maxReconnectInterval?: number
  reconnectDecay?: number
  shouldReconnect?: (closeEvent: CloseEvent) => boolean
}

interface UseWebSocketReturn {
  status: WebSocketStatus
  lastMessage: any
  sendMessage: (message: string) => void
  connect: () => void
  disconnect: () => void
  reconnectAttemptsLeft: number
  isConnecting: boolean
  isConnected: boolean
  hasError: boolean
  nextReconnectIn?: number
}

export function useWebSocket(url: string | null, options: UseWebSocketOptions = {}): UseWebSocketReturn {
  const [status, setStatus] = useState<WebSocketStatus>('disconnected')
  const [lastMessage, setLastMessage] = useState<any>(null)
  const [nextReconnectIn, setNextReconnectIn] = useState<number | undefined>()
  const wsRef = useRef<WebSocket | null>(null)
  const reconnectTimeoutRef = useRef<NodeJS.Timeout | null>(null)
  const reconnectAttemptsRef = useRef(0)
  const urlRef = useRef(url)
  const currentReconnectIntervalRef = useRef(0)
  const countdownIntervalRef = useRef<NodeJS.Timeout | null>(null)

  const {
    onMessage,
    onError,
    onConnect,
    onDisconnect,
    reconnectAttempts = 5,
    reconnectInterval = 1000,
    maxReconnectInterval = 30000,
    reconnectDecay = 1.5,
    shouldReconnect = () => true
  } = options

  // Update url ref when url changes
  useEffect(() => {
    urlRef.current = url
  }, [url])

  const clearReconnectCountdown = useCallback(() => {
    if (countdownIntervalRef.current) {
      clearInterval(countdownIntervalRef.current)
      countdownIntervalRef.current = null
    }
    setNextReconnectIn(undefined)
  }, [])

  const startReconnectCountdown = useCallback((totalTime: number) => {
    clearReconnectCountdown()
    
    let timeLeft = Math.ceil(totalTime / 1000)
    setNextReconnectIn(timeLeft)
    
    countdownIntervalRef.current = setInterval(() => {
      timeLeft -= 1
      setNextReconnectIn(timeLeft)
      
      if (timeLeft <= 0) {
        clearReconnectCountdown()
      }
    }, 1000)
  }, [clearReconnectCountdown])

  const calculateReconnectInterval = useCallback(() => {
    const interval = Math.min(
      reconnectInterval * Math.pow(reconnectDecay, reconnectAttemptsRef.current),
      maxReconnectInterval
    )
    currentReconnectIntervalRef.current = interval
    return interval
  }, [reconnectInterval, reconnectDecay, maxReconnectInterval])

  const connect = useCallback(() => {
    if (!urlRef.current || wsRef.current?.readyState === WebSocket.OPEN) {
      return
    }

    if (reconnectTimeoutRef.current) {
      clearTimeout(reconnectTimeoutRef.current)
      reconnectTimeoutRef.current = null
    }

    clearReconnectCountdown()
    setStatus(reconnectAttemptsRef.current > 0 ? 'reconnecting' : 'connecting')

    try {
      wsRef.current = new WebSocket(urlRef.current)

      wsRef.current.onopen = () => {
        setStatus('connected')
        reconnectAttemptsRef.current = 0 // Reset attempts on successful connection
        currentReconnectIntervalRef.current = 0
        clearReconnectCountdown()
        onConnect?.()
      }

      wsRef.current.onmessage = (event) => {
        try {
          const data = JSON.parse(event.data)
          setLastMessage(data)
          onMessage?.(data)
        } catch (error) {
          console.error('Failed to parse WebSocket message:', error)
          setLastMessage(event.data) // Fallback to raw data
          onMessage?.(event.data)
        }
      }

      wsRef.current.onclose = (event) => {
        const shouldAttemptReconnect = 
          shouldReconnect(event) && 
          reconnectAttemptsRef.current < reconnectAttempts &&
          urlRef.current // Only reconnect if URL is still available

        if (shouldAttemptReconnect) {
          setStatus('reconnecting')
          reconnectAttemptsRef.current++
          const interval = calculateReconnectInterval()
          
          startReconnectCountdown(interval)
          
          reconnectTimeoutRef.current = setTimeout(() => {
            connect()
          }, interval)
        } else {
          setStatus('disconnected')
          clearReconnectCountdown()
        }
        
        onDisconnect?.()
      }

      wsRef.current.onerror = (error) => {
        setStatus('error')
        onError?.(error)
        console.error('WebSocket error:', error)
      }
    } catch (error) {
      setStatus('error')
      console.error('Failed to create WebSocket connection:', error)
    }
  }, [onMessage, onError, onConnect, onDisconnect, reconnectAttempts, shouldReconnect, calculateReconnectInterval, startReconnectCountdown, clearReconnectCountdown])

  const disconnect = useCallback(() => {
    if (reconnectTimeoutRef.current) {
      clearTimeout(reconnectTimeoutRef.current)
      reconnectTimeoutRef.current = null
    }
    
    clearReconnectCountdown()
    
    if (wsRef.current) {
      wsRef.current.close(1000, 'Manual disconnect') // Clean close
      wsRef.current = null
    }
    
    setStatus('disconnected')
    reconnectAttemptsRef.current = 0
    currentReconnectIntervalRef.current = 0
  }, [clearReconnectCountdown])

  const sendMessage = useCallback((message: string) => {
    if (wsRef.current?.readyState === WebSocket.OPEN) {
      wsRef.current.send(message)
    } else {
      console.warn('WebSocket is not connected. Message not sent:', message)
    }
  }, [])

  useEffect(() => {
    if (url) {
      connect()
    } else {
      disconnect()
    }

    return () => {
      disconnect()
    }
  }, [url, connect, disconnect])

  // Cleanup on unmount
  useEffect(() => {
    return () => {
      if (reconnectTimeoutRef.current) {
        clearTimeout(reconnectTimeoutRef.current)
      }
      clearReconnectCountdown()
    }
  }, [clearReconnectCountdown])

  // Computed values for convenience
  const reconnectAttemptsLeft = Math.max(0, reconnectAttempts - reconnectAttemptsRef.current)
  const isConnecting = status === 'connecting' || status === 'reconnecting'
  const isConnected = status === 'connected'
  const hasError = status === 'error'

  return {
    status,
    lastMessage,
    sendMessage,
    connect,
    disconnect,
    reconnectAttemptsLeft,
    isConnecting,
    isConnected,
    hasError,
    nextReconnectIn
  }
}
