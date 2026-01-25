variable "aws_region" {
  type    = string
  default = "us-east-1"
}

# Optional if you use AWS profiles locally (SSO, named profiles, etc.)
# variable "aws_profile" {
#   type    = string
#   default = "default"
# }

variable "environment" {
  type    = string
  default = "prod"
}
