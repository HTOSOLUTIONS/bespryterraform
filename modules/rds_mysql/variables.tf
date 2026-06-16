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

variable "engine_version" {
  type    = string
  default = "8.0"
}

variable "db_port" {
  description = "Database port"
  type    = number
  default = 3306
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
  type        = map(string)
  default     = {}
  description = "Security group IDs allowed to access RDS on db_port (typically EB instance SGs)."

  validation {
    condition     = length(var.allowed_security_group_ids) > 0
    error_message = "allowed_security_group_ids must contain at least one security group id."
  }
}


# Temporary: allow MySQL ingress from developer machine CIDRs (e.g. ["47.x.x.x/32"])
variable "developer_cidr" {
  description = "Optional TEMP ingress CIDR list (typically laptop public IPs as /32) for MySQL."
  type        = list(string)
  default     = []
}


variable "tags" {
  type    = map(string)
  default = {}
}
