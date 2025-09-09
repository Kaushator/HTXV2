variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "repo_id" {
  description = "Artifact Registry repository ID"
  type        = string
  default     = "htx-interface"
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
