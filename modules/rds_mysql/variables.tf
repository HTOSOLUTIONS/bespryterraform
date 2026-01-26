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

# Permanent: allow MySQL ingress from this SG (your EB instances SG)
variable "allowed_security_group_id" {
  type    = string
  default = null
}

# Temporary: allow MySQL ingress from your dev machine (e.g. "47.x.x.x/32")
variable "developer_cidr" {
  description = "Optional TEMP ingress CIDR (e.g., your laptop public IP /32) for MySQL."
  type        = string
  default     = null
}


variable "tags" {
  type    = map(string)
  default = {}
}
