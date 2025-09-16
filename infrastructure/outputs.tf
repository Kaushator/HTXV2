output "vpc_network_id" {
  description = "The ID of the VPC network"
  value       = module.vpc.network_id
}

output "vpc_network_name" {
  description = "The name of the VPC network"
  value       = module.vpc.network_name
}

output "app_subnet_id" {
  description = "The ID of the application subnet"
  value       = module.vpc.subnetwork_id
}

output "cloud_sql_instance_name" {
  description = "Name of the Cloud SQL instance"
  value       = module.cloud_sql.instance_name
}

output "postgres_connection_name" {
  description = "The connection name for the Cloud SQL instance"
  value       = module.cloud_sql.connection_name
}

output "postgres_private_ip" {
  description = "The private IP address of the Cloud SQL instance"
  value       = module.cloud_sql.private_ip_address
}

output "redis_host" {
  description = "The IP address of the Redis instance"
  value       = module.redis.host
}

output "redis_port" {
  description = "The port of the Redis instance"
  value       = module.redis.port
}

output "raw_data_bucket_name" {
  description = "The name of the raw data storage bucket"
  value       = module.gcs.raw_bucket_name
}

output "processed_data_bucket_name" {
  description = "The name of the processed data storage bucket"
  value       = module.gcs.processed_bucket_name
}

output "ml_models_bucket_name" {
  description = "The name of the ML models storage bucket"
  value       = module.gcs.ml_models_bucket_name
}

output "bigquery_dataset_id" {
  description = "The ID of the BigQuery dataset"
  value       = module.bigquery.dataset_id
}

output "bigquery_table_ids" {
  description = "Map of BigQuery tables created in the dataset"
  value       = module.bigquery.table_ids
}

output "artifact_registry_repository" {
  description = "The name of the Artifact Registry repository"
  value       = module.artifact_registry.repository_name
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
  value       = module.secret_manager.secret_ids["db_password"]
}
