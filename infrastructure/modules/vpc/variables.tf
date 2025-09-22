variable "network_name" {
  description = "Name of the VPC network."
  type        = string
}

variable "description" {
  description = "Description of the VPC network."
  type        = string
  default     = ""
}

variable "subnet_name" {
  description = "Name of the primary application subnet."
  type        = string
}

variable "subnet_ip_cidr_range" {
  description = "Primary CIDR range for the application subnet."
  type        = string
}

variable "secondary_ip_ranges" {
  description = "Secondary IP ranges for the subnet."
  type = list(object({
    range_name    = string
    ip_cidr_range = string
  }))
  default = []
}

variable "region" {
  description = "Region where the subnet will be created."
  type        = string
}

variable "router_name" {
  description = "Name of the Cloud Router for NAT."
  type        = string
}

variable "nat_name" {
  description = "Name of the Cloud NAT configuration."
  type        = string
}
