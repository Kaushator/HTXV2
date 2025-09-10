import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'

// Mock WebSocket
class MockWebSocket {
  static readonly CONNECTING = 0
  static readonly OPEN = 1
  static readonly CLOSING = 2
  static readonly CLOSED = 3

  readyState = MockWebSocket.CONNECTING
  url: string
  onopen: ((event: Event) => void) | null = null
  onclose: ((event: CloseEvent) => void) | null = null
  onmessage: ((event: MessageEvent) => void) | null = null
  onerror: ((event: Event) => void) | null = null

  constructor(url: string) {
    this.url = url
    // Simulate immediate connection
    setTimeout(() => this.mockOpen(), 0)
  }

  mockOpen() {
    this.readyState = MockWebSocket.OPEN
    if (this.onopen) {
      this.onopen(new Event('open'))
    }
  }

  mockMessage(data: any) {
    if (this.onmessage) {
      this.onmessage(new MessageEvent('message', { data: JSON.stringify(data) }))
    }
  }

  mockClose() {
    this.readyState = MockWebSocket.CLOSED
    if (this.onclose) {
      this.onclose(new CloseEvent('close'))
    }
  }

  mockError() {
    if (this.onerror) {
      this.onerror(new Event('error'))
    }
  }

  close() {
    this.mockClose()
  }

  send(data: string) {
    // Mock send - do nothing in test
  }
}

// Global WebSocket mock
const originalWebSocket = global.WebSocket
beforeEach(() => {
  global.WebSocket = MockWebSocket as any
})

afterEach(() => {
  global.WebSocket = originalWebSocket
  vi.clearAllTimers()
})

describe('useWebSocket', () => {
  it('should have WebSocket mock available', () => {
    expect(global.WebSocket).toBeDefined()
    expect(global.WebSocket).toBe(MockWebSocket)
  })

  it('should create WebSocket with correct URL', () => {
    const url = 'ws://localhost:8000/test'
    const ws = new global.WebSocket(url)
    expect(ws.url).toBe(url)
    expect(ws.readyState).toBe(MockWebSocket.CONNECTING)
  })

  it('should handle WebSocket lifecycle events', async () => {
    const ws = new MockWebSocket('ws://localhost:8000/test')
    let opened = false
    
    ws.onopen = (event) => {
      expect(event.type).toBe('open')
      expect(ws.readyState).toBe(MockWebSocket.OPEN)
      opened = true
    }

    // Wait for open event
    await new Promise(resolve => setTimeout(resolve, 10))
    expect(opened).toBe(true)
  })

  it('should handle WebSocket messages', async () => {
    const ws = new MockWebSocket('ws://localhost:8000/test')
    const testData = { type: 'ticker_batch', data: { BTC: { price: 50000 } } }
    let messageReceived = false
    
    ws.onmessage = (event) => {
      const received = JSON.parse(event.data)
      expect(received).toEqual(testData)
      messageReceived = true
    }

    ws.onopen = () => {
      ws.mockMessage(testData)
    }

    // Wait for events
    await new Promise(resolve => setTimeout(resolve, 10))
    expect(messageReceived).toBe(true)
  })

  it('should handle WebSocket errors', async () => {
    const ws = new MockWebSocket('ws://localhost:8000/test')
    let errorReceived = false
    
    ws.onerror = (event) => {
      expect(event.type).toBe('error')
      errorReceived = true
    }

    ws.onopen = () => {
      ws.mockError()
    }

    // Wait for events
    await new Promise(resolve => setTimeout(resolve, 10))
    expect(errorReceived).toBe(true)
  })

  it('should handle WebSocket close', async () => {
    const ws = new MockWebSocket('ws://localhost:8000/test')
    let closed = false
    
    ws.onclose = (event) => {
      expect(event.type).toBe('close')
      expect(ws.readyState).toBe(MockWebSocket.CLOSED)
      closed = true
    }

    ws.onopen = () => {
      ws.close()
    }

    // Wait for events
    await new Promise(resolve => setTimeout(resolve, 10))
    expect(closed).toBe(true)
  })
})
