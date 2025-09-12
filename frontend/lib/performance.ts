// Performance monitoring utilities for HTXV2
// Implements performance tracking based on configuration

import { PERFORMANCE_CONFIG, APP_CONFIG } from './config'

// Performance metrics interface
interface PerformanceMetric {
  name: string
  value: number
  timestamp: number
  metadata?: Record<string, any>
}

// User action tracking interface
interface UserAction {
  action: string
  element?: string
  page: string
  timestamp: number
  sessionId: string
  metadata?: Record<string, any>
}

class PerformanceMonitor {
  private sessionId: string
  private observer?: PerformanceObserver

  constructor() {
    this.sessionId = this.generateSessionId()
    
    if (PERFORMANCE_CONFIG.enabled && typeof window !== 'undefined') {
      this.initializeObserver()
    }
  }

  private generateSessionId(): string {
    return `session-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`
  }

  private initializeObserver(): void {
    if ('PerformanceObserver' in window) {
      this.observer = new PerformanceObserver((list) => {
        for (const entry of list.getEntries()) {
          this.handlePerformanceEntry(entry)
        }
      })

      // Observe different types of performance entries
      try {
        this.observer.observe({ entryTypes: ['navigation', 'paint', 'measure'] })
      } catch (error) {
        console.warn('Performance observer failed to initialize:', error)
      }
    }
  }

  private handlePerformanceEntry(entry: PerformanceEntry): void {
    const metric: PerformanceMetric = {
      name: entry.name,
      value: entry.duration || entry.startTime,
      timestamp: Date.now(),
      metadata: {
        entryType: entry.entryType,
        sessionId: this.sessionId,
        page: window.location.pathname,
      }
    }

    // Sample the data based on configuration
    if (Math.random() <= PERFORMANCE_CONFIG.sampleRate) {
      this.sendMetric(metric)
    }
  }

  trackPageLoad(page: string, loadTime: number): void {
    if (!PERFORMANCE_CONFIG.trackPageLoads) return

    const metric: PerformanceMetric = {
      name: 'page_load',
      value: loadTime,
      timestamp: Date.now(),
      metadata: {
        page,
        sessionId: this.sessionId,
        environment: APP_CONFIG.environment,
      }
    }

    this.sendMetric(metric)
  }

  trackUserAction(action: string, element?: string, metadata?: Record<string, any>): void {
    if (!PERFORMANCE_CONFIG.trackUserActions) return

    const userAction: UserAction = {
      action,
      element,
      page: typeof window !== 'undefined' ? window.location.pathname : '',
      timestamp: Date.now(),
      sessionId: this.sessionId,
      metadata,
    }

    this.sendUserAction(userAction)
  }

  trackError(error: Error, metadata?: Record<string, any>): void {
    if (!PERFORMANCE_CONFIG.trackErrors) return

    const errorData = {
      message: error.message,
      stack: error.stack,
      timestamp: Date.now(),
      sessionId: this.sessionId,
      page: typeof window !== 'undefined' ? window.location.pathname : '',
      userAgent: typeof navigator !== 'undefined' ? navigator.userAgent : '',
      metadata,
    }

    this.sendError(errorData)
  }

  trackCustomMetric(name: string, value: number, metadata?: Record<string, any>): void {
    const metric: PerformanceMetric = {
      name,
      value,
      timestamp: Date.now(),
      metadata: {
        ...metadata,
        sessionId: this.sessionId,
        page: typeof window !== 'undefined' ? window.location.pathname : '',
      }
    }

    this.sendMetric(metric)
  }

  private sendMetric(metric: PerformanceMetric): void {
    if (APP_CONFIG.isDevelopment) {
      console.log('Performance Metric:', metric)
    }

    // In production, send to analytics service
    // This would be replaced with actual analytics service integration
    if (APP_CONFIG.isProduction) {
      this.sendToAnalytics('metric', metric)
    }
  }

  private sendUserAction(action: UserAction): void {
    if (APP_CONFIG.isDevelopment) {
      console.log('User Action:', action)
    }

    if (APP_CONFIG.isProduction) {
      this.sendToAnalytics('action', action)
    }
  }

  private sendError(error: any): void {
    if (APP_CONFIG.isDevelopment) {
      console.error('Error Tracked:', error)
    }

    if (APP_CONFIG.isProduction) {
      this.sendToAnalytics('error', error)
    }
  }

  private sendToAnalytics(type: string, data: any): void {
    // Mock implementation - replace with actual analytics service
    // Example: Google Analytics, Mixpanel, Sentry, etc.
    if (typeof window !== 'undefined' && 'navigator' in window && 'sendBeacon' in navigator) {
      const payload = JSON.stringify({ type, data, timestamp: Date.now() })
      // navigator.sendBeacon('/api/analytics', payload)
    }
  }

  getSessionId(): string {
    return this.sessionId
  }

  destroy(): void {
    if (this.observer) {
      this.observer.disconnect()
    }
  }
}

// Create singleton instance
export const performanceMonitor = new PerformanceMonitor()

// Export utility functions
export const trackPageLoad = (page: string, loadTime: number) => 
  performanceMonitor.trackPageLoad(page, loadTime)

export const trackUserAction = (action: string, element?: string, metadata?: Record<string, any>) => 
  performanceMonitor.trackUserAction(action, element, metadata)

export const trackError = (error: Error, metadata?: Record<string, any>) => 
  performanceMonitor.trackError(error, metadata)

export const trackCustomMetric = (name: string, value: number, metadata?: Record<string, any>) => 
  performanceMonitor.trackCustomMetric(name, value, metadata)

export const getSessionId = () => performanceMonitor.getSessionId()