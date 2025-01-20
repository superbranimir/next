locals {
  regions = {
    us      = "us-central1"
    europe  = "europe-west1"
    oceania = "australia-southeast1"
  }
  docker_repository_base_url = "europe-docker.pkg.dev/next-cicd/${var.env}"
  shared_vpc_connectorID     = ""
}
