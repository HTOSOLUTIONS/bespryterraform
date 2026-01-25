data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id

  # S3 bucket names must be globally unique
  state_bucket_name = (
    var.bucket_name_override != ""
    ? var.bucket_name_override
    : "${var.project}-terraform-state-${local.account_id}-${var.aws_region}"
  )

  lock_table_name = "${var.project}-terraform-locks"
}

resource "aws_s3_bucket" "tf_state" {
  bucket = local.state_bucket_name

  tags = {
    Name    = local.state_bucket_name
    Project = var.project
    Purpose = "terraform-remote-state"
  }
}

# Block all public access (strong default)
resource "aws_s3_bucket_public_access_block" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning (protects against accidental overwrites)
resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Default SSE encryption (AES256). (KMS optional later.)
resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Enforce bucket owner; disables ACLs (recommended modern setting)
resource "aws_s3_bucket_ownership_controls" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# Terraform state lock table
resource "aws_dynamodb_table" "tf_locks" {
  name         = local.lock_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name    = local.lock_table_name
    Project = var.project
    Purpose = "terraform-state-locking"
  }
}
