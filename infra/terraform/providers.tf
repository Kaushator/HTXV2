terraform {
  required_providers { google = { source = "hashicorp/google" } }
}
provider "google" {
  project = "vibrant-period-470810-p7"
  region  = "us-central1"
}
