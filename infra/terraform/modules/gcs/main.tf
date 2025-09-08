resource "google_storage_bucket" "raw" {
  name                        = "${var.project_id}-raw"
  location                    = "US"
  uniform_bucket_level_access = true
  versioning { enabled = true }
  lifecycle_rule { condition { age = 90 } action { type = "SetStorageClass" storage_class = "NEARLINE" } }
}
resource "google_storage_bucket" "curated" {
  name                        = "${var.project_id}-curated"
  location                    = "US"
  uniform_bucket_level_access = true
  versioning { enabled = true }
  lifecycle_rule { condition { age = 180 } action { type = "SetStorageClass" storage_class = "COLDLINE" } }
}
output "buckets" { value = { raw = google_storage_bucket.raw.url, curated = google_storage_bucket.curated.url } }
