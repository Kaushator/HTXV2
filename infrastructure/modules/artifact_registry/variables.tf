variable "repository_id" {
  description = "ID of the Artifact Registry repository."
  type        = string
}

variable "location" {
  description = "Location of the repository."
  type        = string
}

variable "description" {
  description = "Description of the repository."
  type        = string
  default     = ""
}

variable "format" {
  description = "Format stored in the repository."
  type        = string
  default     = "DOCKER"
}

variable "labels" {
  description = "Labels to apply to the repository."
  type        = map(string)
  default     = {}
}
