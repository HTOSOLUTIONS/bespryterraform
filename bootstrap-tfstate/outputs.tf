output "tf_state_bucket_name" {
  value       = aws_s3_bucket.tf_state.bucket
  description = "S3 bucket name for Terraform remote state."
}

output "tf_lock_table_name" {
  value       = aws_dynamodb_table.tf_locks.name
  description = "DynamoDB table name for Terraform state locking."
}

output "aws_region" {
  value       = var.aws_region
  description = "Region these resources were created in."
}
