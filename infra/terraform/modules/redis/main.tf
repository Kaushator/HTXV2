resource "google_redis_instance" "cache" {
  name           = "htx-redis"
  tier           = "BASIC"
  memory_size_gb = 1
  region         = var.region
}
output "host" { value = google_redis_instance.cache.host }
