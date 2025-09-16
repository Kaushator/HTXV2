output "host" {
  description = "Hostname of the Redis instance."
  value       = google_redis_instance.this.host
}

output "port" {
  description = "Port of the Redis instance."
  value       = google_redis_instance.this.port
}

output "name" {
  description = "Name of the Redis instance."
  value       = google_redis_instance.this.name
}
