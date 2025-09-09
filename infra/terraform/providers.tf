terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.3"
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

# Определение переменных
variable "project_id" {
  description = "ID проекта Google Cloud"
  type        = string
  default     = "vibrant-period-470810-p7"
}

variable "region" {
  description = "Регион Google Cloud"
  type        = string
  default     = "us-central1"
}

variable "service_account_id" {
  description = "ID сервисного аккаунта для CI/CD"
  type        = string
  default     = "github-actions-deployer"
}

variable "service_account_display_name" {
  description = "Отображаемое имя сервисного аккаунта"
  type        = string
  default     = "GitHub Actions Deployer"
}
