variable "env" {
  type    = string
  default = "dev"
}

variable "domain_root" {
  type    = string
  default = "bespry.net"
}

variable "api_subdomain" {
  type    = string
  default = "api"
}

# If Route53 hosted zone is in same account:
variable "route53_zone_name" {
  type    = string
  default = "bespry.net"
}
