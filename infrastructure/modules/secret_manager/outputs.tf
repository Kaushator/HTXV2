output "secret_ids" {
  description = "Map of secret identifiers keyed by input key."
  value       = { for key, secret in google_secret_manager_secret.this : key => secret.secret_id }
}

output "secret_resource_ids" {
  description = "Map of secret resource names keyed by input key."
  value       = { for key, secret in google_secret_manager_secret.this : key => secret.id }
}
