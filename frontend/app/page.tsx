import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { TrendingUp, Shield, Zap, BarChart3 } from 'lucide-react'
import { TickerDisplay } from '@/components/ticker-display'

export default function HomePage() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 dark:from-gray-900 dark:to-gray-800">
      {/* Header */}
      <header className="border-b bg-white/80 backdrop-blur-sm dark:bg-gray-900/80">
        <div className="container mx-auto px-4 py-4 flex items-center justify-between">
          <div className="flex items-center space-x-2">
            <TrendingUp className="h-8 w-8 text-blue-600" />
            <h1 className="text-2xl font-bold">HTXV2</h1>
          </div>
          <nav className="hidden md:flex items-center space-x-6">
            <Link href="/features" className="text-gray-600 hover:text-gray-900 dark:text-gray-300 dark:hover:text-white">
              Features
            </Link>
            <Link href="/pricing" className="text-gray-600 hover:text-gray-900 dark:text-gray-300 dark:hover:text-white">
              Pricing
            </Link>
            <Link href="/docs" className="text-gray-600 hover:text-gray-900 dark:text-gray-300 dark:hover:text-white">
              Docs
            </Link>
          </nav>
          <div className="flex items-center space-x-2">
            <Button variant="ghost" asChild>
              <Link href="/auth/login">Login</Link>
            </Button>
            <Button asChild>
              <Link href="/auth/register">Get Started</Link>
            </Button>
          </div>
        </div>
      </header>

      {/* Hero Section */}
      <section className="container mx-auto px-4 py-16 text-center">
        <h2 className="text-4xl md:text-6xl font-bold mb-6 bg-gradient-to-r from-blue-600 to-purple-600 bg-clip-text text-transparent">
          AI-Powered Crypto Trading
        </h2>
        <p className="text-xl text-gray-600 dark:text-gray-300 mb-8 max-w-3xl mx-auto">
          Advanced cryptocurrency trading platform with machine learning insights, 
          real-time data analysis, and automated portfolio management.
        </p>
        <div className="flex flex-col sm:flex-row gap-4 justify-center">
          <Button size="lg" asChild>
            <Link href="/auth/register">Start Trading</Link>
          </Button>
          <Button size="lg" variant="outline" asChild>
            <Link href="/demo">View Demo</Link>
          </Button>
        </div>
      </section>

      {/* Real-time Ticker Section */}
      <section className="container mx-auto px-4 py-16">
        <div className="bg-white dark:bg-gray-800 rounded-lg shadow-lg p-6">
          <TickerDisplay 
            symbols={['BTC', 'ETH']}
            wsUrl={process.env.NODE_ENV === 'development' ? 'ws://localhost:8000/api/v1/ws/ticker' : `wss://${process.env.NEXT_PUBLIC_API_URL?.replace('https://', '')}/api/v1/ws/ticker`}
          />
        </div>
      </section>

      {/* Features Grid */}
      <section className="container mx-auto px-4 py-16">
        <h3 className="text-3xl font-bold text-center mb-12">
          Powerful Features
        </h3>
        <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-6">
          <Card>
            <CardHeader>
              <TrendingUp className="h-12 w-12 text-blue-600 mb-4" />
              <CardTitle>Real-Time Analytics</CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-gray-600 dark:text-gray-300">
                Live market data and advanced charting tools with technical indicators.
              </p>
            </CardContent>
          </Card>
          
          <Card>
            <CardHeader>
              <Zap className="h-12 w-12 text-yellow-600 mb-4" />
              <CardTitle>AI Trading Signals</CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-gray-600 dark:text-gray-300">
                Machine learning powered trading signals with confidence scores.
              </p>
            </CardContent>
          </Card>
          
          <Card>
            <CardHeader>
              <BarChart3 className="h-12 w-12 text-green-600 mb-4" />
              <CardTitle>Portfolio Management</CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-gray-600 dark:text-gray-300">
                Comprehensive portfolio tracking with P&L analysis and risk metrics.
              </p>
            </CardContent>
          </Card>
          
          <Card>
            <CardHeader>
              <Shield className="h-12 w-12 text-purple-600 mb-4" />
              <CardTitle>Enterprise Security</CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-gray-600 dark:text-gray-300">
                Bank-grade security with encrypted data and secure API access.
              </p>
            </CardContent>
          </Card>
        </div>
      </section>

      {/* Footer */}
      <footer className="border-t bg-white dark:bg-gray-900">
        <div className="container mx-auto px-4 py-8 text-center text-gray-600 dark:text-gray-300">
          <p>&copy; 2024 HTXV2. All rights reserved.</p>
        </div>
      </footer>
    </div>
  )
}