'use client';

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useApi } from './useApi';
import type {
  MarketData,
  Portfolio,
  Order,
  TradingPair,
  OrderBookData,
  PriceHistory
} from '@/types/api';

export function useMarketData(symbol?: string) {
  const api = useApi();

  return useQuery({
    queryKey: ['marketData', symbol],
    queryFn: async (): Promise<MarketData[]> => {
      const response = await api.get<MarketData[]>('/market-data', {
        params: symbol ? { symbol } : undefined
      });
      return response.data;
    },
    refetchInterval: 5000,
    enabled: true
  });
}

export function usePortfolio() {
  const api = useApi();

  return useQuery({
    queryKey: ['portfolio'],
    queryFn: async (): Promise<Portfolio> => {
      const response = await api.get<Portfolio>('/portfolio');
      return response.data;
    },
    refetchInterval: 10000,
  });
}

export function useActiveOrders() {
  const api = useApi();

  return useQuery({
    queryKey: ['activeOrders'],
    queryFn: async (): Promise<Order[]> => {
      const response = await api.get<Order[]>('/orders', {
        params: { status: 'active' }
      });
      return response.data;
    },
    refetchInterval: 3000,
  });
}

export function useTradingPairs() {
  const api = useApi();

  return useQuery({
    queryKey: ['tradingPairs'],
    queryFn: async (): Promise<TradingPair[]> => {
      const response = await api.get<TradingPair[]>('/trading-pairs');
      return response.data;
    },
    staleTime: 300000,
  });
}

export function useOrderBook(symbol: string) {
  const api = useApi();

  return useQuery({
    queryKey: ['orderBook', symbol],
    queryFn: async (): Promise<OrderBookData> => {
      const response = await api.get<OrderBookData>(`/order-book/${symbol}`);
      return response.data;
    },
    refetchInterval: 1000,
    enabled: !!symbol,
  });
}

export function useCreateOrder() {
  const api = useApi();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (orderData: Partial<Order>): Promise<Order> => {
      const response = await api.post<Order>('/orders', orderData);
      return response.data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['activeOrders'] });
      queryClient.invalidateQueries({ queryKey: ['portfolio'] });
    },
  });
}
