variable "app_name" { type = string }
variable "env_name" { type = string }

variable "instance_type" { type = string }
variable "min_size"      { type = number }
variable "max_size"      { type = number }

variable "cert_arn" { type = string }

variable "environment_variables" {
  type    = map(string)
  default = {}
}

variable "vpc_id" {
  type    = string
  default = null
}

variable "public_subnet_ids" {
  type    = list(string)
  default = null
}

variable "service_role_arn" {
  type = string
}

variable "instance_profile_name" {
  type = string
}
