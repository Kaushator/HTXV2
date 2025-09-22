locals {
  secrets = { for key, value in var.secrets :
    key => {
      secret_id   = lookup(value, "secret_id", key)
      labels      = lookup(value, "labels", {})
      secret_data = lookup(value, "secret_data", null)
    }
  }

  secrets_with_data = { for key, value in local.secrets : key => value if value.secret_data != null }
}

resource "google_secret_manager_secret" "this" {
  for_each = local.secrets

  secret_id = each.value.secret_id
  labels    = each.value.labels

  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret_version" "this" {
  for_each = local.secrets_with_data

  secret      = google_secret_manager_secret.this[each.key].id
  secret_data = each.value.secret_data
}
