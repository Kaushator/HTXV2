resource "google_cloud_scheduler_job" "htx_pull" {
  name = "htx-pull"
  schedule = "*/10 * * * *"
  time_zone = "Etc/UTC"
  pubsub_target {
    topic_name = "projects/${var.project_id}/topics/${var.topics["etl-htx"]}"
    data = base64encode("{"source":"htx","action":"pull"}")
  }
}
resource "google_cloud_scheduler_job" "coingecko_pull" {
  name = "coingecko-pull"
  schedule = "*/15 * * * *"
  time_zone = "Etc/UTC"
  pubsub_target {
    topic_name = "projects/${var.project_id}/topics/${var.topics["etl-coingecko"]}"
    data = base64encode("{"source":"coingecko","action":"pull"}")
  }
}
resource "google_cloud_scheduler_job" "cryptopanic_pull" {
  name = "cryptopanic-pull"
  schedule = "*/20 * * * *"
  time_zone = "Etc/UTC"
  pubsub_target {
    topic_name = "projects/${var.project_id}/topics/${var.topics["etl-cryptopanic"]}"
    data = base64encode("{"source":"cryptopanic","action":"pull"}")
  }
}
output "jobs" { value = [google_cloud_scheduler_job.htx_pull.name, google_cloud_scheduler_job.coingecko_pull.name, google_cloud_scheduler_job.cryptopanic_pull.name] }
