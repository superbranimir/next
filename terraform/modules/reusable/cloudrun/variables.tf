variable "dest_project_id" {
  type        = string
  description = "The identifier of the destination project."
}

variable "region" {
  type        = string
  description = "Region where the cloud run instance should be deployed."
}

variable "serviceName" {
  type        = string
  description = "Name of the Cloud Run service."
}

variable "image" {
  type        = string
  description = "image to run on cloud run"
}

variable "shared_vpc_connectorID" {
  type        = string
  description = "Shared vpc connector id."
  default     = null
}

variable "cr_env" {
  type        = map(any)
  description = "Cloud Run Environment Variables"
  default     = {}
}

variable "permissions" {
  type        = set(string)
  description = "Cloud Run Service Account Permissions"
  default     = []
}

variable "allowUnauthenticatedInvocations" {
  type        = bool
  description = "Allow unauthenticated invocations of the Cloud Run service"
  default     = false
}

variable "ingress" {
  type        = string
  description = "Network ingress setting for Cloud Run (all|internal|internal-and-cloud-load-balancing)"
  default     = "internal-and-cloud-load-balancing"

  validation {
    condition     = can(regex("^(all|internal|internal-and-cloud-load-balancing)$", var.ingress))
    error_message = "Possible values: all, internal, internal-and-cloud-load-balancing."
  }

}

variable "maxInstances" {
  type        = number
  description = "The maximum amount of instances the Cloud Run service will scale to"
  default     = 5
}

variable "minInstances" {
  type        = number
  description = "The minimum amount of instances the Cloud Run service will scale to"
  default     = 0
}

variable "memoryLimitMB" {
  type        = number
  description = "Cloud Run memory limit in MB (without denotation, e.g.: 4096)"
  default     = 512
}

variable "numberOfCPU" {
  type        = number
  description = "Cloud Run number of CPUs (without denotation, e.g.: 1)"
  default     = 1
}

variable "container_concurrency" {
  type        = number
  description = "The maximum allowed in-flight (concurrent) requests per container of the Revision, if 0(default), the cloud run service will manage the concurrency"
  default     = 120
}

variable "cpu_throttling" {
  type        = bool
  description = "If true the Cloud Run service will only be actively consuming CPU while handling requests (throttled), if false the CPU will always be available."
  default     = true
}

variable "timeout_seconds" {
  type        = number
  description = "The maximum duration the instance is allowed for responding to a request."
  default     = 300
}
