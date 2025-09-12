// @cursor: КОНТЕКСТ: HTXV2 - Positions table компонент
// ТЕХНОЛОГИИ: TypeScript, React, отображение портфеля
// ЦЕЛЬ: Таблица текущих позиций с P&L

interface Position {
  symbol: string;
  quantity: number;
  average_price: number;
  current_price: number;
  unrealized_pnl: number;
  unrealized_pnl_percent: number;
  market_value: number;
}

interface PositionsTableProps {
  positions: Position[];
  isLoading?: boolean;
}

export function PositionsTable({ positions, isLoading }: PositionsTableProps) {
  if (isLoading) {
    return (
      <div className="space-y-2">
        <div className="text-sm">Loading positions...</div>
        {Array.from({ length: 3 }).map((_, i) => (
          <div key={i} className="h-12 bg-muted animate-pulse rounded" />
        ))}
      </div>
    );
  }

  if (positions.length === 0) {
    return (
      <div className="text-center text-muted-foreground py-8">
        <div>No positions</div>
        <div className="text-xs">Start trading to build your portfolio</div>
      </div>
    );
  }

  return (
    <div className="space-y-2">
      {positions.map((position) => (
        <div key={position.symbol} className="flex items-center justify-between p-3 border rounded-md">
          <div className="space-y-1">
            <div className="font-medium">{position.symbol}</div>
            <div className="text-sm text-muted-foreground">
              {position.quantity.toFixed(4)} units
            </div>
          </div>
          
          <div className="text-right space-y-1">
            <div className="font-mono">
              ${position.current_price.toFixed(2)}
            </div>
            <div className="text-sm text-muted-foreground">
              Avg: ${position.average_price.toFixed(2)}
            </div>
          </div>
          
          <div className="text-right space-y-1">
            <div className="font-mono">
              ${position.market_value.toFixed(2)}
            </div>
            <div className={`text-sm ${
              position.unrealized_pnl >= 0 ? 'text-green-600' : 'text-red-600'
            }`}>
              ${position.unrealized_pnl.toFixed(2)} ({position.unrealized_pnl_percent.toFixed(2)}%)
            </div>
          </div>
        </div>
      ))}
    </div>
  );
}