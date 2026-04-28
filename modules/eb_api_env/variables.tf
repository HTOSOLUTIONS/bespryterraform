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

variable "application_name" {
  type        = string
  description = "Existing Elastic Beanstalk application name (shared across environments)"
}

variable "solution_stack_name" {
  type        = string
  description = "Optional: pin EB solution stack name to avoid auto-upgrading when most_recent changes."
  default     = null
}

variable "manage_http_listener" {
  type        = bool
  description = "Whether to manage ALB HTTP(80) listener settings via EB environment settings."
  default     = false
}

variable "enable_http_to_https_redirect" {
  type    = bool
  default = true
}
