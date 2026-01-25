variable "aws_region" {
  type    = string
  default = "us-east-1"
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
  # No default on purpose
}

variable "instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "allocated_storage" {
  type    = number
  default = 20
}

# Your current public IP, as x.x.x.x/32
variable "developer_cidr" {
  type = string
}

variable "publicly_accessible" {
  type    = bool
  default = true
}

variable "environment" {
  type    = string
  default = "dev"
}
