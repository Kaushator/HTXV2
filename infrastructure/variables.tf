variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "project_name" {
  description = "The project name for resource naming"
  type        = string
  default     = "htxv2"
}

variable "region" {
  description = "The GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The GCP zone for resources"
  type        = string
  default     = "us-central1-a"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "db_tier" {
  description = "Cloud SQL instance tier"
  type        = string
  default     = "db-f1-micro"
}

variable "database_name" {
  description = "Name of the PostgreSQL database"
  type        = string
  default     = "htxv2"
}

variable "database_user" {
  description = "PostgreSQL database user"
  type        = string
  default     = "htxv2_user"
}

variable "redis_tier" {
  description = "Redis instance tier"
  type        = string
  default     = "BASIC"
}

variable "redis_memory_size" {
  description = "Redis memory size in GB"
  type        = number
  default     = 1
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection for resources"
  type        = bool
  default     = false
}

variable "alert_emails" {
  description = "List of email addresses for monitoring alerts"
  type        = list(string)
  default     = []
}
