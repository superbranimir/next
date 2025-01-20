/* -------------------------------------------------------------------------- */
/*                                  Cloud Run                                 */
/* -------------------------------------------------------------------------- */

locals {
  # default Cloud Run environment variables
  default_cr_env = {
    SERVICE    = var.serviceName
    PROJECT_ID = var.dest_project_id
  }
  default_permissions = [
    "roles/cloudtrace.agent",
    "roles/run.invoker",
    "roles/monitoring.editor"
  ]
}

resource "google_cloud_run_service" "crservice" {
  name     = var.serviceName
  location = var.region

  depends_on = [
    google_project_iam_member.serviceaccount_cloudrun_default,
    google_project_iam_member.serviceaccount_cloudrun
  ]

  autogenerate_revision_name = true

  metadata {
    annotations = {
      "run.googleapis.com/ingress" = var.ingress
    }
  }

  template {
    spec {
      service_account_name  = google_service_account.serviceaccount.email
      container_concurrency = var.container_concurrency
      timeout_seconds       = var.timeout_seconds

      containers {
        image = var.image

        resources {
          limits = {
            memory = "${var.memoryLimitMB}Mi"
            cpu    = "${var.numberOfCPU * 1000}m"
          }
        }

        dynamic "env" {
          for_each = merge(local.default_cr_env, var.cr_env)

          content {
            name  = env.key
            value = env.value
          }
        }
      }
    }
    metadata {
      annotations = {
        "run.googleapis.com/vpc-access-egress"    = var.shared_vpc_connectorID != null ? "private-ranges-only" : null
        "run.googleapis.com/vpc-access-connector" = var.shared_vpc_connectorID != null ? var.shared_vpc_connectorID : null
        "run.googleapis.com/cpu-throttling"       = var.cpu_throttling
        "autoscaling.knative.dev/maxScale"        = var.maxInstances
        "autoscaling.knative.dev/minScale"        = var.minInstances
      }
    }
  }
}


/* -------------------------------------------------------------------------- */
/*                               Service Account                              */
/* -------------------------------------------------------------------------- */

resource "google_service_account" "serviceaccount" {
  account_id = var.serviceName
}

resource "google_project_iam_member" "serviceaccount_cloudrun_default" {
  for_each = toset(local.default_permissions)

  depends_on = [google_service_account.serviceaccount]

  project = var.dest_project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.serviceaccount.email}"

}

resource "google_project_iam_member" "serviceaccount_cloudrun" {
  # checkov:skip=CKV_GCP_41: Token user role is needed
  # checkov:skip=CKV_GCP_49: Token user role is needed
  for_each = var.permissions

  depends_on = [google_service_account.serviceaccount]

  project = var.dest_project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.serviceaccount.email}"

}

/* -------------------------------------------------------------------------- */
/*                     Cloud Run Invocation Authentication                    */
/* -------------------------------------------------------------------------- */
# If variable = true --> allow unauthenticated invocations of this Cloud Run service
resource "google_cloud_run_service_iam_member" "crauthenticationinvocation" {
  count = var.allowUnauthenticatedInvocations ? 1 : 0

  location = google_cloud_run_service.crservice.location
  project  = google_cloud_run_service.crservice.project
  service  = google_cloud_run_service.crservice.name
  role     = "roles/run.invoker"
  member   = "allUsers"
  # checkov:skip=CKV_GCP_102: Needs to be publicly accessible.
}
