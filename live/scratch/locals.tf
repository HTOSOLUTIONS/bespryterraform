locals {
  tags = {
    App       = "BeSpry"
    Env       = var.env
    ManagedBy = "Terraform"
  }

  api_fqdn = "${var.api_subdomain}.${var.root_domain}"
}
