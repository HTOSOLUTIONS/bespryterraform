module "cognito" {
  source      = "../../modules/cognito_user_pool"
  name        = "bespry-${var.env}-userpool"
  client_name = "bespry-${var.env}-web"
  tags        = local.tags
}
