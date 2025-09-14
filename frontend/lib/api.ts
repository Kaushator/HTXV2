// Enhanced API client for HTXV2 with error handling, retries, and monitoring
// Uses configuration from lib/config.ts

import { API_CONFIG, PERFORMANCE_CONFIG } from './config'
import { trackError, trackCustomMetric } from './performance'

// API Response interface
interface ApiResponse<T = any> {
  data: T
  success: boolean
  message?: string
  timestamp: string
}

// API Error interface
interface ApiError extends Error {
  status?: number
  code?: string
  details?: any
}

// Request options interface
interface RequestOptions extends RequestInit {
  timeout?: number
  retries?: number
  retryDelay?: number
}

class ApiClient {
  private baseURL: string
  private defaultTimeout: number
  private defaultRetries: number
  private defaultRetryDelay: number

  constructor() {
    this.baseURL = API_CONFIG.baseURL
    this.defaultTimeout = API_CONFIG.timeout
    this.defaultRetries = API_CONFIG.retries
    this.defaultRetryDelay = API_CONFIG.retryDelay
  }

  async request<T>(
    endpoint: string,
    options: RequestOptions = {}
  ): Promise<ApiResponse<T>> {
    const {
      timeout = this.defaultTimeout,
      retries = this.defaultRetries,
      retryDelay = this.defaultRetryDelay,
      ...fetchOptions
    } = options

    const url = `${this.baseURL}${endpoint}`
    const startTime = performance.now()

    let lastError: ApiError | null = null

    for (let attempt = 0; attempt <= retries; attempt++) {
      try {
        const response = await this.fetchWithTimeout(url, {
          ...fetchOptions,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            ...this.getAuthHeaders(),
            ...fetchOptions.headers,
          },
        }, timeout)

        const endTime = performance.now()
        const duration = endTime - startTime

        // Track performance metrics
        if (PERFORMANCE_CONFIG.enabled) {
          trackCustomMetric('api_request_duration', duration, {
            endpoint,
            method: fetchOptions.method || 'GET',
            status: response.status,
            attempt: attempt + 1,
          })
        }

        if (!response.ok) {
          const errorText = await response.text()
          const error = new Error(`HTTP ${response.status}: ${errorText}`) as ApiError
          error.status = response.status
          
          // Don't retry on 4xx errors (client errors)
          if (response.status >= 400 && response.status < 500) {
            throw error
          }
          
          lastError = error
          
          // Wait before retrying
          if (attempt < retries) {
            await this.delay(retryDelay * Math.pow(2, attempt))
            continue
          }
          
          throw error
        }

        const data = await response.json()
        return data as ApiResponse<T>

      } catch (error) {
        lastError = error as ApiError
        
        // Track errors
        if (PERFORMANCE_CONFIG.trackErrors) {
          trackError(lastError, {
            endpoint,
            method: fetchOptions.method || 'GET',
            attempt: attempt + 1,
          })
        }

        // Don't retry on network errors for the last attempt
        if (attempt === retries) {
          break
        }

        // Wait before retrying
        await this.delay(retryDelay * Math.pow(2, attempt))
      }
    }

    throw lastError || new Error('Request failed after all retry attempts')
  }

  private async fetchWithTimeout(
    url: string,
    options: RequestInit,
    timeout: number
  ): Promise<Response> {
    const controller = new AbortController()
    const timeoutId = setTimeout(() => controller.abort(), timeout)

    try {
      const response = await fetch(url, {
        ...options,
        signal: controller.signal,
      })
      return response
    } finally {
      clearTimeout(timeoutId)
    }
  }

  private getAuthHeaders(): Record<string, string> {
    const headers: Record<string, string> = {}
    
    // Get token from localStorage or cookies
    if (typeof window !== 'undefined') {
      const token = localStorage.getItem('access_token')
      if (token) {
        headers.Authorization = `Bearer ${token}`
      }
    }

    return headers
  }

  private delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms))
  }

  // Convenience methods
  async get<T>(endpoint: string, options?: RequestOptions): Promise<ApiResponse<T>> {
    return this.request<T>(endpoint, { ...options, method: 'GET' })
  }

  async post<T>(
    endpoint: string,
    body?: any,
    options?: RequestOptions
  ): Promise<ApiResponse<T>> {
    return this.request<T>(endpoint, {
      ...options,
      method: 'POST',
      body: body ? JSON.stringify(body) : undefined,
    })
  }

  async put<T>(
    endpoint: string,
    body?: any,
    options?: RequestOptions
  ): Promise<ApiResponse<T>> {
    return this.request<T>(endpoint, {
      ...options,
      method: 'PUT',
      body: body ? JSON.stringify(body) : undefined,
    })
  }

  async delete<T>(endpoint: string, options?: RequestOptions): Promise<ApiResponse<T>> {
    return this.request<T>(endpoint, { ...options, method: 'DELETE' })
  }

  // Health check method
  async healthCheck(): Promise<boolean> {
    try {
      await this.get('/health')
      return true
    } catch {
      return false
    }
  }

  // Update base URL (useful for environment switching)
  setBaseURL(url: string): void {
    this.baseURL = url
  }

  getBaseURL(): string {
    return this.baseURL
  }
}

// Create singleton instance
export const apiClient = new ApiClient()

// Export the class for testing or multiple instances
export { ApiClient }

// Export utility functions
export const healthCheck = () => apiClient.healthCheck()
export const setApiBaseURL = (url: string) => apiClient.setBaseURL(url)