output "network_id" {
  description = "The ID of the created VPC network."
  value       = google_compute_network.this.id
}

output "network_name" {
  description = "The name of the created VPC network."
  value       = google_compute_network.this.name
}

output "network_self_link" {
  description = "Self link of the VPC network."
  value       = google_compute_network.this.self_link
}

output "subnetwork_id" {
  description = "The ID of the primary application subnet."
  value       = google_compute_subnetwork.app.id
}

output "subnetwork_self_link" {
  description = "Self link of the primary application subnet."
  value       = google_compute_subnetwork.app.self_link
}
