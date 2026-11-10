variable "project_id" {
  description = "Google Cloud project that owns the bucket."
  type        = string
}

variable "environment" {
  description = "Environment name: staging or production."
  type        = string

  validation {
    condition     = contains(["staging", "production"], var.environment)
    error_message = "environment must be staging or production."
  }
}

variable "name" {
  description = "Globally unique bucket name."
  type        = string
}

variable "location" {
  description = "Bucket location. Jakarta (DAT-01, pending legal confirmation)."
  type        = string
  default     = "ASIA-SOUTHEAST2"

  validation {
    condition     = upper(var.location) == "ASIA-SOUTHEAST2"
    error_message = "Household data must stay in asia-southeast2 until legal confirms otherwise (DAT-01)."
  }
}

variable "temp_prefix" {
  description = "Object prefix for uploads awaiting processing."
  type        = string
  default     = "tmp/"
}

variable "kms_key_name" {
  description = "Optional Cloud KMS key for default bucket encryption. Null uses Google-managed encryption."
  type        = string
  default     = null
}
