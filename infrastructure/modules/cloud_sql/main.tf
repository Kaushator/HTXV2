resource "google_compute_global_address" "private_ip" {
  name          = "${var.instance_name}-private-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = var.network_self_link
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = var.network_self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip.name]
}

resource "google_sql_database_instance" "this" {
  name             = var.instance_name
  database_version = var.database_version
  region           = var.region

  settings {
    tier              = var.tier
    availability_type = var.availability_type
    disk_type         = var.disk_type
    disk_size         = var.disk_size
    disk_autoresize   = var.disk_autoresize

    database_flags {
      name  = "shared_preload_libraries"
      value = "pgvector"
    }

    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = var.network_self_link
      enable_private_path_for_google_cloud_services = true
      require_ssl                                   = true
    }

    backup_configuration {
      enabled                        = true
      start_time                     = "23:00"
      point_in_time_recovery_enabled = true
      backup_retention_settings {
        retained_backups = 7
      }
    }

    maintenance_window {
      day          = 7
      hour         = 2
      update_track = "stable"
    }
  }

  deletion_protection = var.enable_deletion_protection

  depends_on = [google_service_networking_connection.private_vpc_connection]
}

resource "google_sql_database" "default" {
  name     = var.database_name
  instance = google_sql_database_instance.this.name
}

resource "google_sql_user" "default" {
  name     = var.database_user
  instance = google_sql_database_instance.this.name
  password = var.database_password
}
