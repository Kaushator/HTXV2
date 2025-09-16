#!/usr/bin/env bash
# Скрипт для проверки и создания необходимых баз данных PostgreSQL
# Используется для инициализации среды разработки HTXV2

# Параметры
POSTGRES_CONTAINER="htxenterface_v2-postgres-1"
POSTGRES_USER="htx"
POSTGRES_DEFAULT_DB="htxdb"
REQUIRED_DATABASES=("htx" "htxdb")

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

# Функция для проверки состояния контейнера
check_container_status() {
  local container_name=$1

  docker inspect --format="{{.State.Status}}" $container_name 2>/dev/null || echo "not_found"
}

# Функция для выполнения команды в контейнере PostgreSQL
run_postgres_command() {
  local container_name=$1
  local user=$2
  local database=$3
  local command=$4

  docker exec $container_name psql -U $user -d $database -c "$command" 2>&1
  return $?
}

# Проверка наличия контейнера PostgreSQL
echo -e "Проверка наличия контейнера PostgreSQL ($POSTGRES_CONTAINER)..."
container_status=$(check_container_status $POSTGRES_CONTAINER)

if [ "$container_status" = "not_found" ]; then
  print_status "Контейнер PostgreSQL не запущен!" "ОШИБКА" "${RED}"
  echo "Запустите контейнеры с помощью 'docker compose up -d' перед выполнением этого скрипта."
  exit 1
elif [ "$container_status" != "running" ]; then
  print_status "Контейнер PostgreSQL имеет статус: $container_status" "ОШИБКА" "${RED}"
  echo "Запустите контейнеры с помощью 'docker compose up -d' перед выполнением этого скрипта."
  exit 1
else
  print_status "Контейнер PostgreSQL запущен и работает" "УСПЕХ" "${GREEN}"
fi

# Даем PostgreSQL время на запуск и инициализацию
echo "Даем PostgreSQL время на инициализацию..."
sleep 3

# Проверка и создание всех необходимых баз данных
echo -e "\nПроверка наличия необходимых баз данных..."
for db in "${REQUIRED_DATABASES[@]}"; do
  echo -n "Проверка базы данных '$db'... "

  # Проверяем существование базы данных
  check_db_cmd="SELECT 1 FROM pg_database WHERE datname = '$db'"
  db_exists=$(run_postgres_command $POSTGRES_CONTAINER $POSTGRES_USER $POSTGRES_DEFAULT_DB "$check_db_cmd")

  if echo "$db_exists" | grep -q "1 row"; then
    echo -e "${GREEN}существует!${RESET}"
  else
    echo -e "${YELLOW}не существует.${RESET}"
    echo -n "  Создание базы данных '$db'... "

    # База данных не существует, создаем ее
    create_db_cmd="CREATE DATABASE $db;"
    run_postgres_command $POSTGRES_CONTAINER $POSTGRES_USER $POSTGRES_DEFAULT_DB "$create_db_cmd"

    if [ $? -eq 0 ]; then
      echo -e "${GREEN}создана!${RESET}"
    else
      echo -e "${RED}ошибка создания!${RESET}"
      echo -e "  ${RED}$result${RESET}"
    fi
  fi
done

# Вывод информации о базах данных
echo -e "\nСписок всех баз данных в PostgreSQL:"
list_db_cmd="\l"
db_list=$(run_postgres_command $POSTGRES_CONTAINER $POSTGRES_USER $POSTGRES_DEFAULT_DB "$list_db_cmd")
echo "$db_list"

echo -e "\n${CYAN}===============================================${RESET}"
print_status "Проверка баз данных завершена" "УСПЕХ" "${GREEN}"
echo -e "${CYAN}===============================================${RESET}"
