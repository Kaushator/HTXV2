resource "google_service_account" "api_sa" { account_id = "htx-api-sa" display_name = "HTX API SA" }
resource "google_service_account" "etl_sa" { account_id = "htx-etl-sa" display_name = "HTX ETL SA" }
resource "google_service_account" "scheduler_sa" { account_id = "htx-scheduler-sa" display_name = "HTX Scheduler SA" }

resource "google_project_iam_member" "api_sa_roles" {
  for_each = toset(["roles/secretmanager.secretAccessor","roles/cloudsql.client","roles/pubsub.publisher","roles/storage.objectViewer"])
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.api_sa.email}"
}
resource "google_project_iam_member" "etl_sa_roles" {
  for_each = toset(["roles/bigquery.dataEditor","roles/storage.objectAdmin","roles/secretmanager.secretAccessor","roles/pubsub.subscriber","roles/aiplatform.user"])
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.etl_sa.email}"
}
resource "google_project_iam_member" "scheduler_sa_roles" {
  for_each = toset(["roles/pubsub.publisher"])
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.scheduler_sa.email}"
}

output "api_sa_email" { value = google_service_account.api_sa.email }
output "etl_sa_email" { value = google_service_account.etl_sa.email }
output "scheduler_sa_email" { value = google_service_account.scheduler_sa.email }
