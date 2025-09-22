output "dataset_id" {
  description = "Dataset ID."
  value       = google_bigquery_dataset.this.dataset_id
}

output "dataset_self_link" {
  description = "Self link of the dataset."
  value       = google_bigquery_dataset.this.self_link
}

output "table_ids" {
  description = "Map of table IDs created in the dataset."
  value       = { for k, table in google_bigquery_table.this : k => table.table_id }
}
