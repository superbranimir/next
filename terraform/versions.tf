terraform {
  required_version = ">=1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.14.0, < 7"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 2.1"
    }
  }

  backend "gcs" {
    bucket = "next-tfstate"
  }
}
