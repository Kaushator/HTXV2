variable "instance_name" {
  description = "Name of the Cloud SQL instance."
  type        = string
}

variable "database_version" {
  description = "Version of the Cloud SQL database engine."
  type        = string
  default     = "POSTGRES_15"
}

variable "region" {
  description = "Region for the Cloud SQL instance."
  type        = string
}

variable "tier" {
  description = "Machine tier for the instance."
  type        = string
}

variable "database_name" {
  description = "Default database name to create."
  type        = string
}

variable "database_user" {
  description = "Database user name."
  type        = string
}

variable "database_password" {
  description = "Password for the database user."
  type        = string
  sensitive   = true
}

variable "enable_deletion_protection" {
  description = "Whether deletion protection is enabled for the instance."
  type        = bool
  default     = false
}

variable "network_self_link" {
  description = "Self link of the VPC network to peer with Cloud SQL."
  type        = string
}

variable "availability_type" {
  description = "Availability type for the instance."
  type        = string
  default     = "REGIONAL"
}

variable "disk_type" {
  description = "Type of disk to use for storage."
  type        = string
  default     = "PD_SSD"
}

variable "disk_size" {
  description = "Initial disk size in GB."
  type        = number
  default     = 20
}

variable "disk_autoresize" {
  description = "Whether disk autoresize is enabled."
  type        = bool
  default     = true
}
