output "artifact_registry_repo" { value = module.artifact.repo }
output "bq_dataset"             { value = module.bq.dataset_id }
output "gcs_buckets"            { value = module.gcs.buckets }
output "sql_instance"           { value = module.sql.instance_connection_name }
output "redis_host"             { value = module.redis.host }
output "pubsub_topics"          { value = module.pubsub.topics }
output "scheduler_jobs"         { value = module.scheduler.jobs }
output "secrets"                { value = module.secrets.secret_ids }

# CI/CD
output "github_sa_key" {
  value       = module.cicd.github_sa_key
  sensitive   = true
  description = "Ключ сервисного аккаунта для GitHub Actions (Sensitive)"
}
