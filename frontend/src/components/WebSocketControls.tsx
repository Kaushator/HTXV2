import { useState, useCallback } from 'react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Wifi, WifiOff, Settings, Play, Pause, Plus, X } from 'lucide-react'

interface WebSocketControlsProps {
  isConnected: boolean
  isConnecting: boolean
  symbols: string[]
  interval: number
  onConnect: () => void
  onDisconnect: () => void
  onSymbolsChange: (symbols: string[]) => void
  onIntervalChange: (interval: number) => void
}

export function WebSocketControls({
  isConnected,
  isConnecting,
  symbols,
  interval,
  onConnect,
  onDisconnect,
  onSymbolsChange,
  onIntervalChange
}: WebSocketControlsProps) {
  const [newSymbol, setNewSymbol] = useState('')
  const [showSettings, setShowSettings] = useState(false)

  const addSymbol = useCallback(() => {
    const symbol = newSymbol.trim().toUpperCase()
    if (symbol && !symbols.includes(symbol)) {
      onSymbolsChange([...symbols, symbol])
      setNewSymbol('')
    }
  }, [newSymbol, symbols, onSymbolsChange])

  const removeSymbol = useCallback((symbol: string) => {
    onSymbolsChange(symbols.filter(s => s !== symbol))
  }, [symbols, onSymbolsChange])

  const handleIntervalChange = useCallback((value: string) => {
    const num = parseInt(value)
    if (!isNaN(num) && num >= 200 && num <= 10000) {
      onIntervalChange(num)
    }
  }, [onIntervalChange])

  const getStatusColor = () => {
    if (isConnecting) return 'bg-yellow-100 text-yellow-800 border-yellow-200'
    if (isConnected) return 'bg-green-100 text-green-800 border-green-200'
    return 'bg-red-100 text-red-800 border-red-200'
  }

  const getStatusText = () => {
    if (isConnecting) return 'Connecting...'
    if (isConnected) return 'Connected'
    return 'Disconnected'
  }

  const getStatusIcon = () => {
    if (isConnecting) return <Wifi className="h-4 w-4 animate-pulse" />
    if (isConnected) return <Wifi className="h-4 w-4" />
    return <WifiOff className="h-4 w-4" />
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center justify-between">
          <span>WebSocket Control</span>
          <div className="flex items-center gap-2">
            <Badge className={getStatusColor()}>
              {getStatusIcon()}
              {getStatusText()}
            </Badge>
            <Button
              variant="outline"
              size="sm"
              onClick={() => setShowSettings(!showSettings)}
            >
              <Settings className="h-4 w-4" />
            </Button>
          </div>
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        {/* Connection Controls */}
        <div className="flex gap-2">
          <Button
            onClick={isConnected ? onDisconnect : onConnect}
            disabled={isConnecting}
            className="flex-1"
            variant={isConnected ? "destructive" : "default"}
          >
            {isConnected ? (
              <>
                <Pause className="h-4 w-4 mr-2" />
                Disconnect
              </>
            ) : (
              <>
                <Play className="h-4 w-4 mr-2" />
                Connect
              </>
            )}
          </Button>
        </div>

        {/* Symbols Management */}
        <div className="space-y-2">
          <Label className="text-sm font-medium">Symbols</Label>
          <div className="flex gap-2">
            <Input
              placeholder="Enter symbol (e.g., BTC)"
              value={newSymbol}
              onChange={(e: React.ChangeEvent<HTMLInputElement>) => setNewSymbol(e.target.value)}
              onKeyPress={(e: React.KeyboardEvent<HTMLInputElement>) => e.key === 'Enter' && addSymbol()}
              className="flex-1"
            />
            <Button onClick={addSymbol} size="sm">
              <Plus className="h-4 w-4" />
            </Button>
          </div>
          
          {symbols.length > 0 && (
            <div className="flex flex-wrap gap-1 mt-2">
              {symbols.map((symbol) => (
                <Badge
                  key={symbol}
                  variant="outline"
                  className="cursor-pointer hover:bg-gray-100 dark:hover:bg-gray-800"
                  onClick={() => removeSymbol(symbol)}
                >
                  {symbol}
                  <X className="h-3 w-3 ml-1" />
                </Badge>
              ))}
            </div>
          )}
        </div>

        {/* Settings */}
        {showSettings && (
          <div className="space-y-3 pt-3 border-t">
            <div className="space-y-2">
              <Label htmlFor="interval" className="text-sm font-medium">
                Update Interval (ms)
              </Label>
              <Input
                id="interval"
                type="number"
                min="200"
                max="10000"
                step="100"
                value={interval}
                onChange={(e: React.ChangeEvent<HTMLInputElement>) => handleIntervalChange(e.target.value)}
              />
              <p className="text-xs text-gray-500">
                Minimum: 200ms, Maximum: 10000ms
              </p>
            </div>
          </div>
        )}

        {/* Connection Info */}
        {symbols.length > 0 && (
          <div className="text-xs text-gray-500 space-y-1">
            <div>Tracking: {symbols.join(', ')}</div>
            <div>Update every: {interval}ms</div>
            {isConnected && (
              <div className="text-green-600">
                Live data streaming active
              </div>
            )}
          </div>
        )}
      </CardContent>
    </Card>
  )
}
