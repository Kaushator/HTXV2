resource "google_sql_database_instance" "pg" {
  name             = "htx-pg"
  database_version = "POSTGRES_15"
  region           = var.region
  settings {
    tier = "db-custom-2-4096"
    ip_configuration { ipv4_enabled = true }
    backup_configuration { enabled = true }
    availability_type = "ZONAL"
  }
}
resource "google_sql_database" "appdb" { name = "htxdb" instance = google_sql_database_instance.pg.name }
resource "google_sql_user" "appuser" { name = "htx" instance = google_sql_database_instance.pg.name password = "htxpass" }
output "instance_connection_name" { value = google_sql_database_instance.pg.connection_name }
