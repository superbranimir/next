output "backend_services" {
  description = "The backend service resources."
  value       = google_compute_backend_service.default-backend-service
  sensitive   = true // can contain sensitive iap_config
}

output "external_ip" {
  description = "The external IPv4 assigned to the global fowarding rule."
  value       = local.address
}

output "http_proxy" {
  description = "The HTTP proxy used by this module."
  value       = google_compute_target_http_proxy.default-http-proxy[*].self_link
}

output "https_proxy" {
  description = "The HTTPS proxy used by this module."
  value       = google_compute_target_https_proxy.default-https-proxy[*].self_link
}

output "url_map" {
  description = "The default URL map used by this module."
  value       = google_compute_url_map.default-url-map[*].self_link
}
