output "name" {
  description = "Bucket name."
  value       = google_storage_bucket.photos.name
}

output "temp_prefix" {
  description = "Prefix that the lifecycle backstop applies to."
  value       = var.temp_prefix
}
