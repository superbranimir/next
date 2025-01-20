output "cloudrunservice" {
  value = google_cloud_run_service.crservice
}

output "serviceaccount" {
  value = google_service_account.serviceaccount
}
