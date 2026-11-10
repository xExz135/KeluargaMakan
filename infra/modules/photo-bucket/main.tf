# UNVALIDATED SKELETON: not yet run through `terraform validate` or applied.
# Requires security-reviewer review (data location, storage) before any apply.
#
# Temporary photo storage (SET-05, DAT-03). The application deletes each photo
# right after processing; the lifecycle rule below is only the backstop.

resource "google_storage_bucket" "photos" {
  project       = var.project_id
  name          = var.name
  location      = var.location
  storage_class = "STANDARD"
  force_destroy = false

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = false
  }

  # Deleted photos must not be recoverable: disable soft delete, which would
  # otherwise keep deleted objects for 7 days by default.
  soft_delete_policy {
    retention_duration_seconds = 0
  }

  # Backstop: delete anything in the temporary prefix older than 1 day.
  # Age is counted in whole days and lifecycle actions run asynchronously, so
  # monitoring alerts on objects older than 1 hour (deletion job health).
  lifecycle_rule {
    condition {
      age            = 1
      matches_prefix = [var.temp_prefix]
    }
    action {
      type = "Delete"
    }
  }

  lifecycle_rule {
    condition {
      age = 1
    }
    action {
      type = "AbortIncompleteMultipartUpload"
    }
  }

  dynamic "encryption" {
    for_each = var.kms_key_name == null ? [] : [var.kms_key_name]
    content {
      default_kms_key_name = encryption.value
    }
  }

  labels = {
    app         = "keluargamakan"
    environment = var.environment
    data        = "photos-temporary"
  }
}
