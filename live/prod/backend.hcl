# Terraform remote state config for prod
bucket         = "REPLACE_ME_tfstate_bucket"
key            = "bespry/prod/terraform.tfstate"
region         = "us-east-1"
dynamodb_table = "REPLACE_ME_tfstate_lock_table"
encrypt        = true
