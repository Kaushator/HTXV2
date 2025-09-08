'use client'

import { useState, useEffect } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"

interface Coin {
  symbol: string
  name: string
  source: string
}

interface Analysis {
  symbol: string
  analysis: string
  confidence: number
  signals: Array<{
    type: string
    value: string
    confidence: number
  }>
  timestamp: string
}

export default function HomePage() {
  const [coins, setCoins] = useState<Coin[]>([])
  const [selectedCoin, setSelectedCoin] = useState<string>('')
  const [analysis, setAnalysis] = useState<Analysis | null>(null)
  const [loading, setLoading] = useState(false)
  const [apiStatus, setApiStatus] = useState<string>('checking...')

  useEffect(() => {
    // Проверяем статус API
    checkApiHealth()
    // Загружаем список монет
    fetchCoins()
  }, [])

  const checkApiHealth = async () => {
    try {
      const response = await fetch('/api/health')
      if (response.ok) {
        setApiStatus('connected')
      } else {
        setApiStatus('error')
      }
    } catch (error) {
      setApiStatus('disconnected')
    }
  }

  const fetchCoins = async () => {
    try {
      const response = await fetch('/api/coins')
      if (response.ok) {
        const data = await response.json()
        setCoins(data.coins)
      }
    } catch (error) {
      console.error('Error fetching coins:', error)
    }
  }

  const fetchAnalysis = async (symbol: string) => {
    setLoading(true)
    try {
      const response = await fetch(`/api/analysis/${symbol}`)
      if (response.ok) {
        const data = await response.json()
        setAnalysis(data)
      }
    } catch (error) {
      console.error('Error fetching analysis:', error)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen bg-gradient-to-b from-blue-50 to-white dark:from-gray-900 dark:to-gray-800">
      <div className="container mx-auto px-4 py-8">
        {/* Header */}
        <div className="text-center mb-8">
          <h1 className="text-4xl font-bold text-gray-900 dark:text-white mb-2">
            HTX Interface v2
          </h1>
          <p className="text-lg text-gray-600 dark:text-gray-300">
            Cryptocurrency Trading Platform with ML Analytics
          </p>
          <div className="mt-4">
            <span className={`inline-flex items-center px-3 py-1 rounded-full text-sm font-medium ${
              apiStatus === 'connected' ? 'bg-green-100 text-green-800' :
              apiStatus === 'disconnected' ? 'bg-red-100 text-red-800' :
              'bg-yellow-100 text-yellow-800'
            }`}>
              API Status: {apiStatus}
            </span>
          </div>
        </div>

        {/* Main Content */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
          {/* Coin Selection */}
          <Card>
            <CardHeader>
              <CardTitle>Available Coins</CardTitle>
              <CardDescription>
                Select a cryptocurrency to view ML analysis
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-2">
                {coins.map((coin) => (
                  <Button
                    key={coin.symbol}
                    variant={selectedCoin === coin.symbol ? "default" : "outline"}
                    className="w-full justify-start"
                    onClick={() => {
                      setSelectedCoin(coin.symbol)
                      fetchAnalysis(coin.symbol)
                    }}
                  >
                    <div className="flex items-center justify-between w-full">
                      <span className="font-semibold">{coin.symbol}</span>
                      <span className="text-sm text-gray-500">{coin.name}</span>
                      <span className="text-xs bg-blue-100 text-blue-800 px-2 py-1 rounded">
                        {coin.source}
                      </span>
                    </div>
                  </Button>
                ))}
              </div>
              
              {coins.length === 0 && (
                <div className="text-center py-8 text-gray-500">
                  <p>No coins available. Check API connection.</p>
                  <Button 
                    variant="outline" 
                    onClick={fetchCoins}
                    className="mt-4"
                  >
                    Retry
                  </Button>
                </div>
              )}
            </CardContent>
          </Card>

          {/* Analysis Display */}
          <Card>
            <CardHeader>
              <CardTitle>ML Analysis</CardTitle>
              <CardDescription>
                {selectedCoin ? `Analysis for ${selectedCoin}` : 'Select a coin to view analysis'}
              </CardDescription>
            </CardHeader>
            <CardContent>
              {loading && (
                <div className="text-center py-8">
                  <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto"></div>
                  <p className="mt-2 text-gray-500">Loading analysis...</p>
                </div>
              )}

              {analysis && !loading && (
                <div className="space-y-4">
                  <div className="bg-blue-50 dark:bg-blue-900/20 p-4 rounded-lg">
                    <h3 className="font-semibold text-blue-900 dark:text-blue-100">
                      Overall Analysis
                    </h3>
                    <p className="text-blue-800 dark:text-blue-200 mt-1">
                      {analysis.analysis}
                    </p>
                    <div className="mt-2">
                      <span className="text-sm text-blue-600 dark:text-blue-400">
                        Confidence: {(analysis.confidence * 100).toFixed(1)}%
                      </span>
                    </div>
                  </div>

                  <div className="space-y-3">
                    <h4 className="font-semibold">Signals</h4>
                    {analysis.signals.map((signal, index) => (
                      <div key={index} className="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-800 rounded-lg">
                        <div>
                          <span className="font-medium capitalize">{signal.type}</span>
                          <span className={`ml-2 px-2 py-1 text-xs rounded ${
                            signal.value === 'bullish' ? 'bg-green-100 text-green-800' :
                            signal.value === 'bearish' ? 'bg-red-100 text-red-800' :
                            'bg-gray-100 text-gray-800'
                          }`}>
                            {signal.value}
                          </span>
                        </div>
                        <span className="text-sm text-gray-500">
                          {(signal.confidence * 100).toFixed(1)}%
                        </span>
                      </div>
                    ))}
                  </div>

                  <div className="text-xs text-gray-500 pt-4 border-t">
                    Last updated: {new Date(analysis.timestamp).toLocaleString()}
                  </div>
                </div>
              )}

              {!selectedCoin && !loading && (
                <div className="text-center py-8 text-gray-500">
                  <p>Select a cryptocurrency to view its ML analysis</p>
                </div>
              )}
            </CardContent>
          </Card>
        </div>

        {/* Features Preview */}
        <div className="mt-12 grid grid-cols-1 md:grid-cols-4 gap-6">
          <Card className="text-center">
            <CardContent className="pt-6">
              <div className="text-2xl mb-2">📊</div>
              <h3 className="font-semibold">HTX API</h3>
              <p className="text-sm text-gray-600 dark:text-gray-400">
                Real-time data from HTX exchange
              </p>
            </CardContent>
          </Card>

          <Card className="text-center">
            <CardContent className="pt-6">
              <div className="text-2xl mb-2">🤖</div>
              <h3 className="font-semibold">FinGPT ML</h3>
              <p className="text-sm text-gray-600 dark:text-gray-400">
                Local tensor-based training
              </p>
            </CardContent>
          </Card>

          <Card className="text-center">
            <CardContent className="pt-6">
              <div className="text-2xl mb-2">☁️</div>
              <h3 className="font-semibold">Google Cloud</h3>
              <p className="text-sm text-gray-600 dark:text-gray-400">
                Vertex AI & BigQuery integration
              </p>
            </CardContent>
          </Card>

          <Card className="text-center">
            <CardContent className="pt-6">
              <div className="text-2xl mb-2">📈</div>
              <h3 className="font-semibold">Multi-Source</h3>
              <p className="text-sm text-gray-600 dark:text-gray-400">
                CoinGecko, CSV, CryptoPanic
              </p>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  )
}
