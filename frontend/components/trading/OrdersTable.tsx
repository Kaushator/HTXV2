// @cursor: КОНТЕКСТ: HTXV2 - Orders table компонент
// ТЕХНОЛОГИИ: TypeScript, React, shadcn/ui таблицы
// ЦЕЛЬ: Отображение таблицы ордеров с действиями

interface Order {
  id: string;
  symbol: string;
  side: 'buy' | 'sell';
  type: 'market' | 'limit';
  quantity: number;
  price?: number;
  status: 'pending' | 'filled' | 'cancelled' | 'rejected';
  created_at: string;
}

interface OrdersTableProps {
  orders: Order[];
  isLoading?: boolean;
  showActions?: boolean;
  showFilters?: boolean;
}

export function OrdersTable({ orders, isLoading, showActions, showFilters }: OrdersTableProps) {
  if (isLoading) {
    return (
      <div className="space-y-2">
        <div className="text-sm">Loading orders...</div>
        {Array.from({ length: 3 }).map((_, i) => (
          <div key={i} className="h-12 bg-muted animate-pulse rounded" />
        ))}
      </div>
    );
  }

  if (orders.length === 0) {
    return (
      <div className="text-center text-muted-foreground py-8">
        <div>No orders found</div>
        <div className="text-xs">Place your first order to get started</div>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      {showFilters && (
        <div className="text-xs text-muted-foreground">
          Showing {orders.length} orders
        </div>
      )}
      
      <div className="space-y-2">
        {orders.slice(0, 10).map((order) => (
          <div key={order.id} className="flex items-center justify-between p-3 border rounded-md">
            <div className="space-y-1">
              <div className="font-medium">{order.symbol}</div>
              <div className="text-sm text-muted-foreground">
                {order.side.toUpperCase()} {order.type.toUpperCase()}
              </div>
            </div>
            
            <div className="text-right space-y-1">
              <div className="font-mono">{order.quantity}</div>
              {order.price && (
                <div className="text-sm text-muted-foreground">
                  @${order.price.toFixed(2)}
                </div>
              )}
            </div>
            
            <div className="text-right space-y-1">
              <div className={`text-xs px-2 py-1 rounded ${
                order.status === 'filled' ? 'bg-green-100 text-green-800' :
                order.status === 'pending' ? 'bg-yellow-100 text-yellow-800' :
                order.status === 'cancelled' ? 'bg-gray-100 text-gray-800' :
                'bg-red-100 text-red-800'
              }`}>
                {order.status.toUpperCase()}
              </div>
              
              {showActions && order.status === 'pending' && (
                <button className="text-xs text-red-600 hover:underline">
                  Cancel
                </button>
              )}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}