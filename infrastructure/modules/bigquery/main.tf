locals {
  tables = { for table in var.tables : table.table_id => table }
}

resource "google_bigquery_dataset" "this" {
  dataset_id                 = var.dataset_id
  friendly_name              = var.friendly_name
  description                = var.description
  location                   = var.location
  delete_contents_on_destroy = var.delete_contents_on_destroy
  labels                     = var.labels

  dynamic "access" {
    for_each = var.access
    content {
      role       = access.value.role
      iam_member = access.value.member
    }
  }
}

resource "google_bigquery_table" "this" {
  for_each = local.tables

  dataset_id  = google_bigquery_dataset.this.dataset_id
  table_id    = each.value.table_id
  description = lookup(each.value, "description", null)
  schema      = file(each.value.schema_path)
  clustering  = lookup(each.value, "clustering", [])

  dynamic "time_partitioning" {
    for_each = lookup(each.value, "time_partitioning_field", null) != null ? [each.value] : []
    content {
      type          = lookup(time_partitioning.value, "time_partitioning_type", "DAY")
      field         = time_partitioning.value.time_partitioning_field
      expiration_ms = lookup(time_partitioning.value, "partition_expiration_ms", null)
    }
  }
}
