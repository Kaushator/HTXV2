resource "google_service_account" "github_actions_sa" {
  account_id   = var.service_account_id
  display_name = var.service_account_display_name
  description  = "Service account for GitHub Actions CI/CD pipeline"
}

resource "google_project_iam_member" "github_actions_sa_roles" {
  for_each = toset([
    "roles/artifactregistry.admin",
    "roles/run.admin",
    "roles/iam.serviceAccountUser",
    "roles/storage.admin"
  ])
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.github_actions_sa.email}"
}

# Создаем ключ для сервисного аккаунта
resource "google_service_account_key" "github_actions_sa_key" {
  service_account_id = google_service_account.github_actions_sa.name
}

# Secret в Secret Manager для хранения ключа
resource "google_secret_manager_secret" "github_sa_key" {
  secret_id = "github-actions-sa-key"
  
  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
}

resource "google_secret_manager_secret_version" "github_sa_key" {
  secret      = google_secret_manager_secret.github_sa_key.id
  secret_data = base64decode(google_service_account_key.github_actions_sa_key.private_key)
}

# Создаем Artifact Registry репозиторий для Docker образов
resource "google_artifact_registry_repository" "htx_interface" {
  provider = google-beta
  
  location      = var.region
  repository_id = "htx-interface"
  description   = "Docker repository for HTX Interface"
  format        = "DOCKER"
}

# Создаем Cloud Run сервисы (Backend, Frontend, FinGPT)
resource "google_cloud_run_v2_service" "backend" {
  name     = "htx-interface-backend"
  location = var.region
  
  template {
    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/htx-interface/backend:latest"
      
      resources {
        limits = {
          memory = "1Gi"
          cpu    = "1000m"
        }
      }
      
      ports {
        container_port = 8000
      }
    }
    
    scaling {
      min_instance_count = 1
      max_instance_count = 10
    }
  }
}

resource "google_cloud_run_v2_service" "frontend" {
  name     = "htx-interface-frontend"
  location = var.region
  
  template {
    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/htx-interface/frontend:latest"
      
      resources {
        limits = {
          memory = "512Mi"
          cpu    = "1000m"
        }
      }
      
      ports {
        container_port = 3000
      }
      
      env {
        name  = "BACKEND_BASE"
        value = google_cloud_run_v2_service.backend.uri
      }
      
      env {
        name  = "NEXT_PUBLIC_BACKEND_URL"
        value = google_cloud_run_v2_service.backend.uri
      }
    }
    
    scaling {
      min_instance_count = 0
      max_instance_count = 5
    }
  }
  
  # Ждем, пока backend сервис будет готов
  depends_on = [google_cloud_run_v2_service.backend]
}

resource "google_cloud_run_v2_service" "fingpt" {
  name     = "htx-interface-fingpt"
  location = var.region
  
  template {
    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/htx-interface/fingpt:latest"
      
      resources {
        limits = {
          memory = "8Gi"
          cpu    = "2000m"
        }
      }
      
      ports {
        container_port = 8055
      }
    }
    
    scaling {
      min_instance_count = 0
      max_instance_count = 2
    }
  }
}

# Настройка публичного доступа к сервисам
resource "google_cloud_run_service_iam_member" "backend_public" {
  location = google_cloud_run_v2_service.backend.location
  service  = google_cloud_run_v2_service.backend.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_cloud_run_service_iam_member" "frontend_public" {
  location = google_cloud_run_v2_service.frontend.location
  service  = google_cloud_run_v2_service.frontend.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_cloud_run_service_iam_member" "fingpt_public" {
  location = google_cloud_run_v2_service.fingpt.location
  service  = google_cloud_run_v2_service.fingpt.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Выводим информацию о созданных ресурсах
output "github_sa_key" {
  value     = google_service_account_key.github_actions_sa_key.private_key
  sensitive = true
  description = "Ключ сервисного аккаунта в формате base64"
}

output "service_account_email" {
  value = google_service_account.github_actions_sa.email
  description = "Email сервисного аккаунта для GitHub Actions"
}

output "backend_url" {
  value = google_cloud_run_v2_service.backend.uri
  description = "URL сервиса backend"
}

output "frontend_url" {
  value = google_cloud_run_v2_service.frontend.uri
  description = "URL сервиса frontend"
}

output "fingpt_url" {
  value = google_cloud_run_v2_service.fingpt.uri
  description = "URL сервиса fingpt"
}
