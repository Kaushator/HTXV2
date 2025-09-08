resource "google_bigquery_dataset" "dwh" {
  dataset_id  = "htx_dwh"
  project     = var.project_id
  location    = var.bq_location
  description = "HTX DWH (trades, portfolios, signals)"
}
output "dataset_id" { value = google_bigquery_dataset.dwh.dataset_id }
