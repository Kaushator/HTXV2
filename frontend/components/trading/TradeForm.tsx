// @cursor: КОНТЕКСТ: HTXV2 - Trade form компонент
// ТЕХНОЛОГИИ: TypeScript, React, форма для создания ордеров
// ЦЕЛЬ: Форма покупки/продажи с валидацией

import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';

interface TradeFormProps {
  symbol: string;
  currentPrice: number;
}

export function TradeForm({ symbol, currentPrice }: TradeFormProps) {
  const [side, setSide] = useState<'buy' | 'sell'>('buy');
  const [type, setType] = useState<'market' | 'limit'>('market');
  const [quantity, setQuantity] = useState('');
  const [price, setPrice] = useState(currentPrice.toString());

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    // TODO: Implement order submission
    console.log('Order:', { symbol, side, type, quantity, price });
  };

  return (
    <Card>
      <CardHeader>
        <CardTitle>Place Order</CardTitle>
        <CardDescription>
          {symbol} @ ${currentPrice.toLocaleString()}
        </CardDescription>
      </CardHeader>
      <CardContent>
        <form onSubmit={handleSubmit} className="space-y-4">
          {/* Buy/Sell Toggle */}
          <div className="flex space-x-2">
            <Button
              type="button"
              variant={side === 'buy' ? 'default' : 'outline'}
              className={side === 'buy' ? 'bg-green-600 hover:bg-green-700' : ''}
              onClick={() => setSide('buy')}
              size="sm"
            >
              Buy
            </Button>
            <Button
              type="button"
              variant={side === 'sell' ? 'default' : 'outline'}
              className={side === 'sell' ? 'bg-red-600 hover:bg-red-700' : ''}
              onClick={() => setSide('sell')}
              size="sm"
            >
              Sell
            </Button>
          </div>

          {/* Order Type */}
          <div className="flex space-x-2">
            <Button
              type="button"
              variant={type === 'market' ? 'default' : 'outline'}
              onClick={() => setType('market')}
              size="sm"
            >
              Market
            </Button>
            <Button
              type="button"
              variant={type === 'limit' ? 'default' : 'outline'}
              onClick={() => setType('limit')}
              size="sm"
            >
              Limit
            </Button>
          </div>

          {/* Quantity */}
          <div className="space-y-2">
            <label className="text-sm font-medium">Quantity</label>
            <input
              type="number"
              value={quantity}
              onChange={(e) => setQuantity(e.target.value)}
              placeholder="0.00"
              className="w-full px-3 py-2 border rounded-md focus:outline-none focus:ring-2 focus:ring-primary"
              step="0.0001"
              min="0"
            />
          </div>

          {/* Price (for limit orders) */}
          {type === 'limit' && (
            <div className="space-y-2">
              <label className="text-sm font-medium">Price</label>
              <input
                type="number"
                value={price}
                onChange={(e) => setPrice(e.target.value)}
                placeholder="0.00"
                className="w-full px-3 py-2 border rounded-md focus:outline-none focus:ring-2 focus:ring-primary"
                step="0.01"
                min="0"
              />
            </div>
          )}

          {/* Order Summary */}
          <div className="p-3 bg-muted rounded-md text-sm space-y-1">
            <div className="flex justify-between">
              <span>Order Type:</span>
              <span className="font-medium">{side.toUpperCase()} {type.toUpperCase()}</span>
            </div>
            <div className="flex justify-between">
              <span>Quantity:</span>
              <span className="font-medium">{quantity || '0'}</span>
            </div>
            {type === 'limit' && (
              <div className="flex justify-between">
                <span>Price:</span>
                <span className="font-medium">${price}</span>
              </div>
            )}
            <div className="flex justify-between border-t pt-1">
              <span>Estimated Total:</span>
              <span className="font-medium">
                ${((parseFloat(quantity) || 0) * (type === 'market' ? currentPrice : parseFloat(price) || 0)).toFixed(2)}
              </span>
            </div>
          </div>

          {/* Submit Button */}
          <Button
            type="submit"
            className={`w-full ${
              side === 'buy' 
                ? 'bg-green-600 hover:bg-green-700' 
                : 'bg-red-600 hover:bg-red-700'
            }`}
            disabled={!quantity || (type === 'limit' && !price)}
          >
            {side === 'buy' ? 'Buy' : 'Sell'} {symbol}
          </Button>
        </form>
      </CardContent>
    </Card>
  );
}