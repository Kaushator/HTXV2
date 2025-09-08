variable "project_id" { type = string }
variable "region" { type = string }

variable "db_name" {
  type        = string
  description = "PostgreSQL database name"
  default     = "htx_interface"
}

variable "db_user" {
  type        = string
  description = "PostgreSQL username"
  default     = "postgres"
}

variable "db_password" {
  type        = string
  description = "PostgreSQL user password (use Secret Manager in prod)"
  sensitive   = true
  default     = "postgres123"
}
