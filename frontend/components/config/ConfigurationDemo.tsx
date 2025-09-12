// Configuration demo component to showcase new settings
'use client'

import { useState, useEffect } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { API_CONFIG, WS_CONFIG, FEATURE_FLAGS, APP_CONFIG, PERFORMANCE_CONFIG } from '@/lib/config'
import { trackUserAction, trackCustomMetric } from '@/lib/performance'
import { apiClient } from '@/lib/api'
import { WebSocketClient } from '@/lib/websocket'

export function ConfigurationDemo() {
  const [wsStatus, setWsStatus] = useState<string>('disconnected')
  const [apiStatus, setApiStatus] = useState<string>('checking')

  useEffect(() => {
    // Test API health check
    apiClient.healthCheck()
      .then(isHealthy => setApiStatus(isHealthy ? 'healthy' : 'unhealthy'))
      .catch(() => setApiStatus('error'))

    // Track page view
    trackCustomMetric('config_demo_viewed', 1, { timestamp: Date.now() })
  }, [])

  const handleTrackAction = () => {
    trackUserAction('demo_button_clicked', 'config_demo_button', {
      timestamp: Date.now(),
      feature: 'configuration_demo',
    })
  }

  const handleWSTest = () => {
    const ws = new WebSocketClient(WS_CONFIG.url, {}, {
      onStatusChange: (status) => setWsStatus(status),
    })
    ws.connect()
    
    // Disconnect after 5 seconds
    setTimeout(() => {
      ws.disconnect()
      setWsStatus('disconnected')
    }, 5000)
  }

  return (
    <div className="space-y-6">
      <div className="text-center space-y-2">
        <h1 className="text-3xl font-bold">Configuration Demo</h1>
        <p className="text-muted-foreground">
          Showcasing new frontend configuration and feature flags
        </p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* App Configuration */}
        <Card>
          <CardHeader>
            <CardTitle>App Configuration</CardTitle>
            <CardDescription>Basic application settings</CardDescription>
          </CardHeader>
          <CardContent className="space-y-2">
            <div className="flex justify-between">
              <span className="font-medium">Name:</span>
              <span>{APP_CONFIG.name}</span>
            </div>
            <div className="flex justify-between">
              <span className="font-medium">Version:</span>
              <span>{APP_CONFIG.version}</span>
            </div>
            <div className="flex justify-between">
              <span className="font-medium">Environment:</span>
              <Badge variant={APP_CONFIG.isDevelopment ? 'secondary' : 'default'}>
                {APP_CONFIG.environment}
              </Badge>
            </div>
          </CardContent>
        </Card>

        {/* Feature Flags */}
        <Card>
          <CardHeader>
            <CardTitle>Feature Flags</CardTitle>
            <CardDescription>Current feature flag status</CardDescription>
          </CardHeader>
          <CardContent className="space-y-2">
            {Object.entries(FEATURE_FLAGS).map(([key, value]) => (
              <div key={key} className="flex justify-between items-center">
                <span className="text-sm font-medium">
                  {key.replace('ENABLE_', '').replace(/_/g, ' ')}:
                </span>
                <Badge variant={value ? 'default' : 'secondary'}>
                  {value ? 'Enabled' : 'Disabled'}
                </Badge>
              </div>
            ))}
          </CardContent>
        </Card>

        {/* API Configuration */}
        <Card>
          <CardHeader>
            <CardTitle>API Configuration</CardTitle>
            <CardDescription>API settings and health status</CardDescription>
          </CardHeader>
          <CardContent className="space-y-2">
            <div className="flex justify-between">
              <span className="font-medium">Base URL:</span>
              <span className="text-sm text-muted-foreground truncate max-w-[200px]">
                {API_CONFIG.baseURL}
              </span>
            </div>
            <div className="flex justify-between">
              <span className="font-medium">Timeout:</span>
              <span>{API_CONFIG.timeout}ms</span>
            </div>
            <div className="flex justify-between">
              <span className="font-medium">Retries:</span>
              <span>{API_CONFIG.retries}</span>
            </div>
            <div className="flex justify-between">
              <span className="font-medium">Health Status:</span>
              <Badge 
                variant={
                  apiStatus === 'healthy' ? 'default' : 
                  apiStatus === 'checking' ? 'secondary' : 'destructive'
                }
              >
                {apiStatus}
              </Badge>
            </div>
          </CardContent>
        </Card>

        {/* WebSocket Configuration */}
        <Card>
          <CardHeader>
            <CardTitle>WebSocket Configuration</CardTitle>
            <CardDescription>Real-time connection settings</CardDescription>
          </CardHeader>
          <CardContent className="space-y-2">
            <div className="flex justify-between">
              <span className="font-medium">URL:</span>
              <span className="text-sm text-muted-foreground truncate max-w-[200px]">
                {WS_CONFIG.url}
              </span>
            </div>
            <div className="flex justify-between">
              <span className="font-medium">Reconnect Interval:</span>
              <span>{WS_CONFIG.reconnectInterval}ms</span>
            </div>
            <div className="flex justify-between">
              <span className="font-medium">Max Attempts:</span>
              <span>{WS_CONFIG.maxReconnectAttempts}</span>
            </div>
            <div className="flex justify-between">
              <span className="font-medium">Status:</span>
              <Badge 
                variant={
                  wsStatus === 'connected' ? 'default' : 
                  wsStatus === 'connecting' ? 'secondary' : 'outline'
                }
              >
                {wsStatus}
              </Badge>
            </div>
            <Button onClick={handleWSTest} size="sm" className="w-full">
              Test WebSocket Connection
            </Button>
          </CardContent>
        </Card>

        {/* Performance Monitoring */}
        <Card>
          <CardHeader>
            <CardTitle>Performance Monitoring</CardTitle>
            <CardDescription>Monitoring and analytics settings</CardDescription>
          </CardHeader>
          <CardContent className="space-y-2">
            <div className="flex justify-between">
              <span className="font-medium">Enabled:</span>
              <Badge variant={PERFORMANCE_CONFIG.enabled ? 'default' : 'secondary'}>
                {PERFORMANCE_CONFIG.enabled ? 'Yes' : 'No'}
              </Badge>
            </div>
            <div className="flex justify-between">
              <span className="font-medium">Sample Rate:</span>
              <span>{(PERFORMANCE_CONFIG.sampleRate * 100).toFixed(1)}%</span>
            </div>
            <div className="flex justify-between">
              <span className="font-medium">Track Actions:</span>
              <Badge variant={PERFORMANCE_CONFIG.trackUserActions ? 'default' : 'secondary'}>
                {PERFORMANCE_CONFIG.trackUserActions ? 'Yes' : 'No'}
              </Badge>
            </div>
            <Button onClick={handleTrackAction} size="sm" className="w-full">
              Test Action Tracking
            </Button>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}