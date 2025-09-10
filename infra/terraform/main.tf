module "cicd" {
  source = "./modules/cicd"
  
  project_id = var.project_id
  region     = var.region
  repo_id    = "htx-interface"
}

# Основные outputs для GitHub Actions
output "github_actions_sa_key" {
  value     = module.cicd.github_sa_key
  sensitive = true
  description = "GitHub Actions Service Account Key (base64 encoded)"
}

output "service_account_email" {
  value = module.cicd.service_account_email
  description = "Email сервисного аккаунта для GitHub Actions"
}

# Service URLs для разработки
output "backend_url" {
  value = module.cicd.backend_url
  description = "URL сервиса backend"
}

output "frontend_url" {
  value = module.cicd.frontend_url
  description = "URL сервиса frontend"
}

output "fingpt_url" {
  value = module.cicd.fingpt_url
  description = "URL сервиса fingpt"
}

# WebSocket URL для frontend разработки
output "websocket_url" {
  value = replace(module.cicd.backend_url, "https://", "wss://")
  description = "WebSocket URL для подключения frontend к backend"
}

# Artifact Registry информация
output "artifact_registry_url" {
  value = module.cicd.artifact_registry_url
  description = "URL Artifact Registry для Docker образов"
}

# Docker образы URLs для разработки
output "docker_images" {
  value = {
    backend  = "${var.region}-docker.pkg.dev/${var.project_id}/htx-interface/backend:latest"
    frontend = "${var.region}-docker.pkg.dev/${var.project_id}/htx-interface/frontend:latest"
    fingpt   = "${var.region}-docker.pkg.dev/${var.project_id}/htx-interface/fingpt:latest"
  }
  description = "URLs Docker образов для локальной разработки"
}

# Информация о проекте для настройки локальной среды
output "project_info" {
  value = {
    project_id = var.project_id
    region     = var.region
    zone       = "${var.region}-a"
  }
  description = "Информация о GCP проекте для настройки gcloud CLI"
}

# Environment variables для локальной разработки
output "local_env_vars" {
  value = {
    BACKEND_URL          = module.cicd.backend_url
    FRONTEND_URL         = module.cicd.frontend_url
    FINGPT_URL          = module.cicd.fingpt_url
    WEBSOCKET_URL       = replace(module.cicd.backend_url, "https://", "wss://")
    GCP_PROJECT_ID      = var.project_id
    GCP_REGION          = var.region
    ARTIFACT_REGISTRY   = "${var.region}-docker.pkg.dev/${var.project_id}/htx-interface"
  }
  description = "Environment переменные для локальной разработки"
}

# Команды для быстрого деплоя
output "deploy_commands" {
  value = {
    backend = "gcloud run deploy htx-interface-backend --image=${var.region}-docker.pkg.dev/${var.project_id}/htx-interface/backend:latest --region=${var.region}"
    frontend = "gcloud run deploy htx-interface-frontend --image=${var.region}-docker.pkg.dev/${var.project_id}/htx-interface/frontend:latest --region=${var.region}"
    fingpt = "gcloud run deploy htx-interface-fingpt --image=${var.region}-docker.pkg.dev/${var.project_id}/htx-interface/fingpt:latest --region=${var.region}"
  }
  description = "Команды для быстрого деплоя сервисов"
}
