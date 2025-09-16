resource "google_redis_instance" "this" {
  name           = var.name
  tier           = var.tier
  memory_size_gb = var.memory_size_gb
  region         = var.region

  authorized_network = var.authorized_network
  redis_version      = var.redis_version
  display_name       = var.display_name
  labels             = var.labels

  redis_configs = {
    maxmemory-policy = "allkeys-lru"
  }
}
