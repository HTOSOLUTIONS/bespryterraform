variable "identifier" {
  type = string
}

variable "db_name" {
  type = string
}

variable "username" {
  type = string
}

variable "password" {
  type      = string
  sensitive = true
}

variable "instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "allocated_storage" {
  type    = number
  default = 20
}

# Pick a sane modern default; override per environment.
# Examples: "15.7", "16.3", etc.
variable "engine_version" {
  type    = string
  default = "16.10"
}

variable "db_port" {
  description = "Database port"
  type        = number
  default     = 5432
}

variable "vpc_id" {
  type    = string
  default = null
}

variable "subnet_ids" {
  type    = list(string)
  default = null
}

variable "publicly_accessible" {
  type    = bool
  default = false
}

# Permanent: allow PostgreSQL ingress from these SGs
variable "allowed_security_group_ids" {
  type        = list(string)
  description = "Security group IDs allowed to access RDS on db_port (typically EB instance SGs)."

  validation {
    condition     = length(var.allowed_security_group_ids) > 0
    error_message = "allowed_security_group_ids must contain at least one security group id."
  }
}

# Temporary: allow PostgreSQL ingress from your dev machine (e.g. "47.x.x.x/32")
variable "developer_cidr" {
  description = "Optional TEMP ingress CIDR (e.g., your laptop public IP /32) for PostgreSQL."
  type        = string
  default     = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
