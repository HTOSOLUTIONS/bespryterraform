module "api_cert" {
  source = "../../modules/acm_api_cert"

  env              = var.env
  domain_name      = "${var.api_subdomain}.${var.domain_root}" # api.bespry.net
  route53_zone_name = var.route53_zone_name

  tags = local.tags
}

module "eb_api" {
  source = "../../modules/eb_api_env"

  env       = var.env
  app_name  = local.app_name

  api_cert_arn = module.api_cert.arn

  # FIRST concrete win: set env var to match your Program.cs loader
  aspnetcore_environment = var.env # dev|stage|prod

  tags = local.tags
}
