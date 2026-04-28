# Hosted zone in same AWS account
data "aws_route53_zone" "root" {
  name         = "${var.root_domain}."
  private_zone = false
}


# No idea
data "aws_caller_identity" "current" {}

locals {
  logging_suffix = "_${var.env}"

  api_logging = {
    Controllers = "APINlog${local.logging_suffix}"
    Microsoft  = "APINLog_MicrosoftLogs${local.logging_suffix}"
    Warnings   = "APINLogWarnings${local.logging_suffix}"
    Errors     = "APINLogErrors${local.logging_suffix}"
    Info  = "APINLogInfo${local.logging_suffix}"
  }

  service_logging = {
    Microsoft  = "BeSpryServiceMicrosoftLogs${local.logging_suffix}"
    Warnings   = "BeSpryServiceNLogWarnings${local.logging_suffix}"
    Errors     = "BeSpryServiceNLogErrors${local.logging_suffix}"
    Info     = "BeSpryServiceNLogInfo${local.logging_suffix}"
  }


  dotnet_api_aws_env = {
    "AWS__Region"               = var.aws_region

    "AWS__Logging__Controllers" = local.api_logging.Controllers
    "AWS__Logging__Microsoft"   = local.api_logging.Microsoft
    "AWS__Logging__Warnings"    = local.api_logging.Warnings
    "AWS__Logging__Errors"      = local.api_logging.Errors

    "AWS__Cognito__Region"      = var.aws_region
    "AWS__Cognito__PoolId"      = module.cognito.user_pool_id
    "AWS__Cognito__ClientId"    = module.cognito.user_pool_client_id


    "Sqs__QueueUrl" = aws_sqs_queue.reminders.url

  }

  dotnet_service_aws_env = {
    "AWS__Region"               = var.aws_region

    "AWS__Logging__Microsoft"   = local.service_logging.Microsoft
    "AWS__Logging__Warnings"    = local.service_logging.Warnings
    "AWS__Logging__Errors"      = local.service_logging.Errors
    "AWS__Logging__Info"        = local.service_logging.Info

    "Sqs__QueueUrl" = aws_sqs_queue.reminders.url

  }

}


# 1) ACM cert for api.dev.bespry.net, DNS-validated in Route53
module "api_cert" {
  count = var.enable_acm ? 1 : 0
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
  application_name = "bespry-api"
  enable_http_to_https_redirect = true
  solution_stack_name = var.solution_stack_name

  instance_type = var.instance_type
  min_size      = var.min_size
  max_size      = var.max_size

  vpc_id            = var.vpc_id
  public_subnet_ids = var.public_subnet_ids

  cert_arn = var.enable_acm ? module.api_cert[0].cert_arn : null

	environment_variables = merge(
	  {
		APP_ENV = var.env

		# app config (temporary - we'll replace with Secrets Manager shortly)
		# DB_HOST = module.db.endpoint
		# DB_NAME = module.db.db_name
		# DB_PORT = tostring(module.db.port)
		# DB_USER = var.db_username
		# DB_PASS = var.db_password   # <-- REMOVE THIS LINE

		# New: tell the app which secret to read (we'll create it next step)
		BESPRY_CONFIG_SECRET_ID = "bespry/${var.env}/config"

		S3_BUCKET = module.app_bucket.bucket_name

	  },
	  local.dotnet_api_aws_env,    # <-- this is the new .NET config structure
	  var.api_env_vars
  )


  service_role_arn      = var.eb_service_role_arn
  instance_profile_name = aws_iam_instance_profile.api_instance_profile.name

  ec2_key_name     = var.ec2_key_name
  ssh_ingress_cidr = var.ssh_ingress_cidr

}


# 2b) EB Environment for Service
module "eb_service" {
  source = "../../modules/eb_api_env"

  app_name         = "bespry-api"
  env_name         = "bespry-service-${var.env}"
  env              = var.env
  application_name = "bespry-api"
  enable_http_to_https_redirect = false
  solution_stack_name = var.solution_stack_name

  instance_type = "t3.micro"
  min_size      = 1
  max_size      = 1

  vpc_id            = var.vpc_id
  public_subnet_ids = var.public_subnet_ids

  # ❌ No HTTPS / cert needed for worker
  cert_arn = null

  environment_variables = merge(
    {
      APP_ENV                 = var.env
      BESPRY_CONFIG_SECRET_ID = "bespry/${var.env}/config"
    }, 
	local.dotnet_service_aws_env  # <-- this is the new .NET config structure
  )

  service_role_arn      = var.eb_service_role_arn
  instance_profile_name = aws_iam_instance_profile.api_instance_profile.name

  ec2_key_name     = var.ec2_key_name
  ssh_ingress_cidr = var.ssh_ingress_cidr
}




# 3) Route53 record -> EB environment CNAME
resource "aws_route53_record" "api_dev" {
  depends_on = [module.eb_api] # ensures env exists before DNS
  zone_id    = data.aws_route53_zone.root.zone_id
  name       = local.api_fqdn
  type       = "CNAME"
  ttl        = 60
  records    = [module.eb_api.environment_cname]
}

# 4) SQS QUEUE
resource "aws_sqs_queue" "reminders" {
  name                       = "bespry-${var.env}-reminders"
  visibility_timeout_seconds = 60
  message_retention_seconds  = 345600
  receive_wait_time_seconds  = 20
}