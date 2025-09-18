#!/bin/bash
# Быстрые команды для HTXV2 MCP

# Алиасы для MCP инструментов
alias mcp-health='echo "/tools health_check all"'
alias mcp-assets='echo "/tools list_assets"'
alias mcp-btc='echo "/tools market_analysis BTC 1h"'
alias mcp-eth='echo "/tools market_analysis ETH 1h"'
alias mcp-portfolio='echo "/tools portfolio_status"'
alias mcp-signals='echo "/tools trading_signals"'

# Функции для быстрого доступа
mcp_analyze() {
  local symbol=${1:-BTC}
  local timeframe=${2:-1h}
  echo "/tools market_analysis $symbol $timeframe"
}

mcp_upload() {
  local file=${1:-""}
  local type=${2:-portfolio}
  echo "/tools upload_csv $file $type"
}

# Экспорт функций
export -f mcp_analyze mcp_upload

echo "🚀 HTXV2 MCP быстрые команды загружены!"
echo "Используйте: mcp_analyze BTC 4h"
echo "Или: mcp_upload /path/to/file.csv portfolio"