variable "aws_region" {
  type    = string
  default = "us-east-2"
}

variable "project" {
  type    = string
  default = "bespry"
  description = "Used for naming tfstate resources."
}

variable "bucket_name_override" {
  type        = string
  default     = ""
  description = "Optional: set an explicit globally-unique bucket name. Leave blank to auto-generate using account id."
}
