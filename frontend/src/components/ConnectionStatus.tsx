import React from 'react'
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Wifi, WifiOff, Loader2, AlertCircle, RotateCcw } from "lucide-react"

export type ConnectionStatusType = 'connected' | 'disconnected' | 'connecting' | 'error' | 'reconnecting'

interface ConnectionStatusProps {
  status: ConnectionStatusType
  reconnectAttemptsLeft?: number
  nextReconnectIn?: number
  onManualReconnect?: () => void
}

export function ConnectionStatus({ 
  status, 
  reconnectAttemptsLeft = 0, 
  nextReconnectIn = 0, 
  onManualReconnect 
}: ConnectionStatusProps) {
  const getStatusConfig = () => {
    switch (status) {
      case 'connected':
        return {
          icon: <Wifi className="h-4 w-4" data-testid="connection-status-icon" />,
          label: 'Подключен',
          variant: 'default' as const,
          className: 'bg-green-500 text-white'
        }
      case 'connecting':
        return {
          icon: <Loader2 className="h-4 w-4 animate-spin" data-testid="connection-status-icon" />,
          label: 'Подключение...',
          variant: 'secondary' as const,
          className: 'bg-yellow-500 text-white'
        }
      case 'reconnecting':
        return {
          icon: <RotateCcw className="h-4 w-4 animate-spin" data-testid="connection-status-icon" />,
          label: 'Переподключение...',
          variant: 'secondary' as const,
          className: 'bg-orange-500 text-white'
        }
      case 'error':
        return {
          icon: <AlertCircle className="h-4 w-4" data-testid="connection-status-icon" />,
          label: 'Ошибка',
          variant: 'destructive' as const,
          className: 'bg-red-500 text-white'
        }
      case 'disconnected':
        return {
          icon: <WifiOff className="h-4 w-4" data-testid="connection-status-icon" />,
          label: 'Отключен',
          variant: 'outline' as const,
          className: 'bg-gray-500 text-white'
        }
      default:
        return {
          icon: <WifiOff className="h-4 w-4" data-testid="connection-status-icon" />,
          label: 'Неизвестно',
          variant: 'outline' as const,
          className: 'bg-gray-500 text-white'
        }
    }
  }

  const config = getStatusConfig()
  const showReconnectButton = status === 'disconnected' || status === 'error'

  return (
    <div className="flex items-center gap-2">
      <Badge variant={config.variant} className={config.className}>
        <div className="flex items-center gap-1">
          {config.icon}
          <span>{config.label}</span>
        </div>
      </Badge>
      
      {/* Reconnection info */}
      {status === 'reconnecting' && (
        <div className="flex flex-col text-xs text-gray-500">
          {reconnectAttemptsLeft > 0 && (
            <span>(осталось попыток: {reconnectAttemptsLeft})</span>
          )}
          {nextReconnectIn > 0 && (
            <span>(через {nextReconnectIn}с)</span>
          )}
        </div>
      )}
      
      {/* Manual reconnect button */}
      {showReconnectButton && onManualReconnect && (
        <Button
          variant="outline"
          size="sm"
          onClick={onManualReconnect}
          className="h-8 px-3 text-xs"
        >
          Переподключиться
        </Button>
      )}
    </div>
  )
}
