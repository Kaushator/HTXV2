// Test setup file for Vitest
// Add global test utilities and mocks here

// Mock WebSocket for tests
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
  }

  close() {
    this.readyState = MockWebSocket.CLOSED
  }

  send(data: string) {
    // Mock implementation
  }
}

// Set global WebSocket mock
global.WebSocket = MockWebSocket as any
