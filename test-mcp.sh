#!/bin/bash
# Тест MCP функциональности для HTXV2

echo "🧪 Тестирование MCP инструментов HTXV2..."
echo "================================================"

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
RESET='\033[0m'

# Функция вывода с форматированием
print_status() {
  local message=$1
  local status=$2
  local color=$3
  echo -e "[$color$status$RESET] $message"
}

# 1. Проверка Node.js и npm
echo -e "\n${CYAN}1. Проверка Node.js и npm...${RESET}"
if command -v node &> /dev/null; then
  print_status "Node.js: $(node --version)" "УСПЕХ" "${GREEN}"
else
  print_status "Node.js не найден" "ОШИБКА" "${RED}"
fi

if command -v npm &> /dev/null; then
  print_status "npm: $(npm --version)" "УСПЕХ" "${GREEN}"
else
  print_status "npm не найден" "ОШИБКА" "${RED}"
fi

# 2. Проверка MCP зависимостей
echo -e "\n${CYAN}2. Проверка MCP зависимостей...${RESET}"
cd /workspace/.mcp

if [ -f "package.json" ]; then
  print_status "package.json найден" "УСПЕХ" "${GREEN}"
else
  print_status "package.json не найден" "ОШИБКА" "${RED}"
fi

if [ -f "node_modules/@modelcontextprotocol/sdk/package.json" ]; then
  print_status "MCP SDK установлен" "УСПЕХ" "${GREEN}"
else
  print_status "MCP SDK не установлен" "ОШИБКА" "${RED}"
fi

# 3. Проверка MCP сервера
echo -e "\n${CYAN}3. Проверка MCP сервера...${RESET}"
if [ -f "server.js" ]; then
  print_status "server.js найден" "УСПЕХ" "${GREEN}"
else
  print_status "server.js не найден" "ОШИБКА" "${RED}"
fi

# 4. Тест запуска MCP сервера
echo -e "\n${CYAN}4. Тест запуска MCP сервера...${RESET}"
timeout 5s node server.js &
MCP_PID=$!
sleep 2

if kill -0 $MCP_PID 2>/dev/null; then
  print_status "MCP сервер запущен успешно" "УСПЕХ" "${GREEN}"
  kill $MCP_PID 2>/dev/null
else
  print_status "MCP сервер не запустился" "ОШИБКА" "${RED}"
fi

# 5. Проверка VS Code настроек
echo -e "\n${CYAN}5. Проверка VS Code настроек...${RESET}"
if [ -f "/workspace/.vscode/settings.json" ]; then
  print_status "VS Code настройки найдены" "УСПЕХ" "${GREEN}"
  
  # Проверка MCP конфигурации
  if grep -q "mcp.servers" /workspace/.vscode/settings.json; then
    print_status "MCP сервер настроен в VS Code" "УСПЕХ" "${GREEN}"
  else
    print_status "MCP сервер не настроен в VS Code" "ПРЕДУПРЕЖДЕНИЕ" "${YELLOW}"
  fi
else
  print_status "VS Code настройки не найдены" "ОШИБКА" "${RED}"
fi

# 6. Проверка быстрых команд
echo -e "\n${CYAN}6. Проверка быстрых команд...${RESET}"
if [ -f "/workspace/.mcp/quick-commands.sh" ]; then
  print_status "Быстрые команды найдены" "УСПЕХ" "${GREEN}"
else
  print_status "Быстрые команды не найдены" "ПРЕДУПРЕЖДЕНИЕ" "${YELLOW}"
fi

# 7. Проверка документации
echo -e "\n${CYAN}7. Проверка документации...${RESET}"
if [ -f "/workspace/.mcp/TOKEN_ECONOMY.md" ]; then
  print_status "Инструкции по экономии токенов найдены" "УСПЕХ" "${GREEN}"
else
  print_status "Инструкции по экономии токенов не найдены" "ОШИБКА" "${RED}"
fi

if [ -f "/workspace/.mcp/CODESPACE_SETUP.md" ]; then
  print_status "Инструкции по настройке codespace найдены" "УСПЕХ" "${GREEN}"
else
  print_status "Инструкции по настройке codespace не найдены" "ОШИБКА" "${RED}"
fi

# 8. Итоговый результат
echo -e "\n${CYAN}===============================================${RESET}"
echo -e "${CYAN}    РЕЗУЛЬТАТЫ ТЕСТИРОВАНИЯ MCP${RESET}"
echo -e "${CYAN}===============================================${RESET}"

echo -e "\n${GREEN}✅ Доступные MCP инструменты:${RESET}"
echo -e "  • health_check - проверка системы"
echo -e "  • list_assets - список активов"
echo -e "  • market_analysis - анализ рынка"
echo -e "  • portfolio_status - статус портфеля"
echo -e "  • trading_signals - торговые сигналы"
echo -e "  • upload_csv - загрузка данных"

echo -e "\n${GREEN}✅ Быстрые команды:${RESET}"
echo -e "  • mcp-health - проверка системы"
echo -e "  • mcp-assets - список активов"
echo -e "  • mcp-btc - анализ Bitcoin"
echo -e "  • mcp-portfolio - портфель"

echo -e "\n${GREEN}✅ Экономия токенов:${RESET}"
echo -e "  • Используйте /tools для системных команд"
echo -e "  • Группируйте связанные запросы"
echo -e "  • Конкретизируйте параметры"
echo -e "  • Читайте TOKEN_ECONOMY.md"

echo -e "\n${YELLOW}💡 Следующие шаги:${RESET}"
echo -e "  1. Откройте Copilot Chat в VS Code"
echo -e "  2. Введите /tools для проверки инструментов"
echo -e "  3. Протестируйте: /tools health_check"
echo -e "  4. Изучите экономию токенов в TOKEN_ECONOMY.md"

echo -e "\nТестирование завершено: $(date +"%Y-%m-%d %H:%M:%S")"
echo -e "${CYAN}===============================================${RESET}"