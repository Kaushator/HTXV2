variable "project_id" {
  description = "GCP project ID used for naming."
  type        = string
}

variable "project_name" {
  description = "Project name used for bucket naming."
  type        = string
}

variable "region" {
  description = "Region where the buckets will be created."
  type        = string
}

variable "enable_deletion_protection" {
  description = "Whether deletion protection should be enabled."
  type        = bool
  default     = false
}

variable "raw_bucket_name" {
  description = "Custom name for the raw data bucket."
  type        = string
  default     = null
}

variable "processed_bucket_name" {
  description = "Custom name for the processed data bucket."
  type        = string
  default     = null
}

variable "ml_models_bucket_name" {
  description = "Custom name for the ML models bucket."
  type        = string
  default     = null
}

variable "labels" {
  description = "Labels to apply to all buckets."
  type        = map(string)
  default     = {}
}
