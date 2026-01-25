# Providers shared across all environments
variable "aws_region" {
  type    = string
  default = "us-east-2"
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.tags
  }
}
