locals { etl_image = "${var.region}-docker.pkg.dev/${var.project_id}/${var.repo_id}/etl-jobs:latest" }
resource "google_cloud_run_v2_job" "etl_dispatcher" {
  name     = "htx-etl-dispatcher"
  location = var.region
  template {
    template {
      containers { image = local.etl_image args = ["--from-pubsub"] }
    }
  }
}
