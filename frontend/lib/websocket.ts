// Enhanced WebSocket client for HTXV2 with auto-reconnection and monitoring
// Uses configuration from lib/config.ts

import { WS_CONFIG, PERFORMANCE_CONFIG, APP_CONFIG } from './config'
import { trackError, trackCustomMetric } from './performance'

export type ConnectionStatus = 'connecting' | 'connected' | 'disconnected' | 'error' | 'reconnecting'

interface WebSocketMessage {
  type: string
  data?: any
  timestamp?: string
}

interface WebSocketOptions {
  autoReconnect?: boolean
  maxReconnectAttempts?: number
  reconnectInterval?: number
  protocols?: string[]
}

class WebSocketClient {
  private ws: WebSocket | null = null
  private url: string
  private options: WebSocketOptions
  private status: ConnectionStatus = 'disconnected'
  private reconnectAttempts = 0
  private reconnectTimer: NodeJS.Timeout | null = null
  private heartbeatTimer: NodeJS.Timeout | null = null
  private subscriptions = new Map<string, Set<Function>>()
  private messageQueue: WebSocketMessage[] = []

  // Event handlers
  private onStatusChange?: (status: ConnectionStatus) => void
  private onMessage?: (message: WebSocketMessage) => void
  private onError?: (error: Event) => void

  constructor(
    url?: string,
    options: WebSocketOptions = {},
    handlers: {
      onStatusChange?: (status: ConnectionStatus) => void
      onMessage?: (message: WebSocketMessage) => void
      onError?: (error: Event) => void
    } = {}
  ) {
    this.url = url || WS_CONFIG.url
    this.options = {
      autoReconnect: true,
      maxReconnectAttempts: WS_CONFIG.maxReconnectAttempts,
      reconnectInterval: WS_CONFIG.reconnectInterval,
      ...options,
    }
    
    this.onStatusChange = handlers.onStatusChange
    this.onMessage = handlers.onMessage
    this.onError = handlers.onError
  }

  connect(): void {
    if (this.ws?.readyState === WebSocket.OPEN) {
      return
    }

    this.setStatus('connecting')
    
    try {
      this.ws = new WebSocket(this.url, this.options.protocols)
      this.setupEventHandlers()
      
      // Track connection attempt
      if (PERFORMANCE_CONFIG.enabled) {
        trackCustomMetric('websocket_connection_attempt', 1, {
          url: this.url,
          attempt: this.reconnectAttempts + 1,
        })
      }
    } catch (error) {
      this.handleError(error as Event)
    }
  }

  private setupEventHandlers(): void {
    if (!this.ws) return

    this.ws.onopen = (event) => {
      this.setStatus('connected')
      this.reconnectAttempts = 0
      this.startHeartbeat()
      this.flushMessageQueue()
      
      if (PERFORMANCE_CONFIG.enabled) {
        trackCustomMetric('websocket_connected', 1, {
          url: this.url,
          reconnectAttempts: this.reconnectAttempts,
        })
      }
    }

    this.ws.onmessage = (event) => {
      try {
        const message: WebSocketMessage = JSON.parse(event.data)
        this.handleMessage(message)
      } catch (error) {
        console.warn('Failed to parse WebSocket message:', event.data)
      }
    }

    this.ws.onclose = (event) => {
      this.setStatus('disconnected')
      this.stopHeartbeat()
      
      if (PERFORMANCE_CONFIG.enabled) {
        trackCustomMetric('websocket_disconnected', 1, {
          url: this.url,
          code: event.code,
          reason: event.reason,
          wasClean: event.wasClean,
        })
      }

      // Auto-reconnect if enabled and not manually closed
      if (this.options.autoReconnect && event.code !== 1000) {
        this.scheduleReconnect()
      }
    }

    this.ws.onerror = (event) => {
      this.handleError(event)
    }
  }

  private handleMessage(message: WebSocketMessage): void {
    // Handle ping/pong for heartbeat
    if (message.type === 'ping') {
      this.send({ type: 'pong' })
      return
    }

    // Notify global message handler
    if (this.onMessage) {
      this.onMessage(message)
    }

    // Notify specific subscriptions
    const handlers = this.subscriptions.get(message.type)
    if (handlers) {
      handlers.forEach(handler => {
        try {
          handler(message)
        } catch (error) {
          console.error('Error in message handler:', error)
        }
      })
    }
  }

  private handleError(event: Event): void {
    this.setStatus('error')
    
    if (PERFORMANCE_CONFIG.trackErrors) {
      trackError(new Error('WebSocket error'), {
        url: this.url,
        readyState: this.ws?.readyState,
        event: event.type,
      })
    }

    if (this.onError) {
      this.onError(event)
    }
  }

  private setStatus(status: ConnectionStatus): void {
    if (this.status !== status) {
      this.status = status
      if (this.onStatusChange) {
        this.onStatusChange(status)
      }
    }
  }

  private scheduleReconnect(): void {
    if (
      this.reconnectAttempts >= (this.options.maxReconnectAttempts || 0) ||
      this.reconnectTimer
    ) {
      return
    }

    this.setStatus('reconnecting')
    
    const delay = Math.min(
      this.options.reconnectInterval! * Math.pow(1.5, this.reconnectAttempts),
      30000 // Max 30 seconds
    )

    this.reconnectTimer = setTimeout(() => {
      this.reconnectTimer = null
      this.reconnectAttempts++
      this.connect()
    }, delay)
  }

  private startHeartbeat(): void {
    this.stopHeartbeat()
    
    // Send ping every 30 seconds
    this.heartbeatTimer = setInterval(() => {
      if (this.ws?.readyState === WebSocket.OPEN) {
        this.send({ type: 'ping', timestamp: new Date().toISOString() })
      }
    }, 30000)
  }

  private stopHeartbeat(): void {
    if (this.heartbeatTimer) {
      clearInterval(this.heartbeatTimer)
      this.heartbeatTimer = null
    }
  }

  private flushMessageQueue(): void {
    while (this.messageQueue.length > 0) {
      const message = this.messageQueue.shift()!
      this.send(message)
    }
  }

  send(message: WebSocketMessage): void {
    if (this.ws?.readyState === WebSocket.OPEN) {
      try {
        this.ws.send(JSON.stringify(message))
      } catch (error) {
        console.error('Failed to send WebSocket message:', error)
      }
    } else {
      // Queue message for later
      this.messageQueue.push(message)
    }
  }

  subscribe(messageType: string, handler: Function): () => void {
    if (!this.subscriptions.has(messageType)) {
      this.subscriptions.set(messageType, new Set())
    }
    
    this.subscriptions.get(messageType)!.add(handler)
    
    // Return unsubscribe function
    return () => {
      const handlers = this.subscriptions.get(messageType)
      if (handlers) {
        handlers.delete(handler)
        if (handlers.size === 0) {
          this.subscriptions.delete(messageType)
        }
      }
    }
  }

  unsubscribe(messageType: string, handler?: Function): void {
    if (handler) {
      const handlers = this.subscriptions.get(messageType)
      if (handlers) {
        handlers.delete(handler)
        if (handlers.size === 0) {
          this.subscriptions.delete(messageType)
        }
      }
    } else {
      this.subscriptions.delete(messageType)
    }
  }

  disconnect(): void {
    this.options.autoReconnect = false
    
    if (this.reconnectTimer) {
      clearTimeout(this.reconnectTimer)
      this.reconnectTimer = null
    }
    
    this.stopHeartbeat()
    
    if (this.ws) {
      this.ws.close(1000, 'Manual disconnect')
      this.ws = null
    }
    
    this.setStatus('disconnected')
  }

  getStatus(): ConnectionStatus {
    return this.status
  }

  isConnected(): boolean {
    return this.status === 'connected'
  }

  getReconnectAttempts(): number {
    return this.reconnectAttempts
  }

  // Update URL for reconnection
  setURL(url: string): void {
    this.url = url
  }
}

// Create singleton instance for market data
export const marketDataWS = new WebSocketClient()

// Export the class for custom instances
export { WebSocketClient }