locals {
  buildProject = "next-cicd"
  buildServiceAccountCICDRoles = [
    "roles/artifactregistry.admin",
    "roles/cloudbuild.builds.builder",
    "roles/cloudbuild.serviceAgent",
    "roles/logging.logWriter",
    "roles/resourcemanager.projectIamAdmin",
    "roles/secretmanager.secretAccessor",
    "roles/secretmanager.viewer",
    "roles/iam.serviceAccountUser",
    "roles/serviceusage.serviceUsageAdmin",
    "roles/storage.admin",
    "roles/compute.networkAdmin",
    "roles/containeranalysis.notes.attacher",
    "roles/containeranalysis.notes.occurrences.viewer"
  ]
}

resource "google_service_account" "cicd_next_dev" {
  account_id   = "next-dev"
  display_name = "Next dev"
  project      = local.buildProject
}

resource "google_project_iam_member" "cicd_sldp_dev" {

  for_each = toset(local.buildServiceAccountCICDRoles)

  project = local.buildProject
  role    = each.key
  member  = "serviceAccount:${google_service_account.cicd_next_dev.email}"
}
