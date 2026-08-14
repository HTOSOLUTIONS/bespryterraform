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
  default = "16.13"
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

# Temporary: allow PostgreSQL ingress from developer machine CIDRs (e.g. ["47.x.x.x/32"])
variable "developer_cidr" {
  description = "Optional TEMP ingress CIDR list (typically laptop public IPs as /32) for PostgreSQL."
  type        = list(string)
  default     = []
}

variable "tags" {
  type    = map(string)
  default = {}
}

# Set to true to enable deletion protection for the RDS instance. Defaults to 7 days.
variable "backup_retention_period" {
  description = "Number of days to retain RDS automated backups for point-in-time recovery"
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_period >= 1 && var.backup_retention_period <= 35
    error_message = "backup_retention_period must be between 1 and 35 days."
  }
}

