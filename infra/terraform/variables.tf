variable "project_id" {
  description = "GCP Project ID"
  type        = string
  default     = "vibrant-period-470810-p7"
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}
