Terraform “bootstrap” folder (local state) that creates:

- S3 bucket for Terraform remote state (shared across everything)

- 1 DynamoDB table for state locking

- In us-east-2

- With sane defaults: versioning, encryption, public access block, bucket owner enforced