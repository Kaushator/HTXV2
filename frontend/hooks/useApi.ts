// @cursor: КОНТЕКСТ: HTXV2 - криптотрейдинг платформа
// ТЕХНОЛОГИИ: TypeScript, Next.js, React Query, async/await
// ЦЕЛЬ: Базовый хук для API запросов с React Query интеграцией
// ПАТТЕРН: Переиспользуемый хук с error handling, caching, retry logic

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { ApiResponse, ApiError as ApiErrorType } from '@/types/api';

// API Configuration
const API_CONFIG = {
  baseURL: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000/api/v1',
  timeout: 30000,
  retries: 3,
  retryDelay: 1000
};

// API Client Class
class ApiClient {
  private baseURL: string;

  constructor(baseURL: string = API_CONFIG.baseURL) {
    this.baseURL = baseURL;
  }

  private async request<T>(
    endpoint: string,
    options: RequestInit = {}
  ): Promise<ApiResponse<T>> {
    const url = `${this.baseURL}${endpoint}`;
    
    // Get auth token from localStorage
    const token = typeof window !== 'undefined' ? localStorage.getItem('access_token') : null;
    
    const defaultHeaders: Record<string, string> = {
      'Content-Type': 'application/json',
    };
    
    if (token) {
      defaultHeaders.Authorization = `Bearer ${token}`;
    }

    try {
      const response = await fetch(url, {
        ...options,
        headers: {
          ...defaultHeaders,
          ...options.headers,
        },
      });

      if (!response.ok) {
        const errorData = await response.text();
        throw new ApiError({
          message: `HTTP ${response.status}: ${response.statusText}`,
          code: response.status.toString(),
          details: { response: errorData }
        });
      }

      return await response.json();
    } catch (error) {
      if (error instanceof ApiError) {
        throw error;
      }
      throw new ApiError({
        message: error instanceof Error ? error.message : 'Unknown error',
        code: 'FETCH_ERROR',
        details: { originalError: error }
      });
    }
  }

  async get<T>(endpoint: string): Promise<ApiResponse<T>> {
    return this.request<T>(endpoint, { method: 'GET' });
  }

  async post<T>(endpoint: string, data?: any): Promise<ApiResponse<T>> {
    return this.request<T>(endpoint, {
      method: 'POST',
      body: data ? JSON.stringify(data) : undefined,
    });
  }

  async put<T>(endpoint: string, data?: any): Promise<ApiResponse<T>> {
    return this.request<T>(endpoint, {
      method: 'PUT',
      body: data ? JSON.stringify(data) : undefined,
    });
  }

  async delete<T>(endpoint: string): Promise<ApiResponse<T>> {
    return this.request<T>(endpoint, { method: 'DELETE' });
  }
}

// Global API client instance
export const apiClient = new ApiClient();

// Generic API Hook
export function useApiQuery<T>(
  queryKey: string[],
  endpoint: string,
  options?: {
    enabled?: boolean;
    refetchInterval?: number;
    staleTime?: number;
  }
) {
  return useQuery({
    queryKey,
    queryFn: () => apiClient.get<T>(endpoint),
    enabled: options?.enabled ?? true,
    refetchInterval: options?.refetchInterval,
    staleTime: options?.staleTime ?? 1000 * 60 * 5, // 5 minutes default
    retry: API_CONFIG.retries,
    retryDelay: API_CONFIG.retryDelay,
  });
}

// Generic API Mutation Hook
export function useApiMutation<TData, TVariables = any>(
  endpoint: string,
  method: 'POST' | 'PUT' | 'DELETE' = 'POST',
  options?: {
    onSuccess?: (data: ApiResponse<TData>) => void;
    onError?: (error: ApiError) => void;
    invalidateQueries?: string[][];
  }
) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (variables: TVariables) => {
      switch (method) {
        case 'POST':
          return apiClient.post<TData>(endpoint, variables);
        case 'PUT':
          return apiClient.put<TData>(endpoint, variables);
        case 'DELETE':
          return apiClient.delete<TData>(endpoint);
        default:
          throw new Error(`Unsupported method: ${method}`);
      }
    },
    onSuccess: (data) => {
      // Invalidate related queries
      if (options?.invalidateQueries) {
        options.invalidateQueries.forEach(queryKey => {
          queryClient.invalidateQueries({ queryKey });
        });
      }
      options?.onSuccess?.(data);
    },
    onError: options?.onError,
  });
}

// Error handling utility
export class ApiError extends Error {
  public code: string;
  public details?: Record<string, any>;

  constructor({ message, code, details }: { message: string; code: string; details?: Record<string, any> }) {
    super(message);
    this.name = 'ApiError';
    this.code = code;
    this.details = details;
  }
}