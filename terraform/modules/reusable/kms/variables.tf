variable "region" {
  type        = string
  description = "Region for the keyring that manages encryption keys for terraform"
  default     = "europe-west1"
}

variable "project_id" {
  type        = string
  description = "The identifier of the project."
}
