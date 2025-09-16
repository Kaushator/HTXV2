#!/usr/bin/env bash
# Скрипт инициализации для dev-контейнера HTXV2

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

echo -e "${CYAN}===============================================${RESET}"
echo -e "${CYAN}    ИНИЦИАЛИЗАЦИЯ DEV-КОНТЕЙНЕРА HTXV2${RESET}"
echo -e "${CYAN}===============================================${RESET}"
echo -e "Начало инициализации: $(date +"%Y-%m-%d %H:%M:%S")\n"

# 1. Установка PowerShell Core
echo -e "Установка PowerShell Core..."
if ! command -v pwsh &> /dev/null; then
  # Добавляем репозиторий Microsoft
  curl -sSL https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
  curl -sSL https://packages.microsoft.com/config/ubuntu/20.04/prod.list | tee /etc/apt/sources.list.d/microsoft.list

  # Обновляем и устанавливаем PowerShell
  apt-get update
  apt-get install -y powershell

  if [ $? -eq 0 ]; then
    print_status "PowerShell Core установлен успешно" "УСПЕХ" "${GREEN}"
  else
    print_status "Ошибка при установке PowerShell Core" "ОШИБКА" "${RED}"
  fi
else
  print_status "PowerShell Core уже установлен" "ИНФО" "${CYAN}"
fi

# 2. Установка дополнительных утилит
echo -e "\nУстановка дополнительных утилит..."
apt-get update
apt-get install -y zip unzip curl wget git jq

# 3. Настройка прав на скрипты
echo -e "\nНастройка прав на скрипты..."
chmod +x /workspace/.devcontainer/scripts/powershell/*.ps1
chmod +x /workspace/.devcontainer/scripts/*.sh
print_status "Права на скрипты обновлены" "УСПЕХ" "${GREEN}"

# 4. Создание символических ссылок для удобного доступа
echo -e "\nСоздание символических ссылок..."
mkdir -p /usr/local/bin/htxv2
ln -sf /workspace/.devcontainer/scripts/powershell/test-containers.ps1 /usr/local/bin/htxv2/test-containers
ln -sf /workspace/.devcontainer/scripts/powershell/update-containers.ps1 /usr/local/bin/htxv2/update-containers
ln -sf /workspace/.devcontainer/scripts/powershell/backup-data.ps1 /usr/local/bin/htxv2/backup-data

# Создаем обертки для скриптов
for script in test-containers update-containers backup-data; do
  cat > /usr/local/bin/$script << EOF
#!/usr/bin/env bash
pwsh /workspace/.devcontainer/scripts/powershell/$script.ps1 "\$@"
EOF
  chmod +x /usr/local/bin/$script
done

print_status "Символические ссылки созданы" "УСПЕХ" "${GREEN}"

# 5. Настройка Bash-дополнений для удобства работы
echo -e "\nНастройка Bash-дополнений..."

# Добавляем алиасы в .bashrc
cat > /root/.bash_aliases << EOF
# HTXV2 aliases
alias test-htx='pwsh /workspace/.devcontainer/scripts/powershell/test-containers.ps1'
alias update-htx='pwsh /workspace/.devcontainer/scripts/powershell/update-containers.ps1'
alias backup-htx='pwsh /workspace/.devcontainer/scripts/powershell/backup-data.ps1'
EOF

# Добавляем приветствие в .bashrc
cat >> /root/.bashrc << EOF

# HTXV2 welcome message
echo -e "${CYAN}===============================================${RESET}"
echo -e "${CYAN}    HTXV2 DEV ENVIRONMENT${RESET}"
echo -e "${CYAN}===============================================${RESET}"
echo -e "Доступные команды:"
echo -e "  ${GREEN}test-htx${RESET}    - Тестирование контейнеров"
echo -e "  ${GREEN}update-htx${RESET}  - Обновление контейнеров"
echo -e "  ${GREEN}backup-htx${RESET}  - Создание резервных копий данных"
echo -e "${CYAN}===============================================${RESET}"
EOF

print_status "Bash-дополнения настроены" "УСПЕХ" "${GREEN}"

# 6. Создание базы данных htx в PostgreSQL (если необходимо)
echo -e "\nПроверка и создание базы данных htx..."
sleep 10 # Даем время на запуск PostgreSQL

# Проверяем существование базы данных
docker exec -it htxenterface_v2-postgres-1 psql -U htx -d htxdb -c "SELECT 1 FROM pg_database WHERE datname = 'htx'" | grep -q 1
if [ $? -ne 0 ]; then
  # База данных не существует, создаем ее
  docker exec -it htxenterface_v2-postgres-1 psql -U htx -d htxdb -c "CREATE DATABASE htx;"
  if [ $? -eq 0 ]; then
    print_status "База данных htx создана" "УСПЕХ" "${GREEN}"
  else
    print_status "Ошибка при создании базы данных htx" "ОШИБКА" "${RED}"
  fi
else
  print_status "База данных htx уже существует" "ИНФО" "${CYAN}"
fi

# 7. Вывод итогового результата
echo -e "\n${CYAN}===============================================${RESET}"
echo -e "${CYAN}    РЕЗУЛЬТАТЫ ИНИЦИАЛИЗАЦИИ${RESET}"
echo -e "${CYAN}===============================================${RESET}"
print_status "Инициализация dev-контейнера завершена" "УСПЕХ" "${GREEN}"
echo -e "\nИнициализация завершена: $(date +"%Y-%m-%d %H:%M:%S")"
echo -e "${CYAN}===============================================${RESET}"
