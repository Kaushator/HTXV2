// @cursor: КОНТЕКСТ: HTXV2 - Price chart компонент
// ТЕХНОЛОГИИ: TypeScript, React, возможна интеграция с recharts
// ЦЕЛЬ: Отображение графика цен криптовалют
// TODO: Интегрировать с recharts для полноценных графиков

interface PriceChartProps {
  symbol: string;
  data: any[];
  height?: number;
}

export function PriceChart({ symbol, data, height = 300 }: PriceChartProps) {
  // TODO: Implement actual chart with recharts
  return (
    <div 
      className="flex items-center justify-center border rounded-md bg-muted/50"
      style={{ height: `${height}px` }}
    >
      <div className="text-center text-muted-foreground">
        <div className="text-lg font-medium">{symbol} Price Chart</div>
        <div className="text-sm">Chart implementation coming soon</div>
        <div className="text-xs mt-2">Data points: {data.length}</div>
      </div>
    </div>
  );
}