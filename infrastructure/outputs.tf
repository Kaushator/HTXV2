output "vpc_network_id" {
  description = "The ID of the VPC network"
  value       = google_compute_network.vpc.id
}

output "vpc_network_name" {
  description = "The name of the VPC network"
  value       = google_compute_network.vpc.name
}

output "app_subnet_id" {
  description = "The ID of the application subnet"
  value       = google_compute_subnetwork.app_subnet.id
}

output "postgres_connection_name" {
  description = "The connection name for the Cloud SQL instance"
  value       = google_sql_database_instance.postgres.connection_name
}

output "postgres_private_ip" {
  description = "The private IP address of the Cloud SQL instance"
  value       = google_sql_database_instance.postgres.private_ip_address
}

output "redis_host" {
  description = "The IP address of the Redis instance"
  value       = google_redis_instance.cache.host
}

output "redis_port" {
  description = "The port of the Redis instance"
  value       = google_redis_instance.cache.port
}

output "raw_data_bucket_name" {
  description = "The name of the raw data storage bucket"
  value       = google_storage_bucket.raw_data.name
}

output "processed_data_bucket_name" {
  description = "The name of the processed data storage bucket"
  value       = google_storage_bucket.processed_data.name
}

output "ml_models_bucket_name" {
  description = "The name of the ML models storage bucket"
  value       = google_storage_bucket.ml_models.name
}

output "bigquery_dataset_id" {
  description = "The ID of the BigQuery dataset"
  value       = google_bigquery_dataset.main.dataset_id
}

output "artifact_registry_repository" {
  description = "The name of the Artifact Registry repository"
  value       = google_artifact_registry_repository.main.name
}

output "backend_service_account_email" {
  description = "Email of the backend service account"
  value       = google_service_account.backend_service.email
}

output "etl_service_account_email" {
  description = "Email of the ETL service account"
  value       = google_service_account.etl_service.email
}

output "ml_service_account_email" {
  description = "Email of the ML service account"
  value       = google_service_account.ml_service.email
}

output "data_ingestion_topic" {
  description = "The name of the data ingestion Pub/Sub topic"
  value       = google_pubsub_topic.data_ingestion.name
}

output "ml_training_topic" {
  description = "The name of the ML training Pub/Sub topic"
  value       = google_pubsub_topic.ml_training.name
}

output "database_password_secret_name" {
  description = "The name of the database password secret in Secret Manager"
  value       = google_secret_manager_secret.db_password.secret_id
}