resource "google_secret_manager_secret" "htx_api_key"     { secret_id = "HTX_API_KEY"     replication { automatic = true } }
resource "google_secret_manager_secret" "htx_api_secret"  { secret_id = "HTX_API_SECRET"  replication { automatic = true } }
resource "google_secret_manager_secret" "openai_api_key"  { secret_id = "OPENAI_API_KEY"  replication { automatic = true } }
output "secret_ids" { value = [google_secret_manager_secret.htx_api_key.id, google_secret_manager_secret.htx_api_secret.id, google_secret_manager_secret.openai_api_key.id] }
