resource "google_artifact_registry_repository" "repo" {
  location      = var.region
  repository_id = "htx"
  format        = "DOCKER"
}
output "repo"    { value = google_artifact_registry_repository.repo.id }
output "repo_id" { value = google_artifact_registry_repository.repo.repository_id }
