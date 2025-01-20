locals {
  buildProject = "next-builder"
  envsGithub = {
    owner = "superbranimir"
    repo  = "next"
  }
}

resource "google_cloudbuild_trigger" "ci" {
  project            = local.buildProject
  service_account    = var.service_account_id
  include_build_logs = "INCLUDE_BUILD_LOGS_WITH_STATUS"

  name     = "${var.env}-ci"
  location = "global"
  filename = "build/configs/env-ci.yaml"
  tags     = [var.env, "ci"]

  ignored_files  = ["*"] # files in root are ignored
  included_files = []
  substitutions = {
    "_ENV"           = var.env
    "_IMAGE_VERSION" = "$${SHORT_SHA}"
  }

  github {
    owner = local.envsGithub.owner
    name  = local.envsGithub.repo
    push {
      branch = "^${var.env}$"
    }
  }
  approval_config {
    approval_required = true
  }
}

resource "google_cloudbuild_trigger" "dev-plan" {
  project         = local.buildProject
  service_account = var.service_account_id

  name     = "${var.env}-plan"
  location = "global"
  filename = "build/configs/env-plan.yaml"
  tags     = [var.env, "plan"]

  ignored_files  = []
  included_files = []
  substitutions = {
    "_ENV" = var.env
  }

  source_to_build {
    uri       = "https://github.com/${local.envsGithub.owner}/${local.envsGithub.repo}"
    ref       = "refs/heads/${var.env}"
    repo_type = "GITHUB"
  }
}

resource "google_cloudbuild_trigger" "dev-cd" {
  project         = local.buildProject
  service_account = var.service_account_id

  name     = "${var.env}-cd"
  location = "global"
  filename = "build/configs/env-cd.yaml"
  tags     = [var.env, "cd"]

  ignored_files  = []
  included_files = []
  substitutions = {
    "_ENV" = var.env
  }

  source_to_build {
    uri       = "https://github.com/${local.envsGithub.owner}/${local.envsGithub.repo}"
    ref       = "refs/heads/${var.env}"
    repo_type = "GITHUB"
  }

  approval_config {
    approval_required = true
  }
}