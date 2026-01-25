# Root module for prod
# Recommended: keep this file thinâ€”wire modules together here.

module "eb_api_env" {
  source = "../../modules/eb_api_env"

  # Example inputs (define in your module as needed)
  # env        = "prod"
  # project    = local.project
  # tags       = local.tags
  # aws_region = var.aws_region
}

# Optional modules
# module "acm_api_cert" {
#   source = "../../modules/acm_api_cert"
# }

# module "amplify_app" {
#   source = "../../modules/amplify_app"
# }

# module "route53" {
#   source = "../../modules/route53"
# }
