variable "dataset_id" {
  description = "ID of the BigQuery dataset."
  type        = string
}

variable "friendly_name" {
  description = "Friendly name for the dataset."
  type        = string
  default     = ""
}

variable "description" {
  description = "Description of the dataset."
  type        = string
  default     = ""
}

variable "location" {
  description = "Location for the dataset."
  type        = string
}

variable "delete_contents_on_destroy" {
  description = "Whether dataset contents are deleted when destroying."
  type        = bool
  default     = false
}

variable "access" {
  description = "Access entries applied to the dataset."
  type = list(object({
    role   = string
    member = string
  }))
  default = []
}

variable "labels" {
  description = "Labels applied to the dataset."
  type        = map(string)
  default     = {}
}

variable "tables" {
  description = "Table definitions to create inside the dataset."
  type = list(object({
    table_id                = string
    schema_path             = string
    description             = optional(string)
    time_partitioning_field = optional(string)
    time_partitioning_type  = optional(string, "DAY")
    partition_expiration_ms = optional(number)
    clustering              = optional(list(string), [])
  }))
  default = []
}
