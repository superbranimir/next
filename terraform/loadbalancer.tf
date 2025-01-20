resource "google_compute_region_network_endpoint_group" "us-next-serverless-neg" {
  name                  = "us-app-be-neg"
  network_endpoint_type = "SERVERLESS"
  region                = local.regions.us
  cloud_run {
    service = module.cr_next_app[us].cloudrunservice.name
  }
}

resource "google_compute_region_network_endpoint_group" "eu-next-serverless-neg" {
  name                  = "eu-app-be-neg"
  network_endpoint_type = "SERVERLESS"
  region                = local.regions.europe
  cloud_run {
    service = module.cr_next_app[europe].cloudrunservice.name
  }
}

resource "google_compute_region_network_endpoint_group" "oc-next-serverless-neg" {
  name                  = "oc-app-be-neg"
  network_endpoint_type = "SERVERLESS"
  region                = local.regions.oceania
  cloud_run {
    service = module.cr_next_app[oceania].cloudrunservice.name
  }
}

module "loadbalancer" {
  source = "./modules/reusable/lb_http_neg"
  name   = "global-lb-coverage"

  backends = {
    default = {
      project    = var.dest_project_id
      protocol   = "HTTPS"
      enable_cdn = true

      log_config = {
        enable = false
      }

      groups = [
        {
          # Your serverless service should have a NEG created that's referenced here.
          group = google_compute_region_network_endpoint_group.us-next-serverless-neg.id
        },
        {
          # Your serverless service should have a NEG created that's referenced here.
          group = google_compute_region_network_endpoint_group.eu-next-serverless-neg.id
        },
        {
          # Your serverless service should have a NEG created that's referenced here.
          group = google_compute_region_network_endpoint_group.oc-next-serverless-neg.id
        }
      ]

      iap_config = {
        enable = false
      }
    }
  }
}
