module "db" {
  source     = "../../modules/rds_mysql"
  identifier = "bespry-stage-db"
  db_name    = var.db_name
  username   = var.db_username
  password   = var.db_password
  tags       = local.tags
}
