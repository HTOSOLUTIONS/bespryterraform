# Hosted zone in same AWS account
data "aws_route53_zone" "root" {
  name         = "${var.root_domain}."
  private_zone = false
}


# No idea
data "aws_caller_identity" "current" {}



# 1) ACM cert for api.stage.bespry.net, DNS-validated in Route53
module "api_cert" {
  source  = "../../modules/acm_api_cert"
  domain  = local.api_fqdn
  zone_id = data.aws_route53_zone.root.zone_id
}

# 2) Elastic Beanstalk environment (ALB + HTTPS with ACM cert)
module "eb_api" {
  source = "../../modules/eb_api_env"

  app_name = "bespry-api"
  env_name = "bespry-api-${var.env}"
  env      = var.env

  instance_type = var.instance_type
  min_size      = var.min_size
  max_size      = var.max_size

  vpc_id            = var.vpc_id
  public_subnet_ids = var.public_subnet_ids

  cert_arn = module.api_cert.cert_arn

  environment_variables = merge(
    {
      APP_ENV = "stage"
      # app config
      DB_HOST = module.db.endpoint
      DB_NAME = module.db.db_name
      DB_PORT = tostring(module.db.port)
      DB_USER = var.db_username
      DB_PASS = var.db_password

      S3_BUCKET = module.app_bucket.bucket_name

      COGNITO_USER_POOL_ID     = module.cognito.user_pool_id
      COGNITO_USER_POOL_CLIENT = module.cognito.user_pool_client_id
    },
    var.api_env_vars
  )

  service_role_arn      = var.eb_service_role_arn
  instance_profile_name = aws_iam_instance_profile.api_instance_profile.name

  ec2_key_name     = aws_key_pair.eb_ssh.key_name
  ssh_ingress_cidr = var.ssh_ingress_cidr

}

# 3) Route53 record -> EB environment CNAME
resource "aws_route53_record" "api_stage" {
  depends_on = [module.eb_api] # ensures env exists before DNS
  zone_id    = data.aws_route53_zone.root.zone_id
  name       = local.api_fqdn
  type       = "CNAME"
  ttl        = 60
  records    = [module.eb_api.environment_cname]
}
