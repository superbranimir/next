output "kms_key_id" {
  value     = google_kms_crypto_key.terraform-secrets-key.id
  sensitive = true
}

output "kms_keyring_id" {
  value = google_kms_key_ring.terraform-keyring.id
}
