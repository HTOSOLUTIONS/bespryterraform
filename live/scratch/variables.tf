variable "aws_region" {
  type    = string
  default = "us-east-2"
}

variable "env" {
  type    = string
  default = "dev"
}

variable "root_domain" {
  type    = string
  default = "bespry.net"
}

# Creates api.dev.bespry.net
variable "api_subdomain" {
  type    = string
  default = "api.dev"
}

# EB sizing (POC defaults)
variable "instance_type" {
  type    = string
  default = "t3.small"
}

variable "min_size" {
  type    = number
  default = 1
}

variable "max_size" {
  type    = number
  default = 2
}

# Optional: keep null for POC (default VPC + its subnets)
variable "vpc_id" {
  type    = string
  default = null
}

variable "public_subnet_ids" {
  type    = list(string)
  default = null
}

# Extra env vars injected into EB
variable "api_env_vars" {
  type    = map(string)
  default = {}
}


variable "eb_service_role_arn" {
  type    = string
  default = "arn:aws:iam::891377401485:role/service-role/aws-elasticbeanstalk-service-role-bespry"
}

variable "db_name" {
  type    = string
  default = "appdb"
}


variable "db_username" {
  type    = string
  default = "app_admin"
}


variable "db_password" {
  type      = string
  sensitive = true
}

variable "db_engine" {
  description = "Database engine for this stack. Valid: mysql | postgres"
  type        = string
  default     = "mysql"

  validation {
    condition     = contains(["mysql", "postgres"], var.db_engine)
    error_message = "db_engine must be one of: mysql, postgres"
  }
}

variable "ssh_ingress_cidr" {
  type    = string
  default = null
}

variable "developer_cidr" {
  type    = string
  default = null
}

variable "db_publicly_accessible" {
  type    = bool
  default = false
}

variable "solution_stack_name" {
  type        = string
  default     = null
  description = "Optional: pin EB platform version for this environment."
}