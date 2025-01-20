module "build_service_accounts" {
  source = "./modules/namespace/build_service_accounts"
}

module "dev_triggers" {
  source             = "./modules/reusable/build_trigger"
  env                = "dev"
  service_account_id = module.build_service_accounts.dev_sa.id
}

data "docker_registry_image" "next-app" {
  name = "${local.docker_repository_base_url}/next-app"
}

module "cr_next_app" {
  for_each = local.regions
  source   = "./modules/reusable/cloudrun"

  serviceName = "next-app"

  image                  = "${data.docker_registry_image.next-app.name}@${data.docker_registry_image.next-app.sha256_digest}"
  dest_project_id        = var.dest_project_id
  shared_vpc_connectorID = local.shared_vpc_connectorID
  maxInstances           = 3
  memoryLimitMB          = 2048
  numberOfCPU            = 1

  allowUnauthenticatedInvocations = false

  permissions = [
    "roles/logging.logWriter",
    "roles/cloudtrace.agent",
    "roles/run.invoker",
    "roles/monitoring.editor"
  ]

  region = each.key
}
