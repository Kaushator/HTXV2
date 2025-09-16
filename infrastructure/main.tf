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

resource "random_password" "db_password" {
  length  = 16
  special = true
}

module "vpc" {
  source = "./modules/vpc"

  network_name         = "${var.project_name}-vpc"
  description          = "VPC network for HTXV2 project"
  subnet_name          = "${var.project_name}-app-subnet"
  subnet_ip_cidr_range = "10.0.1.0/24"
  secondary_ip_ranges = [
    {
      range_name    = "services-range"
      ip_cidr_range = "192.168.1.0/24"
    },
    {
      range_name    = "pod-ranges"
      ip_cidr_range = "192.168.64.0/22"
    }
  ]
  region      = var.region
  router_name = "${var.project_name}-router"
  nat_name    = "${var.project_name}-nat"
  depends_on  = [google_project_service.required_apis]
}

module "cloud_sql" {
  source = "./modules/cloud_sql"

  instance_name              = "${var.project_name}-postgres"
  region                     = var.region
  tier                       = var.db_tier
  database_name              = var.database_name
  database_user              = var.database_user
  database_password          = random_password.db_password.result
  enable_deletion_protection = var.enable_deletion_protection
  network_self_link          = module.vpc.network_self_link
  depends_on                 = [google_project_service.required_apis]
}

module "redis" {
  source = "./modules/redis"

  name               = "${var.project_name}-redis"
  region             = var.region
  tier               = var.redis_tier
  memory_size_gb     = var.redis_memory_size
  authorized_network = module.vpc.network_self_link
  display_name       = "HTXV2 Redis Cache"
  depends_on         = [google_project_service.required_apis]
}

module "gcs" {
  source = "./modules/gcs"

  project_id                 = var.project_id
  project_name               = var.project_name
  region                     = var.region
  enable_deletion_protection = var.enable_deletion_protection
  depends_on                 = [google_project_service.required_apis]
}

module "secret_manager" {
  source = "./modules/secret_manager"

  secrets = {
    db_password = {
      secret_id   = "${var.project_name}-db-password"
      secret_data = random_password.db_password.result
    }
    htx_api_key = {
      secret_id = "${var.project_name}-htx-api-key"
    }
    openai_api_key = {
      secret_id = "${var.project_name}-openai-api-key"
    }
  }
  depends_on = [google_project_service.required_apis]
}

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

module "bigquery" {
  source = "./modules/bigquery"

  dataset_id                 = "htxv2_main"
  friendly_name              = "HTXV2 Main Dataset"
  description                = "Main dataset for HTXV2 cryptocurrency data"
  location                   = var.region
  delete_contents_on_destroy = !var.enable_deletion_protection
  access = [
    {
      role   = "OWNER"
      member = "serviceAccount:${google_service_account.etl_service.email}"
    },
    {
      role   = "READER"
      member = "serviceAccount:${google_service_account.backend_service.email}"
    }
  ]
  tables = [
    {
      table_id                = "crypto_prices"
      schema_path             = "${path.module}/schemas/crypto_prices.json"
      description             = "Historical cryptocurrency prices"
      time_partitioning_field = "timestamp"
      clustering              = ["symbol", "exchange"]
    }
  ]
  depends_on = [google_project_service.required_apis]
}

module "artifact_registry" {
  source = "./modules/artifact_registry"

  repository_id = var.project_name
  location      = var.region
  description   = "Docker repository for HTXV2 containers"
  depends_on    = [google_project_service.required_apis]
}

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

resource "google_pubsub_topic" "data_ingestion" {
  name = "${var.project_name}-data-ingestion"
}

resource "google_pubsub_topic" "ml_training" {
  name = "${var.project_name}-ml-training"
}

resource "google_cloud_scheduler_job" "htx_data_ingestion" {
  name     = "${var.project_name}-htx-ingestion"
  region   = var.region
  schedule = "*/5 * * * *"

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
  schedule = "0 */1 * * *"

  http_target {
    http_method = "POST"
    uri         = "https://${var.region}-${var.project_id}.cloudfunctions.net/coingecko-ingestion"

    oidc_token {
      service_account_email = google_service_account.etl_service.email
    }
  }
}

resource "google_logging_metric" "cloud_run_error_count" {
  name        = "${var.project_name}-cloud-run-error-count"
  description = "Count of Cloud Run revisions logging errors."
  filter      = "resource.type=\"cloud_run_revision\" severity>=ERROR"

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"
  }
}

resource "google_monitoring_notification_channel" "email" {
  for_each = { for email in var.alert_emails : email => email }

  display_name = "${var.project_name} Alerts (${each.value})"
  type         = "email"

  labels = {
    email_address = each.value
  }
}

resource "google_monitoring_alert_policy" "cloud_sql_high_cpu" {
  display_name = "HTXV2 Cloud SQL high CPU"
  combiner     = "OR"

  conditions {
    display_name = "Cloud SQL CPU > 80%"

    condition_threshold {
      filter = "resource.type=\"cloudsql_database\" resource.label.project_id=\"${var.project_id}\" metric.type=\"cloudsql.googleapis.com/database/cpu/utilization\""

      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }

      comparison      = "COMPARISON_GT"
      threshold_value = 0.8
      duration        = "300s"
    }
  }

  documentation {
    content   = "Cloud SQL instance ${module.cloud_sql.instance_name} CPU usage exceeded 80% for more than 5 minutes."
    mime_type = "text/markdown"
  }

  notification_channels = values(google_monitoring_notification_channel.email)[*].name
}

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
    "iam.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com"
  ])

  project = var.project_id
  service = each.value

  disable_dependent_services = true
}
