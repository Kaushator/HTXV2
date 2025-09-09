#!/bin/bash
# Скрипт для быстрой настройки локальной среды разработки

set -e

echo "🚀 Настройка локальной среды разработки HTX Interface..."

# Проверяем наличие необходимых утилит
command -v terraform >/dev/null 2>&1 || { echo "❌ Terraform не установлен. Установите: https://terraform.io/downloads"; exit 1; }
command -v gcloud >/dev/null 2>&1 || { echo "❌ gcloud CLI не установлен. Установите: https://cloud.google.com/sdk/docs/install"; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "❌ jq не установлен. Установите: apt-get install jq"; exit 1; }

# Переходим в директорию Terraform
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TERRAFORM_DIR="$PROJECT_ROOT/infra/terraform"

if [ ! -d "$TERRAFORM_DIR" ]; then
    echo "❌ Terraform директория не найдена: $TERRAFORM_DIR"
    exit 1
fi

cd "$TERRAFORM_DIR"

echo "📁 Работаем в директории: $(pwd)"

# Проверяем, что Terraform инициализирован
if [ ! -d ".terraform" ]; then
    echo "🔧 Инициализация Terraform..."
    terraform init
fi

# Получаем outputs из Terraform
echo "📊 Получение Terraform outputs..."

if ! terraform output >/dev/null 2>&1; then
    echo "❌ Terraform outputs недоступны. Убедитесь, что terraform apply был выполнен."
    echo "💡 Выполните: cd $TERRAFORM_DIR && terraform apply"
    exit 1
fi

# Создаем .env файл в корне проекта
echo "📝 Создание .env файла..."
terraform output -json local_env_vars | jq -r 'to_entries[] | "\(.key)=\(.value)"' > "$PROJECT_ROOT/.env"

# Создаем .env файл для frontend
echo "📝 Создание .env.local для frontend..."
mkdir -p "$PROJECT_ROOT/frontend"
{
    echo "NEXT_PUBLIC_BACKEND_URL=$(terraform output -raw backend_url)"
    echo "NEXT_PUBLIC_WS_URL=$(terraform output -raw websocket_url)/ws"
    echo "NEXT_PUBLIC_FINGPT_URL=$(terraform output -raw fingpt_url)"
} > "$PROJECT_ROOT/frontend/.env.local"

# Настраиваем gcloud CLI
echo "⚙️  Настройка gcloud CLI..."
PROJECT_ID=$(terraform output -json project_info | jq -r '.project_id')
REGION=$(terraform output -json project_info | jq -r '.region')
ZONE=$(terraform output -json project_info | jq -r '.zone')

gcloud config set project "$PROJECT_ID"
gcloud config set compute/region "$REGION"
gcloud config set compute/zone "$ZONE"

# Настраиваем Docker для Artifact Registry
echo "🐳 Настройка Docker для Artifact Registry..."
gcloud auth configure-docker us-central1-docker.pkg.dev --quiet

# Создаем файл с полезными командами
echo "📋 Создание файла с полезными командами..."
cat > "$PROJECT_ROOT/scripts/dev-commands.sh" << 'EOF'
#!/bin/bash
# Полезные команды для разработки

# Получить URL сервисов
function get_urls() {
    cd infra/terraform
    echo "Backend:  $(terraform output -raw backend_url)"
    echo "Frontend: $(terraform output -raw frontend_url)"
    echo "FinGPT:   $(terraform output -raw fingpt_url)"
    echo "WebSocket: $(terraform output -raw websocket_url)/ws"
}

# Проверить health всех сервисов
function check_health() {
    cd infra/terraform
    BACKEND_URL=$(terraform output -raw backend_url)
    FRONTEND_URL=$(terraform output -raw frontend_url)
    FINGPT_URL=$(terraform output -raw fingpt_url)
    
    echo "🔍 Проверка health endpoints..."
    echo "Backend:  $(curl -s $BACKEND_URL/health | jq -r '.status // "ERROR"')"
    echo "Frontend: $(curl -s $FRONTEND_URL/health | jq -r '.status // "ERROR"')"
    echo "FinGPT:   $(curl -s $FINGPT_URL/health | jq -r '.status // "ERROR"')"
}

# Быстрый деплой сервиса
function deploy() {
    local service=$1
    if [ -z "$service" ]; then
        echo "Использование: deploy [backend|frontend|fingpt|all]"
        return 1
    fi
    
    cd infra/terraform
    if [ "$service" = "all" ]; then
        echo "🚀 Деплой всех сервисов..."
        eval $(terraform output -json deploy_commands | jq -r '.backend')
        eval $(terraform output -json deploy_commands | jq -r '.frontend')
        eval $(terraform output -json deploy_commands | jq -r '.fingpt')
    else
        echo "🚀 Деплой $service..."
        eval $(terraform output -json deploy_commands | jq -r ".$service")
    fi
}

# Получить логи сервиса
function get_logs() {
    local service=$1
    local limit=${2:-50}
    if [ -z "$service" ]; then
        echo "Использование: get_logs [backend|frontend|fingpt] [limit]"
        return 1
    fi
    
    gcloud logs read "resource.type=cloud_run_revision AND resource.labels.service_name=htx-interface-$service" --limit $limit
}

# Pull Docker образов для локальной разработки
function pull_images() {
    cd infra/terraform
    echo "🐳 Pulling Docker образов..."
    BACKEND_IMAGE=$(terraform output -json docker_images | jq -r '.backend')
    FRONTEND_IMAGE=$(terraform output -json docker_images | jq -r '.frontend')
    FINGPT_IMAGE=$(terraform output -json docker_images | jq -r '.fingpt')
    
    docker pull $BACKEND_IMAGE
    docker pull $FRONTEND_IMAGE
    docker pull $FINGPT_IMAGE
    
    echo "✅ Образы загружены. Для запуска используйте:"
    echo "docker run -p 8000:8000 $BACKEND_IMAGE"
    echo "docker run -p 3000:3000 $FRONTEND_IMAGE"
    echo "docker run -p 8055:8055 $FINGPT_IMAGE"
}

echo "Доступные команды:"
echo "  get_urls     - получить URL всех сервисов"
echo "  check_health - проверить health endpoints"
echo "  deploy       - деплой сервиса (backend|frontend|fingpt|all)"
echo "  get_logs     - получить логи сервиса"
echo "  pull_images  - загрузить Docker образы"
EOF

chmod +x "$PROJECT_ROOT/scripts/dev-commands.sh"

# Создаем alias для удобства
echo "🔗 Создание alias для быстрого доступа к командам..."
cat >> "$PROJECT_ROOT/.env" << EOF

# Полезные alias для разработки
alias dev-cmd="source $PROJECT_ROOT/scripts/dev-commands.sh"
alias get-urls="cd $TERRAFORM_DIR && terraform output | grep '_url'"
alias check-health="cd $TERRAFORM_DIR && source $PROJECT_ROOT/scripts/dev-commands.sh && check_health"
EOF

echo "✅ Локальная среда настроена!"
echo ""
echo "📋 Что было создано:"
echo "  ✓ .env файл в корне проекта"
echo "  ✓ .env.local файл для frontend"
echo "  ✓ gcloud CLI настроен для проекта $PROJECT_ID"
echo "  ✓ Docker настроен для Artifact Registry"
echo "  ✓ Полезные команды в scripts/dev-commands.sh"
echo ""
echo "🚀 Быстрый старт:"
echo "  source .env                     # Загрузить environment переменные"
echo "  source scripts/dev-commands.sh  # Загрузить полезные функции"
echo "  get_urls                        # Получить URL сервисов"
echo "  check_health                    # Проверить статус сервисов"
echo ""
echo "📖 Подробная документация: docs/terraform-outputs.md"
