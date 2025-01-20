variable "env" {
  type        = string
  description = "Environment where the trigger should be configured for."
}
variable "service_account_id" {
  type        = string
  description = "ID service needed to create and run the trigger"
}
