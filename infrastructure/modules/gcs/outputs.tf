output "raw_bucket_name" {
  description = "Name of the raw data bucket."
  value       = google_storage_bucket.raw_data.name
}

output "processed_bucket_name" {
  description = "Name of the processed data bucket."
  value       = google_storage_bucket.processed_data.name
}

output "ml_models_bucket_name" {
  description = "Name of the ML models bucket."
  value       = google_storage_bucket.ml_models.name
}
