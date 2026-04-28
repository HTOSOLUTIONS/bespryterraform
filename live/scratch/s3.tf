module "app_bucket" {
  source      = "../../modules/s3_app_bucket"
  bucket_name = "bespry-dev-app-${data.aws_caller_identity.current.account_id}-${var.aws_region}"
  tags        = local.tags
}
