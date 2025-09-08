# HTX Interface v2 — Monokit (GCP Terraform)

Содержит модульную инфраструктуру GCP: GCS, BigQuery, Cloud SQL Postgres, Memorystore Redis, Pub/Sub, Scheduler,
Artifact Registry, Secret Manager, Cloud Run Jobs (заготовка), включение Vertex AI и др. API.

## Запуск
```bash
cd infra/terraform/envs/dev
terraform init
terraform apply -var-file=dev.tfvars
```
