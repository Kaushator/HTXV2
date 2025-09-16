# Infrastructure

This directory contains Terraform configurations for the GCP infrastructure.

## Structure

- `main.tf` - Main Terraform configuration
- `variables.tf` - Input variables
- `outputs.tf` - Output values
- `terraform.tfvars.example` - Example variables file
- `modules/` - Reusable Terraform modules
- `environments/` - Environment-specific configurations

## Setup

1. Initialize Terraform:
   ```bash
   cd infrastructure
   terraform init
   ```

2. Copy and customize variables:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

3. Plan and apply:
   ```bash
   terraform plan
   terraform apply
   ```

## Bootstrap (Windows PowerShell)

If you want to quickly set up the remote backend bucket and initialize Terraform using your credentials, use the helper script:

```powershell
# From repo root
./scripts/tf-bootstrap.ps1 -ProjectId <your-project-id> -Region us-central1 -BucketName htxv2-terraform-state -Prefix terraform/state

# Optional: provide a service account key JSON
# ./scripts/tf-bootstrap.ps1 -ProjectId <your-project-id> -CredentialsPath C:\path\to\sa.json
```

The script will:
- Ensure the GCS bucket for Terraform state exists
- Generate `infrastructure/backend.hcl` for backend config
- Create `infrastructure/terraform.tfvars` from the example if missing
- Run `terraform init` with the backend config

You can also customize the backend by editing `infrastructure/backend.hcl.example` and copying it to `backend.hcl`.

## Resources Created

- **Networking**: VPC, subnets, firewall rules
- **Compute**: Cloud Run services, Cloud Functions
- **Storage**: Cloud SQL, Memorystore Redis, Cloud Storage buckets
- **Data**: BigQuery datasets and tables
- **AI/ML**: Vertex AI resources
- **Security**: Secret Manager, IAM roles and bindings
- **Monitoring**: Log sinks, monitoring dashboards
