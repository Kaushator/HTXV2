# Terraform Outputs для разработки

Этот документ описывает полезные outputs, которые предоставляет Terraform конфигурация для упрощения локальной разработки и CI/CD.

## Основные URL сервисов

### Service URLs
```bash
# Получить URL backend сервиса
terraform output backend_url

# Получить URL frontend сервиса  
terraform output frontend_url

# Получить URL FinGPT сервиса
terraform output fingpt_url

# Получить WebSocket URL для frontend
terraform output websocket_url
```

### Пример использования:
```bash
# Установить environment переменные для локальной разработки
export BACKEND_URL=$(terraform output -raw backend_url)
export WEBSOCKET_URL=$(terraform output -raw websocket_url)
```

## Docker образы

### Получить URLs Docker образов:
```bash
# Все образы одной командой
terraform output docker_images

# Отдельные образы
terraform output -json docker_images | jq -r '.backend'
terraform output -json docker_images | jq -r '.frontend'
terraform output -json docker_images | jq -r '.fingpt'
```

### Пример использования для локальной разработки:
```bash
# Pull последних образов для локального тестирования
BACKEND_IMAGE=$(terraform output -json docker_images | jq -r '.backend')
docker pull $BACKEND_IMAGE
docker run -p 8000:8000 $BACKEND_IMAGE
```

## Environment переменные

### Получить все env переменные для локальной разработки:
```bash
terraform output local_env_vars
```

### Создать .env файл для локальной разработки:
```bash
# Генерация .env файла
terraform output -json local_env_vars | jq -r 'to_entries[] | "\(.key)=\(.value)"' > .env
```

### Пример .env файла:
```
BACKEND_URL=https://htx-interface-backend-xxx.run.app
FRONTEND_URL=https://htx-interface-frontend-xxx.run.app
FINGPT_URL=https://htx-interface-fingpt-xxx.run.app
WEBSOCKET_URL=wss://htx-interface-backend-xxx.run.app
GCP_PROJECT_ID=vibrant-period-470810-p7
GCP_REGION=us-central1
ARTIFACT_REGISTRY=us-central1-docker.pkg.dev/vibrant-period-470810-p7/htx-interface
```

## Команды деплоя

### Получить готовые команды для деплоя:
```bash
terraform output deploy_commands
```

### Быстрый деплой отдельных сервисов:
```bash
# Backend
eval $(terraform output -json deploy_commands | jq -r '.backend')

# Frontend  
eval $(terraform output -json deploy_commands | jq -r '.frontend')

# FinGPT
eval $(terraform output -json deploy_commands | jq -r '.fingpt')
```

## Информация о проекте

### Получить настройки GCP проекта:
```bash
terraform output project_info
```

### Настройка gcloud CLI:
```bash
# Установить проект по умолчанию
gcloud config set project $(terraform output -raw project_info | jq -r '.project_id')
gcloud config set compute/region $(terraform output -raw project_info | jq -r '.region')
gcloud config set compute/zone $(terraform output -raw project_info | jq -r '.zone')
```

## Artifact Registry

### Получить URL репозитория:
```bash
terraform output artifact_registry_url
```

### Настройка Docker для Artifact Registry:
```bash
# Настроить Docker authentication
gcloud auth configure-docker us-central1-docker.pkg.dev

# Push образа в registry
REGISTRY_URL=$(terraform output -raw artifact_registry_url | cut -d'/' -f1-3)
docker tag my-image:latest $REGISTRY_URL/backend:latest
docker push $REGISTRY_URL/backend:latest
```

## Полезные скрипты

### Скрипт для быстрой настройки локальной среды:
```bash
#!/bin/bash
# setup-local-env.sh

echo "Настройка локальной среды разработки..."

# Получаем outputs из Terraform
cd infra/terraform
terraform output -json local_env_vars > /tmp/env_vars.json
terraform output -json project_info > /tmp/project_info.json

# Создаем .env файл
echo "Создание .env файла..."
jq -r 'to_entries[] | "\(.key)=\(.value)"' /tmp/env_vars.json > ../../.env

# Настраиваем gcloud
echo "Настройка gcloud CLI..."
PROJECT_ID=$(jq -r '.project_id' /tmp/project_info.json)
REGION=$(jq -r '.region' /tmp/project_info.json)
ZONE=$(jq -r '.zone' /tmp/project_info.json)

gcloud config set project $PROJECT_ID
gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE

# Настраиваем Docker
echo "Настройка Docker для Artifact Registry..."
gcloud auth configure-docker us-central1-docker.pkg.dev

echo "Локальная среда настроена!"
echo "Environment переменные доступны в .env файле"
```

### Скрипт для быстрого деплоя:
```bash
#!/bin/bash
# quick-deploy.sh

SERVICE=$1
if [ -z "$SERVICE" ]; then
    echo "Использование: $0 [backend|frontend|fingpt|all]"
    exit 1
fi

cd infra/terraform

if [ "$SERVICE" = "all" ]; then
    # Деплой всех сервисов
    eval $(terraform output -json deploy_commands | jq -r '.backend')
    eval $(terraform output -json deploy_commands | jq -r '.frontend')
    eval $(terraform output -json deploy_commands | jq -r '.fingpt')
else
    # Деплой конкретного сервиса
    eval $(terraform output -json deploy_commands | jq -r ".$SERVICE")
fi
```

## Мониторинг и отладка

### Получить логи сервисов:
```bash
# Backend логи
gcloud logs read "resource.type=cloud_run_revision AND resource.labels.service_name=htx-interface-backend" --limit 50

# Frontend логи
gcloud logs read "resource.type=cloud_run_revision AND resource.labels.service_name=htx-interface-frontend" --limit 50

# FinGPT логи
gcloud logs read "resource.type=cloud_run_revision AND resource.labels.service_name=htx-interface-fingpt" --limit 50
```

### Проверка health endpoints:
```bash
# Health check всех сервисов
BACKEND_URL=$(terraform output -raw backend_url)
FRONTEND_URL=$(terraform output -raw frontend_url)  
FINGPT_URL=$(terraform output -raw fingpt_url)

echo "Backend Health: $(curl -s $BACKEND_URL/health | jq -r '.status')"
echo "Frontend Health: $(curl -s $FRONTEND_URL/health | jq -r '.status')"
echo "FinGPT Health: $(curl -s $FINGPT_URL/health | jq -r '.status')"
```

## Локальная разработка с выводом продакшен данных

### Подключение к продакшен WebSocket из локального frontend:
```bash
# В .env файле frontend проекта
echo "NEXT_PUBLIC_WS_URL=$(terraform output -raw websocket_url)/ws" >> frontend/.env.local
echo "NEXT_PUBLIC_BACKEND_URL=$(terraform output -raw backend_url)" >> frontend/.env.local
```

### Проксирование API запросов:
```javascript
// next.config.js для проксирования API
const BACKEND_URL = process.env.BACKEND_URL || 'http://localhost:8000';

module.exports = {
  async rewrites() {
    return [
      {
        source: '/api/:path*',
        destination: `${BACKEND_URL}/:path*`,
      },
    ];
  },
};
```

Эти outputs значительно упрощают процесс разработки, тестирования и деплоя приложения.
