variable "project_id" {
  description = "Google Cloud project for this environment. Staging and production are separate projects."
  type        = string
}

variable "region" {
  description = "Region for all data stores (DAT-01, pending legal confirmation)."
  type        = string
  default     = "asia-southeast2"

  validation {
    condition     = var.region == "asia-southeast2"
    error_message = "All data stores stay in asia-southeast2 until legal confirms otherwise (DAT-01)."
  }
}
