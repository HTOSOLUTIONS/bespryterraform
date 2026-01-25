# Terraform remote state config for dev
bucket         = "REPLACE_ME_tfstate_bucket"
key            = "bespry/dev/terraform.tfstate"
region         = "us-east-1"
dynamodb_table = "REPLACE_ME_tfstate_lock_table"
encrypt        = true
