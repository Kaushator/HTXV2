# Deployment Log

Date: 2025-09-17 03:51:13

Actions performed:

- Configured Terraform remote backend (GCS) using `infrastructure/backend.hcl`.
- Created state bucket `gs://htxv2-terraform-state` in project `vibrant-period-470810-p7`.
- Generated `infrastructure/terraform.tfvars` with project settings.
- Removed duplicate Terraform folder `HTX_V2/infrastructure/`.
- Fixed Secret Manager replication blocks (`auto {}`) for provider v5 compatibility.
- Removed invalid Cloud SQL `database_flags` for `shared_preload_libraries`.
- Granted IAM roles to user `filkapes@gmail.com` on project `vibrant-period-470810-p7`:
  - roles/serviceusage.serviceUsageAdmin
  - roles/cloudsql.admin
  - roles/cloudscheduler.admin
  - roles/compute.admin
  - roles/compute.networkAdmin
  - roles/servicenetworking.networksAdmin
  - roles/redis.admin
  - roles/storage.admin
  - roles/bigquery.admin
  - roles/artifactregistry.admin
  - roles/secretmanager.admin
  - roles/run.admin
  - roles/cloudfunctions.admin
- Executed Terraform:
  - `terraform init` — success
  - `terraform plan` — success
  - `terraform apply` — partial success

Provisioned resources (highlights):
- VPC network, subnet, router and NAT
- Service Networking private connection
- Memorystore Redis
- Artifact Registry repository
- GCS buckets (raw, processed, ml-models)
- BigQuery dataset and table
- Service accounts and IAM bindings
- Secret Manager secrets and DB password version
- Pub/Sub topics

Pending/blocked:
- Cloud SQL (PostgreSQL) instance creation blocked by Cloud SQL API enablement restriction (org policy):
  - Error enabling `cloudsql.googleapis.com`: AUTH_PERMISSION_DENIED / internal service restriction.
  - Instance creation also errored due to unsupported `database_flags` (fixed in code).

Next steps:
- Org admin needs to allow enabling `cloudsql.googleapis.com` for project `vibrant-period-470810-p7`.
- Re-run `terraform apply` from `infrastructure/` after API is enabled.

