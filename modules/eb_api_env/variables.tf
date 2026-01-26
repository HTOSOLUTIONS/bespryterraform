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

variable "env" {
  description = "Environment short name (dev|stage|prod)"
  type        = string
}

variable "ec2_key_name" {
  description = "Optional EC2 key pair name to enable SSH access to EB instances."
  type        = string
  default     = null
}

variable "ssh_ingress_cidr" {
  description = "Optional temporary CIDR allowed to SSH into EB instances."
  type        = string
  default     = null
}

