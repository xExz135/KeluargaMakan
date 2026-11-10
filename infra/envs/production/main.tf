# UNVALIDATED SKELETON: not yet run through `terraform validate` or applied.
# Production apply is a human gate; IAM, keys and data location changes need
# security-reviewer review.

terraform {
  required_version = ">= 1.9"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 8.10"
    }
  }

  # State bucket is supplied at init time:
  #   terraform init -backend-config="bucket=<state bucket>" -backend-config="prefix=production"
  backend "gcs" {}
}

provider "google" {
  project = var.project_id
  region  = var.region
}

module "photo_bucket" {
  source = "../../modules/photo-bucket"

  project_id  = var.project_id
  environment = "production"
  name        = "${var.project_id}-photos-tmp"
  location    = var.region
}
