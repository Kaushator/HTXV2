import { useState, useEffect } from 'react'

export interface MarketData {
  symbol: string
  price: number
  change24h: number
  volume: number
  lastUpdate: Date
}

export interface Portfolio {
  totalValue: number
  totalPnL: number
  positions: Array<{
    symbol: string
    quantity: number
    average_price: number
    current_price: number
    unrealized_pnl: number
    unrealized_pnl_percent: number
    market_value: number
  }>
}

export interface Order {
  id: string
  symbol: string
  side: 'buy' | 'sell'
  type: 'market' | 'limit'
  quantity: number
  price?: number
  status: 'pending' | 'filled' | 'cancelled' | 'rejected'
  created_at: string
}

export function useMarketData(symbol?: string) {
  const [data, setData] = useState<MarketData | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (!symbol) {
      setLoading(false)
      return
    }

    // Simulate market data fetch - in real implementation this would connect to the backend API
    const fetchMarketData = async () => {
      try {
        setLoading(true)
        setError(null)
        
        // Mock data for now
        await new Promise(resolve => setTimeout(resolve, 1000))
        
        setData({
          symbol,
          price: Math.random() * 50000,
          change24h: (Math.random() - 0.5) * 10,
          volume: Math.random() * 1000000,
          lastUpdate: new Date()
        })
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to fetch market data')
      } finally {
        setLoading(false)
      }
    }

    fetchMarketData()
  }, [symbol])

  return { data, loading, error }
}

export function usePortfolio() {
  const [portfolio, setPortfolio] = useState<Portfolio | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const fetchPortfolio = async () => {
      try {
        setLoading(true)
        setError(null)
        
        // Mock data for now
        await new Promise(resolve => setTimeout(resolve, 500))
        
        setPortfolio({
          totalValue: 10000 + Math.random() * 5000,
          totalPnL: (Math.random() - 0.5) * 2000,
          positions: [
            {
              symbol: 'BTCUSDT',
              quantity: 0.5,
              average_price: 45000,
              current_price: 50000,
              unrealized_pnl: 2500,
              unrealized_pnl_percent: 11.11,
              market_value: 25000
            },
            {
              symbol: 'ETHUSDT',
              quantity: 2.0,
              average_price: 1800,
              current_price: 2000,
              unrealized_pnl: 400,
              unrealized_pnl_percent: 11.11,
              market_value: 4000
            }
          ]
        })
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to fetch portfolio')
      } finally {
        setLoading(false)
      }
    }

    fetchPortfolio()
  }, [])

  return { portfolio, loading, error }
}

export function useActiveOrders() {
  const [orders, setOrders] = useState<Order[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const fetchOrders = async () => {
      try {
        setLoading(true)
        setError(null)
        
        // Mock data for now
        await new Promise(resolve => setTimeout(resolve, 300))
        
        setOrders([
          {
            id: '1',
            symbol: 'BTCUSDT',
            side: 'buy',
            type: 'limit',
            quantity: 0.1,
            price: 45000,
            status: 'pending',
            created_at: new Date().toISOString()
          },
          {
            id: '2',
            symbol: 'ETHUSDT',
            side: 'sell',
            type: 'market',
            quantity: 1.0,
            status: 'pending',
            created_at: new Date().toISOString()
          }
        ])
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to fetch orders')
      } finally {
        setLoading(false)
      }
    }

    fetchOrders()
  }, [])

  return { orders, loading, error }
}