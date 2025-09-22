variable "name" {
  description = "Name of the Redis instance."
  type        = string
}

variable "region" {
  description = "Region for the Redis instance."
  type        = string
}

variable "tier" {
  description = "Service tier for Redis."
  type        = string
}

variable "memory_size_gb" {
  description = "Memory size for Redis in GB."
  type        = number
}

variable "authorized_network" {
  description = "VPC network self link authorized to access Redis."
  type        = string
}

variable "redis_version" {
  description = "Redis engine version."
  type        = string
  default     = "REDIS_7_0"
}

variable "display_name" {
  description = "Display name for the Redis instance."
  type        = string
  default     = ""
}

variable "labels" {
  description = "Labels to apply to the Redis instance."
  type        = map(string)
  default     = {}
}
