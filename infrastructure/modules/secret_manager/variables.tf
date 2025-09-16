variable "secrets" {
  description = "Map of secrets to create in Secret Manager."
  type = map(object({
    secret_id   = optional(string)
    labels      = optional(map(string), {})
    secret_data = optional(string)
  }))
  default = {}
}
