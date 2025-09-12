// @cursor: КОНТЕКСТ: HTXV2 - криптотрейдинг платформа, real-time dashboard
// ТЕХНОЛОГИИ: TypeScript, shadcn/ui, React Query, WebSocket, Next.js
// ЦЕЛЬ: Главный компонент торгового дашборда с real-time обновлениями
// ПАТТЕРН: Композиция компонентов с разделением ответственности

'use client';

import { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { RefreshCw, TrendingUp, TrendingDown, Activity } from 'lucide-react';
import { useMarketDataWebSocket } from '@/hooks/useMarketDataWebSocket';
import { useMarketData, usePortfolio, useActiveOrders } from '@/hooks/useMarketData';
import { PriceChart } from './PriceChart';
import { OrderBook } from './OrderBook';
import { OrdersTable } from './OrdersTable';
import { PositionsTable } from './PositionsTable';
import { TradeForm } from './TradeForm';

interface TradingDashboardProps {
  defaultSymbol?: string;
  className?: string;
}

export function TradingDashboard({ defaultSymbol = 'BTCUSDT', className }: TradingDashboardProps) {
  const [selectedSymbol, setSelectedSymbol] = useState(defaultSymbol);
  const [isAutoRefresh, setIsAutoRefresh] = useState(true);

  // API data hooks
  const { data: marketData, isLoading: isMarketLoading, refetch: refetchMarket } = useMarketData();
  const { data: portfolio, isLoading: isPortfolioLoading } = usePortfolio();
  const { data: activeOrders, isLoading: isOrdersLoading } = useActiveOrders();

  // WebSocket for real-time market data
  const {
    status: wsStatus,
    marketData: realTimeMarketData,
    error: wsError,
    isConnected,
    reconnectAttempts
  } = useMarketDataWebSocket({
    symbol: selectedSymbol,
    // token: authToken, // Add authentication token if available
    onMarketData: (data) => {
      console.log('Received market data:', data);
    },
    onError: (error) => {
      console.error('WebSocket error:', error);
    }
  });

  // Get current symbol data - prioritize real-time data from WebSocket
  const currentSymbolData = marketData?.data?.find((item: any) => item.symbol === selectedSymbol);
  
  // Use real-time data if available, fallback to API data
  const displayPrice = realTimeMarketData?.price ?? currentSymbolData?.price ?? 0;
  const displayChange = realTimeMarketData?.change_24h ?? currentSymbolData?.change_24h_percent ?? 0;
  const displayVolume = realTimeMarketData?.volume ?? currentSymbolData?.volume_24h ?? 0;

  // Handle symbol change - will trigger WebSocket reconnection
  const handleSymbolChange = (symbol: string) => {
    setSelectedSymbol(symbol);
  };

  // Handle refresh
  const handleRefresh = () => {
    refetchMarket();
  };

  return (
    <div className={`container mx-auto p-6 space-y-6 ${className}`}>
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="space-y-1">
          <h1 className="text-3xl font-bold tracking-tight">Trading Dashboard</h1>
          <p className="text-muted-foreground">
            Real-time cryptocurrency trading and portfolio management
          </p>
        </div>
        
        <div className="flex items-center space-x-2">
          <Badge variant={isConnected ? 'default' : wsStatus === 'connecting' ? 'secondary' : 'destructive'}>
            <Activity className="w-3 h-3 mr-1" />
            {wsStatus === 'connecting' ? 'Connecting...' : isConnected ? 'Live' : wsError ? `Error: ${wsError}` : 'Disconnected'}
          </Badge>
          
          {reconnectAttempts > 0 && !isConnected && (
            <Badge variant="outline" className="text-xs">
              Retry {reconnectAttempts}/5
            </Badge>
          )}
          
          <Button
            variant="outline"
            size="sm"
            onClick={handleRefresh}
            disabled={isMarketLoading}
          >
            <RefreshCw className={`w-4 h-4 mr-2 ${isMarketLoading ? 'animate-spin' : ''}`} />
            Refresh
          </Button>
          
          <Button
            variant={isAutoRefresh ? 'default' : 'outline'}
            size="sm"
            onClick={() => setIsAutoRefresh(!isAutoRefresh)}
          >
            {isAutoRefresh ? 'Live Mode' : 'Manual Mode'}
          </Button>
        </div>
      </div>

      {/* Main Price Display */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <div>
              <CardTitle className="text-2xl">{selectedSymbol}</CardTitle>
              <CardDescription>Current market price</CardDescription>
            </div>
            <div className="text-right">
              <div className="text-3xl font-bold">
                ${displayPrice.toLocaleString()}
              </div>
              <div className={`flex items-center ${displayChange >= 0 ? 'text-green-600' : 'text-red-600'}`}>
                {displayChange >= 0 ? (
                  <TrendingUp className="w-4 h-4 mr-1" />
                ) : (
                  <TrendingDown className="w-4 h-4 mr-1" />
                )}
                {displayChange.toFixed(2)}%
              </div>
            </div>
          </div>
        </CardHeader>
      </Card>

      {/* Main Dashboard */}
      <Tabs defaultValue="overview" className="space-y-4">
        <TabsList>
          <TabsTrigger value="overview">Overview</TabsTrigger>
          <TabsTrigger value="trading">Trading</TabsTrigger>
          <TabsTrigger value="portfolio">Portfolio</TabsTrigger>
          <TabsTrigger value="orders">Orders</TabsTrigger>
        </TabsList>

        {/* Overview Tab */}
        <TabsContent value="overview" className="space-y-4">
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            {/* Price Chart */}
            <Card className="lg:col-span-2">
              <CardHeader>
                <CardTitle>Price Chart</CardTitle>
                <CardDescription>24-hour price movement</CardDescription>
              </CardHeader>
              <CardContent>
                <PriceChart 
                  symbol={selectedSymbol}
                  data={marketData?.data || []}
                  height={300}
                />
              </CardContent>
            </Card>

            {/* Order Book */}
            <Card>
              <CardHeader>
                <CardTitle>Order Book</CardTitle>
                <CardDescription>{selectedSymbol} depth</CardDescription>
              </CardHeader>
              <CardContent>
                <OrderBook 
                  symbol={selectedSymbol}
                  orderBook={currentOrderBook}
                  isLoading={!isConnected && !currentOrderBook}
                />
              </CardContent>
            </Card>
          </div>

          {/* Market Overview */}
          <Card>
            <CardHeader>
              <CardTitle>Market Overview</CardTitle>
              <CardDescription>Top trading pairs</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                {marketData?.data?.slice(0, 8).map((item: any) => (
                  <Card 
                    key={item.symbol}
                    className={`cursor-pointer transition-colors ${selectedSymbol === item.symbol ? 'ring-2 ring-primary' : 'hover:bg-muted'}`}
                    onClick={() => handleSymbolChange(item.symbol)}
                  >
                    <CardContent className="p-4">
                      <div className="space-y-2">
                        <div className="font-medium">{item.symbol}</div>
                        <div className="text-2xl font-bold">
                          ${item.price.toLocaleString()}
                        </div>
                        <div className={`text-sm ${item.change_24h_percent >= 0 ? 'text-green-600' : 'text-red-600'}`}>
                          {item.change_24h_percent.toFixed(2)}%
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                ))}
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Trading Tab */}
        <TabsContent value="trading" className="space-y-4">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <TradeForm 
              symbol={selectedSymbol}
              currentPrice={displayPrice}
            />
            
            <Card>
              <CardHeader>
                <CardTitle>Recent Orders</CardTitle>
              </CardHeader>
              <CardContent>
                <OrdersTable 
                  orders={activeOrders?.data || []}
                  isLoading={isOrdersLoading}
                  showActions={true}
                />
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        {/* Portfolio Tab */}
        <TabsContent value="portfolio" className="space-y-4">
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            <Card className="lg:col-span-2">
              <CardHeader>
                <CardTitle>Positions</CardTitle>
                <CardDescription>Your current holdings</CardDescription>
              </CardHeader>
              <CardContent>
                <PositionsTable 
                  positions={portfolio?.data?.positions || []}
                  isLoading={isPortfolioLoading}
                />
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>Portfolio Summary</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div>
                  <div className="text-sm text-muted-foreground">Total Value</div>
                  <div className="text-2xl font-bold">
                    ${portfolio?.data?.total_value?.toLocaleString() || '0'}
                  </div>
                </div>
                <div>
                  <div className="text-sm text-muted-foreground">Total P&L</div>
                  <div className={`text-xl font-semibold ${
                    (portfolio?.data?.total_pnl || 0) >= 0 ? 'text-green-600' : 'text-red-600'
                  }`}>
                    ${portfolio?.data?.total_pnl?.toLocaleString() || '0'}
                    {portfolio?.data?.total_pnl_percent && (
                      <span className="text-sm ml-1">
                        ({portfolio.data.total_pnl_percent.toFixed(2)}%)
                      </span>
                    )}
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        {/* Orders Tab */}
        <TabsContent value="orders" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>All Orders</CardTitle>
              <CardDescription>Order history and active orders</CardDescription>
            </CardHeader>
            <CardContent>
              <OrdersTable 
                orders={activeOrders?.data || []}
                isLoading={isOrdersLoading}
                showActions={true}
                showFilters={true}
              />
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}