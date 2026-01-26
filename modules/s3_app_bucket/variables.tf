variable "bucket_name" {
  description = "Name of the S3 bucket to create"
  type        = string
}

variable "tags" {
  description = "Tags applied to the S3 bucket and related resources"
  type        = map(string)
  default     = {}
}

variable "versioning" {
  description = "Enable versioning on the bucket"
  type        = bool
  default     = true
}

variable "force_destroy" {
  description = "Allow Terraform to delete the bucket even if it contains objects (use with care)"
  type        = bool
  default     = false
}
