import { renderHook } from '@testing-library/react'
import { act } from '@testing-library/react'
import { vi } from 'vitest'
import { useWebSocket } from '@/hooks/useWebSocket'

// Mock WebSocket
class MockWebSocket {
  url: string
  readyState: number = WebSocket.CONNECTING
  onopen: ((event: Event) => void) | null = null
  onclose: ((event: CloseEvent) => void) | null = null
  onmessage: ((event: MessageEvent) => void) | null = null
  onerror: ((event: Event) => void) | null = null

  constructor(url: string) {
    this.url = url
    // Simulate async connection
    setTimeout(() => {
      this.readyState = WebSocket.OPEN
      if (this.onopen) {
        this.onopen(new Event('open'))
      }
    }, 0)
  }

  send(data: string) {
    // Mock send method
  }

  close(code?: number, reason?: string) {
    this.readyState = WebSocket.CLOSED
    if (this.onclose) {
      this.onclose(new CloseEvent('close', { code, reason }))
    }
  }

  static CONNECTING = 0
  static OPEN = 1
  static CLOSING = 2
  static CLOSED = 3
}

// Mock global WebSocket
Object.defineProperty(window, 'WebSocket', {
  writable: true,
  value: MockWebSocket
})

describe('useWebSocket', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    vi.useFakeTimers()
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  it('initializes with disconnected status when no URL provided', () => {
    const { result } = renderHook(() => useWebSocket(null))

    expect(result.current.status).toBe('disconnected')
    expect(result.current.lastMessage).toBe(null)
    expect(result.current.isConnected).toBe(false)
    expect(result.current.isConnecting).toBe(false)
    expect(result.current.hasError).toBe(false)
  })

  it('returns enhanced interface with new properties', () => {
    const { result } = renderHook(() => useWebSocket('ws://localhost:8080'))

    expect(result.current).toHaveProperty('status')
    expect(result.current).toHaveProperty('lastMessage')
    expect(result.current).toHaveProperty('sendMessage')
    expect(result.current).toHaveProperty('connect')
    expect(result.current).toHaveProperty('disconnect')
    expect(result.current).toHaveProperty('reconnectAttemptsLeft')
    expect(result.current).toHaveProperty('isConnecting')
    expect(result.current).toHaveProperty('isConnected')
    expect(result.current).toHaveProperty('hasError')
    expect(result.current).toHaveProperty('nextReconnectIn')
  })

  it('starts in connecting status when URL is provided', () => {
    const { result } = renderHook(() => useWebSocket('ws://localhost:8080'))

    expect(result.current.status).toBe('connecting')
    expect(result.current.isConnecting).toBe(true)
    expect(result.current.isConnected).toBe(false)
  })

  it('provides sendMessage function that handles no connection gracefully', () => {
    const { result } = renderHook(() => useWebSocket(null))

    expect(typeof result.current.sendMessage).toBe('function')
    
    // Should not throw when calling sendMessage without connection
    expect(() => result.current.sendMessage('test')).not.toThrow()
  })

  it('handles exponential backoff configuration', () => {
    const { result } = renderHook(() => 
      useWebSocket('ws://localhost:8080', {
        reconnectAttempts: 3,
        reconnectInterval: 1000,
        maxReconnectInterval: 5000,
        reconnectDecay: 2.0
      })
    )

    expect(result.current.status).toBe('connecting')
    expect(result.current.reconnectAttemptsLeft).toBe(3)
  })

  it('accepts shouldReconnect callback option', () => {
    const shouldReconnect = vi.fn(() => false)
    
    const { result } = renderHook(() => 
      useWebSocket('ws://localhost:8080', {
        shouldReconnect
      })
    )

    expect(result.current.status).toBe('connecting')
  })

  it('provides connect and disconnect methods', () => {
    const { result } = renderHook(() => useWebSocket('ws://localhost:8080'))

    expect(typeof result.current.connect).toBe('function')
    expect(typeof result.current.disconnect).toBe('function')
    
    // Should not throw when calling methods
    act(() => {
      result.current.disconnect()
    })
    
    act(() => {
      result.current.connect()
    })
  })

  it('handles manual disconnect properly', () => {
    const { result } = renderHook(() => useWebSocket(null))

    // First connect
    act(() => {
      result.current.connect()
    })
    
    // Then disconnect
    act(() => {
      result.current.disconnect()
    })
    
    expect(result.current.status).toBe('disconnected')
    expect(result.current.isConnecting).toBe(false)
    expect(result.current.isConnected).toBe(false)
  })

  it('tracks reconnection attempts', () => {
    const { result } = renderHook(() => 
      useWebSocket('ws://localhost:8080', {
        reconnectAttempts: 5
      })
    )

    expect(result.current.reconnectAttemptsLeft).toBe(5)
  })

  it('can be unmounted without errors', () => {
    const { unmount } = renderHook(() => useWebSocket('ws://localhost:8080'))

    expect(() => unmount()).not.toThrow()
  })

  it('handles URL changes', () => {
    const { result, rerender } = renderHook(
      ({ url }) => useWebSocket(url),
      { initialProps: { url: 'ws://localhost:8080' as string | null } }
    )

    expect(result.current.status).toBe('connecting')

    // Change URL to null
    rerender({ url: null })
    expect(result.current.status).toBe('disconnected')
    
    // Change URL back
    rerender({ url: 'ws://localhost:8081' })
    expect(result.current.status).toBe('connecting')
  })

  it('provides proper status indicators', () => {
    const { result } = renderHook(() => useWebSocket('ws://localhost:8080'))

    // Initially connecting
    expect(result.current.isConnecting).toBe(true)
    expect(result.current.isConnected).toBe(false)
    expect(result.current.hasError).toBe(false)
  })
})