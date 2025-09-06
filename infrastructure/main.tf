terraform {
  required_version = ">= 1.5"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }

  backend "gcs" {
    bucket = "htxv2-terraform-state"
    prefix = "terraform/state"
  }
}

# Configure providers
provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Random password for databases
resource "random_password" "db_password" {
  length  = 16
  special = true
}

# VPC Network
resource "google_compute_network" "vpc" {
  name                    = "${var.project_name}-vpc"
  auto_create_subnetworks = false
  description             = "VPC network for HTXV2 project"
}

# Subnet for the application
resource "google_compute_subnetwork" "app_subnet" {
  name          = "${var.project_name}-app-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id
  
  secondary_ip_range {
    range_name    = "services-range"
    ip_cidr_range = "192.168.1.0/24"
  }
  
  secondary_ip_range {
    range_name    = "pod-ranges"
    ip_cidr_range = "192.168.64.0/22"
  }
}

# Cloud NAT for private resources
resource "google_compute_router" "router" {
  name    = "${var.project_name}-router"
  region  = var.region
  network = google_compute_network.vpc.id
}

resource "google_compute_router_nat" "nat" {
  name                               = "${var.project_name}-nat"
  router                            = google_compute_router.router.name
  region                            = var.region
  nat_ip_allocate_option            = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# Cloud SQL instance for PostgreSQL
resource "google_sql_database_instance" "postgres" {
  name             = "${var.project_name}-postgres"
  database_version = "POSTGRES_15"
  region           = var.region
  
  settings {
    tier              = var.db_tier
    availability_type = "REGIONAL"
    disk_type         = "PD_SSD"
    disk_size         = 20
    disk_autoresize   = true
    
    database_flags {
      name  = "shared_preload_libraries"
      value = "pgvector"
    }
    
    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = google_compute_network.vpc.id
      enable_private_path_for_google_cloud_services = true
      require_ssl                                   = true
    }
    
    backup_configuration {
      enabled                        = true
      start_time                     = "23:00"
      point_in_time_recovery_enabled = true
      backup_retention_settings {
        retained_backups = 7
      }
    }
    
    maintenance_window {
      day          = 7
      hour         = 2
      update_track = "stable"
    }
  }
  
  deletion_protection = var.enable_deletion_protection
  
  depends_on = [google_service_networking_connection.private_vpc_connection]
}

# Cloud SQL database
resource "google_sql_database" "app_db" {
  name     = var.database_name
  instance = google_sql_database_instance.postgres.name
}

# Cloud SQL user
resource "google_sql_user" "app_user" {
  name     = var.database_user
  instance = google_sql_database_instance.postgres.name
  password = random_password.db_password.result
}

# Private service connection for Cloud SQL
resource "google_compute_global_address" "private_ip_address" {
  name          = "${var.project_name}-private-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

# Memorystore Redis instance
resource "google_redis_instance" "cache" {
  name           = "${var.project_name}-redis"
  tier           = var.redis_tier
  memory_size_gb = var.redis_memory_size
  region         = var.region
  
  authorized_network = google_compute_network.vpc.id
  redis_version      = "REDIS_7_0"
  display_name       = "HTXV2 Redis Cache"
  
  redis_configs = {
    maxmemory-policy = "allkeys-lru"
  }
}

# Cloud Storage buckets
resource "google_storage_bucket" "raw_data" {
  name          = "${var.project_id}-raw-data"
  location      = var.region
  force_destroy = !var.enable_deletion_protection
  
  uniform_bucket_level_access = true
  
  versioning {
    enabled = true
  }
  
  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type = "Delete"
    }
  }
  
  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }
}

resource "google_storage_bucket" "processed_data" {
  name          = "${var.project_id}-processed-data"
  location      = var.region
  force_destroy = !var.enable_deletion_protection
  
  uniform_bucket_level_access = true
  
  versioning {
    enabled = true
  }
}

resource "google_storage_bucket" "ml_models" {
  name          = "${var.project_id}-ml-models"
  location      = var.region
  force_destroy = !var.enable_deletion_protection
  
  uniform_bucket_level_access = true
  
  versioning {
    enabled = true
  }
}

# BigQuery dataset
resource "google_bigquery_dataset" "main" {
  dataset_id                  = "htxv2_main"
  friendly_name               = "HTXV2 Main Dataset"
  description                 = "Main dataset for HTXV2 cryptocurrency data"
  location                    = var.region
  delete_contents_on_destroy  = !var.enable_deletion_protection
  
  access {
    role          = "OWNER"
    user_by_email = google_service_account.etl_service.email
  }
  
  access {
    role          = "READER"
    user_by_email = google_service_account.backend_service.email
  }
}

# BigQuery table for cryptocurrency prices
resource "google_bigquery_table" "crypto_prices" {
  dataset_id = google_bigquery_dataset.main.dataset_id
  table_id   = "crypto_prices"
  
  time_partitioning {
    type  = "DAY"
    field = "timestamp"
  }
  
  clustering = ["symbol", "exchange"]
  
  schema = file("${path.module}/schemas/crypto_prices.json")
}

# Artifact Registry repository
resource "google_artifact_registry_repository" "main" {
  location      = var.region
  repository_id = var.project_name
  description   = "Docker repository for HTXV2 containers"
  format        = "DOCKER"
}

# Service accounts
resource "google_service_account" "backend_service" {
  account_id   = "${var.project_name}-backend"
  display_name = "HTXV2 Backend Service Account"
  description  = "Service account for the backend API"
}

resource "google_service_account" "etl_service" {
  account_id   = "${var.project_name}-etl"
  display_name = "HTXV2 ETL Service Account"
  description  = "Service account for ETL jobs"
}

resource "google_service_account" "ml_service" {
  account_id   = "${var.project_name}-ml"
  display_name = "HTXV2 ML Service Account"
  description  = "Service account for ML/AI services"
}

# IAM bindings for backend service account
resource "google_project_iam_member" "backend_sql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.backend_service.email}"
}

resource "google_project_iam_member" "backend_storage_viewer" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.backend_service.email}"
}

resource "google_project_iam_member" "backend_bigquery_user" {
  project = var.project_id
  role    = "roles/bigquery.user"
  member  = "serviceAccount:${google_service_account.backend_service.email}"
}

resource "google_project_iam_member" "backend_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.backend_service.email}"
}

# IAM bindings for ETL service account
resource "google_project_iam_member" "etl_storage_admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.etl_service.email}"
}

resource "google_project_iam_member" "etl_bigquery_admin" {
  project = var.project_id
  role    = "roles/bigquery.admin"
  member  = "serviceAccount:${google_service_account.etl_service.email}"
}

resource "google_project_iam_member" "etl_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.etl_service.email}"
}

# IAM bindings for ML service account
resource "google_project_iam_member" "ml_ai_platform_user" {
  project = var.project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${google_service_account.ml_service.email}"
}

resource "google_project_iam_member" "ml_storage_admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.ml_service.email}"
}

# Secret Manager secrets
resource "google_secret_manager_secret" "db_password" {
  secret_id = "${var.project_name}-db-password"
  
  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret_version" "db_password" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = random_password.db_password.result
}

resource "google_secret_manager_secret" "htx_api_key" {
  secret_id = "${var.project_name}-htx-api-key"
  
  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret" "openai_api_key" {
  secret_id = "${var.project_name}-openai-api-key"
  
  replication {
    automatic = true
  }
}

# Cloud Scheduler jobs
resource "google_cloud_scheduler_job" "htx_data_ingestion" {
  name     = "${var.project_name}-htx-ingestion"
  region   = var.region
  schedule = "*/5 * * * *"  # Every 5 minutes
  
  http_target {
    http_method = "POST"
    uri         = "https://${var.region}-${var.project_id}.cloudfunctions.net/htx-ingestion"
    
    oidc_token {
      service_account_email = google_service_account.etl_service.email
    }
  }
}

resource "google_cloud_scheduler_job" "coingecko_data_ingestion" {
  name     = "${var.project_name}-coingecko-ingestion"
  region   = var.region
  schedule = "0 */1 * * *"  # Every hour
  
  http_target {
    http_method = "POST"
    uri         = "https://${var.region}-${var.project_id}.cloudfunctions.net/coingecko-ingestion"
    
    oidc_token {
      service_account_email = google_service_account.etl_service.email
    }
  }
}

# Pub/Sub topics
resource "google_pubsub_topic" "data_ingestion" {
  name = "${var.project_name}-data-ingestion"
}

resource "google_pubsub_topic" "ml_training" {
  name = "${var.project_name}-ml-training"
}

# Enable required APIs
resource "google_project_service" "required_apis" {
  for_each = toset([
    "compute.googleapis.com",
    "cloudsql.googleapis.com",
    "redis.googleapis.com",
    "storage.googleapis.com",
    "bigquery.googleapis.com",
    "artifactregistry.googleapis.com",
    "secretmanager.googleapis.com",
    "cloudscheduler.googleapis.com",
    "pubsub.googleapis.com",
    "run.googleapis.com",
    "cloudfunctions.googleapis.com",
    "aiplatform.googleapis.com",
    "servicenetworking.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com"
  ])
  
  project = var.project_id
  service = each.value
  
  disable_dependent_services = true
}