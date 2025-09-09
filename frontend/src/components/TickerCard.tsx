import { useState, useEffect } from 'react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { TrendingUp, TrendingDown, Minus, Wifi, WifiOff, Loader2, AlertCircle } from 'lucide-react'

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

interface TickerCardProps {
  data: TickerData | null
  symbol: string
  isLoading?: boolean
  hasError?: boolean
}

export function TickerCard({ data, symbol, isLoading, hasError }: TickerCardProps) {
  const [prevPrice, setPrevPrice] = useState<number | null>(null)
  const [priceDirection, setPriceDirection] = useState<'up' | 'down' | 'same'>('same')

  useEffect(() => {
    if (data?.price && prevPrice !== null) {
      if (data.price > prevPrice) {
        setPriceDirection('up')
      } else if (data.price < prevPrice) {
        setPriceDirection('down')
      } else {
        setPriceDirection('same')
      }
    }
    if (data?.price) {
      setPrevPrice(data.price)
    }
  }, [data?.price, prevPrice])

  const formatPrice = (price: number) => {
    if (price < 1) {
      return price.toFixed(6)
    } else if (price < 100) {
      return price.toFixed(4)
    } else {
      return price.toFixed(2)
    }
  }

  const formatVolume = (volume: number) => {
    if (volume >= 1e9) {
      return `${(volume / 1e9).toFixed(2)}B`
    } else if (volume >= 1e6) {
      return `${(volume / 1e6).toFixed(2)}M`
    } else if (volume >= 1e3) {
      return `${(volume / 1e3).toFixed(2)}K`
    }
    return volume.toFixed(2)
  }

  const getTrendIcon = () => {
    if (!data?.change_24h_percent) return <Minus className="h-4 w-4" />
    return data.change_24h_percent > 0 ? 
      <TrendingUp className="h-4 w-4" /> : 
      <TrendingDown className="h-4 w-4" />
  }

  const getTrendColor = () => {
    if (!data?.change_24h_percent) return 'text-gray-500'
    return data.change_24h_percent > 0 ? 'text-green-600' : 'text-red-600'
  }

  const getPriceColor = () => {
    switch (priceDirection) {
      case 'up': return 'text-green-600'
      case 'down': return 'text-red-600'
      default: return 'text-gray-900 dark:text-gray-100'
    }
  }

  if (hasError || data?.error) {
    return (
      <Card className="border-red-200 bg-red-50 dark:border-red-800 dark:bg-red-950">
        <CardHeader className="pb-3">
          <CardTitle className="flex items-center gap-2 text-red-700 dark:text-red-300">
            <AlertCircle className="h-5 w-5" />
            {symbol}
          </CardTitle>
        </CardHeader>
        <CardContent>
          <p className="text-sm text-red-600 dark:text-red-400">
            {data?.error || 'Failed to load ticker data'}
          </p>
        </CardContent>
      </Card>
    )
  }

  if (isLoading || !data) {
    return (
      <Card className="border-gray-200 bg-gray-50 dark:border-gray-700 dark:bg-gray-800">
        <CardHeader className="pb-3">
          <CardTitle className="flex items-center gap-2">
            <Loader2 className="h-5 w-5 animate-spin" />
            {symbol}
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-2">
            <div className="h-6 bg-gray-200 dark:bg-gray-700 rounded animate-pulse" />
            <div className="h-4 bg-gray-200 dark:bg-gray-700 rounded animate-pulse w-2/3" />
            <div className="h-4 bg-gray-200 dark:bg-gray-700 rounded animate-pulse w-1/2" />
          </div>
        </CardContent>
      </Card>
    )
  }

  return (
    <Card className="transition-all duration-200 hover:shadow-md">
      <CardHeader className="pb-3">
        <CardTitle className="flex items-center justify-between">
          <span className="font-bold text-lg">{symbol}</span>
          <Badge variant="outline" className="text-xs">
            {data.source}
          </Badge>
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-3">
        {/* Current Price */}
        <div className="flex items-center justify-between">
          <span className="text-sm font-medium text-gray-500">Price</span>
          <span className={`text-xl font-bold transition-colors duration-200 ${getPriceColor()}`}>
            ${formatPrice(data.price)}
          </span>
        </div>

        {/* 24h Change */}
        <div className="flex items-center justify-between">
          <span className="text-sm font-medium text-gray-500">24h Change</span>
          <div className={`flex items-center gap-1 ${getTrendColor()}`}>
            {getTrendIcon()}
            <span className="font-semibold">
              {data.change_24h_percent > 0 ? '+' : ''}{data.change_24h_percent.toFixed(2)}%
            </span>
          </div>
        </div>

        {/* 24h High/Low */}
        <div className="grid grid-cols-2 gap-4 text-sm">
          <div>
            <span className="text-gray-500">24h High</span>
            <div className="font-semibold">${formatPrice(data.high_24h)}</div>
          </div>
          <div>
            <span className="text-gray-500">24h Low</span>
            <div className="font-semibold">${formatPrice(data.low_24h)}</div>
          </div>
        </div>

        {/* Volume */}
        <div className="flex items-center justify-between">
          <span className="text-sm font-medium text-gray-500">24h Volume</span>
          <span className="font-semibold">${formatVolume(data.volume_24h)}</span>
        </div>

        {/* Last Updated */}
        <div className="text-xs text-gray-400 pt-2 border-t">
          Updated: {new Date(data.timestamp).toLocaleTimeString()}
        </div>
      </CardContent>
    </Card>
  )
}
