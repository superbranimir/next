variable "env" {
  type        = string
  description = "Environment variable"
  default     = "dev"
}

variable "dest_project_id" {
  type        = string
  description = "Where should the resource be deployed."
}
