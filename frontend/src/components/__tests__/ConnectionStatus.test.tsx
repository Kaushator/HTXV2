import { render, screen, fireEvent } from '@testing-library/react'
import { vi } from 'vitest'
import { ConnectionStatus } from '@/components/ConnectionStatus'

describe('ConnectionStatus', () => {
  const defaultProps = {
    status: 'disconnected' as const,
    reconnectAttemptsLeft: 0,
    nextReconnectIn: 0,
    onManualReconnect: vi.fn()
  }

  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('renders disconnected status correctly', () => {
    render(<ConnectionStatus {...defaultProps} status="disconnected" />)
    
    expect(screen.getByText('Отключен')).toBeInTheDocument()
    expect(screen.getByText('Переподключиться')).toBeInTheDocument()
  })

  it('renders connecting status correctly', () => {
    render(<ConnectionStatus {...defaultProps} status="connecting" />)
    
    expect(screen.getByText('Подключение...')).toBeInTheDocument()
  })

  it('renders connected status correctly', () => {
    render(<ConnectionStatus {...defaultProps} status="connected" />)
    
    expect(screen.getByText('Подключен')).toBeInTheDocument()
  })

  it('renders error status correctly', () => {
    render(<ConnectionStatus {...defaultProps} status="error" />)
    
    expect(screen.getByText('Ошибка')).toBeInTheDocument()
    expect(screen.getByText('Переподключиться')).toBeInTheDocument()
  })

  it('renders reconnecting status with attempts left', () => {
    render(
      <ConnectionStatus 
        {...defaultProps} 
        status="reconnecting" 
        reconnectAttemptsLeft={3}
      />
    )
    
    expect(screen.getByText('Переподключение...')).toBeInTheDocument()
    expect(screen.getByText('(осталось попыток: 3)')).toBeInTheDocument()
  })

  it('renders next reconnect countdown', () => {
    render(
      <ConnectionStatus 
        {...defaultProps} 
        status="reconnecting" 
        nextReconnectIn={5}
      />
    )
    
    expect(screen.getByText('(через 5с)')).toBeInTheDocument()
  })

  it('shows manual reconnect button for disconnected status', () => {
    render(<ConnectionStatus {...defaultProps} status="disconnected" />)
    
    const button = screen.getByText('Переподключиться')
    expect(button).toBeInTheDocument()
    expect(button.tagName).toBe('BUTTON')
  })

  it('shows manual reconnect button for error status', () => {
    render(<ConnectionStatus {...defaultProps} status="error" />)
    
    const button = screen.getByText('Переподключиться')
    expect(button).toBeInTheDocument()
    expect(button.tagName).toBe('BUTTON')
  })

  it('does not show manual reconnect button for connected status', () => {
    render(<ConnectionStatus {...defaultProps} status="connected" />)
    
    expect(screen.queryByText('Переподключиться')).not.toBeInTheDocument()
  })

  it('does not show manual reconnect button for connecting status', () => {
    render(<ConnectionStatus {...defaultProps} status="connecting" />)
    
    expect(screen.queryByText('Переподключиться')).not.toBeInTheDocument()
  })

  it('does not show manual reconnect button for reconnecting status', () => {
    render(<ConnectionStatus {...defaultProps} status="reconnecting" />)
    
    expect(screen.queryByText('Переподключиться')).not.toBeInTheDocument()
  })

  it('calls onManualReconnect when button is clicked', () => {
    const onManualReconnect = vi.fn()
    render(
      <ConnectionStatus 
        {...defaultProps} 
        status="disconnected" 
        onManualReconnect={onManualReconnect}
      />
    )
    
    const button = screen.getByText('Переподключиться')
    fireEvent.click(button)
    
    expect(onManualReconnect).toHaveBeenCalledTimes(1)
  })

  it('applies correct badge variants for different statuses', () => {
    const { rerender } = render(<ConnectionStatus {...defaultProps} status="connected" />)
    const badge = screen.getByText('Подключен').closest('.bg-green-500')
    expect(badge).toBeInTheDocument()

    rerender(<ConnectionStatus {...defaultProps} status="disconnected" />)
    const disconnectedBadge = screen.getByText('Отключен').closest('.bg-gray-500')
    expect(disconnectedBadge).toBeInTheDocument()

    rerender(<ConnectionStatus {...defaultProps} status="connecting" />)
    const connectingBadge = screen.getByText('Подключение...').closest('.bg-yellow-500')
    expect(connectingBadge).toBeInTheDocument()

    rerender(<ConnectionStatus {...defaultProps} status="error" />)
    const errorBadge = screen.getByText('Ошибка').closest('.bg-red-500')
    expect(errorBadge).toBeInTheDocument()

    rerender(<ConnectionStatus {...defaultProps} status="reconnecting" />)
    const reconnectingBadge = screen.getByText('Переподключение...').closest('.bg-orange-500')
    expect(reconnectingBadge).toBeInTheDocument()
  })

  it('displays correct icons for each status', () => {
    const { rerender } = render(<ConnectionStatus {...defaultProps} status="connected" />)
    expect(screen.getByTestId('connection-status-icon')).toBeInTheDocument()

    rerender(<ConnectionStatus {...defaultProps} status="disconnected" />)
    expect(screen.getByTestId('connection-status-icon')).toBeInTheDocument()

    rerender(<ConnectionStatus {...defaultProps} status="connecting" />)
    expect(screen.getByTestId('connection-status-icon')).toBeInTheDocument()

    rerender(<ConnectionStatus {...defaultProps} status="error" />)
    expect(screen.getByTestId('connection-status-icon')).toBeInTheDocument()

    rerender(<ConnectionStatus {...defaultProps} status="reconnecting" />)
    expect(screen.getByTestId('connection-status-icon')).toBeInTheDocument()
  })

  it('handles edge case with zero attempts left', () => {
    render(
      <ConnectionStatus 
        {...defaultProps} 
        status="reconnecting" 
        reconnectAttemptsLeft={0}
      />
    )
    
    expect(screen.getByText('Переподключение...')).toBeInTheDocument()
    expect(screen.queryByText('(осталось попыток: 0)')).not.toBeInTheDocument()
  })

  it('handles edge case with negative countdown', () => {
    render(
      <ConnectionStatus 
        {...defaultProps} 
        status="reconnecting" 
        nextReconnectIn={-1}
      />
    )
    
    expect(screen.getByText('Переподключение...')).toBeInTheDocument()
    expect(screen.queryByText('(через -1с)')).not.toBeInTheDocument()
  })

  it('shows both attempts and countdown when both are positive', () => {
    render(
      <ConnectionStatus 
        {...defaultProps} 
        status="reconnecting" 
        reconnectAttemptsLeft={2}
        nextReconnectIn={10}
      />
    )
    
    expect(screen.getByText('Переподключение...')).toBeInTheDocument()
    expect(screen.getByText('(осталось попыток: 2)')).toBeInTheDocument()
    expect(screen.getByText('(через 10с)')).toBeInTheDocument()
  })
})
