variable "project_id" { type = string }
variable "region" { type = string }
variable "bq_location" { type = string }

variable "db_name" {
  type        = string
  description = "PostgreSQL database name for dev"
  default     = "htx_interface"
}

variable "db_user" {
  type        = string
  description = "PostgreSQL username for dev"
  default     = "postgres"
}

variable "db_password" {
  type        = string
  description = "PostgreSQL password for dev"
  sensitive   = true
  default     = "postgres123"
}
