'use client';

import axios, { AxiosInstance, AxiosRequestConfig, AxiosResponse } from 'axios';
import { useCallback, useMemo } from 'react';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000/api/v1';

export function useApi() {
  const apiClient: AxiosInstance = useMemo(() => {
    const client = axios.create({
      baseURL: API_BASE_URL,
      timeout: 10000,
      headers: {
        'Content-Type': 'application/json',
      },
    });

    client.interceptors.request.use(
      (config) => {
        const token = localStorage.getItem('auth_token');
        if (token) {
          config.headers.Authorization = `Bearer ${token}`;
        }
        return config;
      },
      (error) => Promise.reject(error)
    );

    client.interceptors.response.use(
      (response) => response,
      (error) => {
        if (error.response?.status === 401) {
          localStorage.removeItem('auth_token');
          window.location.href = '/auth/login';
        }
        return Promise.reject(error);
      }
    );

    return client;
  }, []);

  const get = useCallback(
    async <T = any>(url: string, config?: AxiosRequestConfig): Promise<AxiosResponse<T>> => {
      return apiClient.get<T>(url, config);
    },
    [apiClient]
  );

  const post = useCallback(
    async <T = any>(url: string, data?: any, config?: AxiosRequestConfig): Promise<AxiosResponse<T>> => {
      return apiClient.post<T>(url, data, config);
    },
    [apiClient]
  );

  const put = useCallback(
    async <T = any>(url: string, data?: any, config?: AxiosRequestConfig): Promise<AxiosResponse<T>> => {
      return apiClient.put<T>(url, data, config);
    },
    [apiClient]
  );

  const patch = useCallback(
    async <T = any>(url: string, data?: any, config?: AxiosRequestConfig): Promise<AxiosResponse<T>> => {
      return apiClient.patch<T>(url, data, config);
    },
    [apiClient]
  );

  const del = useCallback(
    async <T = any>(url: string, config?: AxiosRequestConfig): Promise<AxiosResponse<T>> => {
      return apiClient.delete<T>(url, config);
    },
    [apiClient]
  );

  return {
    get,
    post,
    put,
    patch,
    delete: del,
    client: apiClient,
  };
}
