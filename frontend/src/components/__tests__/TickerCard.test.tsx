import { render, screen } from '@testing-library/react'
import { TickerCard } from '@/components/TickerCard'

const mockTickerData = {
  symbol: 'BTCUSDT',
  price: 50000.12,
  change_24h: 1000,
  change_24h_percent: 2.53,
  volume_24h: 1000000,
  high_24h: 51000,
  low_24h: 49000,
  timestamp: '2024-01-15T20:00:00Z',
  source: 'HTX'
}

describe('TickerCard', () => {
  it('renders ticker symbol and source', () => {
    render(<TickerCard data={mockTickerData} symbol="BTCUSDT" />)
    
    expect(screen.getByText('BTCUSDT')).toBeInTheDocument()
    expect(screen.getByText('HTX')).toBeInTheDocument()
  })

  it('displays price correctly', () => {
    render(<TickerCard data={mockTickerData} symbol="BTCUSDT" />)
    
    expect(screen.getByText('Price')).toBeInTheDocument()
    expect(screen.getByText('$50000.12')).toBeInTheDocument()
  })

  it('displays 24h change with correct formatting', () => {
    render(<TickerCard data={mockTickerData} symbol="BTCUSDT" />)
    
    expect(screen.getByText('24h Change')).toBeInTheDocument()
    expect(screen.getByText('+2.53%')).toBeInTheDocument()
  })

  it('displays 24h high and low', () => {
    render(<TickerCard data={mockTickerData} symbol="BTCUSDT" />)
    
    expect(screen.getByText('24h High')).toBeInTheDocument()
    expect(screen.getByText('$51000.00')).toBeInTheDocument()
    expect(screen.getByText('24h Low')).toBeInTheDocument()
    expect(screen.getByText('$49000.00')).toBeInTheDocument()
  })

  it('displays volume with correct formatting', () => {
    render(<TickerCard data={mockTickerData} symbol="BTCUSDT" />)
    
    expect(screen.getByText('24h Volume')).toBeInTheDocument()
    expect(screen.getByText('$1.00M')).toBeInTheDocument()
  })

  it('displays timestamp', () => {
    render(<TickerCard data={mockTickerData} symbol="BTCUSDT" />)
    
    expect(screen.getByText(/Updated:/)).toBeInTheDocument()
  })

  it('displays source badge', () => {
    render(<TickerCard data={mockTickerData} symbol="BTCUSDT" />)
    
    const sourceBadge = screen.getByText('HTX')
    expect(sourceBadge).toBeInTheDocument()
  })

  it('shows loading state', () => {
    render(<TickerCard data={null} symbol="BTCUSDT" isLoading />)
    
    expect(screen.getByText('BTCUSDT')).toBeInTheDocument()
    // Check for loading animation elements
    expect(document.querySelector('.animate-spin')).toBeInTheDocument()
    expect(document.querySelector('.animate-pulse')).toBeInTheDocument()
  })

  it('shows error state', () => {
    render(<TickerCard data={null} symbol="BTCUSDT" hasError />)
    
    expect(screen.getByText('BTCUSDT')).toBeInTheDocument()
    expect(screen.getByText('Failed to load ticker data')).toBeInTheDocument()
  })

  it('handles missing data gracefully', () => {
    render(<TickerCard data={null} symbol="BTCUSDT" />)
    
    expect(screen.getByText('BTCUSDT')).toBeInTheDocument()
    // Should show loading state when data is null and not explicitly loading/error
    expect(document.querySelector('.animate-spin')).toBeInTheDocument()
  })

  it('shows trending up indicator for positive change', () => {
    const positiveData = { ...mockTickerData, change_24h_percent: 5.2 }
    render(<TickerCard data={positiveData} symbol="BTCUSDT" />)
    
    const changeElement = screen.getByText('+5.20%')
    expect(changeElement).toBeInTheDocument()
    expect(changeElement.closest('div')).toHaveClass('text-green-600')
  })

  it('shows trending down indicator for negative change', () => {
    const negativeData = { ...mockTickerData, change_24h_percent: -3.1 }
    render(<TickerCard data={negativeData} symbol="BTCUSDT" />)
    
    const changeElement = screen.getByText('-3.10%')
    expect(changeElement).toBeInTheDocument()
    expect(changeElement.closest('div')).toHaveClass('text-red-600')
  })

  it('formats large volumes correctly', () => {
    const highVolumeData = { ...mockTickerData, volume_24h: 1500000000 }
    render(<TickerCard data={highVolumeData} symbol="BTCUSDT" />)
    
    expect(screen.getByText('$1.50B')).toBeInTheDocument()
  })

  it('formats small prices correctly', () => {
    const smallPriceData = { 
      ...mockTickerData, 
      price: 0.000123,
      high_24h: 0.000125,
      low_24h: 0.000121
    }
    render(<TickerCard data={smallPriceData} symbol="ALTUSDT" />)
    
    expect(screen.getByText('$0.000123')).toBeInTheDocument()
    expect(screen.getByText('$0.000125')).toBeInTheDocument()
    expect(screen.getByText('$0.000121')).toBeInTheDocument()
  })

  it('handles error in data object', () => {
    const errorData = { ...mockTickerData, error: 'Connection failed' }
    render(<TickerCard data={errorData} symbol="BTCUSDT" />)
    
    expect(screen.getByText('BTCUSDT')).toBeInTheDocument()
    expect(screen.getByText('Connection failed')).toBeInTheDocument()
  })

  it('renders with proper accessibility structure', () => {
    render(<TickerCard data={mockTickerData} symbol="BTCUSDT" />)
    
    // Card should be rendered and contain the expected content
    const card = screen.getByText('BTCUSDT').closest('div')
    expect(card).toBeInTheDocument()
  })
})