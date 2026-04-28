module "db" {
  source     = "../../modules/rds_mysql"
  identifier = "bespry-demo-db"

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password
  tags     = local.tags

  # TEMP: allow MySQL from your dev machine (Workbench)
  developer_cidr = var.developer_cidr

  # PERMANENT: allow MySQL from EB EC2 instances only
  allowed_security_group_id = module.eb_api.instance_security_group_id


  publicly_accessible = var.db_publicly_accessible


}
