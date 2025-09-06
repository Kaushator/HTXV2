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

## Resources Created

- **Networking**: VPC, subnets, firewall rules
- **Compute**: Cloud Run services, Cloud Functions
- **Storage**: Cloud SQL, Memorystore Redis, Cloud Storage buckets
- **Data**: BigQuery datasets and tables
- **AI/ML**: Vertex AI resources
- **Security**: Secret Manager, IAM roles and bindings
- **Monitoring**: Log sinks, monitoring dashboards