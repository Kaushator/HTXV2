locals {
  raw_bucket_name       = var.raw_bucket_name != null ? var.raw_bucket_name : "${var.project_id}-raw-data"
  processed_bucket_name = var.processed_bucket_name != null ? var.processed_bucket_name : "${var.project_id}-processed-data"
  ml_bucket_name        = var.ml_models_bucket_name != null ? var.ml_models_bucket_name : "${var.project_id}-ml-models"
}

resource "google_storage_bucket" "raw_data" {
  name          = local.raw_bucket_name
  location      = var.region
  force_destroy = !var.enable_deletion_protection

  labels                      = var.labels
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type = "Delete"
    }
  }

  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }
}

resource "google_storage_bucket" "processed_data" {
  name          = local.processed_bucket_name
  location      = var.region
  force_destroy = !var.enable_deletion_protection

  labels                      = var.labels
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }
}

resource "google_storage_bucket" "ml_models" {
  name          = local.ml_bucket_name
  location      = var.region
  force_destroy = !var.enable_deletion_protection

  labels                      = var.labels
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }
}
