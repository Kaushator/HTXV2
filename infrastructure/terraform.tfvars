# Copy this file to terraform.tfvars and customize the values

project_id   = "vibrant-period-470810-p7"
project_name = "htxv2"
region       = "us-central1"
zone         = "us-central1-a"
environment  = "dev"

# Database configuration
db_tier       = "db-f1-micro"
database_name = "htxv2"
database_user = "htxv2_user"

# Redis configuration
redis_tier        = "BASIC"
redis_memory_size = 1

# Security
enable_deletion_protection = false
allowed_source_ranges      = ["0.0.0.0/0"]

# Optional: Custom domain
# domain_name = "yourdomain.com"
# ssl_certificate_name = "your-ssl-cert"
