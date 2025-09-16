output "repository_id" {
  description = "ID of the Artifact Registry repository."
  value       = google_artifact_registry_repository.this.repository_id
}

output "repository_name" {
  description = "Full resource name of the Artifact Registry repository."
  value       = google_artifact_registry_repository.this.name
}
