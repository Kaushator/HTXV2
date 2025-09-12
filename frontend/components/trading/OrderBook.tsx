// @cursor: КОНТЕКСТ: HTXV2 - Order book компонент
// ТЕХНОЛОГИИ: TypeScript, React, real-time WebSocket данные
// ЦЕЛЬ: Отображение стакана заявок (bids/asks)

interface OrderBookUpdate {
  symbol: string;
  bids: [number, number][];
  asks: [number, number][];
  timestamp: string;
}

interface OrderBookProps {
  symbol: string;
  orderBook?: OrderBookUpdate;
  isLoading?: boolean;
}

export function OrderBook({ symbol, orderBook, isLoading }: OrderBookProps) {
  if (isLoading) {
    return (
      <div className="space-y-2">
        <div className="text-sm font-medium text-center">Loading...</div>
        {Array.from({ length: 5 }).map((_, i) => (
          <div key={i} className="h-4 bg-muted animate-pulse rounded" />
        ))}
      </div>
    );
  }

  if (!orderBook) {
    return (
      <div className="text-center text-muted-foreground py-8">
        <div>No order book data</div>
        <div className="text-xs">Connect to WebSocket for real-time data</div>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      {/* Asks (Sell orders) */}
      <div className="space-y-1">
        <div className="text-xs font-medium text-red-600">Asks</div>
        {orderBook.asks.slice(0, 5).map(([price, quantity]: [number, number], index: number) => (
          <div key={index} className="flex justify-between text-xs">
            <span className="text-red-600">{price.toFixed(2)}</span>
            <span>{quantity.toFixed(4)}</span>
          </div>
        ))}
      </div>

      {/* Spread */}
      <div className="text-center py-2 border-y">
        <div className="text-xs text-muted-foreground">Spread</div>
        {orderBook.asks[0] && orderBook.bids[0] && (
          <div className="text-sm font-mono">
            {(orderBook.asks[0][0] - orderBook.bids[0][0]).toFixed(2)}
          </div>
        )}
      </div>

      {/* Bids (Buy orders) */}
      <div className="space-y-1">
        <div className="text-xs font-medium text-green-600">Bids</div>
        {orderBook.bids.slice(0, 5).map(([price, quantity]: [number, number], index: number) => (
          <div key={index} className="flex justify-between text-xs">
            <span className="text-green-600">{price.toFixed(2)}</span>
            <span>{quantity.toFixed(4)}</span>
          </div>
        ))}
      </div>
    </div>
  );
}