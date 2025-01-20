resource "google_kms_key_ring" "terraform-keyring" {
  location = var.region
  project  = var.project_id
  name     = "terraform-keyring"
}

resource "google_kms_crypto_key" "terraform-secrets-key" {
  # checkov:skip=CKV_GCP_43 We are not using automated key rotations so skipping this check
  key_ring = google_kms_key_ring.terraform-keyring.id
  name     = "terraform-secrets-key"
  purpose  = "ENCRYPT_DECRYPT"

  version_template {
    algorithm = "GOOGLE_SYMMETRIC_ENCRYPTION"
  }

  lifecycle {
    prevent_destroy = true
  }
}
